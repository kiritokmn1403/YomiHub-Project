import sys; sys.path.insert(0,'.')
from edit import edit
F='lib/yomihub/extensions/ext_errors.dart'
edit(F,"""    if (s.contains('resolve host') || s.contains('no address associated') || s.contains('failed host lookup')) {
      return tr('Tên miền""","""    // 0.5.2: host glued to a path ("mimihentai.moe24403", logs 2 04/11
    // 21:48:19) - the entry/chapter URL was saved by an older version of the
    // extension (relative id without "/"), and the current version prefixes
    // it with its base URL. A DNS/VPN change cannot fix that; a refresh or a
    // migration can.
    if (RegExp(r'host "?[a-z0-9.-]+\\.[a-z]{2,10}\\d+[/"]').hasMatch(s)) {
      return tr('Đường dẫn chương/truyện được lưu từ phiên bản cũ của tiện ích nên bị ghép sai tên miền. Mở chi tiết truyện và kéo xuống để làm mới danh sách chương, hoặc dùng "Di chuyển" sang tiện ích mới.');
    }
    if (s.contains('resolve host') || s.contains('no address associated') || s.contains('failed host lookup')) {
      return tr('Tên miền""")
