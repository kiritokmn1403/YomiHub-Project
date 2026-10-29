import re, json, glob, sys
root = '/work/yh'
lit = r"""(?:r?'(?:[^'\\\n]|\\.)*'|r?"(?:[^"\\\n]|\\.)*")"""
pat = re.compile(r"\btr\(\s*(" + lit + r"(?:\s*" + lit + r")*)", re.S)
def dec(tok):
    out=[]
    for m in re.finditer(lit, tok):
        t=m.group(0); raw=t.startswith('r'); t=t[1:] if raw else t
        body=t[1:-1]
        if not raw:
            body=re.sub(r"\\(.)", lambda mm: {'n':'\n','t':'\t','\\':'\\',"'":"'",'"':'"','$':'$'}.get(mm.group(1), mm.group(1)), body)
        out.append(body)
    return ''.join(out)
keys=set()
for f in glob.glob(root+'/lib/**/*.dart', recursive=True):
    s=open(f,encoding='utf8').read()
    for m in pat.finditer(s):
        k=dec(m.group(1))
        if '${' in k: continue
        keys.add(k)
extra = sys.argv[1:] 
en=json.load(open(root+'/assets/yomihub_i18n/en.json',encoding='utf8'))
missing=sorted(k for k in keys if k not in en)
json.dump(missing, open('/work/tools/i18n_missing.json','w',encoding='utf8'), ensure_ascii=False, indent=1)
print(len(keys), 'keys;', len(missing), 'missing')
