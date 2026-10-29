import 'package:mangayomi/yomihub/share/share_log.dart';
import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';

/// YomiHub 0.2.0: Bluetooth in "AirDrop & Quicksharing".
///
/// Android: direct YomiHub ⇄ YomiHub transfer (RFCOMM, YomiBluetooth.kt),
/// plus the system Bluetooth share / visibility for any other device.
/// Windows: the built-in Bluetooth File Transfer (fsquirt.exe, Windows 7 and
/// later) to send to / receive from phones and other PCs.
class YomiBluetoothShare extends ChangeNotifier {
  YomiBluetoothShare._() {
    if (Platform.isAndroid) _ch.setMethodCallHandler(_onCall);
  }
  static final instance = YomiBluetoothShare._();
  static const _ch = MethodChannel('yomihub/bluetooth');

  bool supported = Platform.isAndroid || Platform.isWindows;
  bool enabled = false, granted = false, listening = false;
  String? name;
  String? progress;
  final received = <String>[];
  final events = StreamController<String>.broadcast();

  Future<dynamic> _onCall(MethodCall c) async {
    switch (c.method) {
      case 'btState':
        listening = c.arguments == 'listening';
      case 'btProgress':
        final m = Map<String, dynamic>.from(c.arguments as Map);
        final size = (m['size'] as num?)?.toInt() ?? 0;
        final done = (m['done'] as num?)?.toInt() ?? 0;
        final pc = size == 0 ? 100 : (done * 100 ~/ size);
        progress = '${m['dir'] == 'in' ? '↓' : '↑'} ${m['name']} $pc%';
        if (done >= size) progress = null;
      case 'btReceived':
        final m = Map<String, dynamic>.from(c.arguments as Map);
        received.insert(0, '${m['path']}');
        events.add(tr('Đã nhận {p0} từ {p1}', {'p0': p.basename('${m['path']}'), 'p1': m['peer']}));
      case 'btSent':
        progress = null;
        events.add(tr('Đã gửi {p0} tệp qua Bluetooth', {'p0': c.arguments}));
      case 'btError':
        progress = null;
        YomiShareLog.error('Bluetooth', 'Truyền tệp', error: c.arguments);
        events.add(tr('Bluetooth lỗi: {p0}', {'p0': c.arguments}));
    }
    notifyListeners();
    return null;
  }

  Future<void> refresh() async {
    if (!Platform.isAndroid) return;
    try {
      final m = await _ch.invokeMapMethod<String, dynamic>('state') ?? {};
      supported = m['supported'] == true;
      enabled = m['enabled'] == true;
      granted = m['granted'] == true;
      listening = m['listening'] == true;
      name = m['name'] as String?;
    } catch (_) {
      supported = false;
    }
    notifyListeners();
  }

  Future<bool> ensureReady() async {
    if (!Platform.isAndroid) return true;
    await refresh();
    if (!granted) {
      await _ch.invokeMethod('requestPermissions');
      await Future<void>.delayed(const Duration(seconds: 2));
      await refresh();
      if (!granted) return false;
    }
    if (!enabled) {
      await _ch.invokeMethod('enable');
      for (var i = 0; i < 15 && !enabled; i++) {
        await Future<void>.delayed(const Duration(seconds: 1));
        await refresh();
      }
    }
    return enabled;
  }

  Future<List<Map<String, String>>> paired() async {
    final l = await _ch.invokeListMethod<dynamic>('paired') ?? const [];
    return l.map((e) => Map<String, String>.from(e as Map)).toList();
  }

  Future<void> listen(bool on) async {
    if (on) {
      if (!await ensureReady()) return;
      await _ch.invokeMethod('listen', {});
      await _ch.invokeMethod('discoverable');
    } else {
      await _ch.invokeMethod('stop');
    }
    await refresh();
  }

  Future<void> sendDirect(String address, List<String> paths) async {
    try {
      await _ch.invokeMethod('send', {'address': address, 'paths': paths});
    } catch (e) {
      YomiShareLog.error('Bluetooth', 'Gửi tệp', target: address, files: paths, error: e);
      rethrow;
    }
  }

  Future<void> sendSystem(List<String> paths) async {
    try {
      await _ch.invokeMethod('sendSystem', {'paths': paths});
    } catch (e) {
      YomiShareLog.error('Bluetooth', 'Gửi tệp (hệ thống)', files: paths, error: e);
      rethrow;
    }
  }
  Future<void> openSettings() => _ch.invokeMethod('settings');
  Future<List<String>> systemFolders() async =>
      (await _ch.invokeListMethod<String>('systemFolders')) ?? const [];

  /// Windows: Bluetooth File Transfer wizard (fsquirt.exe, Windows 7+).
  static Future<bool> windowsWizard({required bool send}) async {
    try {
      await Process.start('fsquirt.exe', [send ? '-send' : '-receive'], mode: ProcessStartMode.detached);
      return true;
    } catch (e) {
      YomiShareLog.error('Bluetooth (Windows)', send ? 'Gửi tệp' : 'Nhận tệp', error: e);
      try {
        await Process.start('cmd', ['/c', 'start', '', 'ms-settings:bluetooth'], mode: ProcessStartMode.detached);
      } catch (_) {}
      return false;
    }
  }
}

/// Section shown in Settings > AirDrop & Quicksharing.
class BluetoothShareSection extends StatefulWidget {
  final Widget Function(String) header;
  const BluetoothShareSection({super.key, required this.header});

  @override
  State<BluetoothShareSection> createState() => _BluetoothShareSectionState();
}

class _BluetoothShareSectionState extends State<BluetoothShareSection> {
  final _bt = YomiBluetoothShare.instance;
  StreamSubscription<String>? _sub;

  @override
  void initState() {
    super.initState();
    _bt.addListener(_changed);
    _sub = _bt.events.stream.listen((m) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
    });
    _bt.refresh();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _bt.removeListener(_changed);
    _sub?.cancel();
    super.dispose();
  }

  Future<List<String>> _pick() async {
    final r = await FilePicker.pickFiles(allowMultiple: true);
    return r.map((e) => e.path).whereType<String>().toList();
  }

  Future<void> _sendDirect() async {
    if (!await _bt.ensureReady()) return _toast(tr('Cần quyền và bật Bluetooth'));
    final devs = await _bt.paired();
    if (!mounted) return;
    if (devs.isEmpty) {
      _toast(tr('Chưa ghép đôi thiết bị nào – mở cài đặt Bluetooth để ghép đôi trước'));
      await _bt.openSettings();
      return;
    }
    final d = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(tr('Gửi tới thiết bị đã ghép đôi')),
        children: [
          for (final d in devs)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, d),
              child: ListTile(leading: const Icon(Icons.bluetooth), title: Text(d['name'] ?? ''), subtitle: Text(d['address'] ?? '')),
            ),
        ],
      ),
    );
    if (d == null) return;
    final files = await _pick();
    if (files.isEmpty) return;
    try {
      await _bt.sendDirect(d['address']!, files);
    } catch (e) {
      return _toast(tr('Gửi Bluetooth thất bại: {p0}', {'p0': e}));
    }
    _toast(tr('Đang gửi {p0} tệp tới {p1}… (máy kia bật “Nhận qua Bluetooth”)', {'p0': files.length, 'p1': d['name']}));
  }

  Future<void> _sendSystem() async {
    final files = await _pick();
    if (files.isEmpty) return;
    try {
      await _bt.sendSystem(files);
    } catch (e) {
      _toast(tr('Gửi Bluetooth thất bại: {p0}', {'p0': e}));
    }
  }

  void _toast(String m) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isWindows) {
      return Column(children: [
        widget.header('Bluetooth'),
        ListTile(
          leading: const Icon(Icons.bluetooth),
          title: Text(tr('Gửi tệp qua Bluetooth')),
          subtitle: Text(tr('Tới điện thoại hoặc máy tính đã ghép đôi (trình gửi tệp Bluetooth của Windows)')),
          onTap: () => YomiBluetoothShare.windowsWizard(send: true),
        ),
        ListTile(
          leading: const Icon(Icons.bluetooth_searching),
          title: Text(tr('Nhận tệp qua Bluetooth')),
          subtitle: Text(tr('Mở chế độ nhận rồi gửi từ máy kia')),
          onTap: () => YomiBluetoothShare.windowsWizard(send: false),
        ),
      ]);
    }
    if (!Platform.isAndroid || !_bt.supported) return const SizedBox.shrink();
    return Column(children: [
      widget.header('Bluetooth'),
      SwitchListTile(
        secondary: Icon(_bt.listening ? Icons.bluetooth_connected : Icons.bluetooth),
        title: Text(tr('Nhận qua Bluetooth')),
        subtitle: Text(_bt.listening
            ? tr('Đang chờ – máy kia chọn “{p0}” để gửi; tệp lưu vào Download/YomiHub/Bluetooth', {'p0': _bt.name ?? tr('thiết bị này')})
            : tr('Nhận tệp từ YomiHub khác, không cần Wi-Fi')),
        value: _bt.listening,
        onChanged: (v) => _bt.listen(v),
      ),
      if (_bt.progress != null)
        ListTile(leading: const Icon(Icons.swap_vert), title: Text(_bt.progress!)),
      ListTile(
        leading: const Icon(Icons.send_to_mobile),
        title: Text(tr('Gửi tới YomiHub qua Bluetooth')),
        subtitle: Text(tr('Điện thoại ↔ điện thoại đã ghép đôi')),
        onTap: _sendDirect,
      ),
      ListTile(
        leading: const Icon(Icons.bluetooth_audio_outlined),
        title: Text(tr('Gửi qua Bluetooth hệ thống')),
        subtitle: Text(tr('Tới máy tính Windows/Mac, điện thoại không có YomiHub')),
        onTap: _sendSystem,
      ),
      ListTile(
        leading: const Icon(Icons.visibility_outlined),
        title: Text(tr('Cho phép thiết bị khác thấy máy này (5 phút)')),
        subtitle: Text(tr('Để máy tính/điện thoại khác gửi tệp bằng Bluetooth hệ thống')),
        onTap: () async {
          if (await _bt.ensureReady()) await const MethodChannel('yomihub/bluetooth').invokeMethod('discoverable');
        },
      ),
      if (_bt.received.isNotEmpty)
        ExpansionTile(
          leading: const Icon(Icons.download_done),
          title: Text(tr('Đã nhận {p0} tệp qua Bluetooth', {'p0': _bt.received.length})),
          children: [
            for (final f in _bt.received.take(30))
              ListTile(dense: true, title: Text(p.basename(f)), subtitle: Text(p.dirname(f), style: const TextStyle(fontSize: 11))),
          ],
        ),
    ]);
  }
}
