/// Replace an extension's stale clearance after the WebView solves a challenge.
/// Preserve unrelated cookies supplied by the extension.
String mergeClearanceCookie(String own, String stored) {
  if (own.trim().isEmpty) return stored;
  final saved = stored.split(';').map((part) => part.trim());
  for (final part in saved) {
    if (part.startsWith('cf_clearance=') && part.length > 'cf_clearance='.length) {
      return [
        ...own.split(';').map((c) => c.trim()).where(
          (c) => c.isNotEmpty && !c.startsWith('cf_clearance='),
        ),
        part,
      ].join('; ');
    }
  }
  return own;
}
