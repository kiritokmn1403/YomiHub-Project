import sys, re, os; sys.path.insert(0,'.')
from edit import edit, ROOT
edit('lib/utils/log/logger.dart',"""  static void log(String message, {LogLevel logLevel = LogLevel.info}) {
    final important =
        logLevel == LogLevel.error || logLevel == LogLevel.warning;
    if (!important && !verbose) return;""","""  /// [always]: 0.5.2 - an INFO line that is written even with "Enable logs"
  /// off (backup / restore results, Windows diagnostics), so a log sent in
  /// by a user shows what happened, not only what failed.
  static void log(String message, {LogLevel logLevel = LogLevel.info, bool always = false}) {
    final important =
        logLevel == LogLevel.error || logLevel == LogLevel.warning;
    if (!important && !always && !verbose) return;""")
# every info-level "[Sao lưu]" line and the Windows diagnostics summary
targets = {
 'lib/modules/more/data_and_storage/providers/backup.dart': 1,
 'lib/modules/more/data_and_storage/providers/backup_format.dart': 2,
 'lib/modules/more/data_and_storage/providers/restore.dart': 2,
 'lib/yomihub/win/win_diag.dart': 1,
}
for rel, n in targets.items():
    p = os.path.join(ROOT, 'overlay', rel)
    s = open(p, encoding='utf-8').read()
    # find "AppLogger.log(" calls containing [Sao lưu]/[Windows] Chẩn đoán with logLevel: LogLevel.info
    pat = re.compile(r"(AppLogger\.log\((?:(?!AppLogger\.log\().){0,600}?(?:\[Sao lưu\]|\[Windows\] Chẩn đoán)(?:(?!AppLogger\.log\().){0,600}?logLevel: LogLevel\.info)(\s*,?\s*\))", re.S)
    found = pat.findall(s)
    assert len(found) == n, (rel, len(found))
    s2 = pat.sub(lambda m: m.group(1) + ', always: true' + m.group(2), s)
    open(p, 'w', encoding='utf-8', newline='').write(s2)
    print('always:', rel, len(found))
cf=os.path.join(ROOT,'audit-0.5.2/changed_files.txt')
lines=set(open(cf).read().split()); lines.add('overlay/lib/yomihub/win/win_diag.dart'); open(cf,'w').write('\n'.join(sorted(lines))+'\n')
