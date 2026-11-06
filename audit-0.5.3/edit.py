import sys, os, shutil
ROOT=os.path.expanduser('~/mnt/A.I Project - YomiHub Project/YomiHub-Project')
def edit(rel, old, new, count=1):
    p=os.path.join(ROOT,'overlay',rel)
    if not os.path.exists(p):
        src=os.path.expanduser('~/mnt/yh/build/mangayomi/'+rel)
        os.makedirs(os.path.dirname(p),exist_ok=True); shutil.copy2(src,p); print('copied from build:',rel)
    s=open(p,encoding='utf-8').read()
    assert s.count(old)==count, f'{rel}: found {s.count(old)} x, expected {count}: {old[:80]!r}'
    b=os.path.join(ROOT,'audit-0.5.3/before',rel)
    if not os.path.exists(b):
        os.makedirs(os.path.dirname(b),exist_ok=True); shutil.copy2(p,b)
    s=s.replace(old,new)
    open(p,'w',encoding='utf-8',newline='').write(s)
    cf=os.path.join(ROOT,'audit-0.5.3/changed_files.txt')
    lines=set(open(cf).read().split()) if os.path.exists(cf) else set()
    lines.add('overlay/'+rel)
    open(cf,'w').write('\n'.join(sorted(lines))+'\n')
    print('edited',rel)
