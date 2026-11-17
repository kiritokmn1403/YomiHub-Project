import os, re
p = os.path.expanduser('~/mnt/A.I Project - YomiHub Project/YomiHub-Project/README.md')
s = open(p, encoding='utf-8').read()
old_hl = re.search(r'\*\*Phiên bản hiện tại: 0\.5\.1\*\*.*?\n\nĐiểm chính của 0\.5\.1:.*?\n', s, re.S).group(0)
new_hl = ('**Phiên bản hiện tại: 0.5.2** (06/11/2026). Có gì mới: [`YomiHub-0.5.2-changelog.md`](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.2/YomiHub-0.5.2-changelog.md). Nhật ký kỹ thuật: [`TECHNICAL_UPDATE_NOTES.md`](TECHNICAL_UPDATE_NOTES.md).\n\n'
          'Điểm chính của 0.5.2: **sao lưu / khôi phục** nhanh và không treo (đọc bản sao lưu TachiyomiMi 12 MB từ 45 s còn 8 s, Mangayomi 22 MB còn 11 s trên Galaxy Note 9; Gộp giữ nguồn và cài tiện ích có trong bản sao lưu, thêm chương còn thiếu cho bộ đã có); **Windows** kèm VC++ runtime, `Setup.exe` cài gói đầy đủ (Java + M-Extension-Server) và tự ghi chẩn đoán phần cứng/thành phần thiếu vào nhật ký (báo lỗi "thiếu tính năng" trên AMD Ryzen 9); **WARP** tự thử cổng khác khi mạng chặn UDP và không còn báo "Đã kết nối" giả; sửa các lỗi trong nhật ký 0.5.1 (thư viện, cập nhật thư viện, Tor, Anime47, FikFap, vBook, Subsplease…).\n')
s = s.replace(old_hl, new_hl)
s = s.replace('ảnh chụp kiểm thử Android/TV/Windows 0.5.1 được đính kèm', 'ảnh chụp kiểm thử Android/TV/Windows 0.5.2 được đính kèm')
s = s.replace('/releases/download/v0.5.1/', '/releases/download/v0.5.2/').replace('releases/tag/v0.5.1', 'releases/tag/v0.5.2')
s = s.replace('-0.5.1-', '-0.5.2-').replace('-0.5.1.txt', '-0.5.2.txt').replace('(Releases v0.5.1)', '(Releases v0.5.2)')
s = s.replace('| `build_051.ps1`, `sync_051.ps1`,', '| `build_052.ps1`, `sync_052.ps1`, `release_052.ps1`,')
s = s.replace('| `qa051.ps1`, `audit-0.5.1/winqa.ps1` và', '| `audit-0.5.2/adb.sh`, `tv.sh`, `framerec.ps1`, `dlg.ps1`, `audit-0.5.1/winqa.ps1` và')
s = s.replace('| `audit-0.3.9/` … `audit-0.5.1/` |', '| `audit-0.3.9/` … `audit-0.5.2/` |')
s = s.replace('(`sync_050.ps1` chỉ chép các tệp trong `audit-0.5.1/changed_files.txt`)', '(`sync_052.ps1` chỉ chép các tệp trong `audit-0.5.2/changed_files.txt`)')
s = s.replace('2. Chạy `build_051.ps1 -step test|unit|apk|tv|win|pack`', '2. Chạy `build_052.ps1 -step test|unit|apk|tv|win|pack`')
assert not [l for l in s.split('\n') if '0.5.1' in l and 'nhật ký 0.5.1' not in l and 'audit-0.5.1/winqa' not in l], [l for l in s.split('\n') if '0.5.1' in l]
open(p, 'w', encoding='utf-8', newline='').write(s)
print('README ok; remaining 0.5.1 refs:', [l[:80] for l in s.split('\n') if '0.5.1' in l])
