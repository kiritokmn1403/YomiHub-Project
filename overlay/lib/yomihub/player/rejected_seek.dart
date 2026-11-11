/// Only return known backend diagnostics. Arbitrary surrounding text can
/// contain a signed media URL, request headers or a local file name.
String? rejectedSeekReason(String message) {
  final lower = message.toLowerCase();
  if (lower.contains('cannot seek in this stream')) {
    return 'Cannot seek in this stream';
  }
  if (lower.contains('cannot seek')) return 'Cannot seek';
  if (lower.contains('force-seekable')) return 'force-seekable';
  return null;
}
