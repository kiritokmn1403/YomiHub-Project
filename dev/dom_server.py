import sys, json, os, hashlib
from bs4 import BeautifulSoup
fin = open(sys.argv[1], 'r', encoding='utf-8'); fout = open(sys.argv[2], 'w', encoding='utf-8')
cache = {}
def soup(h):
    k = hashlib.md5(h.encode('utf-8', 'surrogatepass')).hexdigest()
    s = cache.get(k)
    if s is None:
        s = BeautifulSoup(h, 'lxml')
        if len(cache) > 400: cache.clear()
        cache[k] = s
    return s
def root(s, el):
    if not el: return s
    b = s.body
    if b is None: return s
    kids = [c for c in b.children if getattr(c, 'name', None)]
    return kids[0] if kids else s
for line in fin:
    out = []
    try:
        for op in json.loads(line):
            r = root(soup(op['html']), op.get('el'))
            k, a = op['kind'], op.get('arg')
            if k == 'text': out.append(r.get_text())
            elif k == 'inner': out.append(''.join(str(c) for c in r.contents))
            elif k == 'attr':
                v = r.get(a) if hasattr(r, 'get') else None
                if isinstance(v, list): v = ' '.join(v)
                out.append(v)
            elif k == 'selectFirst':
                e = r.select_one(a); out.append(str(e) if e else None)
            elif k == 'select': out.append([str(e) for e in r.select(a)])
    except Exception as e:
        out = [None]
    fout.write(json.dumps(out) + '\n'); fout.flush()
