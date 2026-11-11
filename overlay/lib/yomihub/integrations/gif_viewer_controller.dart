import 'package:flutter/foundation.dart';
import 'package:mangayomi/yomihub/prefs/yomi_prefs.dart';

/// GIF Viewer & Controller Integration
/// Inspired by ata4/gifiddle and valentinpi/gif-viewer.
///
/// Features integrated:
/// - Play, pause, step forward/backward frame control
/// - Variable playback speed (0.25x to 4.0x)
/// - Reverse playback mode
/// - Infinite loop or single-shot playback
class GifViewerController extends ChangeNotifier {
  static const String prefDefaultSpeed = 'gif_viewer_default_speed';
  static const String prefAutoLoop = 'gif_viewer_auto_loop';

  bool _isPlaying = true;
  bool _isReverse = false;
  bool _isLooping = true;
  double _playbackSpeed = 1.0;
  int _currentFrame = 0;
  int _totalFrames = 1;

  GifViewerController({
    int totalFrames = 1,
    bool autoPlay = true,
  })  : _totalFrames = totalFrames > 0 ? totalFrames : 1,
        _isPlaying = autoPlay {
    _playbackSpeed = YomiPrefs.get<double>(prefDefaultSpeed, 1.0);
    _isLooping = YomiPrefs.get<bool>(prefAutoLoop, true);
  }

  bool get isPlaying => _isPlaying;
  bool get isReverse => _isReverse;
  bool get isLooping => _isLooping;
  double get playbackSpeed => _playbackSpeed;
  int get currentFrame => _currentFrame;
  int get totalFrames => _totalFrames;

  void setTotalFrames(int frames) {
    if (frames > 0 && frames != _totalFrames) {
      _totalFrames = frames;
      if (_currentFrame >= _totalFrames) {
        _currentFrame = _totalFrames - 1;
      }
      notifyListeners();
    }
  }

  void play() {
    if (!_isPlaying) {
      _isPlaying = true;
      notifyListeners();
    }
  }

  void pause() {
    if (_isPlaying) {
      _isPlaying = false;
      notifyListeners();
    }
  }

  void togglePlayPause() {
    _isPlaying = !_isPlaying;
    notifyListeners();
  }

  void setReverse(bool reverse) {
    if (_isReverse != reverse) {
      _isReverse = reverse;
      notifyListeners();
    }
  }

  void toggleReverse() {
    _isReverse = !_isReverse;
    notifyListeners();
  }

  void setLooping(bool loop) {
    if (_isLooping != loop) {
      _isLooping = loop;
      YomiPrefs.set(prefAutoLoop, loop);
      notifyListeners();
    }
  }

  void setSpeed(double speed) {
    if (speed > 0 && (_playbackSpeed - speed).abs() > 0.01) {
      _playbackSpeed = speed;
      YomiPrefs.set(prefDefaultSpeed, speed);
      notifyListeners();
    }
  }

  /// Advances to next frame (taking direction into account).
  void advanceFrame() {
    if (_isReverse) {
      stepBackward();
    } else {
      stepForward();
    }
  }

  void stepForward() {
    if (_currentFrame < _totalFrames - 1) {
      _currentFrame++;
      notifyListeners();
    } else if (_isLooping) {
      _currentFrame = 0;
      notifyListeners();
    } else {
      _isPlaying = false;
      notifyListeners();
    }
  }

  void stepBackward() {
    if (_currentFrame > 0) {
      _currentFrame--;
      notifyListeners();
    } else if (_isLooping) {
      _currentFrame = _totalFrames - 1;
      notifyListeners();
    } else {
      _isPlaying = false;
      notifyListeners();
    }
  }

  void seekToFrame(int frame) {
    final clamped = frame.clamp(0, _totalFrames - 1);
    if (clamped != _currentFrame) {
      _currentFrame = clamped;
      notifyListeners();
    }
  }
}

