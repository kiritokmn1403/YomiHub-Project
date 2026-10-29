import json, sys, re
sys.path.insert(0,'/work/tools')
from i18n_new import L, T
d='/work/yh/assets/yomihub_i18n/'
files={'en':'en','ar':'ar','as':'as','de':'de','es':'es','es_419':'es','fr':'fr','hi':'hi','id':'id','it':'it','ja':'ja','ko':'ko','pt':'pt','pt_BR':'pt','ru':'ru','th':'th','tr':'tr','zh':'zh'}
missing=json.load(open('/work/tools/i18n_missing.json'))
bad=[k for k in missing if k not in T]
print('not covered:', bad)
for fn,lang in files.items():
    p=d+fn+'.json'; j=json.load(open(p,encoding='utf8'))
    i=L.index(lang); n=0
    for k,v in T.items():
        if v is None: continue
        assert len(v)==len(L), (k,len(v))
        # placeholders must survive
        for ph in re.findall(r'\{p\d\}',k): assert ph in v[i], (k,lang)
        if k not in j: j[k]=v[i]; n+=1
    json.dump(j,open(p,'w',encoding='utf8'),ensure_ascii=False,indent=1,sort_keys=True)
    print(fn,n,len(j))
