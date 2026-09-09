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
 'src/ReplicatedStorage/Shared/ProfileSchema.luau', 'src/ServerScriptService/Core/RunEngine.luau',
 'src/ServerScriptService/Services/DecisionService.luau', 'src/ServerScriptService/Services/QueueService.luau',
 'src/StarterPlayerScripts/Controllers/ClientState.luau', 'src/ServerScriptService/Services/RateLimiter.luau', 'src/ServerScriptService/Services/LeaderboardService.luau',
];
let code = 'local modules, cache = {}, {}\n';
for (const p of pure) code += `modules[${JSON.stringify(p)}] = function()\n${fs.readFileSync(path.join(root,p),'utf8')}\nend\n`;
code += 'local function requireTest(p) if not cache[p] then cache[p] = assert(modules[p], p)() end return cache[p] end\n';
code += fs.readFileSync(path.join(root,'tests/engine.spec.luau'),'utf8');
code += '\ndo\n'+fs.readFileSync(path.join(root,'tests/client-state.spec.luau'),'utf8')+'\nend\n';
try { await state.loadstring(code,'engine.spec',true)(); }
catch (error) { console.error(error); failed = true; }
state.destroy();
if (failed) process.exit(1);
