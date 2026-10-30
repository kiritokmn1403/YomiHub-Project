"""YomiHub 0.4.4: tr() coverage scan. Unlike audit-0.3.9/language_audit.py it
joins adjacent Dart string literals (tr('a ' 'b') -> key 'a b'), which is what
tr() receives at runtime."""
import json,re,sys
from pathlib import Path
root=Path(__file__).resolve().parent.parent
lit=re.compile(r"""\s*(?:r?'((?:\\.|[^'\\\n])*)'|r?"((?:\\.|[^"\\\n])*)")""")
def unesc(s): return s.replace("\\'","'").replace('\\"','"').replace('\\n','\n').replace('\\\\','\\').replace('\\$','$')
keys={}
for p in (root/'overlay/lib').rglob('*.dart'):
    t=p.read_text(encoding='utf-8')
    for m in re.finditer(r"\btr\(",t):
        i=m.end(); parts=[]
        while True:
            mm=lit.match(t,i)
            if not mm: break
            parts.append(mm.group(1) if mm.group(1) is not None else mm.group(2)); i=mm.end()
        if not parts: continue
        nxt=t[i:i+1]
        if nxt not in (')',','): continue
        key=unesc(''.join(parts))
        if re.search(r'(?<!\\)\$',''.join(parts)): continue
        keys.setdefault(key,str(p.relative_to(root)))
tables={p.stem:json.loads(p.read_text(encoding='utf-8')) for p in (root/'overlay/assets/yomihub_i18n').glob('*.json')}
miss=sorted(k for k in keys if k not in tables['en'])
out={'strings':len(keys),'missing_en':miss,'missing_count':{l:sum(1 for k in keys if k not in t) for l,t in tables.items()}}
json.dump(out,open(root/'audit-0.4.5/i18n_missing.json','w',encoding='utf-8'),ensure_ascii=False,indent=1)
print(len(keys),len(miss)); print(json.dumps(out['missing_count']))
