import sys; sys.path.insert(0,'.')
from edit import edit
edit('lib/services/crash_report.dart',"""        '${report.error}${report.stack == null ? '' : '\\n${report.stack}'}',
        logLevel: LogLevel.error,
      );""","""        '${report.error}${report.stack == null ? '' : '\\n${report.stack}'}',
        // 0.5.2: a source / network fault (e.g. "Anime47 cần đăng nhập",
        // HTTP 401 PRIVATE_MODE) is not an app failure - WARNING, as the
        // extension line written just before it.
        logLevel: isReportableFailure(report) ? LogLevel.error : LogLevel.warning,
      );""")
