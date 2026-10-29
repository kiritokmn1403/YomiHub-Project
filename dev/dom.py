import sys, json
from bs4 import BeautifulSoup
req = json.loads(sys.stdin.read())
out = []
for op in req:
    html, kind, arg = op['html'], op['kind'], op.get('arg')
    soup = BeautifulSoup(html, 'html.parser')
    root = soup
    if op.get('el'):
        root = next((c for c in soup.contents if getattr(c, 'name', None)), soup)
    if kind == 'select':
        out.append([str(e) for e in root.select(arg)])
    elif kind == 'selectFirst':
        e = root.select_one(arg); out.append(str(e) if e else None)
    elif kind == 'attr':
        v = root.get(arg) if hasattr(root, 'get') else None
        out.append(' '.join(v) if isinstance(v, list) else v)
    elif kind == 'text':
        out.append(root.get_text())
    elif kind == 'inner':
        out.append(''.join(str(c) for c in root.contents))
print(json.dumps(out))
