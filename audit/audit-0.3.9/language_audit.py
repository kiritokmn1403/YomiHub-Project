import json,re
from pathlib import Path
root=Path(__file__).resolve().parent.parent
tables={p.stem:json.loads(p.read_text(encoding='utf-8')) for p in (root/'overlay/assets/yomihub_i18n').glob('*.json')}
keys=set()
locations={}
for p in (root/'overlay/lib').rglob('*.dart'):
    text=p.read_text(encoding='utf-8')
    for m in re.finditer(r"\btr\(\s*'((?:\\.|[^'\\])*)'",text):
        key=m.group(1).replace("\\'", "'").replace('\\n','\n')
        if '$' in key: continue
        keys.add(key);locations.setdefault(key,str(p.relative_to(root)))
missing={lang:sorted(keys-set(table)) for lang,table in tables.items()}
placeholders={lang:[key for key in keys&set(table) if set(re.findall(r'\{p\d+\}',key))!=set(re.findall(r'\{p\d+\}',table[key]))] for lang,table in tables.items()}
out={'literal_strings':len(keys),'missing':missing,'placeholder_mismatches':placeholders,'locations':locations}
(root/'audit-0.3.9/language-coverage.json').write_text(json.dumps(out,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps({'strings':len(keys),'missing':{k:len(v) for k,v in missing.items()},'placeholders':{k:len(v) for k,v in placeholders.items()}},ensure_ascii=False))
