"""Refresh a compact, offline Roblox reflection fixture from a downloaded official API dump."""
from pathlib import Path
import re, json
root = Path(__file__).resolve().parents[1]
data = json.loads((root/'.cache/Roblox-API-Dump.json').read_text())
source = '\n'.join(p.read_text() for p in (root/'src').rglob('*.luau'))
classes = {c['Name']: c for c in data['Classes']}
used = set(re.findall(r'(?:Instance\.new|UI\.new|GetService|IsA)\("([A-Za-z0-9]+)"', source))
used.update(('DataModel','Instance','Player','PlayerGui','Humanoid','HumanoidRootPart','Part','Camera','Tween','DataStore','GlobalDataStore','RBXScriptSignal','Workspace','StarterPlayer','StarterPlayerScripts','ServerScriptService','ReplicatedStorage','Folder','ModuleScript','Script','LocalScript','Frame','TextLabel','TextButton','ScreenGui','Model','WorldModel','Seat'))
used &= classes.keys()
for name in tuple(used):
    c=classes[name]
    while c.get('Superclass') in classes:
        used.add(c['Superclass']);c=classes[c['Superclass']]
def q(value): return json.dumps(value, ensure_ascii=False)
lines = ['-- Generated from Roblox-Client-Tracker API-Dump.json, blob ffaefea669c2a882496dc9d5183b3db146e251db.', '-- Offline contract fixture: validates class/property/enum names, NOT Roblox rendering or physics.', 'return { classes = {']
for name in sorted(used):
    c=classes[name]
    members={};events=[]
    for m in c['Members']:
        if m['MemberType']=='Property': members[m['Name']]=m['ValueType']['Name']
        if m['MemberType']=='Event': events.append(m['Name'])
    lines.append(f'[{q(name)}]={{super={q(c["Superclass"])},properties={{'+','.join(f'[{q(k)}]={q(v)}' for k,v in sorted(members.items()))+'},events={'+','.join(f'[{q(e)}]=true' for e in sorted(events))+'}},')
lines.append('}, enums = {')
used_enums=set(re.findall(r'Enum\.([A-Za-z0-9]+)', source))
for e in data['Enums']:
    if e['Name'] in used_enums:
        lines.append(f'[{q(e["Name"])}]={{'+','.join(f'[{q(item["Name"])}]={item["Value"]}' for item in e['Items'])+'},')
lines.append('} }\n')
(root/'tests/fixtures/api.luau').write_text('\n'.join(lines))
print(f'Wrote {len(used)} classes and {len(used_enums)} enum types to offline fixture.')
