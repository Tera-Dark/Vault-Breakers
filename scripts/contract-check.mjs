import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { LuauState } from 'luau-web';
import './luau-runtime.mjs';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
fs.mkdirSync(path.join(root,'.cache'),{recursive:true});
const relative=p=>path.relative(root,p).split(path.sep).join('/');
const walk=p=>fs.readdirSync(p,{withFileTypes:true}).flatMap(e=>e.isDirectory()?walk(path.join(p,e.name)):[path.join(p,e.name)]);
const sources=walk(path.join(root,'src')).filter(p=>p.endsWith('.luau')).sort();
let bundle=`local API=(function()\n${fs.readFileSync(path.join(root,'tests/fixtures/api.luau'),'utf8')}\nend)()\n`;
bundle+=fs.readFileSync(path.join(root,'tests/roblox-mock.luau'),'utf8');
bundle+='\nlocal factories,nodes,cache={},{},{}\n';
for(const p of sources){const name=relative(p);bundle+=`factories[${JSON.stringify(name)}]=function(script)\n${fs.readFileSync(p,'utf8')}\nend\n`;}
bundle+=`local function folder(parent,name,class) local existing=parent:FindFirstChild(name);if existing then return existing end;local node=Instance.new(class or "Folder");node.Name=name;node.Parent=parent;return node end\n`;
for(const p of sources){
  const rel=relative(p),segments=rel.split('/').slice(2),group=rel.split('/')[1];
  const file=segments.pop(),name=file.replace(/\.(client|server)\.luau$|\.luau$/,'');
  const cls=file.includes('.server.')?'Script':file.includes('.client.')?'LocalScript':'ModuleScript';
  let parent=group==='StarterPlayerScripts'?'folder(game:GetService("StarterPlayer"),"StarterPlayerScripts","StarterPlayerScripts")':`game:GetService(${JSON.stringify(group)})`;
  parent=`folder(${parent},"VaultBreakers")`;
  for(const segment of segments)parent=`folder(${parent},${JSON.stringify(segment)})`;
  bundle+=`nodes[${JSON.stringify(rel)}]=Mock.source(${JSON.stringify(rel)},${JSON.stringify(cls)},${JSON.stringify(name)},${parent})\n`;
}
bundle+=`require=function(node) assert(node and node._modulePath,"require expects a mapped ModuleScript");local p=node._modulePath;if cache[p]==nil then cache[p]=factories[p](node) end;return cache[p] end\n`;
bundle+='\n'+fs.readFileSync(path.join(root,'tests/ui-capture.luau'),'utf8');
const suite=process.argv[2] || 'integration';
if(!['integration','resilience','menu'].includes(suite))throw new Error('Unknown contract suite');
bundle+=fs.readFileSync(path.join(root,`tests/${suite}.spec.luau`),'utf8');
const state=await LuauState.createAsync({print:(...a)=>console.log(...a),warn:(...a)=>console.warn(...a),captureScene: scene=>fs.writeFileSync(path.join(root,'.cache/scene.json'),scene),captureLayout:(name,scene)=>fs.writeFileSync(path.join(root,`.cache/layout-${name}.json`),scene)});
try{await state.loadstring(bundle,'roblox-contract-check',true)();}catch(error){console.error(error);process.exitCode=1;}finally{state.destroy();}
