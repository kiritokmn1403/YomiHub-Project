import os, re
p = os.path.expanduser('~/mnt/A.I Project - YomiHub Project/YomiHub-Project/README.md')
s = open(p, encoding='utf-8').read()
old_hl = re.search(r'\*\*Phiên bản hiện tại: 0\.5\.2\*\*.*?\n\nĐiểm chính của 0\.5\.2:.*?\n', s, re.S).group(0)
new_hl = ('**Phiên bản hiện tại: 0.5.3** (06/11/2026). Có gì mới: [`YomiHub-0.5.3-changelog.md`](https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.3/YomiHub-0.5.3-changelog.md). Nhật ký kỹ thuật: [`TECHNICAL_UPDATE_NOTES.md`](TECHNICAL_UPDATE_NOTES.md).\n\n'
          'Điểm chính của 0.5.3: **29 tiện ích website chuyển sang kho [Kiritokmn Extension Repo](https://github.com/kiritokmn1403/Kiritokmn---Extension-Repo)** (ứng dụng tự thêm kho, tiện ích đã cài giữ nguyên và nhận cập nhật từ kho); mục mới **"Sao Lưu & Đồng Bộ"** ở Cài đặt và Thêm (gồm sao lưu Booru App); công tắc Google Play Books / Booru App nằm trong "Bật/Tắt tính năng & Nguồn mở rộng"; **xuất danh sách MyAnimeList (XML)** và tracker không còn bị thanh hệ thống/bàn phím che; **Cài đặt › Chẩn đoán Windows**; sửa lỗi trong nhật ký 0.5.2 (treo khi tự sao lưu, EPUB hỏng báo lặp, trình phát/Shorts qua VPN).\n')
s = s.replace(old_hl, new_hl)
s = s.replace('ảnh chụp kiểm thử Android/TV/Windows 0.5.2 được đính kèm', 'ảnh chụp kiểm thử Android/TV/Windows 0.5.3 được đính kèm')
s = s.replace('/releases/download/v0.5.2/', '/releases/download/v0.5.3/').replace('releases/tag/v0.5.2', 'releases/tag/v0.5.3')
s = s.replace('-0.5.2-', '-0.5.3-').replace('-0.5.2.txt', '-0.5.3.txt').replace('(Releases v0.5.2)', '(Releases v0.5.3)')
s = s.replace('| `build_052.ps1`, `sync_052.ps1`, `release_052.ps1`,', '| `build_053.ps1`, `sync_053.ps1`, `release_053.ps1`,')
s = s.replace('| `audit-0.5.2/adb.sh`, `tv.sh`, `framerec.ps1`, `dlg.ps1`,', '| `audit-0.5.3/adb.sh`, `job.sh`, `framerec.ps1`, `winshot.ps1`,')
s = s.replace('| `audit-0.3.9/` … `audit-0.5.2/` |', '| `audit-0.3.9/` … `audit-0.5.3/` |')
s = s.replace('(`sync_052.ps1` chỉ chép các tệp trong `audit-0.5.2/changed_files.txt`)', '(`sync_053.ps1` chỉ chép các tệp trong `audit-0.5.3/changed_files.txt`)')
s = s.replace('2. Chạy `build_052.ps1 -step test|unit|apk|tv|win|pack`', '2. Chạy `build_053.ps1 -step test|unit|apk|tv|win|pack`')
if 'Kiritokmn---Extension-Repo/main/repo/index.json' not in s:
    s = s.replace('**Chưa hỗ trợ:**', '**Tiện ích website:** từ 0.5.3 nằm ở kho `https://raw.githubusercontent.com/kiritokmn1403/Kiritokmn---Extension-Repo/main/repo/index.json` (ứng dụng tự thêm khi cập nhật lên 0.5.3; cài thủ công: Duyệt › Tiện ích › Kho tiện ích).\n\n**Chưa hỗ trợ:**', 1)
left = [l[:100] for l in s.split('\n') if '0.5.2' in l]
open(p, 'w', encoding='utf-8', newline='').write(s)
print('README ok; remaining 0.5.2 refs:', left)
