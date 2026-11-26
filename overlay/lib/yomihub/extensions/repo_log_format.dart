import 'dart:async';
import 'dart:io';

/// 0.6.7 (Issue #2): pure-Dart helpers for formatting extension error headers,
/// sanitizing repository URLs in logs, and classifying repository refresh errors.

/// Removes credentials (`user:pass@`), query (`?...`), and fragment (`#...`)
/// from [raw], keeping `scheme`, `host`, non-default `port`, and `path`.
String sanitizeRepoUrl(String? raw) {
  if (raw == null) return '';
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return '';

  final uri = Uri.tryParse(trimmed);
  if (uri != null && uri.scheme.isNotEmpty && uri.host.isNotEmpty) {
    final scheme = uri.scheme.toLowerCase();
    int? port;
    if (uri.hasPort) {
      final p = uri.port;
      final isDefault =
          (scheme == 'http' && p == 80) || (scheme == 'https' && p == 443);
      if (!isDefault) port = p;
    }
    return Uri(
      scheme: uri.scheme,
      host: uri.host,
      port: port,
      path: uri.path,
    ).toString();
  }

  return trimmed
      .replaceFirst(RegExp(r'[?#].*', dotAll: true), '')
      .replaceAll(RegExp(r'//[^/@]+@'), '//');
}

/// Formats the `where` prefix for extension error log lines, including source
/// `id`, `version`, and a sanitized repository URL (or `Built-in/Local`).
String formatExtensionLogHeader({
  String? name,
  int? id,
  String? version,
  String? lang,
  String? engine,
  String? repoName,
  String? repoUrl,
  String? serviceType,
  String? target,
}) {
  final cleanUrl = sanitizeRepoUrl(repoUrl);
  final trimmedRepoName = repoName?.trim() ?? '';
  final hasRepo = trimmedRepoName.isNotEmpty || cleanUrl.isNotEmpty;
  final repoInfo = hasRepo
      ? '${trimmedRepoName.isNotEmpty ? trimmedRepoName : 'repo'}${cleanUrl.isNotEmpty ? ' <$cleanUrl>' : ''}'
      : 'Built-in/Local';

  final ver = version?.trim() ?? '';
  final meta = <String>[
    if (id != null) 'id: $id',
    if (ver.isNotEmpty) ver.startsWith('v') ? ver : 'v$ver',
    (lang != null && lang.trim().isNotEmpty) ? lang.trim() : 'unknown',
    'engine: ${(engine != null && engine.trim().isNotEmpty) ? engine.trim() : 'unknown'}',
    'repo: $repoInfo',
  ];

  final header = 'Extension "${name ?? 'unknown'}" (${meta.join(', ')})';
  final tail = <String>[
    if (serviceType != null && serviceType.trim().isNotEmpty) serviceType.trim(),
    if (target != null && target.trim().isNotEmpty) target.trim(),
  ].join(' ');
  return tail.isEmpty ? header : '$header $tail';
}

enum RepoFailureKind { dns, timeout, http, format, network, other }

class RepoRefreshFailure {
  final String repoLabel;
  final String repoUrl;
  final RepoFailureKind kind;
  final int? httpStatus;
  final String shortReason;

  const RepoRefreshFailure({
    required this.repoLabel,
    required this.repoUrl,
    required this.kind,
    this.httpStatus,
    required this.shortReason,
  });
}

final RegExp _dnsPattern = RegExp(
  r'(failed host lookup|unable to resolve host|no address associated|unknownhost|no such host|nodename nor servname)',
  caseSensitive: false,
);

final RegExp _timeoutPattern = RegExp(
  r'(timeoutexception|timed out|\btimeout\b|hết thời gian|het thoi gian)',
  caseSensitive: false,
);

final RegExp _httpStatusPattern = RegExp(
  r'(?:http(?:\s+error)?(?:\s+status)?(?:\s*[:=]\s*|\s+)|status(?:\s*code)?(?:\s*[:=]\s*|\s+))([1-5]\d{2})\b',
  caseSensitive: false,
);

final RegExp _bareHttpCodePattern = RegExp(r'\b([1-5]\d{2})\b');

final RegExp _formatPattern = RegExp(
  r'(formatexception|invalid repository index|\bjson\b|chỉ mục|chi muc|không đọc được|khong doc duoc)',
  caseSensitive: false,
);

final RegExp _networkPattern = RegExp(
  r'(socketexception|handshakeexception|clientexception|connection|tlsexception|certificateexception)',
  caseSensitive: false,
);

/// Classifies a repository refresh exception into a structured kind, optional
/// HTTP status code, and short human-readable reason.
({RepoFailureKind kind, int? httpStatus, String shortReason}) classifyRepoError(
  Object error,
) {
  final msg = error.toString();

  if (_dnsPattern.hasMatch(msg)) {
    return (kind: RepoFailureKind.dns, httpStatus: null, shortReason: 'DNS');
  }

  if (error is TimeoutException || _timeoutPattern.hasMatch(msg)) {
    return (
      kind: RepoFailureKind.timeout,
      httpStatus: null,
      shortReason: 'hết thời gian',
    );
  }

  final httpMatch = _httpStatusPattern.firstMatch(msg) ??
      (error is HttpException ? _bareHttpCodePattern.firstMatch(msg) : null);
  if (httpMatch != null) {
    final code = int.tryParse(httpMatch.group(1)!);
    if (code != null) {
      return (
        kind: RepoFailureKind.http,
        httpStatus: code,
        shortReason: 'HTTP $code',
      );
    }
  }

  if (error is FormatException || _formatPattern.hasMatch(msg)) {
    return (
      kind: RepoFailureKind.format,
      httpStatus: null,
      shortReason: 'định dạng sai',
    );
  }

  if (error is SocketException ||
      error is HandshakeException ||
      _networkPattern.hasMatch(msg)) {
    return (
      kind: RepoFailureKind.network,
      httpStatus: null,
      shortReason: 'lỗi mạng',
    );
  }

  return (
    kind: RepoFailureKind.other,
    httpStatus: null,
    shortReason: error.runtimeType.toString(),
  );
}

/// Returns lowercased hosts that appear in at least 2 entries of [urls].
Set<String> findDuplicateRepoHosts(Iterable<String?> urls) {
  final counts = <String, int>{};
  for (final raw in urls) {
    final clean = sanitizeRepoUrl(raw);
    if (clean.isEmpty) continue;
    final host = Uri.tryParse(clean)?.host.toLowerCase() ?? '';
    if (host.isEmpty) continue;
    counts[host] = (counts[host] ?? 0) + 1;
  }
  return {
    for (final entry in counts.entries)
      if (entry.value >= 2) entry.key,
  };
}

/// Builds a display label for a repository, keeping repositories on the same
/// host distinct via sanitized `host/path` (or `owner/repo`) when needed.
String repoDisplayLabel(
  String? repoName,
  String? repoUrl, {
  Set<String>? duplicateHosts,
}) {
  final cleanUrl = sanitizeRepoUrl(repoUrl);
  final uri = cleanUrl.isNotEmpty ? Uri.tryParse(cleanUrl) : null;
  final host = uri?.host.toLowerCase() ?? '';
  final name = repoName?.trim() ?? '';
  final isDuplicateHost = host.isNotEmpty &&
      (duplicateHosts?.any((h) => h.toLowerCase() == host) ?? false);

  if (isDuplicateHost && uri != null) {
    final portSuffix = uri.hasPort ? ':${uri.port}' : '';
    final path = uri.path;
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    final distinguishing = (path.isNotEmpty && path != '/')
        ? '${uri.host}$portSuffix$path'
        : (segments.length >= 2
            ? '${uri.host}$portSuffix/${segments[0]}/${segments[1]}'
            : '${uri.host}$portSuffix');
    if (name.isNotEmpty) {
      return '$name ($distinguishing)';
    }
    return distinguishing;
  }

  if (name.isNotEmpty && host.isNotEmpty) {
    return name.toLowerCase() == host ? name : '$name ($host)';
  }
  if (name.isNotEmpty) return name;
  if (host.isNotEmpty) return uri!.host;
  if (cleanUrl.isNotEmpty) return cleanUrl;
  return 'unknown';
}
