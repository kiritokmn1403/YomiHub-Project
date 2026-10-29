import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangayomi/modules/anime/utils/mpv_track_snapshot.dart';
import 'package:media_kit/generated/libmpv/bindings.dart' as mpv;

void main() {
  late MpvTrackSnapshot snapshot;
  setUp(() => snapshot = MpvTrackSnapshot());

  bool emit(String name, Object? value) {
    final property = calloc<mpv.mpv_event_property>();
    final node = calloc<mpv.mpv_node>();
    final nativeName = name.toNativeUtf8();
    Pointer<Utf8>? nativeValue;
    try {
      property.ref.name = nativeName.cast();
      property.ref.format = value == null
          ? mpv.mpv_format.MPV_FORMAT_NONE
          : mpv.mpv_format.MPV_FORMAT_NODE;
      property.ref.data = value == null ? nullptr : node.cast();
      if (value is String) {
        nativeValue = value.toNativeUtf8();
        node.ref.format = mpv.mpv_format.MPV_FORMAT_STRING;
        node.ref.u.string = nativeValue.cast();
      } else if (value is int) {
        node.ref.format = mpv.mpv_format.MPV_FORMAT_INT64;
        node.ref.u.int64 = value;
      }
      return snapshot.accept(property);
    } finally {
      if (nativeValue != null) calloc.free(nativeValue);
      calloc.free(nativeName);
      calloc.free(node);
      calloc.free(property);
    }
  }

  test('copies string and numeric track IDs beyond event lifetime', () {
    expect(emit('aid', 'auto'), isTrue);
    emit('current-tracks/audio/id', 2);
    emit('sid', 'no');
    expect(snapshot['aid'], 'auto');
    expect(snapshot['current-tracks/audio/id'], '2');
    expect(snapshot['sid'], 'no');
  });
  test('unavailable and empty values remove stale state', () {
    emit('sid', 3);
    emit('sid', null);
    expect(snapshot['sid'], isNull);
    emit('aid', 2);
    emit('aid', '  ');
    expect(snapshot['aid'], isNull);
  });
  test(
    'opening another media clears IDs but preserves language preference',
    () {
      emit('alang', ' vi,en ');
      emit('aid', 2);
      emit('current-tracks/sub/id', 4);
      snapshot.clearTracks();
      expect(snapshot['alang'], 'vi,en');
      expect(snapshot['aid'], isNull);
      expect(snapshot['current-tracks/sub/id'], isNull);
    },
  );
  test('unrelated properties are left to the regular event handler', () {
    expect(emit('user-data/aniyomi/pause', 'yes'), isFalse);
    expect(snapshot['user-data/aniyomi/pause'], isNull);
  });

  test('copies native language lists in preference order', () {
    final property = calloc<mpv.mpv_event_property>();
    final node = calloc<mpv.mpv_node>();
    final list = calloc<mpv.mpv_node_list>();
    final values = calloc<mpv.mpv_node>(2);
    final name = 'alang'.toNativeUtf8();
    final vi = 'vi'.toNativeUtf8();
    final en = 'en'.toNativeUtf8();
    try {
      values[0].format = mpv.mpv_format.MPV_FORMAT_STRING;
      values[0].u.string = vi.cast();
      values[1].format = mpv.mpv_format.MPV_FORMAT_STRING;
      values[1].u.string = en.cast();
      list.ref.num = 2;
      list.ref.values = values;
      node.ref.format = mpv.mpv_format.MPV_FORMAT_NODE_ARRAY;
      node.ref.u.list = list;
      property.ref.name = name.cast();
      property.ref.format = mpv.mpv_format.MPV_FORMAT_NODE;
      property.ref.data = node.cast();
      expect(snapshot.accept(property), isTrue);
    } finally {
      for (final pointer in [name, vi, en]) {
        calloc.free(pointer);
      }
      calloc.free(values);
      calloc.free(list);
      calloc.free(node);
      calloc.free(property);
    }
    expect(snapshot['alang'], 'vi,en');
  });
}
