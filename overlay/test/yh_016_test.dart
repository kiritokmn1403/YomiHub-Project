import 'package:flutter_test/flutter_test.dart';
import 'package:mangayomi/yomihub/repos/repo_discovery.dart';
import 'package:mangayomi/yomihub/update/drive_update.dart';

void main() {
  test('Drive update folder', () async {
    final r = await YomiDriveUpdate.check('0.0.1');
    // ignore: avoid_print
    print('DRIVE from 0.0.1 => ${r == null ? 'none (no files yet)' : '${r.$1} ${r.$4.length} files ${r.$3}'}');
    final r2 = await YomiDriveUpdate.check('0.1.6');
    // ignore: avoid_print
    print('DRIVE from 0.1.6 => ${r2?.$1 ?? 'up to date'}');
  }, timeout: const Timeout(Duration(minutes: 3)));

  test('wotaku + miyomi discovery', () async {
    final n = await YomiRepoDiscovery.scan();
    // ignore: avoid_print
    print('DISCOVERED $n');
    for (final r in YomiRepoDiscovery.items) {
      // ignore: avoid_print
      print('  ${r.name} | ${r.note} | ${r.url}');
    }
    expect(n, greaterThan(0));
  }, timeout: const Timeout(Duration(minutes: 5)));
}
