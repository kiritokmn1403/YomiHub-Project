import json
from pathlib import Path
root=Path(__file__).resolve().parent.parent/'overlay/assets/yomihub_i18n'
corrections={
'Bạn có chắc muốn hủy hợp nhất "{p0}" và tách lại thành các bộ riêng lẻ theo từng nguồn không?':'Unmerge "{p0}" and restore separate titles for each source?',
'Chưa có bộ nào được hợp nhất trong thư viện.':'No merged titles in the library yet.',
'Chưa có tiện ích nào được thiết lập hợp nhất.':'No extension groups have been created yet.',
'Chọn các bộ cần hợp nhất':'Select titles to merge',
'Chọn các bộ để hợp nhất':'Select titles to merge',
'Chọn nguồn thay thế cho tất cả {p0} bộ trong "{p1}":':'Select a replacement source for all {p0} titles in "{p1}":',
'Các chương từ các bộ khác sẽ được hợp nhất vào bộ này và giữ nguyên nguồn gốc đọc:':'Chapters from the other titles will be merged into this title while preserving their original sources:',
'Cần cài đặt ít nhất 2 tiện ích để thực hiện hợp nhất.':'Install at least 2 extensions before merging.',
'Cần ít nhất 2 bộ trong thư viện để tiến hành hợp nhất.':'Add at least 2 titles to your library before merging.',
'Danh sách các bộ đã hợp nhất ({p0})':'Merged titles ({p0})',
'Gộp tất cả các bộ sang nguồn mới':'Move all titles to a new source',
'Hợp nhất tiện ích theo lựa chọn':'Choose extensions to merge',
'Hủy hợp nhất':'Unmerge',
'Không có nguồn nào khác cùng thể loại để gộp sang. Vui lòng cài đặt nguồn mới trước.':'No other sources support this content type. Install another source first.',
'Lỗi nén luồng từ máy chủ nguồn: thử lại sau hoặc chuyển sang nguồn phụ.':'Unable to decode the compressed response from this source. Try again later or choose another source.',
'Người dùng tự chọn bộ để hợp nhất':'Choose titles to merge',
'Phát hiện {p0} nhóm bộ có tên trùng nhau trong thư viện. Bạn có muốn xem và xác nhận hợp nhất không?':'Found {p0} groups of titles with matching names. Review and confirm the merge?',
'Tiến hành hợp nhất':'Merge',
'Tách lại nguồn':'Restore separate sources',
'Tự chọn bộ để hợp nhất':'Choose titles to merge',
'Tự chọn các tiện ích để hợp nhất':'Choose extensions to merge',
'Tự chọn các tiện ích để hợp nhất với nhau vào tiện ích đích':'Choose extensions to group under a primary extension',
'Xác nhận hủy hợp nhất':'Confirm unmerge',
'{p0} nguồn ({p1}) • {p2} chương/tập':'{p0} sources ({p1}) • {p2} chapters/episodes',
'Đã hoàn tất hợp nhất các bộ trùng tên.':'Titles with matching names have been merged.',
'Đã hợp nhất thành công vào bộ "{p0}".':'Successfully merged into "{p0}".',
'Đã hợp nhất {p0} tiện ích vào "{p1}".':'Grouped {p0} extensions under "{p1}".',
'Đã hủy hợp nhất thành công. Các bộ đã được tách lại độc lập.':'Unmerged successfully. The titles are separate again.',
'Đề xuất hợp nhất trùng tên':'Suggested merges for matching titles',
}
p=root/'en.json';d=json.loads(p.read_text(encoding='utf-8'));d.update(corrections)
for k,v in list(d.items()):
    if k.startswith('Thiếu ') and 'yomihub_bin' in k:
        d[k]=v.replace('fully recompress','fully extract')
p.write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
p=root/'hi.json';d=json.loads(p.read_text(encoding='utf-8'));d.update({
'Giới hạn lành mạnh: {p0} phút/ngày':'स्वस्थ सीमा: {p0} मिनट/दिन',
'{p0} nguồn ({p1}) • {p2} chương/tập':'{p0} स्रोत ({p1}) • {p2} अध्याय/एपिसोड'})
p.write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('Reviewed English merge terminology and restored two Hindi placeholders.')
