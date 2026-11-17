"""Gop audit-0.5.7/notes/i18n_*.json vao 18 tep overlay/assets/yomihub_i18n/*.json.
Chi THEM khoa con thieu (khong ghi de). Sao luu truoc vao audit-0.5.7/backup/i18n_merge_<thoi gian>/."""
import json, glob, os, shutil, sys, time
root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
idir = os.path.join(root, 'overlay', 'assets', 'yomihub_i18n')
langs = sorted(os.path.splitext(os.path.basename(p))[0] for p in glob.glob(os.path.join(idir, '*.json')))
src = {}
for f in sorted(glob.glob(os.path.join(root, 'audit-0.5.7', 'notes', 'i18n_*.json'))):
    for k, tr in json.load(open(f, encoding='utf-8')).items():
        miss = [l for l in langs if l not in tr or not str(tr[l]).strip()]
        if miss: print('THIEU NGON NGU', os.path.basename(f), repr(k[:50]), miss); sys.exit(2)
        src[k] = tr
bk = os.path.join(root, 'audit-0.5.7', 'backup', 'i18n_merge_' + time.strftime('%Y%m%d_%H%M%S'))
os.makedirs(bk)
added = 0
for l in langs:
    p = os.path.join(idir, l + '.json'); shutil.copy2(p, bk)
    d = json.load(open(p, encoding='utf-8'))
    n = 0
    for k, tr in src.items():
        if k not in d: d[k] = tr[l]; n += 1
    if n:
        with open(p, 'w', encoding='utf-8', newline='\n') as fh:
            json.dump(d, fh, ensure_ascii=False, indent=2); fh.write('\n')
    added += n
print('ngon ngu:', len(langs), '| khoa nguon:', len(src), '| da them:', added, '| sao luu:', bk)
