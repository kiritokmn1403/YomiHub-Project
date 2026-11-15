import re, sys, io
root = sys.argv[1]
SESSION_OLD = 'session_01PnzRAu9eEMtb2yrCdK6awk'
SESSION_NEW = 'session_01C7DNQDCkwzdTEUXagaRHkQ'
def conv(t):
    t = t.replace('0.5.6.1 (0.5.6+49)', '@@N@@ (0.5.7+50)')
    t = t.replace('0\\.5\\.6\\+49', '0\\.5\\.7\\+50').replace('0.5.6+49', '0.5.7+50')
    t = t.replace('0\\.5\\.6\\.1', '@@NRX@@').replace('0.5.6.1', '@@N@@')
    t = t.replace('_0561', '_057')
    t = t.replace('v0.5.6', 'v0.5.6.1')
    t = t.replace('Phiên bản hiện tại: 0.5.6**', 'Phiên bản hiện tại: 0.5.6.1**').replace('Phiên bản trước: 0.5.6**', 'Phiên bản trước: 0.5.6.1**')
    t = t.replace('@@NRX@@', '0\\.5\\.7').replace('@@N@@', '0.5.7')
    t = t.replace(SESSION_OLD, SESSION_NEW)
    return t
def rd(p): return io.open(p, encoding='utf-8-sig', newline='').read()
def wr(p, t): io.open(p, 'w', encoding='utf-8-sig', newline='').write(t)

pub = conv(rd(root + '/release_0561_publish.ps1'))
lines = pub.split('\n')
nl = '\r\n' if pub.count('\r\n') else '\n'
head_old = '\n'.join(lines[:5])
head_new = ('# release_057_publish.ps1 - YomiHub 0.5.7 (0.5.7+50) publish pipeline. MAC DINH = dry run (in ke hoach, khong doi gi).\r\n'
            '# Chi chay that voi -Execute, sau khi da kiem thu thiet bi va dien het <<placeholder>> (Execute dung lai neu con <<).\r\n'
            '# Khong force-push, khong sua/xoa tag cu (v0.5.6, v0.5.6.1), khong tao lai tag da co.\r\n'
            '# Usage: .\\release_057_publish.ps1                                   (dry run)\r\n'
            '#        .\\release_057_publish.ps1 -Execute -ReleaseDate dd/MM/yyyy -FillFile audit-0.5.7\\release\\fill_057.json\r\n'
            '#        fill_057.json (UTF-8): {"device":"...","a6":"...","upgrade":"..."} thay cho <<KET QUA KIEM THU THIET BI>>, <<XAC NHAN danh sach...>>, <<XAC NHAN: giu du lieu...>>')
assert pub.startswith(lines[0])
pub = head_new + pub[len(head_old):].replace('\r\n','\n').replace('\n','\r\n') if nl=='\r\n' else head_new.replace('\r\n','\n') + pub[len(head_old):]
def must(old, new):
    global pub
    assert pub.count(old) == 1, (old, pub.count(old))
    pub = pub.replace(old, new)
must("[string]$VpnResult = '', [string]$Android6Result = ''", "[string]$FillFile = ''")
old_fill = pub[pub.index("$P_DATE = "):pub.index("  return $t\r\n}" if nl=='\r\n' else "  return $t\n}")]
new_fill = nl.join([
 "$P_DATE = '<<NGÀY PHÁT HÀNH>>'",
 "$fill = $null",
 "if ($FillFile) { if (-not [IO.Path]::IsPathRooted($FillFile)) { $FillFile = Join-Path $root $FillFile }; if (-not (Test-Path $FillFile)) { Die \"khong thay $FillFile\" }; $fill = [IO.File]::ReadAllText($FillFile, [Text.Encoding]::UTF8) | ConvertFrom-Json }",
 "function Rep($t, $rx, $v) { if (-not $v) { return $t }; return [regex]::Replace($t, $rx, [Text.RegularExpressions.MatchEvaluator]{ param($m) $v }) }",
 "function Fill($t) {",
 "  $t = $t.Replace($P_DATE, $ReleaseDate)",
 "  if ($fill) {",
 "    $t = Rep $t '<<KẾT QUẢ KIỂM THỬ THIẾT BỊ[^>]*>>' $fill.device",
 "    $t = Rep $t '<<XÁC NHẬN danh sách[^>]*>>' $fill.a6",
 "    $t = Rep $t '<<XÁC NHẬN: giữ dữ liệu[^>]*>>' $fill.upgrade",
 "  }",
 ""])
pub = pub.replace(old_fill, new_fill)
pub = pub.replace("(dien <<KET QUA VPN>> / <<KET QUA ANDROID6>> / <<NGAY PHAT HANH>>)", "(dien bang -ReleaseDate va -FillFile)")
wr(root + '/release_057_publish.ps1', pub)
fx = conv(rd(root + '/release_0561_fixed.ps1'))
wr(root + '/release_057_fixed.ps1', fx)
for n,t in (('publish',pub),('fixed',fx)):
    for i,l in enumerate(t.split('\n'),1):
        if re.search(r'0\.5\.6|0561', l): print(n, i, l[:170])
