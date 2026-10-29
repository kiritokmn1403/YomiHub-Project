import re,glob,sys
VI=re.compile(r"[ăâđêôơưàáạảãằắặẳẵầấậẩẫèéẹẻẽềếệểễìíịỉĩòóọỏõồốộổỗờớợởỡùúụủũừứựửữỳýỵỷỹĂÂĐÊÔƠƯÀÁẠẢÃẰẮẶẲẴẦẤẬẨẪÈÉẸẺẼỀẾỆỂỄÌÍỊỈĨÒÓỌỎÕỒỐỘỔỖỜỚỢỞỠÙÚỤỦŨỪỨỰỬỮỲÝỴỶỸ]")
lit = re.compile(r"""'(?:[^'\\\n]|\\.)*'|"(?:[^"\\\n]|\\.)*\"""")
hits=[]
for f in glob.glob('/work/yh/lib/**/*.dart',recursive=True):
    if '/l10n/' in f or f.endswith('.g.dart') or 'yomi_tr.dart' in f: continue
    for i,line in enumerate(open(f,encoding='utf8'),1):
        st=line.strip()
        if st.startswith('//') or st.startswith('///') or st.startswith('*'): continue
        code=line.split('//')[0] if "'//" not in line and '"//' not in line and 'http' not in line else line
        for m in lit.finditer(code):
            s=m.group(0)
            if not VI.search(s): continue
            pre=code[:m.start()]
            if re.search(r"tr\(\s*$",pre): continue
            if 'AppLogger' in line or 'debugPrint' in line or 'throw ' in line and 'Exception(tr' in line: continue
            hits.append((f.replace('/work/yh/',''),i,s[:80]))
for h in hits: print(*h, sep=':')
print(len(hits), file=sys.stderr)
