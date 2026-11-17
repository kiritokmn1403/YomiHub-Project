import sys; sys.path.insert(0,'.')
from edit import edit
B='lib/modules/more/data_and_storage/providers/backup.dart'
edit(B,"""  final compressionLevel = compression.clamp(0, 9).toInt();
  try {
    final zipPath = await writeMangayomiBackupZip(
      list: list,
      directory: path,
      compressionLevel: compressionLevel,
    );""","""  final compressionLevel = compression.clamp(0, 9).toInt();
  // 0.5.2: a 23 MB backup takes ~8 s on the Note 9 with the "Tạo" screen
  // unchanged - show that it is working (manual backups only).
  final closeLoading = context != null ? BotToast.showLoading() : null;
  try {
    final String zipPath;
    try {
      zipPath = await writeMangayomiBackupZip(
        list: list,
        directory: path,
        compressionLevel: compressionLevel,
      );
    } finally {
      closeLoading?.call();
    }""")
