# Fill audit-0.5.3/notes053.md (template) and put it into TECHNICAL_UPDATE_NOTES.md.
# usage: python3 fill053.py "<end time>"   (re-runnable: replaces the 0.5.3 section)
import os, sys
R = os.path.expanduser('~/mnt/A.I Project - YomiHub Project/YomiHub-Project')
A = os.path.join(R, 'audit-0.5.3')
rd = lambda p: open(p, encoding='utf-8').read()
tpl = rd(os.path.join(A, 'notes053.md'))
build = rd(os.path.join(A, 'build053.md')).rstrip('\n')
relp = os.path.join(A, 'release053.md')
rel = rd(relp).rstrip('\n') if os.path.exists(relp) else '- Đang phát hành: commit + push mã nguồn, Release `v0.5.3` (`release_053.ps1`). Kết quả ghi lại sau khi tải lên xong.'
end = sys.argv[1] if len(sys.argv) > 1 else '…'
sec = tpl.replace('__END__', end).replace('__BUILD__', build).replace('__RELEASE__', rel)
assert '__' + 'BUILD__' not in sec and '__' + 'RELEASE__' not in sec
p = os.path.join(R, 'TECHNICAL_UPDATE_NOTES.md')
s = rd(p)
head = '### 06/11/2026 — Cập nhật phiên bản 0.5.3'
i = s.find(head)
if i >= 0:
    s = s[:i].rstrip('\n') + '\n'
s = s.rstrip('\n') + '\n' + sec.rstrip('\n') + '\n'
st = ('- **06/11/2026 – 0.5.3 (0.5.3+45) đã dựng, kiểm thử và phát hành (GitHub Release `v0.5.3`):** '
      '29 tiện ích website chuyển sang kho Kiritokmn Extension Repo (ứng dụng chỉ tự thêm kho, tiện ích đã cài nhận cập nhật từ kho); '
      'mục "Sao Lưu & Đồng Bộ" ở Cài đặt và Thêm (kèm sao lưu Booru App); công tắc Google Play Books / Booru App trong "Bật/Tắt tính năng & Nguồn mở rộng"; '
      'xuất danh sách MyAnimeList (XML), tracker không bị thanh hệ thống/bàn phím che; Cài đặt › Chẩn đoán Windows; '
      'sửa lỗi trong `logs 3.txt` (treo khi tự sao lưu, EPUB hỏng báo lặp, trình phát/Shorts qua VPN, sao lưu vào đường dẫn Android trên Windows); 19 liên kết dự án GitHub. '
      '`dart analyze` 0 lỗi, 122/122 test. Chi tiết: mục "06/11/2026 — Cập nhật phiên bản 0.5.3" cuối tài liệu.')
marker = '## 1. Trạng thái hiện tại\n\n'
j = s.find(marker); assert j >= 0
k = j + len(marker)
if s[k:].startswith('- **06/11/2026 – 0.5.3'):
    e = s.find('\n', k); s = s[:k] + st + s[e:]
else:
    s = s[:k] + st + '\n' + s[k:]
open(p, 'w', encoding='utf-8', newline='').write(s)
print('notes ok', len(s), 'release section:', 'final' if os.path.exists(relp) else 'placeholder')
