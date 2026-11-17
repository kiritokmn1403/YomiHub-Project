# i18n_merge.py - gop audit-0.5.7/notes/i18n_<goi>.json vao 18 tep overlay/assets/yomihub_i18n/*.json
# Dung: python3 i18n_merge.py <goi> [<goi> ...]   (chi NOI THEM khoa moi vao cuoi tep; khong doi khoa cu)
import json, os, sys, shutil
ROOT = os.path.join(os.path.expanduser('~'), 'mnt', 'YomiHub-Project')
I18N = os.path.join(ROOT, 'overlay', 'assets', 'yomihub_i18n')
LANGS = ['ar','as','de','en','es','es_419','fr','hi','id','it','ja','ko','pt','pt_BR','ru','th','tr','zh']
def enc(s): return json.dumps(s, ensure_ascii=False)
for pkg in sys.argv[1:]:
    src = json.load(open(os.path.join(ROOT, 'audit-0.5.7', 'notes', 'i18n_%s.json' % pkg), encoding='utf-8'))
    for key, tr in src.items():
        miss = [l for l in LANGS if not tr.get(l)]
        if miss: sys.exit('!! %s: thieu ngon ngu %s cho khoa %r' % (pkg, miss, key[:60]))
        for l in LANGS:
            if ('{p0}' in key) != ('{p0}' in tr[l]): sys.exit('!! placeholder lech: %s %r' % (l, key[:60]))
    bk = os.path.join(ROOT, 'audit-0.5.7', 'backup', 'src_0571', 'assets', 'yomihub_i18n_%s' % pkg)
    os.makedirs(bk, exist_ok=True)
    for l in LANGS:
        p = os.path.join(I18N, l + '.json')
        if not os.path.exists(os.path.join(bk, l + '.json')): shutil.copy2(p, os.path.join(bk, l + '.json'))
        raw = open(p, encoding='utf-8', newline='').read()
        cur = json.loads(raw)
        add = [(k, v[l]) for k, v in src.items() if k not in cur]
        if not add: print(pkg, l, 'khong co khoa moi'); continue
        body = raw.rstrip()
        assert body.endswith('}'), p
        body = body[:-1].rstrip()
        body += ''.join(',\n  %s: %s' % (enc(k), enc(v)) for k, v in add) + '\n}'
        new = json.loads(body)
        assert len(new) == len(cur) + len(add) and all(new[k] == cur[k] for k in cur), p
        open(p, 'w', encoding='utf-8', newline='').write(body)
        print(pkg, l, '+%d ->' % len(add), len(new))
