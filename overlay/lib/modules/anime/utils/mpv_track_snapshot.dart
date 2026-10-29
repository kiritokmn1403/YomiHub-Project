import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:media_kit/generated/libmpv/bindings.dart' as mpv;

/// Copies event-owned values before mpv reuses the event memory. Never queries
/// the mpv core synchronously from the Flutter isolate.
class MpvTrackSnapshot {
  static const properties = {
    'aid',
    'sid',
    'current-tracks/audio/id',
    'current-tracks/sub/id',
    'alang',
  };
  final _values = <String, String>{};

  String? operator [](String name) => _values[name];

  void clearTracks() => _values.removeWhere((key, _) => key != 'alang');

  bool accept(Pointer<mpv.mpv_event_property> property) {
    final name = property.ref.name.cast<Utf8>().toDartString();
    if (!properties.contains(name)) return false;
    String? value;
    if (property.ref.format == mpv.mpv_format.MPV_FORMAT_NODE &&
        property.ref.data != nullptr) {
      final node = property.ref.data.cast<mpv.mpv_node>().ref;
      if (node.format == mpv.mpv_format.MPV_FORMAT_STRING &&
          node.u.string != nullptr) {
        value = node.u.string.cast<Utf8>().toDartString().trim();
      } else if (node.format == mpv.mpv_format.MPV_FORMAT_INT64) {
        value = node.u.int64.toString();
      } else if (name == 'alang' &&
          node.format == mpv.mpv_format.MPV_FORMAT_NODE_ARRAY &&
          node.u.list != nullptr) {
        final list = node.u.list.ref;
        final languages = <String>[];
        for (var i = 0; i < list.num; i++) {
          final item = list.values[i];
          if (item.format == mpv.mpv_format.MPV_FORMAT_STRING &&
              item.u.string != nullptr) {
            final language = item.u.string.cast<Utf8>().toDartString().trim();
            if (language.isNotEmpty) languages.add(language);
          }
        }
        value = languages.join(',');
      }
    }
    if (value == null || value.isEmpty) {
      _values.remove(name);
    } else {
      _values[name] = value;
    }
    return true;
  }
}
