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
}
