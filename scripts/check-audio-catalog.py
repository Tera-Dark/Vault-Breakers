#!/usr/bin/env python3
"""Offline consistency check, NOT an audio permission / listening test."""
from pathlib import Path
import json,re
root=Path(__file__).resolve().parents[1]
manifest=json.loads((root/'art/audio/library-manifest.json').read_text())
source=(root/'src/ReplicatedStorage/Config/AssetConfig.luau').read_text()
known={str(a['id']):a for a in manifest['assets']}
defaults=re.search(r'Sounds\s*=\s*\{(.*?)\}',source,re.S).group(1)
for cue,id in re.findall(r'(\w+)\s*=\s*"rbxassetid://(\d+)"',defaults):
    assert id in known,(cue,id)
    item=known[id]
    assert item['assetTypeId']==3 and item['apiIsPublicDomain'] is True
    assert item['creatorId'] in (7462895450,7462718749)
    assert cue in item['roles'],(cue,id)
    assert item['metadataUrl']==f'https://economy.roblox.com/v2/assets/{id}/details'
overrides=re.search(r'OriginalUploads\s*=\s*\{(.*?)\}',source,re.S).group(1)
for cue,value in re.findall(r'(\w+)\s*=\s*"([^"]*)"',overrides):
    assert value=='' or re.fullmatch(r'rbxassetid://[1-9]\d*',value),(cue,value)
assert manifest['studioPlaybackValidated'] is False
print(f'PASS: {len(known)} partner audio asset records match the configured IDs; metadata only, native playback unverified.')
