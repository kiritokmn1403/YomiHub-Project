# A.I Brain – Second Brain (YomiHub) — ĐỌC TRƯỚC

**BẮT BUỘC:** mọi phiên/tác nhân (Claude, Antigravity/Gemini, Codex, người) phải đọc **TOÀN BỘ** thư mục này (00 → 12) **trước khi làm bất kỳ việc gì** – sửa mã, dựng, kiểm thử, phát hành hay trả lời về dự án (yêu cầu chủ dự án 14/11, 18/11/2026). Sau đó đọc `AGENTS.md` và `TECHNICAL_UPDATE_NOTES.md` (ít nhất mục 1 "Trạng thái hiện tại" và nhật ký phiên bản đang làm).

## Thứ tự đọc
| Tệp | Nội dung | Khi nào cập nhật |
|---|---|---|
| `00_README_READ_FIRST_DOC_TRUOC.md` | Mục lục, quy định bắt buộc đọc | Khi thêm/đổi tệp |
| `01_architecture_kien_truc.md` | Kiến trúc ứng dụng & cách mã YomiHub nằm trên nền Mangayomi | Khi thêm mô-đun, đổi nền |
| `02_procedure_quy_trinh.md` | Quy trình làm một đợt cập nhật từ đầu vào đến bàn giao | Khi đổi cách làm |
| `03_build_release_xay_dung_ban_phat_hanh.md` | Dây chuyền dựng các gói & phát hành GitHub/APKPure | Mỗi phiên bản |
| `04_technical_lesson_bai_hoc_ky_thuat.md` | Lỗi đã gặp, nguyên nhân, cách xử lý đúng | Sau mỗi lỗi đáng nhớ |
| `05_testing_kiem_tra.md` | Quy trình kiểm thử (tự động, thiết bị thật, Windows, bằng chứng) | Khi đổi cách kiểm |
| `06_tools_used_cong_cu_su_dung.md` | Công cụ đã dùng và lưu ý | Khi dùng công cụ mới |
| `07_performance_rules_cac_quy_tac_thuc_hien.md` | Quy tắc bắt buộc (dữ liệu, bảo mật, phát hành, báo cáo) | Khi chủ dự án đặt quy tắc mới |
| `08_ai_session_tips_meo_su_dung_phien_lam_viec_voi_ai.md` | Mẹo làm việc trong phiên Claude/AI (quyền, hạn mức, hẹn giờ) | Khi rút kinh nghiệm phiên |
| `09_A.I._agent orchestration_dieu_phoi_tac_nhan.md` | Chia việc cho tác nhân phụ, Antigravity `/swarm` | Sau mỗi đợt điều phối |
| `10_project_directory_structure_cau_truc_thu_muc_du_an.md` | Cây thư mục dự án, máy dựng, repo liên quan | Khi thêm/di chuyển thư mục |
| `11_project_handover_process_quy_trinh_ban_giao_du_an.md` | Quy trình bàn giao cuối phiên / cuối phiên bản / nhận bàn giao + trạng thái bàn giao hiện tại | Cuối mỗi phiên, mỗi phiên bản |
| `12_session log_nhat_ky_phien_lam_viec.md` | Nhật ký ngắn từng phiên làm việc | **Cuối mỗi phiên** (thêm mục mới ở cuối) |

## Ghi nhớ nhanh
- Chỉ sửa mã trong `overlay/`; thư mục dựng ở `D:\yh\...` là bản sao.
- Không đưa mật khẩu, token, Client Secret, keystore vào tệp chia sẻ, log hay GitHub.
- Không coi "ĐẠT" khi chưa có log/ảnh/video thật.
- Đăng công khai (GitHub Release, push repo tiện ích, APKPure) cần chủ dự án xác nhận rõ trong chat.
- Ghi tiến độ sau mỗi bước; cuối phiên ghi nhật ký (12) và bàn giao theo 11; cuối đợt bổ sung kiến thức vào đúng tệp trong thư mục này.
- Tiến độ bản đang làm: `audit/audit-<phiên bản>/coordination/PROGRESS_*.md`, `audit/audit-<phiên bản>/notes/`.
