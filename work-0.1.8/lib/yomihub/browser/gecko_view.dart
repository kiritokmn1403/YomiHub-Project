import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

/// Controls one Gecko (Firefox engine) tab.
class GeckoController {
  final MethodChannel _ch;
  GeckoController(this._ch);
  Future<void> load(String url) => _ch.invokeMethod('load', url);
  Future<void> back() => _ch.invokeMethod('back');
  Future<void> forward() => _ch.invokeMethod('forward');
  Future<void> reload() => _ch.invokeMethod('reload');
  Future<void> stop() => _ch.invokeMethod('stop');
  Future<void> clearHistory() => _ch.invokeMethod('clearHistory');
  Future<void> desktop(bool on) => _ch.invokeMethod('desktop', on);

  static const _global = MethodChannel('yomihub/gecko');
  static bool? _supported;

  /// GeckoView needs Android 8.0+ (and is Android-only).
  static Future<bool> supported() async {
    if (!Platform.isAndroid) return false;
    if (_supported != null) return _supported!;
    try {
      _supported = await _global.invokeMethod<bool>('supported') ?? false;
    } catch (_) {
      _supported = false;
    }
    return _supported!;
  }
}

/// YomiHub 0.1.4: a browser tab rendered by GeckoView (Firefox engine).
class GeckoBrowserView extends StatefulWidget {
  final String url;
  final bool desktop;
  final bool adblock;
  final void Function(GeckoController c)? onCreated;
  final void Function(String url)? onUrl;
  final void Function(String title)? onTitle;
  final void Function(int progress)? onProgress;
  final void Function(bool canBack)? onCanBack;
  final void Function(bool canForward)? onCanForward;
  final void Function(String url)? onNewWindow;
  final void Function()? onPageStop;

  const GeckoBrowserView({
    super.key,
    required this.url,
    this.desktop = false,
    this.adblock = true,
    this.onCreated,
    this.onUrl,
    this.onTitle,
    this.onProgress,
    this.onCanBack,
    this.onCanForward,
    this.onNewWindow,
    this.onPageStop,
  });

  @override
  State<GeckoBrowserView> createState() => _GeckoBrowserViewState();
}

class _GeckoBrowserViewState extends State<GeckoBrowserView> {
  MethodChannel? _ch;

  void _attach(int id) {
    final ch = MethodChannel('yomihub/gecko_$id');
    _ch = ch;
    ch.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'url':
          widget.onUrl?.call('${call.arguments}');
        case 'title':
          widget.onTitle?.call('${call.arguments}');
        case 'progress':
          widget.onProgress?.call((call.arguments as num).toInt());
        case 'canBack':
          widget.onCanBack?.call(call.arguments == true);
        case 'canForward':
          widget.onCanForward?.call(call.arguments == true);
        case 'newWindow':
          widget.onNewWindow?.call('${call.arguments}');
        case 'pageStop':
          widget.onPageStop?.call();
      }
      return null;
    });
    widget.onCreated?.call(GeckoController(ch));
  }

  @override
  void dispose() {
    _ch?.setMethodCallHandler(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const viewType = 'yomihub/gecko';
    final params = <String, dynamic>{
      'url': widget.url,
      'desktop': widget.desktop,
      'adblock': widget.adblock,
    };
    // GeckoView draws into a SurfaceView: use hybrid composition.
    return PlatformViewLink(
      viewType: viewType,
      surfaceFactory: (context, controller) => AndroidViewSurface(
        controller: controller as AndroidViewController,
        gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{
          Factory<OneSequenceGestureRecognizer>(EagerGestureRecognizer.new),
        },
        hitTestBehavior: PlatformViewHitTestBehavior.opaque,
      ),
      onCreatePlatformView: (p) {
        final c = PlatformViewsService.initExpensiveAndroidView(
          id: p.id,
          viewType: viewType,
          layoutDirection: TextDirection.ltr,
          creationParams: params,
          creationParamsCodec: const StandardMessageCodec(),
          onFocus: () => p.onFocusChanged(true),
        );
        c.addOnPlatformViewCreatedListener(p.onPlatformViewCreated);
        c.addOnPlatformViewCreatedListener(_attach);
        c.create();
        return c;
      },
    );
  }
}
