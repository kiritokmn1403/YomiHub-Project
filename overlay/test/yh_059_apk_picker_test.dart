import 'package:flutter_test/flutter_test.dart';
import 'package:mangayomi/yomihub/update/apk_variant_picker.dart';

const base = 'https://github.com/kiritokmn1403/YomiHub-Project/releases/download/v0.5.9';
final assets = [
  '$base/YomiHub-0.5.9-android6-arm64-v8a.apk',
  '$base/YomiHub-0.5.9-android6-armeabi-v7a.apk',
  '$base/YomiHub-0.5.9-android6-x86_64.apk',
  '$base/YomiHub-0.5.9-arm64-v8a.apk',
  '$base/YomiHub-0.5.9-armeabi-v7a.apk',
  '$base/YomiHub-0.5.9-x86_64.apk',
  '$base/YumiHub-Android-TV-0.5.9-arm64-v8a.apk',
  '$base/YumiHub-Android-TV-0.5.9-armeabi-v7a.apk',
  '$base/YomiHub-0.5.9-windows-x64-Setup.exe',
];

String pick(int sdk, List<String> abis, {bool tv = false}) =>
    pickUpdateApk(assetUrls: assets, supportedAbis: abis, sdkInt: sdk, isTv: tv)!
        .split('/').last;

void main() {
  test('Android 16 arm64 phone gets the normal APK, not android6 (log 0.5.8 bug)', () {
    expect(pick(36, ['arm64-v8a', 'armeabi-v7a', 'armeabi']), 'YomiHub-0.5.9-arm64-v8a.apk');
  });
  test('Android 10 Note 9 gets normal arm64', () {
    expect(pick(29, ['arm64-v8a', 'armeabi-v7a']), 'YomiHub-0.5.9-arm64-v8a.apk');
  });
  test('Android 6.0 device gets the android6 APK', () {
    expect(pick(23, ['armeabi-v7a', 'armeabi']), 'YomiHub-0.5.9-android6-armeabi-v7a.apk');
  });
  test('TV gets YumiHub Android TV APK for its ABI', () {
    expect(pick(30, ['armeabi-v7a'], tv: true), 'YumiHub-Android-TV-0.5.9-armeabi-v7a.apk');
  });
  test('x86_64 emulator gets normal x86_64', () {
    expect(pick(34, ['x86_64', 'arm64-v8a']), 'YomiHub-0.5.9-x86_64.apk');
  });
  test('no APK → null', () {
    expect(pickUpdateApk(assetUrls: ['$base/a.exe'], supportedAbis: ['arm64-v8a'], sdkInt: 34, isTv: false), isNull);
  });
}
