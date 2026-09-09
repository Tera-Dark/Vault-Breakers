#!/usr/bin/env python3
"""Deterministic, dependency-free builder for this project's source-only Roblox place.

Implements a deliberately small subset of Roblox binary/XML serialization: folders,
services, LuaSourceContainers, names and Script.RunContext. The complete set is built
by StageBuilder when Play starts. This is not a general Rojo replacement; unfamiliar
project keys fail closed. Roblox Studio is required to verify native place loading.
"""
from __future__ import annotations
import argparse
from collections import defaultdict
from dataclasses import dataclass
import hashlib
import json
from pathlib import Path
import struct
import sys
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
MAGIC = b"<roblox!\x89\xff\r\n\x1a\n"
SERVICES = {"ReplicatedStorage", "ServerScriptService", "StarterPlayer"}

@dataclass
class Node:
    name: str
    cls: str
    parent: int
    ref: int
    source_path: str | None = None
    source: str | None = None

def collect() -> list[Node]:
    project = json.loads((ROOT / "default.project.json").read_text(encoding="utf-8"))
    if project["tree"].get("$className") != "DataModel":
        raise ValueError("Expected a DataModel root")
    nodes = []
    def add(name, cls, parent, file=None):
        node = Node(name, cls, parent, len(nodes))
        if file:
            node.source_path = file.relative_to(ROOT).as_posix()
            node.source = file.read_text(encoding="utf-8")
        nodes.append(node)
        return node.ref
    def directory(folder, parent):
        for file in sorted(folder.iterdir(), key=lambda f: f.name):
            if file.is_dir():
                directory(file, add(file.name, "Folder", parent))
            elif file.suffix == ".luau":
                if file.name.endswith(".server.luau"): cls, name = "Script", file.name[:-12]
                elif file.name.endswith(".client.luau"): cls, name = "LocalScript", file.name[:-12]
                else: cls, name = "ModuleScript", file.stem
                add(name, cls, parent, file)
            else:
                raise ValueError(f"Unsupported source-tree file: {file}")
    def mount(name, item, parent):
        unsupported = [k for k in item if k.startswith("$") and k not in {"$className", "$path"}]
        if unsupported: raise ValueError(f"Unsupported project keys: {unsupported}")
        ref = add(name, item.get("$className", "Folder"), parent)
        if "$path" in item:
            directory(ROOT / item["$path"], ref)
        for child, spec in sorted(item.items()):
            if not child.startswith("$"): mount(child, spec, ref)
    for name, spec in sorted(project["tree"].items()):
        if not name.startswith("$"): mount(name, spec, -1)
    return nodes

def string(value: str) -> bytes:
    encoded = value.encode("utf-8")
    return struct.pack("<I", len(encoded)) + encoded

def interleave(values, signed_delta=False):
    if signed_delta:
        prev, result = 0, []
        for value in values:
            delta, prev = value - prev, value
            result.append(((delta << 1) ^ (delta >> 31)) & 0xffffffff)
        values = result
    words = [struct.pack(">I", v) for v in values]
    return bytes(word[i] for i in range(4) for word in words)

def chunk(tag, payload):
    return tag + struct.pack("<III", 0, len(payload), 0) + payload

def binary(nodes):
    classes = defaultdict(list)
    for node in nodes: classes[node.cls].append(node)
    groups = sorted(classes.items())
    output = [MAGIC + struct.pack("<HIIQ", 0, len(groups), len(nodes), 0)]
    for cid, (cls, items) in enumerate(groups):
        service = cls in SERVICES
        payload = struct.pack("<I", cid) + string(cls) + bytes([service]) + struct.pack("<I", len(items))
        payload += interleave([n.ref for n in items], True)
        if service: payload += bytes([1] * len(items))
        output.append(chunk(b"INST", payload))
    for cid, (cls, items) in enumerate(groups):
        def prop(name, kind, values):
            output.append(chunk(b"PROP", struct.pack("<I", cid) + string(name) + bytes([kind]) + values))
        prop("Name", 1, b"".join(string(n.name) for n in items))
        if items[0].source is not None:
            prop("Source", 1, b"".join(string(n.source) for n in items))
        if cls == "Script":
            prop("RunContext", 0x12, interleave([1] * len(items)))  # Enum.RunContext.Server
    payload = bytes([0]) + struct.pack("<I", len(nodes))
    payload += interleave([n.ref for n in nodes], True)
    payload += interleave([n.parent for n in nodes], True)
    output += [chunk(b"PRNT", payload), chunk(b"END\0", b"</roblox>")]
    return b"".join(output)

# Reverse decoder validates counts, paths, references and embedded source parity.
# Accepts LZ4 chunks as well, so a separately Rojo-built file can be checked when liblz4 is installed.
def decode(data):
    if not data.startswith(MAGIC): raise ValueError("Not a Roblox binary place")
    version, class_count, instance_count, reserved = struct.unpack_from("<HIIQ", data, 14)
    if version or reserved: raise ValueError("Unsupported binary header")
    nodes, classes = {}, {}
    pos, ended = 32, False
    def read_string(buf, cursor):
        size = struct.unpack_from("<I", buf, cursor)[0]; cursor += 4
        return buf[cursor:cursor+size].decode("utf-8"), cursor+size
    def integers(buf, cursor, count, deltas=False):
        values = [int.from_bytes(bytes(buf[cursor+i+j*count] for j in range(4)), "big") for i in range(count)]
        if deltas:
            total, refs = 0, []
            for value in values: total += (value >> 1) ^ -(value & 1); refs.append(total)
            values = refs
        return values, cursor+count*4
    while pos < len(data):
        tag, compressed, raw, flags = struct.unpack_from("<4sIII", data, pos); pos += 16
        if flags: raise ValueError("Unexpected chunk flags")
        payload = data[pos:pos+(compressed or raw)]; pos += compressed or raw
        if compressed:
            import ctypes, ctypes.util
            library = ctypes.util.find_library("lz4")
            if not library: raise ValueError("Compressed check requires native liblz4; our builder itself has no dependency")
            lz4 = ctypes.CDLL(library)
            lz4.LZ4_decompress_safe.argtypes = [ctypes.c_char_p, ctypes.c_void_p, ctypes.c_int, ctypes.c_int]
            lz4.LZ4_decompress_safe.restype = ctypes.c_int
            decoded = ctypes.create_string_buffer(raw)
            if lz4.LZ4_decompress_safe(payload, decoded, compressed, raw) != raw: raise ValueError("Invalid LZ4 chunk")
            payload = decoded.raw
        if len(payload) != raw: raise ValueError("Truncated chunk")
        if tag == b"INST":
            cid = struct.unpack_from("<I", payload)[0]
            cls, p = read_string(payload, 4); service = payload[p]; p += 1
            count = struct.unpack_from("<I", payload, p)[0]; p += 4
            refs, p = integers(payload, p, count, True)
            if service: p += count
            if p != len(payload): raise ValueError("Invalid INST length")
            if cid in classes or any(ref in nodes for ref in refs): raise ValueError("Duplicate class/reference")
            classes[cid] = refs
            for ref in refs: nodes[ref] = {"class": cls, "props": {}, "parent": None}
        elif tag == b"PROP":
            cid = struct.unpack_from("<I", payload)[0]
            name, p = read_string(payload, 4); kind = payload[p]; p += 1
            refs = classes[cid]
            if kind == 1:
                values = []
                for _ in refs: value, p = read_string(payload, p); values.append(value)
            elif kind == 0x12:
                values, p = integers(payload, p, len(refs))
            else:
                continue  # Properties outside our source-only subset are irrelevant to source parity.
            if p != len(payload): raise ValueError("Invalid PROP length")
            for ref, value in zip(refs, values): nodes[ref]["props"][name] = value
        elif tag == b"PRNT":
            if payload[0]: raise ValueError("Unknown parent format")
            count = struct.unpack_from("<I", payload, 1)[0]
            refs, p = integers(payload, 5, count, True)
            parents, p = integers(payload, p, count, True)
            if p != len(payload) or count != instance_count: raise ValueError("Invalid PRNT length/count")
            for ref, parent in zip(refs, parents):
                if parent != -1 and parent not in nodes: raise ValueError("Invalid parent reference")
                nodes[ref]["parent"] = parent
        elif tag == b"END\0":
            if payload != b"</roblox>": raise ValueError("Invalid file terminator")
            ended = True
            if pos != len(data): raise ValueError("Trailing binary content")
            break
    if not ended or len(nodes) != instance_count or len(classes) != class_count: raise ValueError("Header count mismatch")
    def node_path(ref, visited=None):
        visited = set() if visited is None else visited
        if ref in visited: raise ValueError("Parent cycle")
        visited.add(ref); node = nodes[ref]
        if node["parent"] is None: raise ValueError("Missing parent")
        prefix = "" if node["parent"] == -1 else node_path(node["parent"], visited) + "/"
        return prefix + node["props"]["Name"]
    return {node_path(ref): node for ref, node in nodes.items()}

def expected(nodes):
    def node_path(n): return (node_path(nodes[n.parent]) + "/" if n.parent >= 0 else "") + n.name
    return {node_path(n): n for n in nodes}

def verify(data, nodes):
    actual, wanted = decode(data), expected(nodes)
    if set(actual) != set(wanted): raise ValueError("Place hierarchy differs from default.project.json")
    for path, node in wanted.items():
        saved = actual[path]
        if saved["class"] != node.cls: raise ValueError(f"Class differs: {path}")
        if saved["props"].get("Source") != node.source: raise ValueError(f"Embedded source is stale: {node.source_path}")
        if node.cls == "Script" and saved["props"].get("RunContext") != 1: raise ValueError("Server RunContext is missing")
    return len([n for n in nodes if n.source is not None])

def xml(nodes):
    doc = ET.Element("roblox", version="4")
    ET.SubElement(doc, "External").text = "null"
    ET.SubElement(doc, "External").text = "nil"
    elements = {}
    for n in nodes:
        item = ET.SubElement(doc if n.parent == -1 else elements[n.parent], "Item", {"class": n.cls, "referent": f"RBX{n.ref}"})
        elements[n.ref] = item
        properties = ET.SubElement(item, "Properties")
        ET.SubElement(properties, "string", name="Name").text = n.name
        if n.source is not None: ET.SubElement(properties, "ProtectedString", name="Source").text = n.source
        if n.cls == "Script": ET.SubElement(properties, "token", name="RunContext").text = "1"
    ET.indent(doc, space="  ")
    return ET.tostring(doc, encoding="utf-8", xml_declaration=True)

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="Verify the existing binary's embedded sources, without rewriting it")
    parser.add_argument("--output", type=Path, default=ROOT/"VaultBreakers.rbxl")
    parser.add_argument("--xml", type=Path, help="Also emit an optional readable .rbxlx Studio place")
    args = parser.parse_args()
    nodes = collect()
    if args.check:
        count = verify(args.output.read_bytes(), nodes)
        print(f"PASS: {count} embedded sources, hierarchy and server RunContext match source. Native Studio loading is not certified.")
        return
    data = binary(nodes); count = verify(data, nodes)
    args.output.parent.mkdir(parents=True, exist_ok=True); args.output.write_bytes(data)
    if args.xml:
        args.xml.parent.mkdir(parents=True, exist_ok=True); args.xml.write_bytes(xml(nodes))
    manifest = {"format": "Roblox binary v0; uncompressed source-only place", "builder": "scripts/build-place.py", "instances": len(nodes), "scriptCount": count, "sha256": hashlib.sha256(data).hexdigest(), "studioValidated": False,
                "sources": {n.source_path: hashlib.sha256(n.source.encode("utf-8")).hexdigest() for n in nodes if n.source is not None}}
    (ROOT/"docs").mkdir(exist_ok=True)
    (ROOT/"docs/build-manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2)+"\n", encoding="utf-8")
    print(f"Built {args.output.name}: {len(data):,} bytes, {len(nodes)} Instances, {count} verified embedded sources.")
    print("Scene is created on Play. Open/playtest in Roblox Studio before publishing.")

if __name__ == "__main__":
    try: main()
    except (OSError, ValueError, KeyError, struct.error) as error: sys.exit(str(error))
