# Phần A — Claude: điều phối, phân tích, rà soát, nghiệm thu

1. `LOG_FINDINGS.md`: phân nhóm toàn bộ 2.007 mục log, mỗi nhóm có số lần, ví dụ, phiên chịu trách nhiệm (YomiHub Update dòng 1; Feature Check 3).
2. `GITHUB_PROJECTS_DIFF.md`: đối chiếu `Project GitHub.xlsx` với danh sách "Dự Án GitHub đã sử dụng" trong ứng dụng; bổ sung phần thiếu (Update dòng 2; Feature Check 1, 31).
3. `L10N_REPORT.md`: chuỗi chưa dịch / thiếu khóa trong mọi ngôn ngữ; bổ sung bản dịch (Feature Check 27, 30). Rà cài đặt ngôn ngữ + NSFW của tiện ích (34).
4. Giám sát: đọc STATUS của B và C, rà diff `overlay/`, log test/build; ghi `YÊU CẦU SỬA` vào `REVIEW_CLAUDE.md` và nhắc trực tiếp trong phiên tương ứng.
5. Duyệt Mốc 1, Mốc 2; kiểm tra độc lập `output/0.5.6` (đủ 6 APK + gói Windows, băm, phiên bản, bản TV không có Comic/Novel/Play Books/Booru).
6. Gộp `NOTES_B.md`, `NOTES_C.md`, `NOTES_A.md` vào `TECHNICAL_UPDATE_NOTES.md`; thống kê tính năng mới và lỗi đã sửa so với 0.5.5; đối chiếu Release `v0.5.6`.
