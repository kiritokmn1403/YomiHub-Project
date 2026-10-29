import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:mangayomi/utils/log/logger.dart';

/// YomiHub 0.2.2: network speed test (LibreSpeed protocol,
/// https://github.com/librespeed/speedtest), plus Cloudflare's speed
/// endpoints as a nearby server for Vietnam / Asia.
///
/// LibreSpeed backends expose four files: garbage.php (download),
/// empty.php (upload / ping) and getIP.php (IP + ISP). The test is written
/// in Dart (no WebView), so it works the same on Android 6.0+ and Windows.
class YomiSpeedServer {
  final String name;
  final String base;
  final String dl, ul, ping, ip;
  final bool cloudflare;
  const YomiSpeedServer(this.name, this.base, this.dl, this.ul, this.ping, this.ip, {this.cloudflare = false});

  Uri _u(String path, [Map<String, String>? q]) {
    final b = base.endsWith('/') ? base : '$base/';
    final u = Uri.parse(b).resolve(path);
    return u.replace(queryParameters: {...u.queryParameters, ...?q});
  }

  Uri downloadUri() => cloudflare
      ? Uri.parse('https://speed.cloudflare.com/__down?bytes=50000000')
      : _u(dl, {'ckSize': '100', 'r': '${Random().nextInt(1 << 30)}'});
  Uri uploadUri() => cloudflare
      ? Uri.parse('https://speed.cloudflare.com/__up')
      : _u(ul, {'r': '${Random().nextInt(1 << 30)}'});
  Uri pingUri() => cloudflare
      ? Uri.parse('https://speed.cloudflare.com/__down?bytes=0&r=${Random().nextInt(1 << 30)}')
      : _u(ping, {'r': '${Random().nextInt(1 << 30)}'});
  Uri ipUri() => cloudflare ? Uri.parse('https://speed.cloudflare.com/meta') : _u(ip, {'isp': 'true'});

  factory YomiSpeedServer.fromJson(Map<String, dynamic> j) => YomiSpeedServer(
    '${j['name']}',
    '${j['server']}'.startsWith('//') ? 'https:${j['server']}' : '${j['server']}',
    '${j['dlURL']}',
    '${j['ulURL']}',
    '${j['pingURL']}',
    '${j['getIpURL']}',
  );
}

enum SpeedPhase { idle, selecting, ping, download, upload, done, error }

class SpeedResult {
  double? pingMs, jitterMs, downMbps, upMbps;
  String? ip, isp, server;
  DateTime at = DateTime.now();
  Map<String, dynamic> toJson() => {
    'ping': pingMs,
    'jitter': jitterMs,
    'down': downMbps,
    'up': upMbps,
    'ip': ip,
    'isp': isp,
    'server': server,
    'at': at.millisecondsSinceEpoch,
  };
  static SpeedResult fromJson(Map j) => SpeedResult()
    ..pingMs = (j['ping'] as num?)?.toDouble()
    ..jitterMs = (j['jitter'] as num?)?.toDouble()
    ..downMbps = (j['down'] as num?)?.toDouble()
    ..upMbps = (j['up'] as num?)?.toDouble()
    ..ip = j['ip'] as String?
    ..isp = j['isp'] as String?
    ..server = j['server'] as String?
    ..at = DateTime.fromMillisecondsSinceEpoch((j['at'] as num?)?.toInt() ?? 0);
}

class YomiSpeedTest {
  static const cloudflare = YomiSpeedServer(
    'Cloudflare',
    'https://speed.cloudflare.com/',
    '',
    '',
    '',
    '',
    cloudflare: true,
  );

  /// Used when servers.php cannot be reached.
  static const fallback = <YomiSpeedServer>[
    YomiSpeedServer('Tokyo, Japan (A573)', 'https://librespeed.a573.net/', 'backend/garbage.php', 'backend/empty.php', 'backend/empty.php', 'backend/getIP.php'),
    YomiSpeedServer('Los Angeles, USA (Clouvider)', 'https://la.speedtest.clouvider.net/backend', 'garbage.php', 'empty.php', 'empty.php', 'getIP.php'),
    YomiSpeedServer('Frankfurt, Germany (Clouvider)', 'https://fra.speedtest.clouvider.net/backend', 'garbage.php', 'empty.php', 'empty.php', 'getIP.php'),
    YomiSpeedServer('Amsterdam, Netherlands (Clouvider)', 'https://ams.speedtest.clouvider.net/backend', 'garbage.php', 'empty.php', 'empty.php', 'getIP.php'),
    YomiSpeedServer('Helsinki, Finland (Hetzner)', 'https://www.librespeed.fi/', 'backend/garbage.php', 'backend/empty.php', 'backend/empty.php', 'backend/getIP.php'),
  ];

  static List<YomiSpeedServer>? _servers;

  static HttpClient _client() => HttpClient()
    ..connectionTimeout = const Duration(seconds: 8)
    ..idleTimeout = const Duration(seconds: 5)
    ..userAgent = 'YomiHub-SpeedTest';

  static Future<List<YomiSpeedServer>> servers() async {
    if (_servers != null) return _servers!;
    final c = _client();
    try {
      final req = await c.getUrl(Uri.parse('https://librespeed.org/backend-servers/servers.php'));
      final res = await req.close().timeout(const Duration(seconds: 10));
      final body = await res.transform(utf8.decoder).join();
      final l = (jsonDecode(body) as List).map((e) => YomiSpeedServer.fromJson(e as Map<String, dynamic>)).toList();
      _servers = [cloudflare, ...l];
    } catch (e) {
      AppLogger.logOnce('speedtest:list', 'SpeedTest: không tải được danh sách máy chủ LibreSpeed ($e) – dùng danh sách dự phòng');
      _servers = [cloudflare, ...fallback];
    } finally {
      c.close(force: true);
    }
    return _servers!;
  }

  bool _stop = false;
  void stop() => _stop = true;

  final void Function(SpeedPhase phase, double? live, SpeedResult r) onUpdate;
  YomiSpeedTest(this.onUpdate);

  Future<double?> _pingOnce(HttpClient c, YomiSpeedServer s) async {
    final sw = Stopwatch()..start();
    try {
      final req = await c.getUrl(s.pingUri());
      req.headers.set('cache-control', 'no-cache');
      final res = await req.close().timeout(const Duration(seconds: 5));
      await res.drain<void>();
      return sw.elapsedMicroseconds / 1000.0;
    } catch (_) {
      return null;
    }
  }

  /// Picks the server with the lowest ping among [candidates].
  Future<YomiSpeedServer> pickBest(List<YomiSpeedServer> candidates) async {
    final c = _client();
    try {
      final results = await Future.wait(candidates.map((s) async {
        await _pingOnce(c, s); // warm-up (DNS + TLS)
        final p = await _pingOnce(c, s);
        return (s, p ?? double.infinity);
      }));
      results.sort((a, b) => a.$2.compareTo(b.$2));
      return results.first.$2.isFinite ? results.first.$1 : cloudflare;
    } finally {
      c.close(force: true);
    }
  }

  Future<SpeedResult> run(YomiSpeedServer? server, {Duration each = const Duration(seconds: 10)}) async {
    _stop = false;
    final r = SpeedResult();
    final c = _client()..maxConnectionsPerHost = 8;
    try {
      onUpdate(SpeedPhase.selecting, null, r);
      var s = server;
      if (s == null) {
        final all = await servers();
        s = await pickBest(all.take(12).toList());
      }
      r.server = s.name;

      // IP / ISP
      try {
        final req = await c.getUrl(s.ipUri());
        final res = await req.close().timeout(const Duration(seconds: 6));
        final body = await res.transform(utf8.decoder).join();
        final j = jsonDecode(body);
        if (j is Map) {
          r.ip = '${j['processedString'] ?? j['clientIp'] ?? ''}'.split(' - ').first;
          final raw = j['rawIspInfo'];
          r.isp = s.cloudflare
              ? [j['asOrganization'], j['city'], j['country']].whereType<String>().join(', ')
              : (raw is Map ? '${raw['org'] ?? ''}' : '${j['processedString'] ?? ''}'.split(' - ').skip(1).join(' - '));
        }
      } catch (_) {}

      // ping + jitter
      onUpdate(SpeedPhase.ping, null, r);
      final pings = <double>[];
      await _pingOnce(c, s);
      for (var i = 0; i < 10 && !_stop; i++) {
        final p = await _pingOnce(c, s);
        if (p != null) {
          pings.add(p);
          onUpdate(SpeedPhase.ping, p, r);
        }
      }
      if (pings.isEmpty) throw 'máy chủ không phản hồi (ping)';
      r.pingMs = pings.reduce(min);
      var j = 0.0;
      for (var i = 1; i < pings.length; i++) {
        j += (pings[i] - pings[i - 1]).abs();
      }
      r.jitterMs = pings.length > 1 ? j / (pings.length - 1) : 0;

      // download
      if (!_stop) r.downMbps = await _transfer(c, s, true, each, r);
      // upload
      if (!_stop) r.upMbps = await _transfer(c, s, false, each, r);
      onUpdate(_stop ? SpeedPhase.idle : SpeedPhase.done, null, r);
      return r;
    } catch (e) {
      AppLogger.log('SpeedTest (${r.server ?? '?'}): $e', logLevel: LogLevel.warning);
      onUpdate(SpeedPhase.error, null, r);
      rethrow;
    } finally {
      c.close(force: true);
    }
  }

  Future<double> _transfer(HttpClient c, YomiSpeedServer s, bool down, Duration each, SpeedResult r) async {
    final phase = down ? SpeedPhase.download : SpeedPhase.upload;
    var bytes = 0;
    var counted = 0; // bytes after the grace period
    final sw = Stopwatch()..start();
    const grace = Duration(milliseconds: 1500);
    final end = each + grace;
    var graceBytes = -1;
    final payload = Uint8List(256 * 1024);
    final rnd = Random();
    for (var i = 0; i < payload.length; i += 4) {
      payload[i] = rnd.nextInt(256);
    }

    Future<void> worker(int n) async {
      await Future.delayed(Duration(milliseconds: 150 * n));
      while (!_stop && sw.elapsed < end) {
        try {
          if (down) {
            final req = await c.getUrl(s.downloadUri());
            req.headers.set('cache-control', 'no-cache');
            final res = await req.close();
            await for (final chunk in res) {
              bytes += chunk.length;
              if (_stop || sw.elapsed >= end) break;
            }
          } else {
            final req = await c.postUrl(s.uploadUri());
            req.headers.contentType = ContentType.binary;
            req.contentLength = payload.length * 16;
            for (var k = 0; k < 16 && !_stop && sw.elapsed < end; k++) {
              req.add(payload);
              await req.flush();
              bytes += payload.length;
            }
            if (_stop || sw.elapsed >= end) {
              req.abort();
              break;
            }
            final res = await req.close();
            await res.drain<void>();
          }
        } catch (_) {
          await Future.delayed(const Duration(milliseconds: 200));
        }
      }
    }

    final ticker = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (sw.elapsed >= grace && graceBytes < 0) graceBytes = bytes;
      final t = sw.elapsedMilliseconds / 1000.0;
      if (t > 0) {
        final live = graceBytes >= 0 && sw.elapsed > grace
            ? (bytes - graceBytes) * 8 / ((sw.elapsed - grace).inMilliseconds / 1000.0) / 1e6
            : bytes * 8 / t / 1e6;
        if (down) {
          r.downMbps = live;
        } else {
          r.upMbps = live;
        }
        onUpdate(phase, live, r);
      }
    });
    await Future.wait(List.generate(down ? 4 : 3, worker));
    ticker.cancel();
    if (graceBytes < 0) graceBytes = 0;
    counted = bytes - graceBytes;
    final secs = max(0.5, (sw.elapsed - grace).inMilliseconds / 1000.0);
    return counted * 8 / secs / 1e6;
  }
}
