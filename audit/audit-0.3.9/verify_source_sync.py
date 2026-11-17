from pathlib import Path
import json,hashlib
root=Path(__file__).resolve().parent
project=root.parent
builds={'android':Path('D:/A.I Project/yh/build/mangayomi'),
        'windows':Path('D:/A.I Project/yh/buildwin/mangayomi')}
def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest() if path.exists() else None
rows=[]
for rel in json.loads((root/'changed-files.json').read_text(encoding='utf-8')):
    source=digest(project/'overlay'/rel)
    row={'file':rel,'overlay_sha256':source}
    for name,build in builds.items():
        row[name+'_sha256']=digest(build/rel)
        row[name+'_matches']=row[name+'_sha256']==source
        row[name+'_before_sha256']=digest(root/'before'/name/rel)
    rows.append(row)
(root/'SOURCE_MANIFEST.json').write_text(json.dumps(rows,indent=2),encoding='utf-8')
failures=[r['file'] for r in rows if not r['android_matches'] or not r['windows_matches']]
print(json.dumps({'checked':len(rows),'mismatches':failures}))
if failures: raise SystemExit(1)
