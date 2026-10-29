import 'package:mangayomi/yomihub/share/share_log.dart';
import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// A YomiHub found on the local network.
class YomiPeer {
  final String name;
  final String host;
  final int port;
  final String token;
  final String platform;
  YomiPeer(this.name, this.host, this.port, this.token, this.platform);
  String get base => 'http://$host:$port/$token';
}

/// YomiHub "AirDrop & Quicksharing", LAN part.
///
/// * A small HTTP server on the Wi-Fi address: any phone or computer
///   (iPhone/iPad/Mac with Safari, Windows, Linux) opens the page from a QR
///   code to download the files offered here or send files to this device.
///   No app needed on the other side – the practical stand-in for AirDrop,
///   which needs Apple-only Wi-Fi hardware (AWDL).
/// * YomiHub ↔ YomiHub discovery by UDP broadcast, then direct transfer.
class YomiLanShare {
  YomiLanShare._();
  static final instance = YomiLanShare._();

  static const httpPort = 47330;
  static const udpPort = 47331;
  static const _tools = MethodChannel('com.yomihub/tools');

  HttpServer? _server;
  RawDatagramSocket? _udp;
  Timer? _autoOff;
  String token = '';
  String deviceName = 'YomiHub';
  final offered = <String>[]; // file paths offered for download
  final received = ValueNotifier<List<String>>([]);
  final running = ValueNotifier<bool>(false);
  final status = ValueNotifier<String>('');
  DateTime? visibleUntil;

  static (String title, String link, String type)? currentMedia;

  static void setCurrentMedia({required String title, required String link, required String type}) {
    currentMedia = (title, link, type);
  }

  bool get isRunning => _server != null;
  int get port => _server?.port ?? httpPort;

  Future<String?> localIp() async {
    try {
      final ifs = await NetworkInterface.list(type: InternetAddressType.IPv4, includeLoopback: false);
      String? best;
      for (final i in ifs) {
        for (final a in i.addresses) {
          final ip = a.address;
          final n = i.name.toLowerCase();
          if (ip.startsWith('169.254.')) continue;
          final wifi = n.contains('wlan') || n.contains('wi-fi') || n.contains('wifi') || n.startsWith('en') || n.contains('ap');
          final lan = ip.startsWith('192.168.') || ip.startsWith('10.') || RegExp(r'^172\.(1[6-9]|2\d|3[01])\.').hasMatch(ip);
          if (wifi && lan) return ip;
          if (lan && !n.contains('tun') && !n.contains('rmnet') && !n.contains('vpn')) best ??= ip;
        }
      }
      return best;
    } catch (_) {
      return null;
    }
  }

  Future<Directory> receiveDir() async {
    Directory? base;
    try {
      if (Platform.isAndroid) {
        base = await getExternalStorageDirectory();
      } else {
        base = await getDownloadsDirectory();
      }
    } catch (_) {}
    base ??= await getApplicationDocumentsDirectory();
    final d = Directory(p.join(base.path, Platform.isAndroid ? 'Received' : 'YomiHub Received'));
    await d.create(recursive: true);
    return d;
  }

  Future<String?> pageUrl() async {
    final ip = await localIp();
    if (ip == null || !isRunning) return null;
    return 'http://$ip:$port/$token/';
  }

  /// Turns the receiver on ("Mọi người trong 10 phút", like AirDrop).
  Future<void> start({Duration visibleFor = const Duration(minutes: 10)}) async {
    if (_server == null) {
      token = List.generate(6, (_) => Random.secure().nextInt(10)).join();
      try {
        if (Platform.isAndroid) {
          deviceName = (await _tools.invokeMethod<String>('deviceName')) ?? deviceName;
          await _tools.invokeMethod('multicast', {'on': true});
        } else {
          deviceName = Platform.localHostname;
        }
      } catch (_) {}
      try {
        _server = await HttpServer.bind(InternetAddress.anyIPv4, httpPort, shared: true);
      } catch (_) {
        try {
          _server = await HttpServer.bind(InternetAddress.anyIPv4, 0);
        } catch (e) {
          YomiShareLog.error('Wi-Fi/LAN', 'Bật chế độ nhận', error: e);
          rethrow;
        }
      }
      _server!.listen(_handle, onError: (_) {});
      try {
        _udp = await RawDatagramSocket.bind(InternetAddress.anyIPv4, udpPort, reuseAddress: true);
        _udp!.broadcastEnabled = true;
        _udp!.listen((ev) {
          if (ev != RawSocketEvent.read) return;
          final d = _udp?.receive();
          if (d == null) return;
          if (utf8.decode(d.data, allowMalformed: true) == 'YH?') {
            final reply = 'YH!${jsonEncode({'name': deviceName, 'port': port, 'token': token, 'platform': Platform.operatingSystem})}';
            _udp?.send(utf8.encode(reply), d.address, d.port);
          }
        });
      } catch (_) {}
    }
    visibleUntil = DateTime.now().add(visibleFor);
    _autoOff?.cancel();
    _autoOff = Timer(visibleFor, stop);
    running.value = true;
  }

  Future<void> stop() async {
    _autoOff?.cancel();
    await _server?.close(force: true);
    _server = null;
    _udp?.close();
    _udp = null;
    visibleUntil = null;
    running.value = false;
    try {
      if (Platform.isAndroid) await _tools.invokeMethod('multicast', {'on': false});
    } catch (_) {}
  }

  /// Finds other YomiHub devices on the same Wi-Fi.
  Future<List<YomiPeer>> discover({Duration wait = const Duration(seconds: 3)}) async {
    final peers = <String, YomiPeer>{};
    RawDatagramSocket? s;
    try {
      s = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      s.broadcastEnabled = true;
      s.listen((ev) {
        if (ev != RawSocketEvent.read) return;
        final d = s?.receive();
        if (d == null) return;
        final msg = utf8.decode(d.data, allowMalformed: true);
        if (!msg.startsWith('YH!')) return;
        try {
          final j = jsonDecode(msg.substring(3)) as Map<String, dynamic>;
          if (j['token'] == token && isRunning) return; // ourselves
          peers[d.address.address] = YomiPeer('${j['name']}', d.address.address, j['port'] as int, '${j['token']}', '${j['platform']}');
        } catch (_) {}
      });
      final ip = await localIp();
      final targets = <InternetAddress>[InternetAddress('255.255.255.255')];
      if (ip != null) {
        final parts = ip.split('.');
        targets.add(InternetAddress('${parts[0]}.${parts[1]}.${parts[2]}.255'));
      }
      for (var i = 0; i < 3; i++) {
        for (final t in targets) {
          try {
            s.send(utf8.encode('YH?'), t, udpPort);
          } catch (_) {}
        }
        await Future.delayed(Duration(milliseconds: wait.inMilliseconds ~/ 3));
      }
    } catch (e) {
      YomiShareLog.error('Wi-Fi/LAN', 'Tìm thiết bị', error: e);
    } finally {
      s?.close();
    }
    return peers.values.toList();
  }

  /// Sends [files] to another YomiHub (or any receiver page) directly.
  Future<int> sendTo(YomiPeer peer, List<String> files, {void Function(String)? onProgress}) async {
    var ok = 0;
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 8)
      ..findProxy = ((_) => 'DIRECT');
    final errors = <String>[];
    final target = '${peer.name} (${peer.host}:${peer.port})';
    try {
      for (final f in files) {
        final file = File(f);
        if (!await file.exists()) {
          errors.add('${p.basename(f)}: không tìm thấy tệp');
          continue;
        }
        onProgress?.call(p.basename(f));
        try {
          final req = await client.putUrl(Uri.parse('${peer.base}/upload?name=${Uri.encodeQueryComponent(p.basename(f))}'));
          req.headers.set('X-YH-From', deviceName);
          req.contentLength = await file.length();
          await req.addStream(file.openRead());
          final res = await req.close();
          final body = await res.transform(utf8.decoder).join().catchError((_) => '');
          if (res.statusCode == 200) {
            ok++;
          } else {
            errors.add('${p.basename(f)}: HTTP ${res.statusCode}${body.isEmpty ? '' : ' $body'}');
          }
        } catch (e) {
          errors.add('${p.basename(f)}: $e');
        }
      }
    } catch (e) {
      errors.add('$e');
    } finally {
      client.close(force: true);
    }
    if (errors.isNotEmpty) {
      YomiShareLog.error('Wi-Fi/LAN', 'Gửi tệp', target: target, files: files, sent: ok, error: errors.join(' | '));
    }
    return ok;
  }

  Future<void> _handle(HttpRequest r) async {
    final segs = r.uri.pathSegments;
    final res = r.response;
    try {
      if (segs.isEmpty || segs.first != token) {
        res.statusCode = 404;
        res.write(tr('YomiHub: liên kết đã hết hạn – quét lại mã QR.'));
        return;
      }
      final action = segs.length > 1 ? segs[1] : '';
      if (action == '' || action == 'index.html') {
        res.headers.contentType = ContentType.html;
        res.write(_page());
      } else if (action == 'f' && segs.length > 2) {
        final i = int.tryParse(segs[2]) ?? -1;
        if (i < 0 || i >= offered.length) {
          res.statusCode = 404;
          return;
        }
        final f = File(offered[i]);
        res.headers.set('Content-Disposition', "attachment; filename*=UTF-8''${Uri.encodeComponent(p.basename(f.path))}");
        res.headers.contentType = ContentType.binary;
        res.contentLength = await f.length();
        await res.addStream(f.openRead());
      } else if (action == 'upload' && (r.method == 'PUT' || r.method == 'POST')) {
        var name = p.basename(r.uri.queryParameters['name'] ?? 'tep_${DateTime.now().millisecondsSinceEpoch}');
        name = name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
        final dir = await receiveDir();
        var out = File(p.join(dir.path, name));
        var n = 1;
        while (await out.exists()) {
          out = File(p.join(dir.path, '${p.basenameWithoutExtension(name)} ($n)${p.extension(name)}'));
          n++;
        }
        final sink = out.openWrite();
        await sink.addStream(r);
        await sink.close();
        received.value = [out.path, ...received.value];
        status.value = tr('Đã nhận {p0}{p1}', {'p0': p.basename(out.path), 'p1': r.headers.value('X-YH-From') != null ? ' từ ${r.headers.value('X-YH-From')}' : ''});
        res.write('ok');
      } else {
        res.statusCode = 404;
      }
    } catch (e) {
      YomiShareLog.error('Wi-Fi/LAN', 'Nhận tệp', target: r.connectionInfo?.remoteAddress.address, error: e);
      try {
        res.statusCode = 500;
        res.write('$e');
      } catch (_) {}
    } finally {
      try {
        await res.close();
      } catch (_) {}
    }
  }

  String _esc(String s) => const HtmlEscape().convert(s);

  String _page() {
    final items = StringBuffer();
    for (var i = 0; i < offered.length; i++) {
      final f = File(offered[i]);
      final size = f.existsSync() ? f.lengthSync() : 0;
      items.write('<li><a href="f/$i">${_esc(p.basename(f.path))}</a> <small>${(size / 1048576).toStringAsFixed(1)} MB</small></li>');
    }
    final mediaCard = currentMedia == null
        ? ''
        : '''<div class="card"><b>🎬 Nội dung đang xem / đọc</b>
<p><b>${_esc(currentMedia!.$1)}</b> (${_esc(currentMedia!.$3)})</p>
<a href="${_esc(currentMedia!.$2)}" target="_blank" class="btn" style="text-decoration:none;display:inline-block;margin-top:8px">Mở xem ngay</a>
</div>''';

    return '''<!doctype html><html lang="vi"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>YomiHub – ${_esc(deviceName)}</title>
<style>body{font-family:-apple-system,Segoe UI,Roboto,sans-serif;max-width:640px;margin:0 auto;padding:16px;background:#101418;color:#e8eaed}
h1{font-size:20px}.card{background:#1c2128;border-radius:14px;padding:16px;margin:12px 0}a{color:#8ab4f8}li{margin:8px 0}
button,label.btn{background:#8ab4f8;color:#0b1b33;border:0;border-radius:20px;padding:10px 18px;font-size:15px;display:inline-block}
#log{white-space:pre-line;font-size:13px;color:#9aa0a6}</style></head><body>
<h1>YomiHub · ${_esc(deviceName)}</h1>
$mediaCard
<div class="card"><b>Gửi tệp tới thiết bị này</b><p>Chọn tệp (ảnh, video, PDF, EPUB, sao lưu…) rồi chờ báo xong.</p>
<label class="btn">Chọn tệp<input id="f" type="file" multiple hidden></label><div id="log"></div></div>
<div class="card"><b>Tải tệp từ thiết bị này</b><ul>${items.isEmpty ? '<li><small>Chưa có tệp nào được chia sẻ.</small></li>' : items}</ul></div>
<script>
document.getElementById('f').onchange=async function(){var log=document.getElementById('log');for(const file of this.files){log.textContent+='Đang gửi '+file.name+'…\\n';
try{const r=await fetch('upload?name='+encodeURIComponent(file.name),{method:'PUT',body:file});log.textContent+=(r.ok?'✓ Xong: ':'✗ Lỗi: ')+file.name+'\\n';}catch(e){log.textContent+='✗ '+file.name+': '+e+'\\n';}}};
</script></body></html>''';
  }
}
