#!/usr/bin/env python3
"""Optional OFL-licensed fonts for offline review only; never runtime assets.
Requires the GitHub CLI. Downloads pinned public blobs to ignored .cache/fonts.
"""
import base64
import hashlib
import json
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[1]
FONTS = (
    ("google/fonts", "304e608cb0717db90ac2c54ead2d0a86324aaa68", "FredokaOne.ttf"),
    ("notofonts/noto-cjk", "ff4c0450e8a5bf0290fbb6013a72dc61a10e8e56", "NotoSansCJKsc-Bold.otf"),
)

def blob_id(content):
    return hashlib.sha1(b"blob " + str(len(content)).encode() + b"\0" + content).hexdigest()

def main():
    folder = ROOT / ".cache/fonts"
    folder.mkdir(parents=True, exist_ok=True)
    for repo, sha, name in FONTS:
        file = folder / name
        if file.exists() and blob_id(file.read_bytes()) == sha:
            print("Verified:", name)
            continue
        data = json.loads(subprocess.check_output(["gh", "api", f"repos/{repo}/git/blobs/{sha}"]))
        content = base64.b64decode(data["content"])
        if blob_id(content) != sha:
            raise ValueError("Font blob hash does not match: " + name)
        file.write_bytes(content)
        print("Fetched and verified:", name)

if __name__ == "__main__":
    main()
