import 'package:mangayomi/eval/interface.dart';
import 'package:mangayomi/models/source.dart';

import 'dart/service.dart';
import 'javascript/service.dart';
import 'mihon/service.dart';
import 'lnreader/service.dart';
import 'aidoku/service.dart';

ExtensionService getExtensionService(Source source, String androidProxyServer) {
  return switch (source.sourceCodeLanguage) {
    SourceCodeLanguage.dart => DartExtensionService(source),
    SourceCodeLanguage.javascript => JsExtensionService(source),
    SourceCodeLanguage.mihon => MihonExtensionService(
      source,
      androidProxyServer,
    ),
    SourceCodeLanguage.lnreader => LNReaderExtensionService(source),
    SourceCodeLanguage.aidoku => AidokuExtensionService(source),
  };
}

/// Creating an extension service evaluates the entire extension source, which
/// is far too slow for UI-thread paths (headers, filters, preferences, ...).
/// This keeps a small pool of live services keyed by source version so those
/// paths pay the spin-up cost once. Returned instances are shared — callers
/// must NOT dispose them; evicted instances are disposed here.
const _cachedServiceLimit = 6;
final _serviceCache = <String, ExtensionService>{};

ExtensionService getCachedExtensionService(
  Source source,
  String androidProxyServer,
) {
  final key =
      '${source.id}|${source.version}|${source.sourceCode?.hashCode}|$androidProxyServer';
  final cached = _serviceCache.remove(key);
  if (cached != null) {
    _serviceCache[key] = cached; // re-insert as most recently used
    return cached;
  }
  final service = getExtensionService(source, androidProxyServer);
  _serviceCache[key] = service;
  if (_serviceCache.length > _cachedServiceLimit) {
    _serviceCache.remove(_serviceCache.keys.first)?.dispose();
  }
  return service;
}

/// YomiHub 0.2.1: drop cached services of [sourceId] (after its stored
/// filter list / code changed).
void invalidateExtensionService(int? sourceId) {
  if (sourceId == null) return;
  final keys = _serviceCache.keys.where((k) => k.startsWith('$sourceId|')).toList();
  for (final k in keys) {
    try {
      _serviceCache.remove(k)?.dispose();
    } catch (_) {}
  }
}

Future<T> withExtensionService<T>(
  Source source,
  String proxyServer,
  Future<T> Function(ExtensionService service) action,
) async {
  final service = getExtensionService(source, proxyServer);
  try {
    return await action(service);
  } finally {
    service.dispose();
  }
}


/// YomiHub 0.2.3: drops every cached extension service (each JS / QuickJS
/// runtime holds several MB) – used when the system reports low memory.
int clearExtensionServiceCache() {
  final n = _serviceCache.length;
  for (final s in _serviceCache.values.toList()) {
    try {
      s.dispose();
    } catch (_) {}
  }
  _serviceCache.clear();
  return n;
}
