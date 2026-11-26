import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangayomi/yomihub/library/local_image_uri.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('0.6.7 ảnh cục bộ content:// / file:// không đi mạng', () {
    test('nhận diện URI cục bộ', () {
      expect(isLocalImageUri('content://com.android.externalstorage.documents/document/primary%3Aa.jpg'), isTrue);
      expect(isLocalImageUri('  CONTENT://x/y'), isTrue);
      expect(isLocalImageUri('file:///sdcard/a.png'), isTrue);
      expect(isLocalImageUri('https://cdn.donmai.us/a.jpg'), isFalse);
      expect(isLocalImageUri('//i.hinhgg.com/a.jpg'), isFalse);
      expect(isLocalImageUri('data:image/png;base64,AA=='), isFalse);
    });

    test('file:// đọc bằng dart:io', () async {
      final dir = await Directory.systemTemp.createTemp('yh067');
      final f = File('${dir.path}/c.png')..writeAsBytesSync([1, 2, 3]);
      final b = await readLocalImageUri(f.uri.toString());
      expect(b, [1, 2, 3]);
      await dir.delete(recursive: true);
    });

    test('content:// gọi kênh readUri trên Android', () async {
      const ch = MethodChannel('yh067/test_tools');
      String? asked;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(ch, (call) async {
        asked = call.method;
        return Uint8List.fromList([9, 9]);
      });
      final b = await readLocalImageUri('content://a/b', channel: ch, isAndroid: true);
      expect(asked, 'readUri');
      expect(b, [9, 9]);
    });

    test('content:// mất quyền → StateError tiếng Việt, không phải lỗi mạng', () async {
      const ch = MethodChannel('yh067/test_tools2');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(ch, (call) async {
        throw PlatformException(code: 'YH_TOOLS', message: 'Permission Denial');
      });
      expect(
        () => readLocalImageUri('content://a/b', channel: ch, isAndroid: true),
        throwsA(isA<StateError>().having((e) => e.message, 'msg', contains('mất quyền'))),
      );
    });

    test('content:// ngoài Android báo rõ', () async {
      expect(
        () => readLocalImageUri('content://a/b', isAndroid: false),
        throwsA(isA<StateError>()),
      );
    });
  });
}
