
    // 0.5.1: "Decode & Extract" (kiritokmn1403) ported to Dart
    test('AxmlDecoder reads manifest, attributes and UTF-8 strings longer than 127 bytes', () {
      final doc = AxmlDecoder.decode(base64Decode('AwAIALgDAAABABwABAIAABEAAAAAAAAAAAEAAGAAAAAAAAAAAAAAAAoAAAA3AAAAQgAAAEwAAABaAAAAZgAAAG0AAAB1AAAAkQAAAJ0AAADKAAAA0wAAAO4AAADyAAAAAAEAAAgBAAAHB2FuZHJvaWQAKipodHRwOi8vc2NoZW1hcy5hbmRyb2lkLmNvbS9hcGsvcmVzL2FuZHJvaWQACAhtYW5pZmVzdAAHB3BhY2thZ2UACwt2ZXJzaW9uTmFtZQAJCW1ldGEtZGF0YQAEBG5hbWUABQV2YWx1ZQAZGXRhY2hpeW9taS5leHRlbnNpb24uY2xhc3MACQkuTWFuZ2FEZXgAKipldS5rYW5hZGUudGFjaGl5b21pLmV4dGVuc2lvbi5hbGwubWFuZ2FkZXgABgYxLjQuMTIAGBh0YWNoaXlvbWkuZXh0ZW5zaW9uLm5zZncAAQExAAsLYXBwbGljYXRpb24ABQVsYWJlbACAl4CXTG9vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vb29vbwAAARAAGAAAAAEAAAD/////AAAAAAEAAAACARAATAAAAAEAAAD//////////wIAAAAUABQAAgAAAAAAAAD/////AwAAAAoAAAAIAAADCgAAAAEAAAAEAAAACwAAAAgAAAMLAAAAAgEQADgAAAABAAAA//////////8OAAAAFAAUAAEAAAAAAAAAAQAAAA8AAAAQAAAACAAAAxAAAAACARAATAAAAAEAAAD//////////wUAAAAUABQAAgAAAAAAAAABAAAABgAAAAgAAAAIAAADCAAAAAEAAAAHAAAACQAAAAgAAAMJAAAAAwEQABgAAAABAAAA//////////8FAAAAAgEQAEwAAAABAAAA//////////8FAAAAFAAUAAIAAAAAAAAAAQAAAAYAAAAMAAAACAAAAwwAAAABAAAABwAAAA0AAAAIAAADDQAAAAMBEAAYAAAAAQAAAP//////////BQAAAAMBEAAYAAAAAQAAAP//////////DgAAAAMBEAAYAAAAAQAAAP//////////AgAAAAEBEAAYAAAAAQAAAP////8AAAAAAQAAAA=='));
      final root = doc.root!;
      expect(root.name, 'manifest');
      expect(root.attr('package'), 'eu.kanade.tachiyomi.extension.all.mangadex');
      expect(root.attr('versionName'), '1.4.12');
      final app = root.descendants('application').first;
      expect(app.attr('label')!.length, 151); // the JS script cut this to 128
      final md = {for (final m in root.descendants('meta-data')) m.attr('name'): m.attr('value')};
      expect(md['tachiyomi.extension.class'], '.MangaDex');
      expect(doc.xml, contains('xmlns:android="http://schemas.android.com/apk/res/android"'));
    });

    test('ApkInspector + DexReader on a real APK (YomiHub itself, when built)', () {
      final f = [
        'build/app/outputs/flutter-apk/app-arm64-v8a-release.apk',
        'build/app/outputs/flutter-apk/app-x86_64-release.apk',
      ].map(File.new).where((f) => f.existsSync()).firstOrNull;
      if (f == null) return; // not built in this checkout
      final info = ApkInspector.inspect(f.readAsBytesSync());
      expect(info.package, 'com.yomihub.app');
      expect(info.versionName, startsWith('0.'));
      expect(info.dexFiles, greaterThan(0));
      expect(info.classCount, greaterThan(100));
      expect(info.permissions, contains('android.permission.INTERNET'));
    });

    test('DexReader rejects non-DEX data', () {
      expect(() => DexReader.read(Uint8List.fromList(List.filled(200, 0))), throwsFormatException);
    });
