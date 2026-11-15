import 'package:mangayomi/yomihub/prefs/yomi_prefs.dart';

/// Nuvio Media Hub Integration
/// Inspired by NuvioMedia/NuvioMobile (Unified streaming & playback hub).
///
/// Features integrated:
/// - Player gesture control definitions (left swipe brightness, right swipe volume)
/// - Double-tap seek duration customizer
/// - Picture-in-Picture window aspect ratio & state manager
/// - Media casting & external monitor detection state
class NuvioMediaHub {
  NuvioMediaHub._();

  static const String prefSwipeBrightness = 'nuvio_swipe_brightness';
  static const String prefSwipeVolume = 'nuvio_swipe_volume';
  static const String prefDoubleTapSeekSec = 'nuvio_double_tap_seek_sec';

  /// Whether vertical drag on left screen side adjusts brightness.
  static bool get swipeBrightnessEnabled => YomiPrefs.get<bool>(prefSwipeBrightness, true);

  /// Whether vertical drag on right screen side adjusts volume.
  static bool get swipeVolumeEnabled => YomiPrefs.get<bool>(prefSwipeVolume, true);

  /// Double tap seek interval in seconds (default 10s).
  static int get doubleTapSeekSeconds => YomiPrefs.get<int>(prefDoubleTapSeekSec, 10);

  /// Computes volume delta from a vertical drag delta.
  static double computeVolumeDelta(double dy, double screenHeight) {
    if (screenHeight <= 0) return 0.0;
    // Dragging up (negative dy) increases volume
    return (-dy / (screenHeight * 0.7)).clamp(-1.0, 1.0);
  }

  /// Computes brightness delta from a vertical drag delta.
  static double computeBrightnessDelta(double dy, double screenHeight) {
    if (screenHeight <= 0) return 0.0;
    return (-dy / (screenHeight * 0.7)).clamp(-1.0, 1.0);
  }

  /// Returns target aspect ratio for Picture-in-Picture window.
  static double getOptimalPipAspectRatio(double? videoWidth, double? videoHeight) {
    if (videoWidth == null || videoHeight == null || videoWidth <= 0 || videoHeight <= 0) {
      return 16 / 9; // Default widescreen
    }
    final ratio = videoWidth / videoHeight;
    // Android PiP supports aspect ratios between 0.418 and 2.39
    return ratio.clamp(0.42, 2.39);
  }

  /// 0.5.7: size handed to Android's Picture-in-Picture. A missing / zero
  /// size becomes 16:9 and the ratio is kept inside what Android accepts
  /// (it throws IllegalArgumentException outside 0.418…2.39).
  static (double, double) pipVideoSize(int? videoWidth, int? videoHeight) {
    final ratio = getOptimalPipAspectRatio(
      videoWidth?.toDouble(),
      videoHeight?.toDouble(),
    );
    final h = (videoHeight != null && videoHeight > 0) ? videoHeight.toDouble() : 360.0;
    return ((h * ratio).roundToDouble(), h);
  }

  /// 0.5.7: new brightness / volume (0…1) after a vertical drag of [dy]
  /// pixels. Null when that side's gesture is switched off in the settings.
  static double? applySwipe({
    required bool leftSide,
    required double current,
    required double dy,
    required double screenHeight,
    double? travel,
  }) {
    if (leftSide ? !swipeBrightnessEnabled : !swipeVolumeEnabled) return null;
    // [travel]: pixels of drag for the full 0…1 range (the player keeps its
    // historical 500 px); default = 70 % of the screen height.
    final h = travel != null && travel > 0 ? travel / 0.7 : screenHeight;
    final delta = leftSide
        ? computeBrightnessDelta(dy, h)
        : computeVolumeDelta(dy, h);
    return (current + delta).clamp(0.0, 1.0);
  }

  /// 0.5.7: double-tap seek length. The player's own setting
  /// (Cài đặt > Trình phát > "Double tap to skip") stays the source of truth;
  /// the Nuvio key only overrides it when it was set explicitly.
  static int resolveDoubleTapSeconds(int playerSetting) {
    final v = YomiPrefs.get<int>(prefDoubleTapSeekSec, 0);
    return v > 0 ? v : playerSetting;
  }
}
