export 'gif_viewer_controller.dart';
export 'nuvio_media_hub.dart';
export 'nyora_data_bridge.dart';
export 'yomihon_novel_enhancer.dart';
export 'yomikiru_reader_enhancer.dart';
export 'zenshin_anime_tracker.dart';

/// YomiHub 0.5.6 — Registry & Audit table of open-source project integrations.
///
/// Bảng đối chiếu tích hợp dự án mới (YomiHub Update mục 5):
/// Dự án · Đã lấy gì · Chưa lấy gì · Lý do
class YomiIntegrations {
  YomiIntegrations._();

  static const List<Map<String, String>> integrationAuditTable = [
    {
      'project': 'Yomikiru',
      'url': 'https://github.com/mienaiyami/yomikiru',
      'status': 'Chưa tích hợp',
      'taken': 'Mã thử nghiệm: Thuật toán ghép trang đôi (dual-page spread) cho màn hình lớn, 4 chế độ căn chỉnh trang (Smart, Width, Height, 1:1), phím tắt bàn phím desktop (Left/Right, A/D, Space, PageUp/Down, Home/End), bộ lọc hình ảnh.',
      'notTaken': 'Runtime Electron/Node.js cồng kềnh.',
      'reason': 'YomiHub sử dụng Flutter Native Engine tối ưu hiệu năng và bộ nhớ, không cần phụ thuộc framework Electron.',
    },
    {
      'project': 'Yomihon',
      'url': 'https://miyomi.app/software/yomihon',
      'status': 'Chưa tích hợp',
      'taken': 'Mã thử nghiệm: Quy chuẩn typography (Compact, Standard, Relaxed), hỗ trợ bố cục văn bản dọc (Tate-gaki CJK), bộ tính toán thời lượng đọc ước tính theo từ/phút (WPM).',
      'notTaken': 'Giao diện web HTML riêng biệt của Yomihon.',
      'reason': 'YomiHub đã có sẵn trình đọc tiểu thuyết tích hợp Material 3 và hiệu ứng Liquid Glass.',
    },
    {
      'project': 'Zenshin',
      'url': 'https://github.com/hitarth-gg/zenshin',
      'status': 'Chưa tích hợp',
      'taken': 'Mã thử nghiệm: Thuật toán bóc tách số tập anime thông minh từ tiêu đề/tên file phức tạp, ngưỡng tự động đồng bộ tiến độ xem (85%), tính điểm độ tin cậy khi khớp siêu dữ liệu với AniList/MAL.',
      'notTaken': 'Lõi torrent cũ gắn liền với hệ sinh thái riêng của Zenshin.',
      'reason': 'YomiHub đã tích hợp sẵn engine torrent đa nền tảng độc lập (torrent_server.dart).',
    },
    {
      'project': 'Nyora',
      'url': 'https://github.com/Nyora-Manga',
      'status': 'Chưa tích hợp',
      'taken': 'Mã thử nghiệm: Bộ phân tích cấu trúc kho nguồn data-driven (Nyora manifest parser), cơ chế chuẩn hóa metadata đa nguồn mở rộng.',
      'notTaken': 'Mã giao diện Android Kotlin nguyên bản.',
      'reason': 'YomiHub phát triển trên Flutter để chia sẻ 100% mã nguồn giữa Android và Windows.',
    },
    {
      'project': 'Nuvio',
      'url': 'https://github.com/NuvioMedia/NuvioMobile',
      'status': 'Chưa tích hợp',
      'taken': 'Mã thử nghiệm: Bộ cử chỉ vuốt điều chỉnh độ sáng/âm lượng hai bên màn hình trình phát, thời gian tua nhanh chạm đúp tùy chỉnh, bộ tính tỉ lệ khung hình cửa sổ Picture-in-Picture tối ưu.',
      'notTaken': 'Hệ thống tài khoản người dùng đám mây của Nuvio.',
      'reason': 'YomiHub bảo vệ sự riêng tư tối đa, hỗ trợ lưu trữ cục bộ và sao lưu tự chọn.',
    },
    {
      'project': 'GIF Viewer',
      'url': 'https://github.com/ata4/gifiddle',
      'status': 'Chưa tích hợp',
      'taken': 'Mã thử nghiệm: Bộ điều khiển GifViewerController: dừng/phát, chuyển từng khung hình tới/lui, đảo chiều phát, điều chỉnh tốc độ từ 0.25x đến 4.0x, chế độ lặp vô tận.',
      'notTaken': 'Mã nguồn C++ Win32 cũ.',
      'reason': 'Được hiện thực lại hoàn toàn bằng Dart hướng đối tượng, hỗ trợ hoàn hảo trên cả Android và Windows.',
    },
  ];
}
