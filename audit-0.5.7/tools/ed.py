# ed.py - YomiHub 0.5.7 (phien lam viec 14/11/2026, Claude Fable): doc-sua-ghi co sao luu.
# Dung: from ed import *  (chay voi cwd = goc du an)
import os, shutil, sys
ROOT = os.path.join(os.path.expanduser('~'), 'mnt', 'YomiHub-Project')
OV = os.path.join(ROOT, 'overlay')
BK = os.path.join(ROOT, 'audit-0.5.7', 'backup', 'src_0571')

def backup(rel):
    src = os.path.join(OV, rel)
    dst = os.path.join(BK, rel)
    if os.path.exists(src) and not os.path.exists(dst):
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        shutil.copy2(src, dst)
        print('backup', rel)

def read(rel):
    with open(os.path.join(OV, rel), 'r', encoding='utf-8', newline='') as f:
        return f.read()

def write(rel, s):
    p = os.path.join(OV, rel)
    os.makedirs(os.path.dirname(p), exist_ok=True)
    with open(p, 'w', encoding='utf-8', newline='') as f:
        f.write(s)
    print('write', rel, len(s))

def sub(rel, old, new, count=1):
    backup(rel)
    s = read(rel)
    crlf = '\r\n' in s
    if crlf:
        old = old.replace('\r\n', '\n').replace('\n', '\r\n')
        new = new.replace('\r\n', '\n').replace('\n', '\r\n')
    n = s.count(old)
    if n != count:
        print('!! %s: expected %d occurrence(s), found %d of: %r' % (rel, count, n, old[:80]))
        sys.exit(3)
    write(rel, s.replace(old, new))
