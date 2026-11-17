import sys; sys.path.insert(0,'.')
from edit import edit
edit('lib/modules/more/data_and_storage/providers/backup_decoder.dart',"""      final pw = passwordToTry;
      final backup = await Isolate.run(() => _decodeBackupFile(path, pw));
""","""      final pw = passwordToTry;
      final sw = Stopwatch()..start();
      final backup = await Isolate.run(() => _decodeBackupFile(path, pw));
      AppLogger.log(
        '[Sao lưu] Đã giải nén + đọc JSON ${path.split(RegExp(r'[\\\\/]')).last} ở luồng nền trong ${(sw.elapsedMilliseconds / 1000).toStringAsFixed(1)} s',
        logLevel: LogLevel.info, always: true,
      );
""")
