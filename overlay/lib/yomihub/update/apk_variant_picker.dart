// 0.5.9: picks the right APK from a release's assets for this device.
//
// Bug fixed (log 17–18/11/2026, Xiaomi Android 16): the old picker only matched
// the CPU ABI, so `YomiHub-0.5.8-android6-arm64-v8a.apk` (listed first) was
// installed on an Android 16 phone. Its older extension runtime then failed
// every new Keiyoushi extension with `typeParametersSerializers()`.
//
// Rules, in order:
//  1. TV devices take `android-tv` APKs; phones never take them.
//  2. sdkInt >= 24 (Android 7.0+) takes the normal APK; the `android6` APK only
//     if nothing else exists. sdkInt < 24 takes the `android6` APK first.
//  3. Within the chosen group, the first device ABI that matches wins
//     (supportedAbis is ordered by preference). Fallback: first in the group.
import 'package:mangayomi/yomihub/update/drive_update.dart';

bool _isTvApk(String name) => name.contains('android-tv');
bool _isA6Apk(String name) => name.contains('android6');

String? pickUpdateApk({
  required List<String> assetUrls,
  required List<String> supportedAbis,
  required int sdkInt,
  required bool isTv,
}) {
  final apks = <String, String>{
    for (final u in assetUrls)
      if (YomiDriveUpdate.fileName(u).toLowerCase().endsWith('.apk'))
        u: YomiDriveUpdate.fileName(u).toLowerCase(),
  };
  if (apks.isEmpty) return null;

  List<String> where(bool Function(String n) test) =>
      [for (final e in apks.entries) if (test(e.value)) e.key];

  final byKind = isTv
      ? where(_isTvApk)
      : where((n) => !_isTvApk(n));
  final pool = byKind.isNotEmpty ? byKind : apks.keys.toList();

  final wantA6 = sdkInt < 24;
  final preferred = [for (final u in pool) if (_isA6Apk(apks[u]!) == wantA6) u];
  final group = preferred.isNotEmpty ? preferred : pool;

  for (final abi in supportedAbis) {
    final a = abi.toLowerCase();
    for (final u in group) {
      if (apks[u]!.contains(a)) return u;
    }
  }
  return group.first;
}
