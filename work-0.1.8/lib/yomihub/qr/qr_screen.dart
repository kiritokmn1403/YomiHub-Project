import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:mangayomi/models/manga.dart';
import 'package:mangayomi/modules/more/settings/browse/providers/browse_state_provider.dart';
import 'package:mangayomi/yomihub/browser/browser_screen.dart';
import 'package:mangayomi/yomihub/repos/repo_importer.dart';
import 'package:mangayomi/yomihub/vpn/vpn_tunnels.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:zxing2/qrcode.dart' as zx;

/// YomiHub 0.1.5: Settings › Mã QR — scan (camera on Android, or from an
/// image file on every platform) and generate QR codes.
///
/// Scanned codes are understood: extension repository links and deep links
/// (tachiyomi:// aniyomi:// mihon:// lnreader:// yomihub:// …), raw repo index
/// URLs, VPN profiles (WireGuard .conf text, vless/vmess/trojan/ss links),
/// web links (open in the in-app browser) and plain text (copy).
class YomiQrScreen extends ConsumerStatefulWidget {
  const YomiQrScreen({super.key});

  @override
  ConsumerState<YomiQrScreen> createState() => _YomiQrScreenState();
}

class _YomiQrScreenState extends ConsumerState<YomiQrScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);
  final _text = TextEditingController();
  MobileScannerController? _cam;
  bool _handling = false;
  String? _last;

  bool get _hasCamera => Platform.isAndroid || Platform.isIOS;

  @override
  void initState() {
    super.initState();
    if (_hasCamera) {
      _cam = MobileScannerController(
        formats: const [BarcodeFormat.qrCode],
        detectionSpeed: DetectionSpeed.noDuplicates,
      );
    }
    _tabs.addListener(() {
      if (_cam == null) return;
      _tabs.index == 0 ? _cam!.start() : _cam!.stop();
    });
  }

  @override
  void dispose() {
    _cam?.dispose();
    _tabs.dispose();
    _text.dispose();
    super.dispose();
  }

  // ───────────── scanning ─────────────

  Future<void> _onCode(String? raw) async {
    if (raw == null || raw.trim().isEmpty || _handling) return;
    _handling = true;
    _last = raw.trim();
    await _cam?.stop();
    if (mounted) setState(() {});
    try {
      await _handle(_last!);
    } finally {
      _handling = false;
      if (mounted && _tabs.index == 0) await _cam?.start();
    }
  }

  Future<void> _fromImage() async {
    final res = await FilePicker.pickFiles(type: FileType.image);
    final path = res.isEmpty ? null : res.first.path;
    if (path == null) return;
    String? text;
    if (_cam != null) {
      final cap = await _cam!.analyzeImage(path);
      text = cap?.barcodes.firstOrNull?.rawValue;
    }
    text ??= await _decodeFile(path);
    if (text == null) {
      _snack('Không tìm thấy mã QR trong ảnh');
      return;
    }
    await _onCode(text);
  }

  /// Pure-Dart decoder (zxing2) – works on Windows too.
  static Future<String?> _decodeFile(String path) async {
    try {
      final decoded = img.decodeImage(await File(path).readAsBytes());
      if (decoded == null) return null;
      final im = decoded.width > 1600
          ? img.copyResize(decoded, width: 1600)
          : decoded;
      final pixels = Int32List(im.width * im.height);
      var i = 0;
      for (final p in im) {
        pixels[i++] =
            0xFF000000 | (p.r.toInt() << 16) | (p.g.toInt() << 8) | p.b.toInt();
      }
      final source = zx.RGBLuminanceSource(im.width, im.height, pixels);
      final bitmap = zx.BinaryBitmap(zx.GlobalHistogramBinarizer(source));
      return zx.QRCodeReader().decode(bitmap).text;
    } catch (_) {
      return null;
    }
  }

  Future<void> _handle(String code) async {
    final uri = Uri.tryParse(code);
    final scheme = uri?.scheme.toLowerCase() ?? '';
    // 1) repository deep links
    if (uri != null &&
        (uri.host == 'add-repo' ||
            uri.host == 'extension-store' ||
            (scheme == 'lnreader' && uri.host == 'repo'))) {
      final repos = YomiRepoImporter.fromDeepLink(uri);
      if (repos.isNotEmpty) return _addRepos(repos);
    }
    // 2) raw repository index
    if ((scheme == 'http' || scheme == 'https') &&
        RegExp(
          r'(index(\.min)?\.(json|pb)|plugins(\.min)?\.json|anime_index\.json|novel_index\.json|sources/index)',
        ).hasMatch(code)) {
      return _addRepos([ImportedRepo(code)]);
    }
    // 3) VPN profiles
    final vpnType = _vpnType(code);
    if (vpnType != null) {
      final ok = await _confirm(
        'Thêm hồ sơ VPN',
        'Nhận ra cấu hình ${vpnType.label}. Thêm vào VPN & DNS › Dịch vụ VPN?',
      );
      if (ok) {
        await YomiTunnels.instance.init();
        final err = await YomiTunnels.instance.importText(code, type: vpnType);
        _snack(err ?? 'Đã thêm hồ sơ ${vpnType.label}');
      }
      return;
    }
    // 4) web links
    if (scheme == 'http' || scheme == 'https') {
      final act = await _choose(code, const ['Mở trong trình duyệt', 'Sao chép']);
      if (act == 0 && mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => BrowserScreen(initialUrl: code)),
        );
      } else if (act == 1) {
        await Clipboard.setData(ClipboardData(text: code));
        _snack('Đã sao chép');
      }
      return;
    }
    // 5) anything else
    final act = await _choose(code, const ['Sao chép']);
    if (act == 0) {
      await Clipboard.setData(ClipboardData(text: code));
      _snack('Đã sao chép');
    }
  }

  static TunnelType? _vpnType(String code) {
    final t = code.trim();
    if (RegExp(r'^(vless|vmess|trojan|ss)://', caseSensitive: false).hasMatch(t)) {
      return TunnelType.xray;
    }
    if (t.contains('[Interface]') && t.contains('[Peer]')) {
      return TunnelType.wireguard;
    }
    if (RegExp(r'^\s*client\s*$', multiLine: true).hasMatch(t) &&
        t.contains('remote ')) {
      return TunnelType.openvpn;
    }
    return null;
  }

  Future<void> _addRepos(List<ImportedRepo> repos) async {
    final ok = await _confirm(
      'Thêm kho tiện ích',
      repos.map((r) => r.url).join('\n'),
    );
    if (!ok) return;
    final n = await YomiRepoImporter.addAll(ref, repos);
    _snack(n > 0 ? 'Đã thêm $n kho tiện ích' : 'Kho đã có sẵn hoặc không đọc được');
  }

  Future<bool> _confirm(String title, String body) async {
    if (!mounted) return false;
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(title),
            content: SingleChildScrollView(child: SelectableText(body)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Huỷ'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Thêm'),
              ),
            ],
          ),
        ) ==
        true;
  }

  Future<int?> _choose(String code, List<String> actions) async {
    if (!mounted) return null;
    return showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nội dung mã QR'),
        content: SingleChildScrollView(child: SelectableText(code)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
          for (var i = 0; i < actions.length; i++)
            FilledButton.tonal(
              onPressed: () => Navigator.pop(ctx, i),
              child: Text(actions[i]),
            ),
        ],
      ),
    );
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  // ───────────── generating ─────────────

  void _fillRepos() {
    final urls = <String>[
      for (final t in ItemType.values)
        ...ref.read(extensionsRepoStateProvider(t))
            .map((r) => r.jsonUrl ?? '')
            .where((u) => u.isNotEmpty),
    ];
    if (urls.isEmpty) {
      _snack('Chưa có kho tiện ích nào');
      return;
    }
    // One yomihub:// link carrying every repository (url= repeated).
    final link = Uri(
      scheme: 'yomihub',
      host: 'add-repo',
      queryParameters: {'url': urls},
    ).toString();
    setState(() => _text.text = link);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mã QR'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(icon: Icon(Icons.qr_code_scanner), text: 'Quét mã'),
            Tab(icon: Icon(Icons.qr_code_2), text: 'Tạo mã'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        physics: const NeverScrollableScrollPhysics(),
        children: [_scanTab(), _makeTab()],
      ),
    );
  }

  Widget _scanTab() {
    final theme = Theme.of(context);
    return Column(
      children: [
        Expanded(
          child: _cam == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Máy tính không có máy quét camera tích hợp. Chọn ảnh chứa mã QR (ảnh chụp màn hình…) để đọc.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                )
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    MobileScanner(
                      controller: _cam!,
                      onDetect: (c) => _onCode(c.barcodes.firstOrNull?.rawValue),
                      errorBuilder: (ctx, e) => Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'Không mở được camera (${e.errorCode.name}). Hãy cấp quyền Camera cho YomiHub hoặc chọn ảnh.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: Container(
                        width: 240,
                        height: 240,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 3),
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 12,
                      top: 12,
                      child: IconButton.filledTonal(
                        tooltip: 'Đèn flash',
                        icon: const Icon(Icons.flash_on),
                        onPressed: () => _cam?.toggleTorch(),
                      ),
                    ),
                  ],
                ),
        ),
        if (_last != null)
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Mã vừa quét'),
            subtitle: Text(_last!, maxLines: 2, overflow: TextOverflow.ellipsis),
            onTap: () => _handle(_last!),
          ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton.icon(
            icon: const Icon(Icons.image_outlined),
            label: const Text('Quét từ ảnh'),
            onPressed: _fromImage,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(
            'Hiểu được: link kho tiện ích (Mihon, Aniyomi, Nekoyomi, LNReader, Mangayomi…), cấu hình VPN '
            '(WireGuard, OpenVPN, vless/vmess/trojan/ss), link web và văn bản.',
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _makeTab() {
    final data = _text.text.trim();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: _text,
          minLines: 1,
          maxLines: 5,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            labelText: 'Nội dung (link, văn bản, cấu hình VPN…)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            ActionChip(
              avatar: const Icon(Icons.extension_outlined, size: 18),
              label: const Text('Kho tiện ích của tôi'),
              onPressed: _fillRepos,
            ),
            ActionChip(
              avatar: const Icon(Icons.content_paste, size: 18),
              label: const Text('Dán'),
              onPressed: () async {
                final c = await Clipboard.getData('text/plain');
                if (c?.text != null) setState(() => _text.text = c!.text!);
              },
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (data.isNotEmpty)
          Center(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: data.length > 2900
                  ? const SizedBox(
                      width: 260,
                      child: Text(
                        'Nội dung quá dài cho một mã QR (tối đa ~2.900 ký tự).',
                        style: TextStyle(color: Colors.black),
                      ),
                    )
                  : QrImageView(
                      data: data,
                      size: 260,
                      backgroundColor: Colors.white,
                      errorCorrectionLevel: QrErrorCorrectLevel.M,
                    ),
            ),
          ),
      ],
    );
  }
}
