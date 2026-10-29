import 'package:mangayomi/yomihub/share/share_log.dart';
import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';
import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:mangayomi/yomihub/share/lan_share.dart';
import 'package:mangayomi/yomihub/share/bluetooth_share.dart';

/// Settings > AirDrop & Quicksharing.
class AirDropQuickShareScreen extends StatefulWidget {
  const AirDropQuickShareScreen({super.key});
  @override
  State<AirDropQuickShareScreen> createState() => _AirDropQuickShareScreenState();
}

class _AirDropQuickShareScreenState extends State<AirDropQuickShareScreen> {
  static const _tools = MethodChannel('com.yomihub/tools');
  final _lan = YomiLanShare.instance;
  String? _url;
  bool _google = false, _samsung = false;
  List<YomiPeer> _peers = [];
  bool _scanning = false;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _lan.status.addListener(_onStatus);
    _refresh();
    if (Platform.isAndroid) {
      _tools.invokeMapMethod<String, dynamic>('targets').then((m) {
        if (!mounted || m == null) return;
        setState(() {
          _google = m['google'] == true;
          _samsung = m['samsung'] == true;
        });
      }).catchError((_) {});
    }
    _tick = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) setState(() {});
    });
  }

  void _onStatus() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_lan.status.value)));
    setState(() {});
  }

  Future<void> _refresh() async {
    final u = await _lan.pageUrl();
    if (mounted) setState(() => _url = u);
  }

  @override
  void dispose() {
    _lan.status.removeListener(_onStatus);
    _tick?.cancel();
    super.dispose();
  }

  Future<List<String>> _pick() async {
    final r = await FilePicker.pickFiles();
    return r.map((e) => e.path).whereType<String>().toList();
  }

  Future<void> _quickShare(String target) async {
    final files = await _pick();
    if (files.isEmpty) return;
    try {
      await _tools.invokeMethod('share', {'paths': files, 'target': target});
    } catch (e) {
      YomiShareLog.error('Quick Share', 'Chia sẻ tệp', target: target, files: files, error: e);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('Không mở được Quick Share: {p0}', {'p0': e}))));
    }
  }

  Future<void> _toggleReceive(bool on) async {
    if (on) {
      try {
        await _lan.start();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('Không bật được chế độ nhận: {p0}', {'p0': e}))));
      }
    } else {
      await _lan.stop();
    }
    await _refresh();
  }

  Future<void> _offer() async {
    final files = await _pick();
    if (files.isEmpty) return;
    if (!_lan.isRunning) await _lan.start();
    _lan.offered.addAll(files.where((f) => !_lan.offered.contains(f)));
    await _refresh();
  }

  Future<void> _scan() async {
    setState(() => _scanning = true);
    final peers = await _lan.discover();
    if (mounted) {
      setState(() {
        _peers = peers;
        _scanning = false;
      });
    }
  }

  Future<void> _sendTo(YomiPeer peer) async {
    final files = await _pick();
    if (files.isEmpty || !mounted) return;
    final msg = ScaffoldMessenger.of(context);
    msg.showSnackBar(SnackBar(content: Text(tr('Đang gửi {p0} tệp tới {p1}…', {'p0': files.length, 'p1': peer.name}))));
    try {
      final n = await _lan.sendTo(peer, files);
      if (n < files.length) {
        msg.showSnackBar(SnackBar(content: Text(tr('Một số tệp gửi lỗi – xem Nhật ký ứng dụng'))));
      }
      msg.showSnackBar(SnackBar(content: Text(tr('Đã gửi {p0}/{p1} tệp tới {p2}', {'p0': n, 'p1': files.length, 'p2': peer.name}))));
    } catch (e) {
      YomiShareLog.error('Wi-Fi/LAN', 'Gửi tệp', target: peer.name, files: files, error: e);
      msg.showSnackBar(SnackBar(content: Text(tr('Gửi thất bại: {p0}', {'p0': e}))));
    }
  }

  Widget _header(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
        child: Text(t, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
      );

  @override
  Widget build(BuildContext context) {
    final on = _lan.isRunning;
    final left = _lan.visibleUntil?.difference(DateTime.now()).inMinutes;
    return Scaffold(
      appBar: AppBar(title: const Text('AirDrop & Quicksharing')),
      body: ListView(
        children: [
          _header(tr('Nhận tệp (giống AirDrop “Mọi người”)')),
          SwitchListTile(
            secondary: const Icon(Icons.wifi_tethering),
            title: Text(tr('Cho phép nhận tệp qua Wi-Fi')),
            subtitle: Text(on
                ? tr('Đang hiển thị với thiết bị cùng mạng{p0}', {'p0': left != null ? ' · ${tr('tự tắt sau {p0} phút', {'p0': left + 1})}' : ''})
                : tr('iPhone, iPad, Mac, máy tính Windows/Linux và YomiHub khác gửi được tệp cho bạn')),
            value: on,
            onChanged: _toggleReceive,
          ),
          if (on && _url != null)
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(8),
                      child: QrImageView(data: _url!, version: QrVersions.auto, size: 190),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(_url!, textAlign: TextAlign.center),
                    const SizedBox(height: 4),
                    Text(
                      tr('Trên iPhone/Mac: mở Camera quét mã → Safari mở trang gửi/nhận tệp. Trên máy tính: gõ địa chỉ trên vào trình duyệt. Hai máy phải cùng Wi-Fi.'),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12),
                    ),
                    TextButton.icon(
                      onPressed: () => Clipboard.setData(ClipboardData(text: _url!)),
                      icon: const Icon(Icons.copy, size: 18),
                      label: Text(tr('Sao chép địa chỉ')),
                    ),
                  ],
                ),
              ),
            ),
          if (on && _url == null)
            ListTile(
              leading: Icon(Icons.wifi_off),
              title: Text(tr('Chưa có Wi-Fi')),
              subtitle: Text(tr('Kết nối Wi-Fi (hoặc bật điểm phát sóng) để thiết bị khác thấy bạn')),
            ),
          ListTile(
            leading: const Icon(Icons.upload_file),
            title: Text(tr('Chia sẻ tệp cho thiết bị khác tải về')),
            subtitle: Text(_lan.offered.isEmpty
                ? tr('Chọn tệp; người khác quét mã QR để tải')
                : tr('{p0} tệp đang chia sẻ: {p1}', {'p0': _lan.offered.length, 'p1': _lan.offered.map(p.basename).take(3).join(', ')})),
            onTap: _offer,
            trailing: _lan.offered.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(() => _lan.offered.clear()),
                  ),
          ),
          ValueListenableBuilder<List<String>>(
            valueListenable: _lan.received,
            builder: (_, list, _) => list.isEmpty
                ? const SizedBox.shrink()
                : ExpansionTile(
                    leading: const Icon(Icons.download_done),
                    title: Text(tr('Đã nhận {p0} tệp', {'p0': list.length})),
                    children: [
                      for (final f in list.take(20))
                        ListTile(
                          dense: true,
                          title: Text(p.basename(f)),
                          subtitle: Text(p.dirname(f), style: const TextStyle(fontSize: 11)),
                          onTap: () => launchUrl(Uri.file(f)),
                        ),
                    ],
                  ),
          ),
          _header(tr('Gửi tới YomiHub gần đây')),
          ListTile(
            leading: _scanning
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.radar),
            title: Text(tr('Tìm thiết bị')),
            subtitle: Text(tr('Máy kia mở mục này và bật “Cho phép nhận tệp”')),
            onTap: _scanning ? null : _scan,
          ),
          for (final peer in _peers)
            ListTile(
              leading: Icon(peer.platform == 'android' ? Icons.phone_android : Icons.computer),
              title: Text(peer.name),
              subtitle: Text(tr('{p0} · bấm để chọn tệp gửi', {'p0': peer.host})),
              onTap: () => _sendTo(peer),
            ),
          if (Platform.isAndroid) ...[
            _header('Quick Share'),
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: Text(tr('Gửi qua Quick Share (Google / Nearby Share)')),
              subtitle: Text(_google ? tr('Gửi tới Android, Chromebook, Windows có Quick Share') : tr('Không thấy Quick Share của Google – sẽ mở bảng chia sẻ')),
              onTap: () => _quickShare('google'),
            ),
            if (_samsung)
              ListTile(
                leading: const Icon(Icons.share),
                title: Text(tr('Gửi qua Quick Share (Samsung)')),
                onTap: () => _quickShare('samsung'),
              ),
            ListTile(
              leading: const Icon(Icons.ios_share),
              title: Text(tr('Bảng chia sẻ của hệ thống')),
              subtitle: const Text('Bluetooth, Wi-Fi Direct, Zalo, Telegram…'),
              onTap: () => _quickShare('system'),
            ),
          ],
          if (Platform.isWindows) ...[
            _header('Quick Share'),
            ListTile(
              leading: const Icon(Icons.open_in_new),
              title: const Text('Quick Share cho Windows (Google)'),
              subtitle: Text(tr('Cài ứng dụng chính thức để gửi/nhận với điện thoại Android')),
              onTap: () => launchUrl(Uri.parse('https://www.android.com/better-together/quick-share-app/')),
            ),
          ],
          // YomiHub 0.2.0: Bluetooth
          BluetoothShareSection(header: _header),
          _header(tr('Về AirDrop')),
          ListTile(
            leading: Icon(Icons.info_outline),
            title: Text(tr('AirDrop gốc chỉ có trên thiết bị Apple')),
            subtitle: Text(
              tr('AirDrop dùng chuẩn Wi-Fi riêng của Apple (AWDL). Điện thoại Android và đa số máy Windows không phát được sóng này (dự án OpenDrop cũng chỉ chạy trên Linux với card Wi-Fi đặc biệt). YomiHub dùng cách tương đương: iPhone/Mac quét mã QR ở trên để gửi và nhận tệp qua Wi-Fi, không cần cài thêm ứng dụng.'),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
