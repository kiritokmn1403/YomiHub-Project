from ed import *

rel = 'lib/yomihub/extensions/ext_errors.dart'
sub(rel, """    r'not configured|chưa cấu hình|trong cài đặt (của )?tiện ích|đăng nhập)',""",
         """    r'not configured|chưa cấu hình|trong cài đặt (của )?tiện ích|đăng nhập|'
    // 0.5.7 (logs 7, 12/11 16:18: Kavita "OPDS URL required / Please configure
    // your Kavita server connection" was an ERROR with a native stack)
    r'(opds )?url required|please configure|server connection)',""")
sub(rel, """    r'http error 5(2[0-9]|0[234])|status(code)?[=: ]+5(2[0-9]|0[234])\\b|'""",
         """    // 0.5.7: + 530 (Cloudflare: origin unreachable – logs 7 HentaiVN.plus,
    // Phim Nhựa), "HTTP 5xx <url>" and "HTTP 0 <url>" (no answer at all) as
    // written by the JavaScript extensions of the Kiritokmn repo
    r'http (error )?5(2[0-9]|30|0[234])\\b|status(code)?[=: ]+5(2[0-9]|30|0[234])\\b|'
    r'\\bhttp 0 https?://|'""")
sub(rel, """    if (RegExp(r'\\b52[0-9]\\b').hasMatch(s)) {""", """    if (RegExp(r'\\b5(2[0-9]|30)\\b').hasMatch(s)) {""")
sub(rel, """  /// One-line, user-readable form of an extension error (no stack, no
  /// "statusCode: 500" padding added by the APK bridge).""", """  // ---- 0.5.7 (logs 7, 12-14/11/2026) -----------------------------------
  /// The APK extension needs a class / method that the extension runner of
  /// this build does not have (logs 7, 14/11 07:38 "MiMi": `abstract method
  /// "… GeneratedSerializer.typeParametersSerializers()"`). Seen with the
  /// separate Android 6.0 APK, whose libraries cannot keep interface default
  /// methods; never an error a stack trace of the app helps with.
  static final RegExp _incompatible = RegExp(
    r'(abstract method "|abstractmethoderror|nosuchmethoderror|noclassdeffounderror|'
    r'incompatibleclasschangeerror|no (static|virtual|direct|interface) method )',
    caseSensitive: false,
  );
  static bool isIncompatible(Object e) => _incompatible.hasMatch(e.toString());

  static String incompatibleHint() => tr(
      'Tiện ích này cần thư viện mới hơn bộ chạy tiện ích APK của bản cài hiện tại: hãy cập nhật YomiHub; nếu đang dùng bản APK dành cho Android 6.0 trên máy Android 7.0 trở lên, hãy cài bản APK thường.');

  /// The source answered, but not with what the extension expects (Aidoku
  /// "SourceError: missing result / JSON parse error", an empty body, a
  /// missing CSRF token …): the site changed or blocked the request. One
  /// warning line; the native stack of the app says nothing about it.
  static final RegExp _sourceData = RegExp(
    r'(sourceerror: (missing result|json parse error|[a-z ]{3,40}$)|csrf token not found|'
    r'end of input at character 0|no value for [a-z_]+$|method not allowed)',
    caseSensitive: false,
    multiLine: true,
  );
  static bool isSourceDataError(Object e) => _sourceData.hasMatch(short(e));

  /// An extension its repository marks as discontinued ("… (Ngừng hoạt
  /// động)"): its site is gone, every call fails – noted once per run.
  static bool isDiscontinued(String? name) {
    final n = (name ?? '').toLowerCase();
    return n.contains('(ngừng hoạt động)') || n.contains('(discontinued)') || n.contains('(dead)');
  }

  static final Set<String> _discontinuedNoted = {};
  static bool noteDiscontinuedOnce(String? name, String? lang) => _discontinuedNoted.add(_key(name, lang));

  /// One-line, user-readable form of an extension error (no stack, no
  /// "statusCode: 500" padding added by the APK bridge).""")

rel = 'lib/services/isolate_service.dart'
sub(rel, """      if (YomiExtErrors.isSetupError(e)) {
        if (!YomiExtErrors.needsSetup(source?.name, source?.lang)) {""", """      if (YomiExtErrors.isDiscontinued(source?.name)) {
        // 0.5.7 (logs 7, 14/11: "Phim Nhựa (Ngừng hoạt động)", "Rổ Phim (Ngừng
        // hoạt động)" … were ERRORs): the repository itself says the site is
        // gone – one information line per run, and background work skips it
        YomiExtErrors.markSlow(source?.name, source?.lang);
        if (YomiExtErrors.noteDiscontinuedOnce(source?.name, source?.lang)) {
          AppLogger.log(
              '$where: ${YomiExtErrors.short(e).split('\\n').first} – tiện ích được kho đánh dấu đã ngừng hoạt động',
              logLevel: LogLevel.info);
        }
      } else if (YomiExtErrors.isSetupError(e)) {
        if (!YomiExtErrors.needsSetup(source?.name, source?.lang)) {""")
sub(rel, """      } else if (serviceType == 'search' &&
          (query ?? '').trim().isNotEmpty &&
          RegExp(r"expected start of the object '\\{', but had '\\['|http error 404\\b",
                  caseSensitive: false)
              .hasMatch(e.toString())) {""", """      } else if (YomiExtErrors.isIncompatible(e)) {
        // 0.5.7: the extension needs a newer extension runner (MiMi, logs 7)
        if (YomiExtErrors.shouldLog(source?.name, source?.lang, serviceType, e)) {
          AppLogger.log(
              '$where: ${YomiExtErrors.short(e).split('\\n').first} – ${YomiExtErrors.incompatibleHint()}',
              logLevel: LogLevel.warning);
        }
      } else if (serviceType == 'search' &&
          (query ?? '').trim().isNotEmpty &&
          RegExp(r"expected start of the object '\\{', but had '\\['|http error 404\\b|"
                  // 0.5.7 (logs 7, global search 12/11 16:18): Aidoku sources
                  // and the NHentai (dart) source with no match
                  r"sourceerror: missing result|bad state: no element",
                  caseSensitive: false)
              .hasMatch(e.toString())) {""")
sub(rel, """      } else if (YomiExtErrors.shouldLog(source?.name, source?.lang, serviceType, e)) {
        final timeout = e is TimeoutException;""", """      } else if (YomiExtErrors.isSourceDataError(e)) {
        // 0.5.7: the site answered with something the extension cannot read
        if (YomiExtErrors.shouldLog(source?.name, source?.lang, serviceType, e)) {
          AppLogger.log('$where: ${YomiExtErrors.short(e)}', logLevel: LogLevel.warning);
        }
      } else if (YomiExtErrors.shouldLog(source?.name, source?.lang, serviceType, e)) {
        final timeout = e is TimeoutException;""")

rel = 'lib/utils/platform_utils.dart'
sub(rel, """const bool kIsTvBuild = bool.fromEnvironment('IS_TV_BUILD', defaultValue: false);
""", """const bool kIsTvBuild = bool.fromEnvironment('IS_TV_BUILD', defaultValue: false);

/// 0.5.7: true in the separate Android 6.0 APK (`YomiHub-<ver>-android6-*`,
/// minSdk 23, built with `--dart-define=IS_A6_BUILD=true`).
const bool kIsA6Build = bool.fromEnvironment('IS_A6_BUILD', defaultValue: false);
""")
print('t4 ok')
