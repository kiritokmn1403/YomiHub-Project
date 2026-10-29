import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mangayomi/models/manga.dart';
import 'package:mangayomi/modules/more/data_and_storage/providers/delete_source.dart';
import 'package:mangayomi/yomihub/update/drive_update.dart';

Manga title(String name, [ItemType type = ItemType.manga]) => Manga(
  name: name,
  itemType: type,
  source: 'test',
  author: '',
  artist: '',
  genre: [],
  imageUrl: '',
  lang: 'vi',
  link: '/title',
  status: Status.unknown,
  description: '',
  sourceId: 1,
);

String entry(String id, String name, {bool folder = false}) =>
    '<div id="entry-$id" class="flip-entry extra"><a href="https://drive.google.com/${folder ? 'drive/folders' : 'file/d'}/$id">'
    '<div class="flip-entry-title">$name</div></a></div>';
String listing(String body) => '<div class="flip-entries">$body</div>';

void main() {
  test('duplicate search preserves Unicode titles and media types', () {
    final groups = findDuplicateMangaClusters([
      title('進撃の巨人'),
      title('進撃の巨人'),
      title('鬼滅の刃'),
      title('Tôi là ai?'),
      title('Tôi là ai!'),
      title('Toi la ai'),
      title('Tôi là ai?', ItemType.anime),
      title('Tôi là ai?', ItemType.novel),
      title(''),
      title('---'),
    ]);
    expect(groups, hasLength(2));
    expect(groups.map((g) => g.mangaList.length), everyElement(2));
  });

  test('duplicate search handles a large library', () {
    final items = List.generate(20000, (i) => title('Title ${i ~/ 2}'));
    expect(findDuplicateMangaClusters(items), hasLength(10000));
  });

  test(
    'Drive listing tolerates extra classes and missing modified dates',
    () async {
      final client = MockClient(
        (request) async => http.Response(
          listing(entry('apk', 'YomiHub-0.3.9-arm64-v8a.apk')),
          200,
        ),
      );
      final update = await YomiDriveUpdate.check('0.3.8', client: client);
      expect(update?.$1, '0.3.9');
      expect(
        YomiDriveUpdate.fileName(update!.$4.single as String),
        'YomiHub-0.3.9-arm64-v8a.apk',
      );
    },
  );

  test(
    'Drive selects latest compatible release, ignoring notes-only versions',
    () async {
      final client = MockClient(
        (request) async => http.Response(
          listing(
            entry('notes', 'YomiHub-0.5.0-notes.txt') +
                entry('apk', 'YomiHub-0.4.0-arm64-v8a.apk') +
                entry('win', 'YomiHub-0.3.9-Windows.exe'),
          ),
          200,
        ),
      );
      final update = await YomiDriveUpdate.check(
        '0.3.8',
        client: client,
        acceptsFile: (name) => name.endsWith('.exe'),
      );
      expect(update?.$1, '0.3.9');
      expect(update?.$4, hasLength(1));
    },
  );

  test('Drive folder cycles are visited once', () async {
    var count = 0;
    final client = MockClient((request) async {
      count++;
      return http.Response(
        listing(
          entry(YomiDriveUpdate.rootFolderId, '0.3.9', folder: true) +
              entry('apk', 'YomiHub-0.3.9.apk'),
        ),
        200,
      );
    });
    expect((await YomiDriveUpdate.check('0.3.8', client: client))?.$1, '0.3.9');
    expect(count, 1);
  });

  test('Drive failures are not reported as already up to date', () async {
    final client = MockClient((request) async => http.Response('denied', 403));
    await expectLater(
      YomiDriveUpdate.check('0.3.8', client: client),
      throwsA(isA<http.ClientException>()),
    );
    final login = MockClient(
      (request) async => http.Response('<html>Sign in</html>', 200),
    );
    await expectLater(
      YomiDriveUpdate.check('0.3.8', client: login),
      throwsFormatException,
    );
  });

  test(
    'Drive returns null only for a valid listing without newer releases',
    () async {
      final client = MockClient(
        (request) async =>
            http.Response(listing(entry('apk', 'YomiHub-0.3.8.apk')), 200),
      );
      expect(await YomiDriveUpdate.check('0.3.9', client: client), isNull);
    },
  );
}
