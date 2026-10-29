import json, re, concurrent.futures, urllib.request, urllib.error, time
from pathlib import Path

ROOT = Path(__file__).resolve().parent
PROJECT = ROOT.parent
requirements = json.loads((ROOT / 'Project YomiHub.json').read_text(encoding='utf-8'))
github = json.loads((ROOT / 'Project GitHub.json').read_text(encoding='utf-8'))

def fetch(item):
    kind, name, url = item
    start = time.monotonic()
    result = dict(kind=kind, name=name, url=url)
    try:
        req = urllib.request.Request(url, headers={'User-Agent': 'YomiHub-0.3.9-audit'})
        with urllib.request.urlopen(req, timeout=15) as response:
            body = response.read(5_000_000)
            result.update(status=response.status, final_url=response.url, bytes=len(body))
            if kind == 'repo' and (url.endswith('.json') or url.endswith('.pb')):
                if url.endswith('.json'):
                    parsed = json.loads(body)
                    result.update(format=type(parsed).__name__, entries=len(parsed))
                else:
                    result['format'] = 'protobuf (transport only)'
            if kind == 'upstream':
                data = json.loads(body)
                result.update(default_branch=data.get('default_branch'), pushed_at=data.get('pushed_at'), archived=data.get('archived'))
            if kind == 'drive':
                (ROOT / 'drive-listing.html').write_bytes(body)
                result['entries'] = body.count(b'flip-entry-title')
    except Exception as error:
        result['error'] = str(error)
    result['seconds'] = round(time.monotonic()-start, 2)
    return result

items=[]
for row in requirements['Extension Repo'][1:]:
    for url in row['cells'].values():
        if url.startswith('https://'): items.append(('repo', 'extension repository', url.strip()))
items.append(('drive','updates','https://drive.google.com/embeddedfolderview?id=16PCPorl1Ae9nmKMMWAC3Oz1rp_w9tH__'))
for repo in ['aniyomiorg/aniyomi','Seguaz/Nekoyomi','kodjodevf/mangayomi']:
    items.append(('upstream',repo,'https://api.github.com/repos/'+repo))
with concurrent.futures.ThreadPoolExecutor(max_workers=5) as pool:
    results=list(pool.map(fetch, items))
(ROOT / 'network-results.json').write_text(json.dumps(results,ensure_ascii=False,indent=2),encoding='utf-8')

source=(PROJECT/'overlay/lib/yomihub/about/github_projects_screen.dart')
about='\n'.join(p.read_text(encoding='utf-8') for p in (PROJECT/'overlay/lib/yomihub/about').glob('*.dart'))
links=[]
for rows in github.values():
    for row in rows:
        url=row['cells'].get('C','').strip()
        if url.startswith('http'): links.append({'row':row['row'],'url':url,'listed_in_about':url.rstrip('/') in about})
(ROOT/'github-reference-coverage.json').write_text(json.dumps(links,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps({'network_checks':len(results),'success':sum(r.get('status')==200 for r in results),'references':len(links),'listed':sum(r['listed_in_about'] for r in links)},ensure_ascii=False))
