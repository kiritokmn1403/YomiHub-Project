# gen_057_scripts.py - tao bo script dung 0.5.7 (0.5.7+50) tu bo 0.5.6.1 (0.5.6+49). Chi TAO tep moi, khong sua tep cu.
import os, re, sys
R = os.path.expanduser('~/mnt/YomiHub-Project')
pairs = {
 'sync_0561.ps1':'sync_057.ps1', 'build_0561_android.ps1':'build_057_android.ps1', 'build_0561.ps1':'build_057.ps1',
 'build_0561_android6.ps1':'build_057_android6.ps1', 'make_appxbundle_0561.ps1':'make_appxbundle_057.ps1',
 'make_installer_exe_0561.ps1':'make_installer_exe_057.ps1',
}
subs = [
 (r'0\\\.5\\\.6\\\+49', r'0\\.5\\.7\\+50'),          # regex trong PS
 (r"Version=\"0\\\.5\\\.6\\\.1\"", r'Version="0\\.5\\.7"'),
 ('0\\.5\\.6\\.1', '0\\.5\\.7'),
 ('0.5.6.1+49', '0.5.7+50'),
 ('0.5.6+49', '0.5.7+50'),
 ('0.5.6.1', '0.5.7'),
 ('0561', '057'),
 ("$pubVer -ne '0.5.6'", "$pubVer -ne '0.5.7'"),
 ("kỳ vọng '0.5.6'", "kỳ vọng '0.5.7'"),
 ("$code -ne '49'", "$code -ne '50'"),
 ("kỳ vọng '49'", "kỳ vọng '50'"),
 ('-0.5.6-', '-0.5.7PREV-'), ('output\\0.5.6\\', 'output\\0.5.7PREV\\'),
]
for src, dst in pairs.items():
    p = os.path.join(R, src)
    s = open(p, encoding='utf-8-sig', newline='').read()
    for a, b in subs: s = s.replace(a, b)
    s = s.replace('0.5.7PREV', '0.5.6.1')
    if dst == 'build_057_android6.ps1':
        n = s.count('--split-debug-info')
        assert n == 1, n
        s = s.replace('--split-debug-info', '--dart-define=IS_A6_BUILD=true --split-debug-info')
    out = os.path.join(R, dst)
    if os.path.exists(out): sys.exit('da ton tai: ' + dst)
    open(out, 'w', encoding='utf-8-sig', newline='').write(s)
    print(dst, len(s))
