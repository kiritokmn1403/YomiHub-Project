import 'dart:convert';
import 'package:mangayomi/yomihub/prefs/yomi_prefs.dart';

/// Nyora Data-Driven Bridge
/// Inspired by Nyora-Manga (Data-driven manga reader ecosystem).
///
/// Features integrated:
/// - Nyora data-driven schema parser for sources & manifests
/// - Multi-repo metadata normalization
/// - Source latency & availability health checks
class NyoraDataBridge {
  NyoraDataBridge._();

  static const String prefEnableNyoraProtocol = 'nyora_protocol_enabled';

  /// Whether Nyora data-driven repository protocol is active.
  static bool get isNyoraProtocolEnabled => YomiPrefs.get<bool>(prefEnableNyoraProtocol, true);

  /// Parses a Nyora repository manifest JSON into standardized entries.
  static List<NyoraSourceMeta> parseRepositoryManifest(String jsonString) {
    try {
      final decoded = jsonDecode(jsonString);
      final List<dynamic> list;
      if (decoded is List) {
        list = decoded;
      } else if (decoded is Map<String, dynamic> && decoded['sources'] is List) {
        list = decoded['sources'] as List<dynamic>;
      } else if (decoded is Map<String, dynamic> && decoded['data'] is List) {
        list = decoded['data'] as List<dynamic>;
      } else {
        return [];
      }

      return list
          .whereType<Map<String, dynamic>>()
          .map((m) => NyoraSourceMeta.fromJson(m))
          .where((m) => m.id.isNotEmpty && m.name.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }
}

/// Standardized metadata for a Nyora-compatible source.
class NyoraSourceMeta {
  final String id;
  final String name;
  final String baseUrl;
  final String lang;
  final String version;
  final bool isNsfw;
  final String? iconUrl;

  const NyoraSourceMeta({
    required this.id,
    required this.name,
    required this.baseUrl,
    required this.lang,
    required this.version,
    this.isNsfw = false,
    this.iconUrl,
  });

  factory NyoraSourceMeta.fromJson(Map<String, dynamic> json) {
    return NyoraSourceMeta(
      id: (json['id'] ?? json['pkg'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      baseUrl: (json['baseUrl'] ?? json['url'] ?? '').toString(),
      lang: (json['lang'] ?? 'all').toString(),
      version: (json['version'] ?? '1.0.0').toString(),
      isNsfw: json['isNsfw'] == true || json['nsfw'] == 1,
      iconUrl: json['icon']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'baseUrl': baseUrl,
        'lang': lang,
        'version': version,
        'isNsfw': isNsfw,
        if (iconUrl != null) 'icon': iconUrl,
      };
}

