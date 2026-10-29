// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get library => 'Thư viện';

  @override
  String get updates => 'Cập nhật';

  @override
  String get history => 'Lịch sử';

  @override
  String get browse => 'Duyệt';

  @override
  String get more => 'Thêm';

  @override
  String get open_random_entry => 'Mở mục ngẫu nhiên';

  @override
  String get import => 'Nhập';

  @override
  String get filter => 'Bộ lọc';

  @override
  String get ignore_filters => 'Bỏ qua bộ lọc';

  @override
  String get downloaded => 'Đã tải';

  @override
  String get unread => 'Chưa đọc';

  @override
  String get unwatched => 'Chưa xem';

  @override
  String get started => 'Đã bắt đầu';

  @override
  String get bookmarked => 'Đã đánh dấu';

  @override
  String get sort => 'Sắp xếp';

  @override
  String get alphabetically => 'Theo bảng chữ cái';

  @override
  String get last_read => 'Đọc gần nhất';

  @override
  String get last_watched => 'Xem gần nhất';

  @override
  String get last_update_check => 'Lần kiểm tra cập nhật gần nhất';

  @override
  String last_entry_delete_warning(
    num count,
    Object entryType,
    Object entryTypePlural,
    Object mediaType,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Bạn đang xóa toàn bộ $count $entryTypePlural của $mediaType này khỏi thư viện.',
      one: 'Bạn đang xóa $entryType duy nhất của $mediaType này khỏi thư viện.',
    );
    return '$_temp0\nThao tác này cũng sẽ xóa $mediaType khỏi thư viện của bạn.\n\nLưu ý: Các tệp sẽ không bị xóa.';
  }

  @override
  String get chapter => 'chương';

  @override
  String get episode => 'tập';

  @override
  String get unread_count => 'Số chương chưa đọc';

  @override
  String get unwatched_count => 'Số tập chưa xem';

  @override
  String get latest_chapter => 'Chương mới nhất';

  @override
  String get latest_episode => 'Tập mới nhất';

  @override
  String get date_added => 'Ngày thêm';

  @override
  String get display => 'Hiển thị';

  @override
  String get display_mode => 'Chế độ hiển thị';

  @override
  String get compact_grid => 'Lưới thu gọn';

  @override
  String get compression_level => 'Mức nén';

  @override
  String compression_info(Object level) {
    return 'Nén càng cao thì tệp sao lưu càng nhỏ nhưng tốn CPU hơn. Mặc định: $level';
  }

  @override
  String get comfortable_grid => 'Lưới thoải mái';

  @override
  String get cover_only_grid => 'Lưới chỉ ảnh bìa';

  @override
  String get list => 'Danh sách';

  @override
  String get badges => 'Huy hiệu';

  @override
  String get downloaded_chapters => 'Chương đã tải';

  @override
  String get downloaded_episodes => 'Tập đã tải';

  @override
  String get language => 'Ngôn ngữ';

  @override
  String get local_source => 'Nguồn cục bộ';

  @override
  String get tabs => 'Thẻ';

  @override
  String get show_category_tabs => 'Hiện thẻ danh mục';

  @override
  String get show_numbers_of_items => 'Hiện số lượng mục';

  @override
  String get other => 'Khác';

  @override
  String get show_continue_reading_buttons => 'Hiện nút đọc tiếp';

  @override
  String get show_continue_watching_buttons => 'Hiện nút xem tiếp';

  @override
  String get empty_library => 'Thư viện trống';

  @override
  String get search => 'Tìm kiếm...';

  @override
  String get no_recent_updates => 'Không có cập nhật gần đây';

  @override
  String get remove_everything => 'Xóa tất cả';

  @override
  String get remove_everything_msg => 'Bạn chắc chứ? Toàn bộ lịch sử sẽ bị mất';

  @override
  String get remove_all_update_msg =>
      'Bạn chắc chứ? Toàn bộ cập nhật sẽ bị xóa';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Hủy';

  @override
  String get remove => 'Xóa';

  @override
  String get remove_history_msg =>
      'Thao tác này sẽ xóa ngày đọc của chương này. Bạn chắc chứ?';

  @override
  String get last_used => 'Dùng gần nhất';

  @override
  String get pinned => 'Đã ghim';

  @override
  String get sources => 'Nguồn';

  @override
  String get install => 'Cài';

  @override
  String get update => 'Cập nhật';

  @override
  String get latest => 'Mới nhất';

  @override
  String get extensions => 'Tiện ích mở rộng';

  @override
  String get migrate => 'Chuyển nguồn';

  @override
  String get mass_migration_title => 'Chuyển nguồn hàng loạt';

  @override
  String get mass_migration_preview_items => 'Xem trước các mục';

  @override
  String get mass_migration_destination_source => 'Nguồn đích';

  @override
  String get mass_migration_no_library_items =>
      'Không có mục nào trong thư viện để chuyển nguồn hàng loạt.';

  @override
  String get mass_migration_no_destination_sources =>
      'Không có nguồn đích nào đã cài đặt.';

  @override
  String get mass_migration_installed => 'Đã cài đặt';

  @override
  String mass_migration_items_ready_for_review(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mục sẵn sàng để xem lại',
      one: '1 mục sẵn sàng để xem lại',
    );
    return '$_temp0';
  }

  @override
  String mass_migration_item_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mục',
      one: '1 mục',
    );
    return '$_temp0';
  }

  @override
  String get mass_migration_select_destination_source => 'Chọn nguồn đích';

  @override
  String mass_migration_finding_matches(Object source, Object language) {
    return 'Đang tìm kết quả khớp trong $source • $language';
  }

  @override
  String mass_migration_processing_item(int current, int total) {
    return 'Đang xử lý mục $current / $total';
  }

  @override
  String get mass_migration_waiting_next_item =>
      'Chờ 2 giây trước mục tiếp theo...';

  @override
  String get mass_migration_waiting_next_migration =>
      'Chờ 2 giây trước lần chuyển tiếp theo...';

  @override
  String mass_migration_matched_so_far(int count) {
    return 'Đã khớp: $count';
  }

  @override
  String mass_migration_no_match_count(int count) {
    return 'Không khớp: $count';
  }

  @override
  String mass_migration_review_matches(Object source) {
    return 'Xem lại kết quả khớp cho $source';
  }

  @override
  String mass_migration_found_matches(int count) {
    return 'Tìm thấy khớp: $count';
  }

  @override
  String mass_migration_no_matches(int count) {
    return 'Không khớp: $count';
  }

  @override
  String mass_migration_selected_to_migrate(int count) {
    return 'Đã chọn để chuyển: $count';
  }

  @override
  String get mass_migration_finish_review => 'Hoàn tất xem lại';

  @override
  String mass_migration_migrate_selected(int count) {
    return 'Chuyển các mục đã chọn ($count)';
  }

  @override
  String mass_migration_migrating_selected(Object source) {
    return 'Đang chuyển các mục đã chọn sang $source';
  }

  @override
  String get mass_migration_no_items_selected => 'Chưa chọn mục nào để chuyển.';

  @override
  String mass_migration_migrating_item(int current, int total) {
    return 'Đang chuyển mục $current / $total';
  }

  @override
  String get mass_migration_complete => 'Đã chuyển nguồn hàng loạt xong';

  @override
  String get mass_migration_complete_success_message =>
      'Tất cả các mục đã chọn được xử lý thành công.';

  @override
  String get mass_migration_complete_partial_message =>
      'Đã chuyển xong, còn vài mục cần xử lý thủ công.';

  @override
  String mass_migration_route_summary(Object source, Object destination) {
    return '$source → $destination';
  }

  @override
  String get mass_migration_processed => 'Đã xử lý';

  @override
  String get mass_migration_matched => 'Đã khớp';

  @override
  String get mass_migration_migrated => 'Đã chuyển';

  @override
  String get mass_migration_skipped => 'Đã bỏ qua';

  @override
  String get mass_migration_failed => 'Thất bại';

  @override
  String get mass_migration_failed_items => 'Mục thất bại';

  @override
  String get mass_migration_exit => 'Thoát chuyển nguồn hàng loạt';

  @override
  String get mass_migration_no_destination_match =>
      'Không tìm thấy kết quả khớp ở nguồn đích';

  @override
  String mass_migration_query(Object query) {
    return 'Truy vấn: $query';
  }

  @override
  String get mass_migration_skip => 'Bỏ qua';

  @override
  String get mass_migration_loading => 'Đang tải...';

  @override
  String get mass_migration_choose_another_result => 'Chọn kết quả khác';

  @override
  String get mass_migration_source_chapters => 'Chương ở nguồn';

  @override
  String get mass_migration_destination_chapters => 'Chương ở đích';

  @override
  String mass_migration_chapter_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count chương',
      one: '1 chương',
    );
    return '$_temp0';
  }

  @override
  String mass_migration_source_chapter_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count chương nguồn',
      one: '1 chương nguồn',
    );
    return '$_temp0';
  }

  @override
  String mass_migration_destination_chapter_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count chương đích',
      one: '1 chương đích',
    );
    return '$_temp0';
  }

  @override
  String get mass_migration_no_chapters_found => 'Không tìm thấy chương nào.';

  @override
  String mass_migration_and_more_chapters(int count) {
    return 'Và $count chương nữa...';
  }

  @override
  String get mass_migration_unknown_title => 'Không rõ tiêu đề';

  @override
  String get mass_migration_unknown_match => 'Không rõ kết quả khớp';

  @override
  String get mass_migration_unknown_source => 'Không rõ nguồn';

  @override
  String get mass_migration_unknown_chapter => 'Không rõ chương';

  @override
  String get migrate_confirm => 'Chuyển sang nguồn khác';

  @override
  String get clean_database => 'Dọn dẹp cơ sở dữ liệu';

  @override
  String cleaned_database(Object x) {
    return 'Đã dọn cơ sở dữ liệu! Đã xóa $x mục';
  }

  @override
  String get clean_database_desc =>
      'Thao tác này sẽ xóa mọi mục chưa được thêm vào thư viện!';

  @override
  String get incognito_mode => 'Chế độ ẩn danh';

  @override
  String get incognito_mode_description => 'Tạm dừng ghi lịch sử đọc';

  @override
  String get downloaded_only => 'Chỉ mục đã tải';

  @override
  String get downloaded_only_description =>
      'Chỉ hiện các mục đã tải trong thư viện';

  @override
  String get download_queue => 'Hàng đợi tải xuống';

  @override
  String get categories => 'Danh mục';

  @override
  String get statistics => 'Thống kê';

  @override
  String get settings => 'Cài đặt';

  @override
  String get about => 'Giới thiệu';

  @override
  String get help => 'Trợ giúp';

  @override
  String get no_downloads => 'Không có tải xuống';

  @override
  String get edit_categories => 'Sửa danh mục';

  @override
  String get edit_categories_description =>
      'Bạn chưa có danh mục nào. Nhấn nút cộng để tạo danh mục sắp xếp thư viện';

  @override
  String get add => 'Thêm';

  @override
  String get add_category => 'Thêm danh mục';

  @override
  String get name => 'Tên';

  @override
  String label_value(Object label, Object value) {
    return '$label: $value';
  }

  @override
  String get url => 'URL';

  @override
  String get category_name_required => '*Bắt buộc';

  @override
  String get add_category_error_exist => 'Đã có danh mục với tên này!';

  @override
  String get delete_category => 'Xóa danh mục';

  @override
  String delete_category_msg(Object name) {
    return 'Bạn muốn xóa danh mục $name?';
  }

  @override
  String get rename_category => 'Đổi tên danh mục';

  @override
  String get general => 'Chung';

  @override
  String get general_subtitle => 'Ngôn ngữ ứng dụng';

  @override
  String get app_language => 'Ngôn ngữ ứng dụng';

  @override
  String get default_subtitle_language => 'Ngôn ngữ phụ đề mặc định';

  @override
  String get appearance => 'Giao diện';

  @override
  String get appearance_subtitle => 'Chủ đề, định dạng ngày giờ';

  @override
  String get theme => 'Chủ đề';

  @override
  String get dark_mode => 'Chế độ tối';

  @override
  String get follow_system_theme => 'Theo chủ đề hệ thống';

  @override
  String get on => 'Bật';

  @override
  String get off => 'Tắt';

  @override
  String get pure_black_dark_mode => 'Chế độ tối đen tuyền';

  @override
  String get timestamp => 'Dấu thời gian';

  @override
  String get relative_timestamp => 'Thời gian tương đối';

  @override
  String get relative_timestamp_short => 'Ngắn (Hôm nay, Hôm qua)';

  @override
  String get relative_timestamp_long => 'Dài (Ngắn+, n ngày trước)';

  @override
  String get date_format => 'Định dạng ngày';

  @override
  String get reader => 'Trình đọc';

  @override
  String get refresh => 'Làm mới';

  @override
  String get reader_subtitle => 'Chế độ đọc, hiển thị, điều hướng';

  @override
  String get default_reading_mode => 'Chế độ đọc mặc định';

  @override
  String get reading_mode_vertical => 'Dọc';

  @override
  String get reading_mode_horizontal => 'Ngang';

  @override
  String get reading_mode_left_to_right => 'Trái sang phải';

  @override
  String get reading_mode_right_to_left => 'Phải sang trái';

  @override
  String get reading_mode_vertical_continuous => 'Dọc liên tục';

  @override
  String get reading_mode_webtoon => 'Webtoon';

  @override
  String get double_tap_animation_speed => 'Tốc độ hiệu ứng nhấn đúp';

  @override
  String get normal => 'Bình thường';

  @override
  String get fast => 'Nhanh';

  @override
  String get no_animation => 'Không hiệu ứng';

  @override
  String get animate_page_transitions => 'Hiệu ứng chuyển trang';

  @override
  String get crop_borders => 'Cắt viền';

  @override
  String get downloads => 'Tải xuống';

  @override
  String get downloads_subtitle => 'Cài đặt tải xuống';

  @override
  String get download_location => 'Vị trí tải xuống';

  @override
  String get custom_location => 'Vị trí tùy chỉnh';

  @override
  String get only_on_wifi => 'Chỉ khi có Wi-Fi';

  @override
  String get save_as_cbz_archive => 'Lưu dạng tệp CBZ';

  @override
  String get delete_download_after_reading => 'Xóa bản tải sau khi đọc';

  @override
  String get concurrent_downloads => 'Số lượt tải đồng thời';

  @override
  String get browse_subtitle => 'Nguồn, tìm kiếm toàn cục';

  @override
  String get only_include_pinned_sources => 'Chỉ gồm nguồn đã ghim';

  @override
  String get nsfw_sources => 'Nguồn NSFW (18+)';

  @override
  String get nsfw_sources_show => 'Hiện trong danh sách nguồn và tiện ích';

  @override
  String get nsfw_sources_info =>
      'Tùy chọn này không ngăn được các tiện ích không chính thức hoặc gắn nhãn sai hiển thị nội dung NSFW (18+) trong ứng dụng';

  @override
  String get version => 'Phiên bản';

  @override
  String beta_version(Object version) {
    return 'Beta ($version)';
  }

  @override
  String get check_for_update => 'Kiểm tra cập nhật';

  @override
  String get logs_on => 'Bật ghi nhật ký';

  @override
  String get share_app_logs => 'Chia sẻ nhật ký ứng dụng';

  @override
  String get no_app_logs => 'Không có tệp log.txt!';

  @override
  String get failed => 'Thất bại!';

  @override
  String n_days_ago(Object days) {
    return '$days ngày trước';
  }

  @override
  String get today => 'Hôm nay';

  @override
  String get yesterday => 'Hôm qua';

  @override
  String get a_week_ago => 'Một tuần trước';

  @override
  String get next_week => 'Tuần sau';

  @override
  String get add_to_library => 'Thêm vào thư viện';

  @override
  String get completed => 'Hoàn thành';

  @override
  String get ongoing => 'Đang tiến hành';

  @override
  String get on_hiatus => 'Tạm ngưng';

  @override
  String get canceled => 'Đã hủy';

  @override
  String get publishing_finished => 'Đã phát hành xong';

  @override
  String get unknown => 'Không rõ';

  @override
  String get empty_placeholder => 'TRỐNG\nRỐNG\nỐNG\nNG\n\n';

  @override
  String get error => 'Lỗi';

  @override
  String error_with_message(Object error) {
    return 'Lỗi: $error';
  }

  @override
  String get no_pages_available => 'Lỗi: không có trang nào';

  @override
  String get set_categories => 'Đặt danh mục';

  @override
  String get edit => 'Sửa';

  @override
  String get in_library => 'Trong thư viện';

  @override
  String get filter_scanlator_groups => 'Lọc nhóm dịch';

  @override
  String get reset => 'Đặt lại';

  @override
  String get by_source => 'Theo nguồn';

  @override
  String get by_chapter_number => 'Theo số chương';

  @override
  String get by_episode_number => 'Theo số tập';

  @override
  String get by_upload_date => 'Theo ngày đăng';

  @override
  String get source_title => 'Tiêu đề nguồn';

  @override
  String get create_extension => 'Tạo tiện ích';

  @override
  String get developer_mode => 'Chế độ nhà phát triển';

  @override
  String get developer_mode_subtitle =>
      'Hiện công cụ phát triển tiện ích (tạo tiện ích, sửa mã)';

  @override
  String get choose_extension_language => 'Chọn ngôn ngữ tiện ích';

  @override
  String get lang => 'Ngôn ngữ';

  @override
  String get base_url => 'BaseUrl';

  @override
  String get api_url_optional => 'ApiUrl (tùy chọn)';

  @override
  String get icon_url => 'iconUrl';

  @override
  String get source_icon_url => 'URL biểu tượng nguồn';

  @override
  String get notes => 'ghi chú';

  @override
  String get extension_name_example => 'vd: myAnime';

  @override
  String get language_code_example => 'vd: vi';

  @override
  String get base_url_example => 'vd: https://example.com';

  @override
  String get api_url_example => 'vd: https://api.example.com';

  @override
  String get extension_notes_example => 'vd: tiện ích này cần đăng nhập';

  @override
  String get type => 'Loại';

  @override
  String get target => 'Mục tiêu';

  @override
  String get source_type_single => 'đơn';

  @override
  String get source_type_multi => 'đa';

  @override
  String get source_type_torrent => 'torrent';

  @override
  String get source_language_dart => 'Dart';

  @override
  String get source_language_javascript => 'JavaScript';

  @override
  String get source_language_lnreader_compiled_js => 'LNReader JS đã biên dịch';

  @override
  String get source_created_successfully => 'Đã tạo nguồn thành công';

  @override
  String get source_already_exists => 'Nguồn đã tồn tại';

  @override
  String get error_when_creating_source => 'Lỗi khi tạo nguồn';

  @override
  String get cookies_deleted => 'Đã xóa cookie!';

  @override
  String get delete_all_cookies => 'Xóa toàn bộ cookie';

  @override
  String get chapter_number => 'Số chương';

  @override
  String get episode_number => 'Số tập';

  @override
  String get share => 'Chia sẻ';

  @override
  String n_chapters(Object n) {
    return '$n chương';
  }

  @override
  String missing_chapters(Object count) {
    return 'Thiếu $count chương';
  }

  @override
  String get no_description => 'Không có mô tả';

  @override
  String get resume => 'Tiếp tục';

  @override
  String get read => 'Đọc';

  @override
  String get watch => 'Xem';

  @override
  String get popular => 'Phổ biến';

  @override
  String get open_in_browser => 'Mở trong trình duyệt';

  @override
  String get clear_cookie => 'Xóa cookie';

  @override
  String get show_page_number => 'Hiện số trang';

  @override
  String get from_library => 'Từ thư viện';

  @override
  String get downloaded_chapter => 'Chương đã tải';

  @override
  String page(Object page) {
    return 'Trang $page';
  }

  @override
  String get global_search => 'Tìm kiếm toàn cục';

  @override
  String get color_blend_level => 'Mức pha màu';

  @override
  String current(Object char) {
    return 'Hiện tại $char';
  }

  @override
  String finished(Object char) {
    return 'Đã xong $char';
  }

  @override
  String next(Object char) {
    return 'Tiếp theo $char';
  }

  @override
  String previous(Object char) {
    return 'Trước $char';
  }

  @override
  String get no_more_chapter => 'Không còn chương nào';

  @override
  String get no_result => 'Không có kết quả';

  @override
  String get send => 'Gửi';

  @override
  String get delete => 'Xóa';

  @override
  String get start_downloading => 'Bắt đầu tải ngay';

  @override
  String get retry => 'Thử lại';

  @override
  String get add_chapters => 'Thêm chương';

  @override
  String get delete_chapters => 'Xóa chương?';

  @override
  String get default0 => 'Mặc định';

  @override
  String get total_chapters => 'Tổng số chương';

  @override
  String get total_episodes => 'Tổng số tập';

  @override
  String get import_local_file => 'Nhập tệp cục bộ';

  @override
  String get import_files => 'Tệp';

  @override
  String get split_epub_chapters => 'Tách thành các chương';

  @override
  String get split_epub_chapters_description =>
      'Nhập mỗi chương EPUB thành một mục riêng';

  @override
  String get nothing_read_recently => 'Chưa đọc gì gần đây';

  @override
  String get status => 'Trạng thái';

  @override
  String get not_started => 'Chưa bắt đầu';

  @override
  String get score => 'Điểm';

  @override
  String get start_date => 'Ngày bắt đầu';

  @override
  String get finish_date => 'Ngày hoàn thành';

  @override
  String get reading => 'Đang đọc';

  @override
  String get on_hold => 'Tạm hoãn';

  @override
  String get dropped => 'Bỏ dở';

  @override
  String get plan_to_read => 'Dự định đọc';

  @override
  String get re_reading => 'Đọc lại';

  @override
  String get chapters => 'Chương';

  @override
  String get add_tracker => 'Thêm theo dõi';

  @override
  String get one_tracker => '1 trình theo dõi';

  @override
  String n_tracker(Object n) {
    return '$n trình theo dõi';
  }

  @override
  String get tracking => 'Theo dõi';

  @override
  String get syncing => 'Đồng bộ';

  @override
  String get sync_logged => 'Đăng nhập thành công';

  @override
  String get syncing_subtitle =>
      'Đồng bộ tiến độ giữa nhiều thiết bị qua máy chủ \ntự lưu trữ.';

  @override
  String get last_sync => 'Đồng bộ lần cuối: ';

  @override
  String get sync_login_browser => 'Đăng nhập bằng trình duyệt';

  @override
  String get sync_server => 'Địa chỉ máy chủ đồng bộ';

  @override
  String get sync_starting => 'Đang bắt đầu đồng bộ...';

  @override
  String get sync_finished => 'Đồng bộ xong';

  @override
  String get sync_failed => 'Đồng bộ thất bại';

  @override
  String get sync_restore_in_progress => 'Bỏ qua đồng bộ — đang khôi phục';

  @override
  String sync_progress_percent(Object percent) {
    return 'Đang đồng bộ… $percent%';
  }

  @override
  String get sync_progress_indeterminate => 'Đang đồng bộ…';

  @override
  String get sync_button_sync => 'Đồng bộ tiến độ';

  @override
  String get sync_button_upload => 'Chỉ tải lên';

  @override
  String get sync_button_upload_info =>
      'Dữ liệu trên thiết bị này sẽ ghi đè dữ liệu trên máy chủ ở các mục trùng nhau. Không có gì trên máy chủ bị xóa.';

  @override
  String get sync_button_download => 'Chỉ tải về';

  @override
  String get sync_button_download_info =>
      'Lấy toàn bộ dữ liệu từ máy chủ. Không có gì trên thiết bị này bị xóa.';

  @override
  String get sync_status_not_configured => 'Chưa kết nối';

  @override
  String get sync_status_checking => 'Đang kiểm tra kết nối...';

  @override
  String get sync_status_connected => 'Đã kết nối';

  @override
  String get sync_status_unauthorized =>
      'Phiên đăng nhập hết hạn, vui lòng đăng nhập lại';

  @override
  String get sync_status_unreachable => 'Không kết nối được máy chủ';

  @override
  String get sync_section_general => 'Chung';

  @override
  String get sync_on => 'Bật đồng bộ';

  @override
  String get sync_auto => 'Tự động đồng bộ';

  @override
  String get sync_auto_warning =>
      'Tự động đồng bộ hiện là tính năng thử nghiệm!';

  @override
  String get sync_auto_off => 'Tắt';

  @override
  String get sync_auto_5_minutes => 'Mỗi 5 phút';

  @override
  String get sync_auto_10_minutes => 'Mỗi 10 phút';

  @override
  String get sync_auto_30_minutes => 'Mỗi 30 phút';

  @override
  String get sync_auto_1_hour => 'Mỗi 1 giờ';

  @override
  String get sync_auto_3_hours => 'Mỗi 3 giờ';

  @override
  String get sync_auto_6_hours => 'Mỗi 6 giờ';

  @override
  String get sync_auto_12_hours => 'Mỗi 12 giờ';

  @override
  String get server_error => 'Lỗi máy chủ!';

  @override
  String get dialog_confirm => 'Xác nhận';

  @override
  String get description => 'Mô tả';

  @override
  String get reorder_navigation => 'Tùy chỉnh thanh điều hướng';

  @override
  String get reorder_navigation_description =>
      'Sắp xếp và bật/tắt từng mục điều hướng theo nhu cầu.';

  @override
  String get full_screen_player => 'Dùng toàn màn hình';

  @override
  String get full_screen_player_info =>
      'Tự động chuyển toàn màn hình khi phát video.';

  @override
  String episode_progress(Object n) {
    return 'Tiến độ: $n';
  }

  @override
  String n_episodes(Object n) {
    return '$n tập';
  }

  @override
  String missing_episodes(Object count) {
    return 'Thiếu $count tập';
  }

  @override
  String get manga_sources => 'Nguồn Truyện tranh';

  @override
  String get anime_sources => 'Nguồn Phim & Điện ảnh';

  @override
  String get novel_sources => 'Nguồn Tiểu thuyết';

  @override
  String get anime_extensions => 'Tiện ích Phim & Điện ảnh';

  @override
  String get manga_extensions => 'Tiện ích Truyện tranh';

  @override
  String get novel_extensions => 'Tiện ích Tiểu thuyết';

  @override
  String get extension_settings => 'Cài đặt tiện ích';

  @override
  String get anime => 'Phim & Điện ảnh';

  @override
  String get manga => 'Truyện tranh';

  @override
  String get novel => 'Tiểu thuyết';

  @override
  String get library_no_category_exist => 'Bạn chưa có danh mục nào';

  @override
  String get watching => 'Đang xem';

  @override
  String get plan_to_watch => 'Dự định xem';

  @override
  String get re_watching => 'Xem lại';

  @override
  String get episodes => 'Tập';

  @override
  String get download => 'Tải xuống';

  @override
  String get new_update_available => 'Có bản cập nhật mới';

  @override
  String app_version(Object v) {
    return 'Phiên bản ứng dụng: v$v';
  }

  @override
  String get searching_for_updates => 'Đang tìm bản cập nhật...';

  @override
  String get no_new_updates_available => 'Không có bản cập nhật mới';

  @override
  String get uninstall => 'Gỡ cài đặt';

  @override
  String uninstall_extension(Object ext) {
    return 'Gỡ tiện ích $ext?';
  }

  @override
  String double_tap_search_hint(Object type) {
    return 'Nhấn đúp để tìm trong mọi $type';
  }

  @override
  String get show_nav_double_tap_tooltip => 'Hiện gợi ý nhấn đúp để tìm kiếm';

  @override
  String get show_nav_double_tap_tooltip_subtitle =>
      'Hiện chú thích trên các mục Truyện tranh/Phim & Điện ảnh/Tiểu thuyết, cho biết nhấn đúp sẽ mở Tìm kiếm toàn cục.';

  @override
  String already_in_library(Object source, Object title) {
    return '\"$title\" đã có trong thư viện qua $source.';
  }

  @override
  String get add_anyway => 'Vẫn thêm';

  @override
  String get langauage => 'Ngôn ngữ';

  @override
  String get extension_detail => 'Chi tiết tiện ích';

  @override
  String get scale_type => 'Kiểu co giãn';

  @override
  String get scale_type_fit_screen => 'Vừa màn hình';

  @override
  String get scale_type_stretch => 'Kéo giãn';

  @override
  String get scale_type_fit_width => 'Vừa chiều rộng';

  @override
  String get scale_type_fit_height => 'Vừa chiều cao';

  @override
  String get scale_type_original_size => 'Kích thước gốc';

  @override
  String get scale_type_smart_fit => 'Vừa thông minh';

  @override
  String get page_preload_amount => 'Số trang tải trước';

  @override
  String get page_preload_amount_subtitle =>
      'Số trang được tải trước khi đọc. Giá trị càng cao thì đọc càng mượt, nhưng tốn bộ nhớ đệm và dữ liệu mạng hơn.';

  @override
  String get image_loading_error => 'Không tải được ảnh này';

  @override
  String get add_episodes => 'Thêm tập';

  @override
  String get video_quality => 'Chất lượng';

  @override
  String get video_subtitle => 'Phụ đề';

  @override
  String get check_for_extension_updates => 'Kiểm tra cập nhật tiện ích';

  @override
  String get auto_extensions_updates => 'Tự động cập nhật tiện ích';

  @override
  String get auto_extensions_updates_subtitle =>
      'Tự động cập nhật tiện ích khi có phiên bản mới.';

  @override
  String get check_for_app_updates =>
      'Kiểm tra cập nhật ứng dụng khi khởi động';

  @override
  String get reading_mode => 'Chế độ đọc';

  @override
  String get custom_filter => 'Bộ lọc tùy chỉnh';

  @override
  String get background_color => 'Màu nền';

  @override
  String get white => 'Trắng';

  @override
  String get black => 'Đen';

  @override
  String get grey => 'Xám';

  @override
  String get automaic => 'Tự động';

  @override
  String get preferred_domain => 'Tên miền ưu tiên';

  @override
  String get load_more => 'Tải thêm';

  @override
  String get cancel_all_for_this_series => 'Hủy tất cả của bộ này';

  @override
  String get login => 'Đăng nhập';

  @override
  String login_into(Object tracker) {
    return 'Đăng nhập vào $tracker';
  }

  @override
  String get email_adress => 'Địa chỉ email';

  @override
  String get password => 'Mật khẩu';

  @override
  String log_out_from(Object tracker) {
    return 'Đăng xuất khỏi $tracker?';
  }

  @override
  String get log_out => 'Đăng xuất';

  @override
  String get update_pending => 'Đang chờ cập nhật';

  @override
  String get update_all => 'Cập nhật tất cả';

  @override
  String get backup_and_restore => 'Sao lưu và khôi phục';

  @override
  String get create_backup => 'Tạo bản sao lưu';

  @override
  String get create_backup_dialog_title => 'Bạn muốn sao lưu những gì?';

  @override
  String get create_backup_subtitle =>
      'Có thể dùng để khôi phục thư viện hiện tại';

  @override
  String get restore_backup => 'Khôi phục bản sao lưu';

  @override
  String get encrypt_backups => 'Mã hóa bản sao lưu';

  @override
  String get encrypt_backups_info =>
      'Đặt mật khẩu cho tệp sao lưu bằng mã hóa AES';

  @override
  String get no_secure_storage => 'Không tìm thấy kho lưu trữ bảo mật';

  @override
  String get no_keyring_warning =>
      'Hệ thống này không có dịch vụ keyring (vd. gnome-keyring hoặc kwallet trên Linux), nên không thể lưu mật khẩu an toàn.\n\nLưu mật khẩu không mã hóa trong cơ sở dữ liệu của ứng dụng? Bất kỳ ai truy cập được dữ liệu ứng dụng trên thiết bị này đều có thể đọc được.';

  @override
  String get enter_backup_password => 'Nhập mật khẩu sao lưu';

  @override
  String get incorrect_password_try_again => 'Sai mật khẩu, hãy thử lại.';

  @override
  String get set_backup_password => 'Đặt mật khẩu sao lưu';

  @override
  String get confirm_password => 'Xác nhận mật khẩu';

  @override
  String get passwords_do_not_match => 'Mật khẩu không khớp';

  @override
  String get password_required_to_restore =>
      'Cần mật khẩu để khôi phục bản sao lưu này.';

  @override
  String get restore_backup_subtitle => 'Khôi phục thư viện từ tệp sao lưu';

  @override
  String get automatic_backups => 'Sao lưu tự động';

  @override
  String get backup_frequency => 'Tần suất sao lưu';

  @override
  String get backup_location => 'Vị trí sao lưu';

  @override
  String get backup_options => 'Tùy chọn sao lưu';

  @override
  String get backup_options_dialog_title => 'Bạn muốn sao lưu những gì?';

  @override
  String get backup_options_subtitle =>
      'Những thông tin nào sẽ có trong tệp sao lưu?';

  @override
  String get backup_and_restore_warning_info =>
      'Bạn nên lưu thêm bản sao ở nơi khác';

  @override
  String get library_entries => 'Các mục trong thư viện';

  @override
  String get chapters_and_episode => 'Chương và tập';

  @override
  String get every_6_hours => 'Mỗi 6 giờ';

  @override
  String get every_12_hours => 'Mỗi 12 giờ';

  @override
  String get daily => 'Hằng ngày';

  @override
  String get every_2_days => 'Mỗi 2 ngày';

  @override
  String get weekly => 'Hằng tuần';

  @override
  String get restore_backup_warning_title =>
      'Khôi phục bản sao lưu sẽ ghi đè toàn bộ dữ liệu hiện có.\n\nTiếp tục khôi phục?';

  @override
  String get restore_sync_question_title => 'Đồng bộ dữ liệu vừa khôi phục?';

  @override
  String get restore_sync_question_message =>
      'Thiết bị này đang kết nối máy chủ đồng bộ. Tải dữ liệu vừa khôi phục lên ngay? Nếu không, đồng bộ sẽ bị tắt để dữ liệu cũ trên máy chủ không ghi đè dữ liệu bạn vừa khôi phục.';

  @override
  String get restore_sync_question_confirm => 'Có, đồng bộ';

  @override
  String get restore_sync_question_deny => 'Không, tắt đồng bộ';

  @override
  String get sync_disabled_after_restore =>
      'Đồng bộ đã tắt. Bạn có thể bật lại trong Cài đặt.';

  @override
  String get restore_sync_disabled_question_title => 'Đồng bộ đang tắt';

  @override
  String get restore_sync_disabled_question_message =>
      'Đồng bộ đang tắt. Bật lại và tải dữ liệu vừa khôi phục lên máy chủ?';

  @override
  String get restore_sync_question_reenable => 'Có, bật lại và đồng bộ';

  @override
  String get restore_sync_question_keep_disabled => 'Giữ tắt';

  @override
  String get restore_sync_uploading =>
      'Đang đồng bộ dữ liệu đã khôi phục lên máy chủ…';

  @override
  String get restore_sync_upload_success =>
      'Đã đồng bộ dữ liệu đã khôi phục lên máy chủ';

  @override
  String get services => 'Dịch vụ';

  @override
  String get tracking_warning_info =>
      'Đồng bộ một chiều để cập nhật tiến độ chương lên dịch vụ theo dõi. Thiết lập theo dõi cho từng mục bằng nút theo dõi của mục đó.';

  @override
  String get use_page_tap_zones => 'Dùng vùng chạm chuyển trang';

  @override
  String get manage_trackers => 'Quản lý trình theo dõi';

  @override
  String get restore => 'Khôi phục';

  @override
  String get backups => 'Bản sao lưu';

  @override
  String get by_scanlator => 'Theo nhóm dịch';

  @override
  String get by_name => 'Theo tên';

  @override
  String get installed => 'Đã cài đặt';

  @override
  String get auto_scroll => 'Tự động cuộn';

  @override
  String get video_audio => 'Âm thanh';

  @override
  String get video_audio_info =>
      'Ngôn ngữ ưu tiên, chỉnh cao độ, kênh âm thanh';

  @override
  String get player => 'Trình phát';

  @override
  String get markEpisodeAsSeenSetting => 'Đánh dấu đã xem tập phim khi nào';

  @override
  String get mark_duplicate_chapters_read =>
      'Đánh dấu đã đọc các chương trùng số';

  @override
  String get default_skip_intro_length =>
      'Thời lượng bỏ qua phần mở đầu mặc định';

  @override
  String get default_playback_speed_length => 'Tốc độ phát mặc định';

  @override
  String get updateProgressAfterReading => 'Cập nhật tiến độ sau khi đọc';

  @override
  String get no_sources_installed => 'Chưa cài nguồn nào!';

  @override
  String get show_extensions => 'Hiện tiện ích';

  @override
  String get default_skip_forward_skip_length => 'Thời lượng tua tới mặc định';

  @override
  String get aniskip_requires_info =>
      'AniSkip chỉ hoạt động khi phim được theo dõi bằng MAL hoặc Anilist.';

  @override
  String get enable_aniskip => 'Bật AniSkip';

  @override
  String get enable_auto_skip => 'Bật tự động bỏ qua';

  @override
  String get aniskip_button_timeout => 'Thời gian chờ nút';

  @override
  String get skip_opening => 'Bỏ qua mở đầu';

  @override
  String get skip_ending => 'Bỏ qua kết thúc';

  @override
  String get fullscreen => 'Toàn màn hình';

  @override
  String get update_library => 'Cập nhật thư viện';

  @override
  String updating_library(Object cur, Object failed, Object max) {
    return 'Đang cập nhật thư viện ($cur / $max) - Lỗi: $failed';
  }

  @override
  String get next_chapter => 'Chương tiếp theo';

  @override
  String get next_5_chapters => '5 chương tiếp theo';

  @override
  String get next_10_chapters => '10 chương tiếp theo';

  @override
  String get next_25_chapters => '25 chương tiếp theo';

  @override
  String get all_chapters => 'Tất cả chương';

  @override
  String get next_episode => 'Tập tiếp theo';

  @override
  String get next_5_episodes => '5 tập tiếp theo';

  @override
  String get next_10_episodes => '10 tập tiếp theo';

  @override
  String get next_25_episodes => '25 tập tiếp theo';

  @override
  String get all_episodes => 'Tất cả tập';

  @override
  String get cover_saved => 'Đã lưu ảnh bìa';

  @override
  String get set_as_cover => 'Đặt làm ảnh bìa';

  @override
  String get use_this_as_cover_art => 'Dùng ảnh này làm ảnh bìa?';

  @override
  String get save => 'Lưu';

  @override
  String get picture_saved => 'Đã lưu ảnh';

  @override
  String get cover_updated => 'Đã cập nhật ảnh bìa';

  @override
  String get include_subtitles => 'Kèm phụ đề';

  @override
  String get blend_mode_default => 'Mặc định';

  @override
  String get blend_mode_multiply => 'Nhân (Multiply)';

  @override
  String get blend_mode_screen => 'Màn chắn (Screen)';

  @override
  String get blend_mode_overlay => 'Phủ (Overlay)';

  @override
  String get blend_mode_colorDodge => 'Làm sáng màu (ColorDodge)';

  @override
  String get blend_mode_lighten => 'Làm sáng (Lighten)';

  @override
  String get blend_mode_colorBurn => 'Làm tối màu (ColorBurn)';

  @override
  String get blend_mode_darken => 'Làm tối (Darken)';

  @override
  String get blend_mode_difference => 'Khác biệt (Difference)';

  @override
  String get blend_mode_saturation => 'Độ bão hòa (Saturation)';

  @override
  String get blend_mode_softLight => 'Ánh sáng dịu (SoftLight)';

  @override
  String get blend_mode_plus => 'Cộng (Plus)';

  @override
  String get blend_mode_exclusion => 'Loại trừ (Exclusion)';

  @override
  String get custom_color_filter => 'Bộ lọc màu tùy chỉnh';

  @override
  String get color_filter_blend_mode => 'Chế độ hòa trộn bộ lọc màu';

  @override
  String get enable_all => 'Bật tất cả';

  @override
  String get disable_all => 'Tắt tất cả';

  @override
  String get font => 'Phông chữ';

  @override
  String get color => 'Màu';

  @override
  String get font_size => 'Cỡ chữ';

  @override
  String get text => 'Văn bản';

  @override
  String get border => 'Viền';

  @override
  String get background => 'Nền';

  @override
  String get no_subtite_warning_message =>
      'Không có tác dụng vì video này không có phụ đề';

  @override
  String get grid_size => 'Kích thước lưới';

  @override
  String n_per_row(Object n) {
    return '$n mỗi hàng';
  }

  @override
  String get horizontal_continious => 'Ngang liên tục';

  @override
  String get edit_code => 'Sửa mã';

  @override
  String get use_libass => 'Bật libass';

  @override
  String get use_libass_info =>
      'Dùng libass để hiển thị phụ đề cho backend gốc.';

  @override
  String get libass_not_disable_message =>
      'Tắt `use libass` trong cài đặt trình phát để tùy chỉnh phụ đề.';

  @override
  String get override_ass_subtitles => 'Ghi đè phụ đề ASS';

  @override
  String get override_ass_subtitles_info =>
      'Áp dụng kiểu tùy chỉnh cho phụ đề ASS/SSA';

  @override
  String get torrent_stream => 'Phát torrent';

  @override
  String get add_torrent => 'Thêm torrent';

  @override
  String get enter_torrent_hint_text => 'Nhập magnet hoặc URL tệp torrent';

  @override
  String get torrent_url => 'URL torrent';

  @override
  String get or => 'HOẶC';

  @override
  String get advanced => 'Nâng cao';

  @override
  String get advanced_info => 'Cấu hình mpv';

  @override
  String get use_native_http_client => 'Dùng HTTP client gốc của hệ thống';

  @override
  String get use_native_http_client_info =>
      'Tự động hỗ trợ tính năng của hệ thống như VPN, hỗ trợ thêm tính năng HTTP như HTTP/3 và xử lý chuyển hướng tùy chỉnh';

  @override
  String n_hour_ago(Object hour) {
    return '$hour giờ trước';
  }

  @override
  String n_hours_ago(Object hours) {
    return '$hours giờ trước';
  }

  @override
  String n_minute_ago(Object minute) {
    return '$minute phút trước';
  }

  @override
  String n_minutes_ago(Object minutes) {
    return '$minutes phút trước';
  }

  @override
  String n_day_ago(Object day) {
    return '$day ngày trước';
  }

  @override
  String get now => 'bây giờ';

  @override
  String library_last_updated(Object lastUpdated) {
    return 'Thư viện cập nhật lần cuối: $lastUpdated';
  }

  @override
  String get data_and_storage => 'Dữ liệu và bộ nhớ';

  @override
  String get download_location_info => 'Dùng cho tải chương';

  @override
  String get storage => 'Bộ nhớ';

  @override
  String get clear_chapter_and_episode_cache => 'Xóa bộ nhớ đệm chương và tập';

  @override
  String get cache_cleared => 'Đã xóa bộ nhớ đệm';

  @override
  String get clear_chapter_or_episode_cache_on_app_launch =>
      'Xóa bộ nhớ đệm chương/tập khi mở ứng dụng';

  @override
  String get app_settings => 'Cài đặt ứng dụng';

  @override
  String get sources_settings => 'Cài đặt nguồn';

  @override
  String get include_sensitive_settings =>
      'Gồm cài đặt nhạy cảm (vd. token đăng nhập trình theo dõi)';

  @override
  String get create => 'Tạo';

  @override
  String get downloads_are_limited_to_wifi => 'Chỉ tải xuống khi có Wi-Fi';

  @override
  String get recommendations => 'Đề xuất';

  @override
  String get recommendations_similar => 'tương tự';

  @override
  String get recommendations_weights => 'Trọng số đề xuất';

  @override
  String get recommendations_weights_genre => 'Thể loại tương tự';

  @override
  String get recommendations_weights_setting => 'Bối cảnh tương tự';

  @override
  String get recommendations_weights_synopsis => 'Cốt truyện tương tự';

  @override
  String get recommendations_weights_theme => 'Chủ đề tương tự';

  @override
  String get manga_extensions_repo => 'Kho tiện ích Truyện tranh';

  @override
  String get anime_extensions_repo => 'Kho tiện ích Phim & Điện ảnh';

  @override
  String get novel_extensions_repo => 'Kho tiện ích Tiểu thuyết';

  @override
  String get custom_dns => 'DNS tùy chỉnh (để trống để dùng DNS hệ thống)';

  @override
  String get android_proxy_server =>
      'Máy chủ proxy Android (M-Extension-Server)';

  @override
  String get get_m_extension_server => 'Tải M-Extension-Server';

  @override
  String get get_sync_server => 'Tải máy chủ đồng bộ tại đây';

  @override
  String get undefined => 'chưa xác định';

  @override
  String get empty_extensions_repo =>
      'Chưa có URL kho nào. Nhấn nút cộng để thêm!';

  @override
  String get add_extensions_repo => 'Thêm URL kho';

  @override
  String get remove_extensions_repo => 'Xóa URL kho';

  @override
  String get manage_manga_repo_urls => 'Quản lý URL kho Truyện tranh';

  @override
  String get manage_anime_repo_urls => 'Quản lý URL kho Phim & Điện ảnh';

  @override
  String get manage_novel_repo_urls => 'Quản lý URL kho Tiểu thuyết';

  @override
  String get url_cannot_be_empty => 'URL không được để trống';

  @override
  String get url_must_end_with_dot_json_or_dot_pb =>
      'URL phải kết thúc bằng .json / .pb';

  @override
  String get repo_url => 'URL kho';

  @override
  String get invalid_url_format => 'Định dạng URL không hợp lệ';

  @override
  String get clear_all_sources => 'Xóa toàn bộ nguồn';

  @override
  String get clear_all_sources_msg =>
      'Thao tác này sẽ xóa sạch mọi nguồn của ứng dụng. Bạn có chắc muốn tiếp tục?';

  @override
  String get sources_cleared => 'Đã xóa các nguồn!!!';

  @override
  String get repo_added => 'Đã thêm kho nguồn!';

  @override
  String get repo_already_exists => 'Kho đã tồn tại!';

  @override
  String get add_repo => 'Thêm kho?';

  @override
  String get genre_search_library => 'Tìm thể loại trong thư viện';

  @override
  String get genre_search_source => 'Duyệt trong nguồn';

  @override
  String get source_not_added => 'Nguồn chưa được cài!';

  @override
  String get load_own_subtitles => 'Tải phụ đề của bạn...';

  @override
  String get search_subtitles => 'Tìm phụ đề trực tuyến...';

  @override
  String extension_notes(Object notes) {
    return 'Ghi chú: $notes';
  }

  @override
  String get unsupported_repo =>
      'Bạn vừa thêm một kho không được hỗ trợ. Hãy kiểm tra lại URL kho!';

  @override
  String get end_of_chapter => 'Hết chương';

  @override
  String get chapter_completed => 'Đã đọc xong chương';

  @override
  String get continue_to_next_chapter => 'Cuộn tiếp để đọc chương sau';

  @override
  String get no_next_chapter => 'Không có chương tiếp theo';

  @override
  String get you_have_finished_reading => 'Bạn đã đọc xong';

  @override
  String get return_to_the_list_of_chapters => 'Quay lại danh sách chương';

  @override
  String get hwdec => 'Bộ giải mã phần cứng';

  @override
  String get enable_hardware_accel => 'Tăng tốc phần cứng';

  @override
  String get enable_hardware_accel_info =>
      'Bật/tắt nếu bạn gặp lỗi hoặc ứng dụng bị thoát';

  @override
  String get track_library_navigate => 'Đến mục có sẵn trong máy';

  @override
  String get track_library_add => 'Thêm vào thư viện trong máy';

  @override
  String get track_library_add_confirm =>
      'Thêm mục đang theo dõi vào thư viện trong máy';

  @override
  String get track_library_not_logged =>
      'Đăng nhập trình theo dõi tương ứng để dùng tính năng này!';

  @override
  String get track_library_switch => 'Chuyển sang trình theo dõi khác';

  @override
  String get go_back => 'Quay lại';

  @override
  String get merge_library_nav_mobile =>
      'Gộp điều hướng thư viện trên điện thoại';

  @override
  String get enable_discord_rpc => 'Bật Discord RPC';

  @override
  String get hide_discord_rpc_incognito =>
      'Ẩn Discord RPC khi ở chế độ ẩn danh';

  @override
  String get rpc_show_reading_watching_progress =>
      'Hiện chương hiện tại trên Discord (cần khởi động lại)';

  @override
  String get rpc_show_title => 'Hiện tiêu đề hiện tại trên Discord';

  @override
  String get rpc_show_cover_image => 'Hiện ảnh bìa hiện tại trên Discord';

  @override
  String get enable_mpv => 'Bật shader / script mpv';

  @override
  String get mpv_info => 'Hỗ trợ script .js trong mpv/scripts/';

  @override
  String get mpv_redownload => 'Tải lại tệp cấu hình mpv';

  @override
  String get mpv_redownload_info => 'Thay tệp cấu hình cũ bằng tệp mới!';

  @override
  String get mpv_download => 'Cần tệp cấu hình MPV!\nTải ngay?';

  @override
  String get custom_buttons => 'Nút tùy chỉnh';

  @override
  String get custom_buttons_info => 'Chạy mã lua bằng nút tùy chỉnh';

  @override
  String get custom_buttons_edit => 'Sửa nút tùy chỉnh';

  @override
  String get custom_buttons_add => 'Thêm nút tùy chỉnh';

  @override
  String get custom_buttons_added => 'Đã thêm nút tùy chỉnh!';

  @override
  String get custom_buttons_delete => 'Xóa nút tùy chỉnh';

  @override
  String get custom_buttons_text => 'Chữ trên nút';

  @override
  String get custom_buttons_text_req => 'Cần nhập chữ trên nút';

  @override
  String get custom_buttons_js_code => 'mã lua';

  @override
  String get custom_buttons_js_code_req => 'Cần nhập mã lua';

  @override
  String get custom_buttons_js_code_long => 'mã lua (khi nhấn giữ)';

  @override
  String get custom_buttons_startup => 'mã lua (khi khởi động)';

  @override
  String n_days(Object n) {
    return '$n ngày';
  }

  @override
  String get decoder => 'Bộ giải mã';

  @override
  String get decoder_info =>
      'Giải mã phần cứng, định dạng điểm ảnh, khử dải màu';

  @override
  String get enable_gpu_next => 'Bật gpu-next (chỉ Android)';

  @override
  String get enable_gpu_next_info => 'Backend hiển thị video mới';

  @override
  String get debanding => 'Khử dải màu';

  @override
  String get use_yuv420p => 'Dùng định dạng điểm ảnh YUV420P';

  @override
  String get use_yuv420p_info =>
      'Có thể sửa lỗi màn hình đen với một số codec, cũng có thể tăng hiệu năng nhưng giảm chất lượng';

  @override
  String get audio_preferred_languages => 'Ngôn ngữ ưu tiên';

  @override
  String get audio_preferred_languages_info =>
      'Ngôn ngữ âm thanh được chọn mặc định cho video có nhiều luồng âm thanh, dùng mã 2/3 chữ cái (vd: vi, en, ja). Nhiều giá trị cách nhau bằng dấu phẩy.';

  @override
  String get enable_audio_pitch_correction => 'Bật chỉnh cao độ âm thanh';

  @override
  String get enable_audio_pitch_correction_info =>
      'Giữ âm thanh không bị the thé khi phát nhanh hoặc trầm khi phát chậm';

  @override
  String get audio_channels => 'Kênh âm thanh';

  @override
  String get volume_boost_cap => 'Giới hạn tăng âm lượng';

  @override
  String get internal_player => 'Trình phát tích hợp';

  @override
  String get internal_player_info => 'Tiến độ, điều khiển, hướng màn hình';

  @override
  String get subtitle_delay_text => 'Độ trễ phụ đề';

  @override
  String get subtitle_delay => 'Độ trễ (ms)';

  @override
  String get subtitle_speed => 'Tốc độ';

  @override
  String get tracks => 'Luồng';

  @override
  String get playback_speed => 'Tốc độ phát';

  @override
  String get shaders => 'Shader';

  @override
  String get video_fit => 'Tỉ lệ khung';

  @override
  String get calendar => 'Lịch';

  @override
  String get calendar_no_data => 'Chưa có dữ liệu.';

  @override
  String get calendar_info =>
      'Lịch chỉ dự đoán ngày ra chương tiếp theo dựa trên các lần đăng trước. Một số dữ liệu có thể không chính xác 100%!';

  @override
  String in_n_day(Object days) {
    return 'trong $days ngày';
  }

  @override
  String in_n_days(Object days) {
    return 'trong $days ngày';
  }

  @override
  String get clear_library => 'Xóa thư viện';

  @override
  String get clear_library_desc =>
      'Chọn xóa toàn bộ mục Truyện tranh, Phim & Điện ảnh và/hoặc Tiểu thuyết';

  @override
  String get clear_library_input =>
      'Gõ \'manga\', \'anime\' và/hoặc \'novel\' (cách nhau bằng dấu phẩy) để xóa các mục tương ứng (manga = Truyện tranh, anime = Phim & Điện ảnh)';

  @override
  String get watch_order => 'Thứ tự xem';

  @override
  String get sequels => 'Phần tiếp theo';

  @override
  String get recommendations_similarity => 'Độ tương đồng:';

  @override
  String get local_folder_structure => 'Cấu trúc thư mục cục bộ';

  @override
  String get local_folder => 'Thư mục cục bộ';

  @override
  String get add_local_folder => 'Thêm thư mục cục bộ';

  @override
  String get rescan_local_folder => 'Quét lại mọi thư mục cục bộ';

  @override
  String get default_download_destination => 'Nơi tải xuống mặc định';

  @override
  String get ask_download_destination => 'Hỏi nơi tải xuống';

  @override
  String get ask_download_destination_desc =>
      'Chọn thư mục mỗi khi bắt đầu tải.';

  @override
  String get select_download_destination => 'Chọn nơi tải xuống';

  @override
  String get clear_local_library => 'Xóa thư viện cục bộ';

  @override
  String get clear_local_library_desc =>
      'Xóa các mục thư mục và tệp nén cục bộ khỏi thư viện.';

  @override
  String get clear_local_library_msg =>
      'Thao tác này sẽ xóa các mục thư mục và tệp nén cục bộ khỏi thư viện. Tệp trên ổ đĩa không bị xóa.';

  @override
  String get custom => 'Tùy chỉnh';

  @override
  String get no_local_folder_available_for_downloads =>
      'Không có thư mục cục bộ nào để tải xuống';

  @override
  String failed_to_create_cbz(Object error) {
    return 'Không tạo được CBZ: $error';
  }

  @override
  String error_reading_cover_image(Object error) {
    return 'Lỗi đọc ảnh bìa: $error';
  }

  @override
  String error_reading_metadata(Object error) {
    return 'Lỗi đọc siêu dữ liệu: $error';
  }

  @override
  String error_saving_chapter_episode_to_library(Object error) {
    return 'Lỗi lưu chương/tập vào thư viện: $error';
  }

  @override
  String error_reading_chapter_cover_image(Object error) {
    return 'Lỗi đọc ảnh bìa chương: $error';
  }

  @override
  String error_reading_archive_cover_image(Object error) {
    return 'Lỗi đọc ảnh bìa tệp nén: $error';
  }

  @override
  String error_getting_local_library(Object error) {
    return 'Lỗi lấy thư viện cục bộ: $error';
  }

  @override
  String get export_metadata => 'Xuất siêu dữ liệu';

  @override
  String get exported => 'Đã xuất';

  @override
  String failed_to_export_metadata(Object error) {
    return 'Xuất siêu dữ liệu thất bại: $error';
  }

  @override
  String unrecognized_chapter_numbers(Object count) {
    return '$count chương không tự đánh số được và có thể bị sai thứ tự hoặc thiếu trong trình đọc.';
  }

  @override
  String get cloudflare_resolution_webview_server_start_failed =>
      'Không khởi động được máy chủ WebView xử lý Cloudflare.';

  @override
  String tracker_token_expired(Object tracker) {
    return 'Token $tracker đã hết hạn';
  }

  @override
  String get video_list_empty => 'Danh sách video trống';

  @override
  String playback_speed_multiplier(Object value) {
    return 'x$value';
  }

  @override
  String could_not_launch_url(Object url) {
    return 'Không mở được $url';
  }

  @override
  String get text_size => 'Cỡ chữ:';

  @override
  String get text_align => 'Căn lề';

  @override
  String get line_height => 'Giãn dòng';

  @override
  String get show_scroll_percentage => 'Hiện phần trăm cuộn';

  @override
  String get remove_extra_paragraph_spacing => 'Bỏ khoảng cách đoạn thừa';

  @override
  String select_label_color(Object label) {
    return 'Chọn màu $label';
  }

  @override
  String get default_user_agent => 'User agent mặc định';

  @override
  String get forceLandscapeMode => 'Buộc xoay ngang';

  @override
  String get forceLandscapeModeSubtitle => 'Buộc trình phát dùng hướng ngang.';

  @override
  String get dns_over_https => 'DNS-over-HTTPS (DoH)';

  @override
  String get dns_provider => 'Nhà cung cấp DNS';

  @override
  String get tracked => 'Đã theo dõi';

  @override
  String get auth_unlock_msg => 'Xác thực để mở khóa YomiHub';

  @override
  String get app_locked => 'YomiHub đang khóa';

  @override
  String get auth_to_continue => 'Xác thực để tiếp tục';

  @override
  String get authenticating => 'Đang xác thực...';

  @override
  String get lock => 'Khóa';

  @override
  String get unlock => 'Mở khóa';

  @override
  String get security => 'Bảo mật';

  @override
  String get auth_to_change_security_setting =>
      'Xác thực để đổi cài đặt bảo mật';

  @override
  String get app_lock => 'Khóa ứng dụng';

  @override
  String get require_biometric_or_device_credential =>
      'Yêu cầu sinh trắc học hoặc mật khẩu thiết bị khi mở ứng dụng';

  @override
  String get biometric_or_device_credential_not_available =>
      'Thiết bị này không hỗ trợ xác thực sinh trắc học';

  @override
  String get app_lock_description =>
      'Khi bật khóa ứng dụng, bạn sẽ phải xác thực \nmỗi lần mở ứng dụng hoặc quay lại từ nền.';

  @override
  String get keep_screen_on => 'Giữ màn hình luôn sáng';

  @override
  String get webtoon_side_padding => 'Lề hai bên webtoon';

  @override
  String get show_page_gaps => 'Hiện khoảng cách giữa trang';

  @override
  String get invert_colors => 'Đảo màu';

  @override
  String get grayscale => 'Thang xám';

  @override
  String get brightness => 'Độ sáng';

  @override
  String get contrast => 'Độ tương phản';

  @override
  String get saturation => 'Độ bão hòa';

  @override
  String get navigation_layout => 'Bố cục điều hướng';

  @override
  String get nav_layout_default => 'Mặc định';

  @override
  String get nav_layout_l_shaped => 'Hình chữ L';

  @override
  String get nav_layout_kindle => 'Kiểu Kindle';

  @override
  String get nav_layout_edge => 'Cạnh';

  @override
  String get nav_layout_right_and_left => 'Phải và trái';

  @override
  String get nav_layout_disabled => 'Tắt';

  @override
  String get color_enhancements => 'Tăng cường màu';

  @override
  String get total => 'Tổng';

  @override
  String get mean_per_title => 'Trung bình mỗi bộ';

  @override
  String get completion_rate => 'Tỉ lệ hoàn thành';

  @override
  String get watching_time => 'Thời gian xem';

  @override
  String get reading_time => 'Thời gian đọc';

  @override
  String average_chapters_per_title(Object title) {
    return 'Số chương trung bình mỗi $title';
  }

  @override
  String get read_percentage => 'Phần trăm đã đọc';

  @override
  String get entries => 'Mục';

  @override
  String get android_proxy_server_mihon => 'Máy chủ proxy Android (Mihon)';

  @override
  String get android_proxy_server_mihon_description =>
      'Tải và cấu hình máy chủ proxy cần thiết để dùng tiện ích Mihon.';

  @override
  String get mihon_proxy_server => 'Máy chủ proxy Mihon';

  @override
  String get extension_server_intro_with_jre =>
      'Tải gói máy chủ proxy trước khi dùng tiện ích Mihon. Gói gồm JRE và tệp JAR máy chủ tiện ích.';

  @override
  String get extension_server_intro_ios =>
      'Tải tệp JAR máy chủ proxy trước khi dùng tiện ích Mihon. iOS chỉ cần tệp JAR máy chủ tiện ích.';

  @override
  String get checking_files => 'Đang kiểm tra tệp';

  @override
  String get files_installed => 'Đã cài tệp';

  @override
  String get files_missing => 'Thiếu tệp';

  @override
  String get update_files => 'Cập nhật tệp';

  @override
  String get up_to_date => 'Đã mới nhất';

  @override
  String get choose_location => 'Chọn vị trí';

  @override
  String get import_existing_jar => 'Nhập tệp JAR có sẵn';

  @override
  String get detect_files_in_selected_folder => 'Dò tệp trong thư mục đã chọn';

  @override
  String get preparing_download => 'Đang chuẩn bị tải...';

  @override
  String get app_install_location => 'Vị trí cài ứng dụng';

  @override
  String get install_location => 'Vị trí cài đặt';

  @override
  String get jre_executable => 'Tệp chạy JRE';

  @override
  String get extension_server_jar => 'JAR máy chủ tiện ích';

  @override
  String get installed_version => 'Phiên bản đã cài';

  @override
  String get latest_version => 'Phiên bản mới nhất';

  @override
  String get m_extension_server_description =>
      'Dùng M-Extension-Server khi cần một thiết bị Android riêng làm proxy. Đặt địa chỉ proxy ở đây và tải APK từ GitHub.';

  @override
  String get set_proxy_address => 'Đặt địa chỉ proxy';

  @override
  String get no_newer_proxy_server_release_available =>
      'Không có bản máy chủ proxy mới hơn.';

  @override
  String get could_not_check_proxy_server_updates =>
      'Không kiểm tra được cập nhật máy chủ proxy.';

  @override
  String get no_extension_server_bundle_available_for_this_platform =>
      'Không có gói máy chủ tiện ích cho nền tảng này.';

  @override
  String failed_to_download_bundle(Object statusCode) {
    return 'Tải gói thất bại ($statusCode).';
  }

  @override
  String get downloaded_bundle_missing_expected_files =>
      'Gói đã tải thiếu các tệp cần thiết.';

  @override
  String get extension_server_files_ready =>
      'Tệp máy chủ tiện ích đã sẵn sàng.';

  @override
  String get ios_extension_server_import_hint =>
      'Trên iOS, máy chủ được cài trong sandbox của ứng dụng. Dùng \"Nhập tệp JAR có sẵn\" để thêm tệp đã tải.';

  @override
  String get select_extension_server_folder => 'Chọn thư mục máy chủ tiện ích';

  @override
  String get selected_folder_does_not_exist => 'Thư mục đã chọn không tồn tại.';

  @override
  String get no_extension_server_files_found_in_selected_folder =>
      'Không tìm thấy tệp máy chủ tiện ích trong thư mục đã chọn.';

  @override
  String get extension_server_files_linked =>
      'Đã liên kết tệp máy chủ tiện ích.';

  @override
  String get select_extension_server_jar => 'Chọn JAR máy chủ tiện ích';

  @override
  String get selected_file_could_not_be_accessed =>
      'Không truy cập được tệp đã chọn.';

  @override
  String get extension_server_jar_imported => 'Đã nhập JAR máy chủ tiện ích.';

  @override
  String get could_not_launch_apk_bridge_page =>
      'Không mở được trang M-Extension-Server.';

  @override
  String get proxy_server_ip_hint =>
      'IP máy chủ (vd. 10.0.0.5 hoặc https://example.com)';

  @override
  String get not_configured => 'Chưa cấu hình';

  @override
  String get zero_interpreter => 'Trình thông dịch Zero';

  @override
  String get zero_interpreter_description =>
      'Điều khiển máy chủ thông dịch Zero tự động hoặc thủ công.';

  @override
  String get start_server_on_launch => 'Khởi động máy chủ khi mở ứng dụng';

  @override
  String get runtime_status => 'Trạng thái chạy';

  @override
  String get running => 'Đang chạy';

  @override
  String get stopped => 'Đã dừng';

  @override
  String get start => 'Bắt đầu';

  @override
  String get stop => 'Dừng';

  @override
  String get webview => 'Webview';

  @override
  String get tts => 'Đọc văn bản (TTS)';

  @override
  String get tts_speed => 'Tốc độ';

  @override
  String get tts_pitch => 'Cao độ';

  @override
  String get tts_language => 'Ngôn ngữ';

  @override
  String get tts_voice => 'Giọng đọc';

  @override
  String get tts_stop => 'Dừng';

  @override
  String get tts_play => 'Phát';

  @override
  String get tts_pause => 'Tạm dừng';

  @override
  String get tts_previous => 'Đoạn trước';

  @override
  String get tts_next => 'Đoạn sau';

  @override
  String tts_paragraph_progress(Object current, Object total) {
    return 'Đoạn $current / $total';
  }

  @override
  String get tts_settings => 'Cài đặt TTS';

  @override
  String get tts_default => 'Mặc định';

  @override
  String get webtoon_disable_zoom_out => 'Tắt thu nhỏ webtoon';

  @override
  String get webtoon_double_tap_zoom_enabled => 'Nhấn đúp để phóng to webtoon';

  @override
  String get navigate_to_pan => 'Điều hướng để kéo ảnh';

  @override
  String get navigate_to_pan_subtitle =>
      'Di chuyển ảnh đang phóng to trước khi lật trang';

  @override
  String get split_wide_pages => 'Tách trang rộng';

  @override
  String get dual_page_invert => 'Đảo thứ tự nửa trang đã cắt';

  @override
  String get dual_page_rotate_to_fit => 'Xoay cho vừa';

  @override
  String get dual_page_rotate_to_fit_invert => 'Đảo chiều xoay';

  @override
  String get double_page_single_first_page => 'Trang đầu đơn';

  @override
  String get double_page_single_first_page_subtitle =>
      'Hiện riêng trang đầu tiên ở chế độ trang đôi';

  @override
  String get double_page_auto => 'Tự động trang đôi';

  @override
  String get double_page_auto_subtitle =>
      'Tự chuyển sang trang đôi khi xoay ngang';

  @override
  String get landscape_zoom => 'Tự phóng to khi xoay ngang';

  @override
  String get zoom_start_position => 'Vị trí bắt đầu phóng to';

  @override
  String get zoom_start_left => 'Trái';

  @override
  String get zoom_start_right => 'Phải';

  @override
  String get zoom_start_center => 'Giữa';

  @override
  String get automatic_background => 'Nền tự động';

  @override
  String get tapping_inversion => 'Đảo vùng chạm';

  @override
  String get tapping_inversion_none => 'Không';

  @override
  String get tapping_inversion_horizontal => 'Ngang';

  @override
  String get tapping_inversion_vertical => 'Dọc';

  @override
  String get tapping_inversion_both => 'Cả hai';

  @override
  String get flash_on_page_change => 'Nháy khi lật trang';

  @override
  String get flash_on_page_change_subtitle =>
      'Hỗ trợ chống lưu ảnh trên màn AMOLED';

  @override
  String get flash_color => 'Màu nháy';

  @override
  String get flash_color_black => 'Đen';

  @override
  String get flash_color_white => 'Trắng';

  @override
  String get flash_color_white_black => 'Trắng & Đen';

  @override
  String flash_interval(String n) {
    return 'Chu kỳ nháy: $n trang';
  }

  @override
  String flash_duration(String n) {
    return 'Thời gian nháy: $n ms';
  }

  @override
  String get show_navigation_overlay_on_start => 'Hiện lớp điều hướng khi mở';

  @override
  String get reader_hide_threshold => 'Ngưỡng ẩn thanh đọc';

  @override
  String get reader_hide_threshold_highest => 'Cao nhất (5 px)';

  @override
  String get reader_hide_threshold_high => 'Cao (13 px)';

  @override
  String get reader_hide_threshold_low => 'Thấp (31 px)';

  @override
  String get reader_hide_threshold_lowest => 'Thấp nhất (47 px)';

  @override
  String get error_no_pages_available => 'Lỗi: không có trang nào';

  @override
  String get app_ui_scale => 'Tỉ lệ giao diện';

  @override
  String get app_ui_scale_subtitle =>
      'Phóng to hoặc thu nhỏ giao diện cho phù hợp với màn hình và khoảng cách xem.';

  @override
  String get allow_concurrent_downloads => 'Cho phép tải đồng thời';

  @override
  String get allow_concurrent_downloads_subtitle =>
      'Tải từ nhiều nguồn khác nhau cùng lúc. Mỗi nguồn vẫn chỉ tải một chương một lúc để không quá tải. Tắt để tải lần lượt từng chương ở mọi nguồn.';

  @override
  String get download_delay => 'Độ trễ tải xuống';

  @override
  String get download_delay_subtitle =>
      'Tắt. Thêm thời gian chờ ngẫu nhiên giữa các chương để giảm tải cho nguồn.';

  @override
  String get save_search => 'Lưu tìm kiếm';

  @override
  String get saved_searches => 'Tìm kiếm đã lưu';

  @override
  String get enter_search_to_save_first => 'Hãy nhập từ khóa trước khi lưu';

  @override
  String get no_saved_searches =>
      'Chưa có tìm kiếm nào được lưu cho nguồn này.\nHãy tìm kiếm, rồi chọn \"Lưu tìm kiếm\".';

  @override
  String get source => 'Nguồn';

  @override
  String get something_went_wrong => 'Đã xảy ra lỗi';

  @override
  String get startup_failed => 'YomiHub không khởi động được';

  @override
  String sources_with_no_results(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nguồn không có kết quả',
      one: '1 nguồn không có kết quả',
    );
    return '$_temp0';
  }

  @override
  String get import_mode_title => 'Nhập theo cách nào?';

  @override
  String get import_mode_message =>
      'Chọn gộp bản sao lưu này vào thư viện hiện tại, hoặc thay thế toàn bộ thư viện bằng nó.';

  @override
  String get import_mode_keep_existing => 'Gộp';

  @override
  String get import_mode_keep_existing_subtitle =>
      'Thêm bộ mới và cập nhật bộ trùng. Không xóa gì trong thư viện hiện tại.';

  @override
  String get import_mode_replace => 'Thay thế';

  @override
  String get import_mode_replace_subtitle =>
      'Xóa toàn bộ thư viện hiện tại và thay bằng bản sao lưu này.';

  @override
  String get replace_summary_title => 'Sẵn sàng thay thế thư viện';

  @override
  String replace_summary_message(Object currentCount, Object backupCount) {
    return 'Thao tác này xóa toàn bộ thư viện hiện tại ($currentCount bộ) và thay bằng $backupCount bộ từ bản sao lưu. Chỉ có thể hoàn tác bằng cách khôi phục lại.';
  }

  @override
  String get replace_summary_confirm => 'Thay thế';

  @override
  String replace_result_message(Object count) {
    return 'Đã thay thư viện bằng $count bộ từ bản sao lưu.';
  }

  @override
  String get category_conflict_title => 'Phát hiện danh mục trùng';

  @override
  String get category_conflict_message =>
      'Bản sao lưu có danh mục đã tồn tại trong thư viện. Giữ để gộp các bộ mới vào danh mục có sẵn, hoặc xóa để các bộ đó không thuộc danh mục nào.';

  @override
  String get category_conflict_keep => 'Giữ — gộp vào danh mục có sẵn';

  @override
  String get category_conflict_delete => 'Xóa — để bộ không thuộc danh mục';

  @override
  String get source_conflict_title => 'Không tìm thấy nguồn';

  @override
  String get source_conflict_message =>
      'Các nguồn trong bản sao lưu không khớp với tiện ích đã cài. Giữ tên gốc (nhập nhưng không có nguồn hoạt động), hoặc chuyển sang tiện ích đã cài để các bộ này cập nhật được.';

  @override
  String get source_conflict_keep => 'Giữ tên gốc (không có nguồn hoạt động)';

  @override
  String get import_summary_title => 'Sẵn sàng nhập';

  @override
  String import_summary_message(
    Object newSeries,
    Object updatedSeries,
    Object newChapters,
  ) {
    return '$newSeries bộ mới, $updatedSeries bộ có sẵn sẽ được cập nhật và thêm $newChapters chương mới. Không có gì trong thư viện bị xóa.';
  }

  @override
  String get import_summary_confirm => 'Nhập';

  @override
  String import_result_message(
    Object newSeries,
    Object updatedSeries,
    Object newChapters,
  ) {
    return 'Đã nhập $newSeries bộ mới, cập nhật $updatedSeries bộ có sẵn, thêm $newChapters chương mới.';
  }

  @override
  String get roll_back => 'Hoàn tác';

  @override
  String get roll_back_confirm_message =>
      'Khôi phục thư viện về bản chụp an toàn ngay trước thay đổi này, hoàn tác mọi thứ vừa làm.';

  @override
  String get roll_back_done => 'Đã hoàn tác về bản chụp trước thay đổi.';

  @override
  String get restoring_backup => 'Đang khôi phục thư viện…';

  @override
  String get roll_back_last_change => 'Hoàn tác thay đổi gần nhất';

  @override
  String roll_back_last_change_subtitle(Object date, Object description) {
    return 'Bản chụp lúc $date — $description';
  }

  @override
  String roll_back_available_count(Object count) {
    return 'Có $count thay đổi gần đây có thể hoàn tác';
  }

  @override
  String get delete_source_title => 'Xóa một nguồn và các bộ của nó';

  @override
  String get delete_source_subtitle =>
      'Chọn một nguồn và xóa mọi bộ của nguồn đó khỏi thư viện, kèm chương, bản tải, lịch sử và theo dõi.';

  @override
  String get delete_source_pick_title => 'Chọn nguồn cần xóa';

  @override
  String get delete_source_empty => 'Không có nguồn nào trong thư viện.';

  @override
  String delete_source_confirm_title(Object sourceName) {
    return 'Xóa $sourceName?';
  }

  @override
  String delete_source_confirm_message(
    Object mangaCount,
    Object chapterCount,
    Object historyCount,
    Object updateCount,
  ) {
    return 'Thao tác này xóa vĩnh viễn $mangaCount bộ, $chapterCount chương, $historyCount mục lịch sử và $updateCount mục cập nhật. Liên kết theo dõi được giữ lại. Chỉ có thể hoàn tác bằng cách khôi phục lại.';
  }

  @override
  String get delete_source_also_remove_extension => 'Gỡ luôn tiện ích đã cài';

  @override
  String get delete_source_keep_history => 'Giữ lịch sử đọc';

  @override
  String get delete_source_keep_downloads => 'Giữ bản ghi tải xuống';

  @override
  String get delete_source_button => 'Xóa';

  @override
  String delete_source_result_message(Object mangaCount, Object sourceName) {
    return 'Đã xóa $mangaCount bộ khỏi $sourceName.';
  }

  @override
  String get merge_manga_title => 'Hợp nhất các bộ trùng';

  @override
  String get merge_manga_subtitle =>
      'Tìm các bộ cùng tên trong cùng nguồn (vd. sau khi hợp nhất nguồn trùng) và gộp thành một, không xóa những gì bạn muốn giữ.';

  @override
  String get merge_manga_none_found =>
      'Không tìm thấy bộ nào có khả năng trùng.';

  @override
  String get merge_manga_pick_title => 'Các bộ có thể trùng';

  @override
  String get merge_manga_choose_primary_title => 'Gộp các bộ khác vào bộ nào?';

  @override
  String get merge_manga_choose_primary_message =>
      'Chương, lịch sử và theo dõi của các mục khác sẽ được gộp vào mục bạn chọn — không xóa gì.';

  @override
  String merge_manga_chapters_subtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count chương',
      one: '1 chương',
    );
    return '$_temp0';
  }

  @override
  String get merge_manga_button => 'Hợp nhất';

  @override
  String merge_manga_result_message(Object count, Object mangaName) {
    return 'Đã gộp $count bộ trùng vào $mangaName.';
  }

  @override
  String get merge_preview_title => 'Xác nhận hợp nhất';

  @override
  String merge_manga_preview_message(
    Object totalChapters,
    Object duplicateChapters,
    Object keptChapters,
    Object duplicateTracks,
  ) {
    return 'Tìm thấy $totalChapters chương ở các mục khác. $duplicateChapters chương trùng sẽ bị bỏ (giữ bản có tiến độ đọc); $keptChapters chương sẽ được thêm. $duplicateTracks liên kết theo dõi trùng cũng sẽ bị bỏ.';
  }

  @override
  String get memory_overlay => 'Hiện mức dùng bộ nhớ';

  @override
  String get memory_overlay_subtitle =>
      'Hiển thị trực tiếp bộ nhớ ứng dụng đang dùng, để đo trên thiết bị thay vì đoán: theo dõi khi cuộn thư viện hoặc đọc chương.';

  @override
  String get beta => 'Beta';

  @override
  String get error_reports => 'Báo cáo lỗi';

  @override
  String get error_reports_subtitle =>
      'Các lỗi ứng dụng đã ghi lại và cách báo cáo';

  @override
  String get error_reports_empty =>
      'Chưa có lỗi nào. Các lỗi ứng dụng bắt được sẽ lưu ở đây để bạn báo cáo.';

  @override
  String get error_reports_likely_cause => 'Nguyên nhân có thể';

  @override
  String get error_reports_report => 'Báo cáo trên GitHub';

  @override
  String get error_reports_banner => 'YomiHub gặp lỗi';

  @override
  String get error_reports_banner_action => 'Xem';

  @override
  String get error_reports_copy => 'Sao chép';

  @override
  String get error_reports_copied => 'Đã sao chép vào bộ nhớ tạm';

  @override
  String get error_reports_clear => 'Xóa';

  @override
  String get error_reports_extension_failure =>
      'Lỗi này đến từ một tiện ích, không phải từ YomiHub. Tiện ích do người quản lý kho mà bạn cài nguồn này viết và bảo trì, nên cần báo lỗi cho họ. Hãy cung cấp tên nguồn và mục bạn đang mở.';

  @override
  String get error_reports_already_reported => 'Đã báo cáo';

  @override
  String get error_reports_expected_failure =>
      'Lỗi này thường do nguồn hoặc mạng chứ không phải ứng dụng: liên kết hết hạn, máy chủ ngừng hoạt động hoặc mất kết nối. Chỉ nên báo cáo nếu lỗi lặp lại ở một nguồn vẫn hoạt động nơi khác.';

  @override
  String get share_unavailable_copied =>
      'Nền tảng này không hỗ trợ chia sẻ nên nội dung đã được sao chép vào bộ nhớ tạm.';

  @override
  String get onboarding_title => 'Chào mừng đến với YomiHub';

  @override
  String get onboarding_libraries_body =>
      'Chọn những gì bạn đọc và xem. Mục bạn bỏ qua sẽ không hiện trên thanh điều hướng, có thể đổi lại trong Giao diện.';

  @override
  String get onboarding_nav_title => 'Thư viện của bạn';

  @override
  String get onboarding_nav_body =>
      'Mỗi loại một thẻ riêng, hoặc gộp chung vào một thẻ Thư viện có thể chuyển đổi bên trong.';

  @override
  String get onboarding_nav_split => 'Mỗi loại một thẻ';

  @override
  String get onboarding_nav_merged => 'Một thẻ Thư viện';

  @override
  String get onboarding_nav_inside =>
      'Nhấn Thư viện sẽ đổi thanh điều hướng thành các mục này';

  @override
  String get onboarding_next => 'Tiếp';

  @override
  String get onboarding_restore => 'Khôi phục bản sao lưu';

  @override
  String get onboarding_or_local => 'Hoặc dùng tệp bạn đã có';

  @override
  String get onboarding_local_folder => 'Thêm thư mục';

  @override
  String onboarding_local_existing(Object count) {
    return 'Đã thiết lập $count thư mục';
  }

  @override
  String get onboarding_local_any_type =>
      'Truyện tranh, Phim & Điện ảnh và Tiểu thuyết đều được hỗ trợ. Mỗi bộ sẽ vào đúng thư viện dựa trên nội dung bên trong.';

  @override
  String get onboarding_local_scanning => 'Đang quét thư mục';

  @override
  String onboarding_local_found(Object count) {
    return 'Tìm thấy $count bộ';
  }

  @override
  String get onboarding_local_remove => 'Xóa thư mục đó';

  @override
  String get onboarding_local_in_downloads =>
      'Đây là thư mục tải xuống của ứng dụng. Thêm vào sẽ tạo bản sao cục bộ thứ hai của thư viện mà ứng dụng đang quản lý.';

  @override
  String get onboarding_local_empty =>
      'Không tìm thấy gì. Hãy chọn thư mục chứa các thư mục truyện, không phải thư mục của một bộ.';

  @override
  String get onboarding_repo_failed =>
      'Không đọc được kho đó. Hãy kiểm tra địa chỉ và kết nối mạng.';

  @override
  String get onboarding_repo_title => 'Thêm nguồn';

  @override
  String get onboarding_body =>
      'YomiHub không kèm sẵn nguồn nào. Hãy thêm một kho, các tiện ích trong kho sẽ có thể cài và duyệt.';

  @override
  String get onboarding_add => 'Thêm kho';

  @override
  String get onboarding_skip => 'Để sau';

  @override
  String get onboarding_continue => 'Tiếp tục';

  @override
  String get onboarding_later =>
      'Bạn có thể thêm sau trong Cài đặt, mục Duyệt.';

  @override
  String get onboarding_replay => 'Hiện màn hình chào mừng';

  @override
  String get onboarding_replay_subtitle =>
      'Mở lại màn hình lần đầu như khi mới cài.';

  @override
  String get missing_source_check_title => 'Kiểm tra nguồn bị thiếu';

  @override
  String get missing_source_check_subtitle =>
      'Tìm các mục trong thư viện có tiện ích chưa được cài - khôi phục bản sao lưu có thể để lại các mục trỏ tới nguồn chưa cài trên thiết bị này.';

  @override
  String get missing_source_check_none_found =>
      'Nguồn của mọi mục trong thư viện đều đã được cài.';

  @override
  String missing_source_check_result_title(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Thiếu $count nguồn',
      one: 'Thiếu 1 nguồn',
    );
    return '$_temp0';
  }

  @override
  String global_search_no_sources(String itemType) {
    return 'Chưa cài nguồn $itemType nào.';
  }

  @override
  String get global_search_no_sources_hint =>
      'Thêm kho trong Duyệt, rồi cài một tiện ích từ kho đó.';

  @override
  String global_search_only_pinned(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nguồn',
      one: '1 nguồn',
    );
    return 'Bạn có $_temp0 cho mục này, nhưng chỉ tìm trong nguồn đã ghim.';
  }

  @override
  String get global_search_only_pinned_hint =>
      'Ghim một nguồn, hoặc tắt \"Chỉ gồm nguồn đã ghim\" trong cài đặt Duyệt.';

  @override
  String get global_search_all_nsfw =>
      'Mọi nguồn của mục này đều được đánh dấu NSFW và đang bị ẩn.';

  @override
  String get global_search_all_nsfw_hint =>
      'Bật nguồn NSFW trong cài đặt Duyệt để tìm trong các nguồn đó.';

  @override
  String get missing_source_check_result_message =>
      'Các mục này trỏ tới nguồn chưa được cài trên thiết bị. Nhấn vào một mục để chuyển sang nguồn đã cài, cài tiện ích tương ứng, hoặc dùng \"Xóa một nguồn và các bộ của nó\" để xóa.';

  @override
  String get related_titles => 'Liên quan';

  @override
  String get related_none => 'Không tìm thấy bộ liên quan.';

  @override
  String get relation_adaptation => 'Chuyển thể';

  @override
  String get relation_sequel => 'Phần tiếp theo';

  @override
  String get relation_prequel => 'Phần trước';

  @override
  String get relation_parent => 'Truyện gốc';

  @override
  String get relation_side_story => 'Ngoại truyện';

  @override
  String get relation_spin_off => 'Phần phụ';

  @override
  String get relation_alternative => 'Phiên bản khác';

  @override
  String get auto_library_update => 'Tự động cập nhật thư viện';

  @override
  String get auto_library_update_subtitle =>
      'Kiểm tra chương mới cho mọi mục trong thư viện khi mở ứng dụng.';

  @override
  String get auto_library_update_never => 'Không bao giờ';

  @override
  String get auto_library_update_12_hours => 'Mỗi 12 giờ';

  @override
  String get auto_library_update_daily => 'Hằng ngày';

  @override
  String get auto_library_update_2_days => 'Mỗi 2 ngày';

  @override
  String get auto_library_update_weekly => 'Hằng tuần';

  @override
  String get auto_library_update_wifi_only => 'Chỉ khi có Wi-Fi';

  @override
  String get auto_library_update_wifi_only_subtitle =>
      'Bỏ qua cập nhật định kỳ khi dùng dữ liệu di động.';

  @override
  String get padding => 'Lề';

  @override
  String get page_mode => 'Chế độ trang';

  @override
  String get single_page => 'Trang đơn';

  @override
  String get double_page => 'Trang đôi';

  @override
  String get speed => 'Tốc độ';

  @override
  String get theme_dark => 'Tối';

  @override
  String get theme_light => 'Sáng';

  @override
  String get theme_black => 'Đen';

  @override
  String get theme_sepia => 'Nâu đỏ (Sepia)';

  @override
  String get decrease => 'Giảm';

  @override
  String get increase => 'Tăng';

  @override
  String get chapter_swipe_actions => 'Thao tác vuốt chương';

  @override
  String get chapter_swipe_start => 'Vuốt phải';

  @override
  String get chapter_swipe_end => 'Vuốt trái';

  @override
  String get chapter_swipe_toggle_bookmark => 'Bật/tắt đánh dấu';

  @override
  String get chapter_swipe_toggle_read => 'Bật/tắt đã đọc';

  @override
  String get chapter_swipe_download => 'Tải xuống';

  @override
  String get chapter_swipe_disabled => 'Tắt';

  @override
  String get browser => 'Trình duyệt';

  @override
  String get browser_history => 'Lịch sử duyệt web';

  @override
  String get clear_browser_history => 'Xóa lịch sử duyệt web';

  @override
  String get browser_search_hint => 'Tìm kiếm hoặc nhập địa chỉ';
}
