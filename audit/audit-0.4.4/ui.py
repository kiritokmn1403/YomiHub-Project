import re,sys,html
x=open(sys.argv[1],encoding='utf-8').read()
for m in re.finditer(r'<node [^>]*>',x):
    n=m.group(0); a=re.search(r"content-desc=\"([^\"]*)\"",n); b=re.search(r" text=\"([^\"]*)\"",n); t=(a.group(1) if a else "") or (b.group(1) if b else "")
    if t.strip(): print(html.unescape(t).replace('\n',' | ')[:80], re.search(r'bounds="([^"]*)"',n).group(1))
