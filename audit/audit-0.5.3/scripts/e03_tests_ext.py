import sys,os; sys.path.insert(0,os.path.expanduser('~/mnt/A.I Project - YomiHub Project/YomiHub-Project/audit-0.5.3')); from edit import edit
H='''
// 0.5.3: the website extensions moved to the Kiritokmn Extension Repo
// (sources-yomihub/); older checkouts still have them in assets/.
String _extSource(String f) {
  for (final d in const [
    'assets/yomihub_extensions',
    r'D:\\A.I Project\\A.I Project - Extension Repo\\Kiritokmn - Extension Repo\\sources-yomihub',
  ]) {
    final x = File('$d/$f');
    if (x.existsSync()) return x.readAsStringSync();
  }
  throw StateError('extension source $f not found');
}
'''
F='test/yh_049_test.dart'
edit(F,"    final s = File('assets/yomihub_extensions/anime47.js').readAsStringSync();","    final s = _extSource('anime47.js');")
p=os.path.expanduser('~/mnt/A.I Project - YomiHub Project/YomiHub-Project/overlay/'+F); s=open(p,encoding='utf-8').read()
i=s.index('\nvoid main(')
open(p,'w',encoding='utf-8',newline='').write(s[:i]+H+s[i:])
G='test/yh_052_test.dart'
edit(G,"_read('assets/yomihub_extensions/fikfap.js')","_extSource('fikfap.js')")
edit(G,"_read('assets/yomihub_extensions/anime47.js')","_extSource('anime47.js')")
p=os.path.expanduser('~/mnt/A.I Project - YomiHub Project/YomiHub-Project/overlay/'+G); s=open(p,encoding='utf-8').read()
i=s.index('\nvoid main(')
open(p,'w',encoding='utf-8',newline='').write(s[:i]+H+s[i:])
