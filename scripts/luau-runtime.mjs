// luau-web 1.4 ships a fixed ~17 MiB WASM heap, too small for two reflection-backed
// studios + GUI Instances. Use Emscripten's public instantiateWasm hook to set a
// 64 MiB initial heap. This changes the WASM memory limits only, never Luau code.
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { InternalLuauWasmModule } from 'luau-web';
const dir=path.dirname(fileURLToPath(import.meta.url));
const variant=('Suspending' in WebAssembly && 'promising' in WebAssembly)?'JSPI':'Asyncify';
const wrapper=fs.readFileSync(path.join(dir,`node_modules/luau-web/src/lib/Luau.Web.${variant}.js`),'utf8');
const base64=wrapper.match(/function findWasmBinary\(\)\{return base64Decode\("([A-Za-z0-9+/=]+)"\)/)?.[1];
if(!base64)throw new Error('Pinned Luau WASM layout changed; review runtime setup.');
const binary=Buffer.from(base64,'base64');
const read=(buf,start)=>{let value=0,shift=0,p=start;do{const b=buf[p++];value|=(b&127)<<shift;shift+=7;if(!(b&128))break;}while(true);return [value,p];};
const leb=n=>{const bytes=[];do{let b=n&127;n>>>=7;if(n)b|=128;bytes.push(b);}while(n);return Buffer.from(bytes);};
let p=8,parts=[binary.subarray(0,8)],patched=false;
while(p<binary.length){
 const id=binary[p++];let size;[size,p]=read(binary,p);let payload=binary.subarray(p,p+size);p+=size;
 if(id===5){
  let q=0,count;[count,q]=read(payload,q);if(count!==1)throw new Error('Unexpected WASM memory count');
  const flags=payload[q++];if(flags>1)throw new Error('Unexpected WASM memory limits');
  let minimum;[minimum,q]=read(payload,q);let maximum=0;if(flags&1)[maximum,q]=read(payload,q);
  const pages=Math.max(minimum,1024);
  payload=Buffer.concat([leb(1),Buffer.from([flags]),leb(pages),...(flags&1?[leb(Math.max(maximum,pages))]:[])]);patched=true;
 }
 parts.push(Buffer.from([id]),leb(payload.length),payload);
}
if(!patched)throw new Error('WASM memory section not found.');
const enlarged=Buffer.concat(parts);
InternalLuauWasmModule.instantiateWasm=(imports,receive)=>{
 WebAssembly.instantiate(enlarged,imports).then(({instance,module})=>receive(instance,module));
 return {};
};
