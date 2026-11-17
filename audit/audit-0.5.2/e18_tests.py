import sys; sys.path.insert(0,'.')
from edit import edit
T='test/yh_052_test.dart'
edit(T,"""import 'package:mangayomi/yomihub/win/win_diag.dart';""","""import 'package:mangayomi/yomihub/win/win_diag.dart';
import 'package:mangayomi/services/crash_report.dart';""")
edit(T,"""    test('new strings translated into every language', () {""","""    test('source faults are logged as warnings, backup results always', () {
      final r = CrashReport(
        time: DateTime(2026, 11, 6),
        source: 'updateMangaDetail',
        error: 'Error: Anime47 cần đăng nhập: bấm nút Webview',
      );
      expect(isReportableFailure(r), isFalse);
      final crash = _read('lib/services/crash_report.dart');
      expect(crash, contains('isReportableFailure(report) ? LogLevel.error : LogLevel.warning'));
      expect(_read('lib/utils/log/logger.dart'), contains('!always && !verbose'));
      final fmt = _read('lib/modules/more/data_and_storage/providers/backup_format.dart');
      expect(fmt, contains('_chapterUrlsFor('));
      expect(fmt, isNot(contains('.getAllByMangaId(existing.id)')));
      expect(_read('lib/yomihub/win/win_diag.dart'), contains('always: true'));
    });

    test('new strings translated into every language', () {""")
