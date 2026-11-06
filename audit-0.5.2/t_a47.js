const fs=require('fs');
const src=fs.readFileSync(process.argv[2],'utf8').match(/  async resolveId\(url\) \{[\s\S]*?\n  \}\n/)[0];
const store={};
global.SharedPreferences=class{getString(k,d){return store[k]||d} setString(k,v){store[k]=v}};
const o=eval("({api(){return 'https://animevui.com/api'}, async json(u){const r=await fetch(u,{headers:{Accept:'application/json',Origin:'https://anime47.best',Referer:'https://anime47.best/'}});return r.json()},"+src+"})");
(async()=>{for(const u of ["https://anime47.best/phim/tensei-shitara-slime-datta-ken-4th-season-1","https://anime47.best/phim/fx-senshi-kurumi-chan-11297","https://anime47.best/phim/x/m10321.html","10321"]){try{console.log(u,'->',await o.resolveId(u))}catch(e){console.log(u,'ERR',e.message)}}})();
