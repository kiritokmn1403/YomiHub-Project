import fs from 'fs';

const d = JSON.parse(fs.readFileSync('D:/A.I Project/A.I Project - YomiHub Project/YomiHub-Project/audit/audit-0.5.9/antigravity/repo_suggestions_059.json', 'utf8'));

console.log(`Total: ${d.length}`);
console.log(`Alive: ${d.filter(x => x.alive).length}`);
console.log(`Dead: ${d.filter(x => !x.alive).length}`);
console.log(`In-App: ${d.filter(x => x.inApp).length}`);
console.log(`New (Not in-app): ${d.filter(x => !x.inApp).length}`);
console.log('');

d.forEach((x, i) => {
  const status = x.alive ? 'ALIVE' : 'DEAD ';
  const appStatus = x.inApp ? 'IN-APP' : 'NEW   ';
  console.log(`${String(i + 1).padStart(2, ' ')}. [${status}] [${appStatus}] ${x.name.padEnd(35, ' ')} | Type: ${x.type.padEnd(6, ' ')} | Engine: ${x.engine.padEnd(8, ' ')} | Count: ${String(x.count).padStart(5, ' ')} | URL: ${x.url}`);
});
