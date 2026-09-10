import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { LuauState } from 'luau-web';
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const walk = p => fs.readdirSync(p, {withFileTypes:true}).flatMap(e => e.isDirectory() ? walk(path.join(p,e.name)) : [path.join(p,e.name)]);
const state = await LuauState.createAsync({ print: (...args) => console.log(...args), warn: (...args) => console.warn(...args) });
let failed = false;
const files = walk(path.join(root,'src')).filter(p=>p.endsWith('.luau'));
for (const file of files) {
  try { state.loadstring(fs.readFileSync(file,'utf8'), path.relative(root,file), true); }
  catch (error) { failed = true; console.error(String(error)); }
}
if (failed) { state.destroy(); process.exit(1); }
console.log(`PASS: ${files.length} Luau source files compile (Luau WASM; not a Roblox runtime test).`);
const pure = [
 'src/ReplicatedStorage/Config/GameConfig.luau', 'src/ReplicatedStorage/Config/RewardPool.luau',
 'src/ReplicatedStorage/Config/OfferAlgorithm.luau', 'src/ReplicatedStorage/Shared/DecisionQuality.luau',
 'src/ReplicatedStorage/Shared/ProgressionRules.luau', 'src/ReplicatedStorage/Shared/ReactionRules.luau', 'src/ReplicatedStorage/Config/CosmeticCatalog.luau',
 'src/ReplicatedStorage/Shared/ShowRules.luau', 'src/ReplicatedStorage/Shared/BroadcastState.luau',
 'src/ReplicatedStorage/Shared/ProfileSchema.luau', 'src/ServerScriptService/Core/RunEngine.luau',
 'src/ServerScriptService/Services/DecisionService.luau', 'src/ServerScriptService/Services/QueueService.luau',
 'src/StarterPlayerScripts/Controllers/ClientState.luau', 'src/ServerScriptService/Services/RateLimiter.luau', 'src/ServerScriptService/Services/LeaderboardService.luau',
];
let code = `local modules,cache,nodes={}, {}, {}
local requireTest
local function require(node)return requireTest(node._path)end
local function makeNode(path)
 local parent=nodes;local node
 for segment in path:gmatch("[^/]+")do
  local name=segment:gsub("%.luau$","");node=parent[name]
  if not node then node={Parent=parent,Name=name};parent[name]=node end
  parent=node
 end
 node._path=path;nodes[path]=node
end
`;
for (const p of pure) code += `makeNode(${JSON.stringify(p)})\nmodules[${JSON.stringify(p)}] = function(script)\n${fs.readFileSync(path.join(root,p),'utf8')}\nend\n`;
code += 'requireTest=function(p) if not cache[p] then cache[p] = assert(modules[p], p)(nodes[p]) end return cache[p] end\n';
code += fs.readFileSync(path.join(root,'tests/engine.spec.luau'),'utf8');
code += '\ndo\n'+fs.readFileSync(path.join(root,'tests/show.spec.luau'),'utf8')+'\nend\n';
code += '\ndo\n'+fs.readFileSync(path.join(root,'tests/client-state.spec.luau'),'utf8')+'\nend\n';
try { await state.loadstring(code,'engine.spec',true)(); }
catch (error) { console.error(error); failed = true; }
state.destroy();
if (failed) process.exit(1);
