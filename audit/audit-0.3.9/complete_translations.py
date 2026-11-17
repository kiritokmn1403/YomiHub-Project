"""Translate missing public UI text, preserving placeholders and existing tables.
Machine translations require review; this does not certify linguistic quality.
"""
from pathlib import Path
import json, re, time, urllib.request, urllib.parse, concurrent.futures

ROOT=Path(__file__).resolve().parent
ASSETS=ROOT.parent/'overlay/assets/yomihub_i18n'
audit=json.loads((ROOT/'language-coverage.json').read_text(encoding='utf-8'))
cache=ROOT/'translation-cache'
cache.mkdir(exist_ok=True)

def request(text,lang):
    target={'zh':'zh-CN','pt_BR':'pt','es_419':'es'}.get(lang,lang)
    url='https://translate.googleapis.com/translate_a/single?'+urllib.parse.urlencode(
        {'client':'gtx','sl':'vi','tl':target,'dt':'t','q':text})
    for attempt in range(3):
        try:
            with urllib.request.urlopen(urllib.request.Request(url,headers={'User-Agent':'YomiHub-localization-review'}),timeout=30) as response:
                payload=json.load(response)
            return ''.join(part[0] for part in payload[0] if part and part[0])
        except Exception:
            if attempt==2: raise
            time.sleep(2*(attempt+1))

def translate_language(lang,keys):
    path=cache/(lang+'.json')
    translated=json.loads(path.read_text(encoding='utf-8')) if path.exists() else {}
    errors=[]
    todo=[k for k in keys if k not in translated]
    for start in range(0,len(todo),8):
        group=todo[start:start+8]
        prepared=[k.replace('\n',' ZXNEWLINEZX ') for k in group]
        try:
            result=request('\n'.join(prepared),lang).split('\n')
            result=[r.strip() for r in result if r.strip()]
            if len(result)!=len(group):
                result=[request(k,lang) for k in prepared]
            for key,value in zip(group,result):
                value=re.sub(r'\s*ZXNEWLINEZX\s*','\n',value)
                value=re.sub(r'\{\s*p\s*(\d+)\s*\}',r'{p\1}',value)
                if set(re.findall(r'\{p\d+\}',key))!=set(re.findall(r'\{p\d+\}',value)):
                    errors.append({'key':key,'error':'placeholder mismatch'});continue
                if 'ZXNEWLINEZX' in value: errors.append({'key':key,'error':'newline marker'});continue
                translated[key]=value
            path.write_text(json.dumps(translated,ensure_ascii=False,indent=2),encoding='utf-8')
        except Exception as exc:
            errors.append({'batch':start,'error':str(exc)})
    tablepath=ASSETS/(lang+'.json')
    table=json.loads(tablepath.read_text(encoding='utf-8'))
    for key,value in translated.items(): table.setdefault(key,value)
    tablepath.write_text(json.dumps(table,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    return {'language':lang,'added':len(translated),'errors':errors}

if __name__=='__main__':
    results=[]
    with concurrent.futures.ThreadPoolExecutor(max_workers=3) as pool:
        pending=[pool.submit(translate_language,lang,keys) for lang,keys in audit['missing'].items()]
        for future in concurrent.futures.as_completed(pending):
            item=future.result();results.append(item)
            print(json.dumps(item,ensure_ascii=False),flush=True)
    (ROOT/'translation-results.json').write_text(json.dumps(results,ensure_ascii=False,indent=2),encoding='utf-8')
