import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';
import 'package:mangayomi/yomihub/prefs/yomi_prefs.dart';
import 'package:mangayomi/yomihub/speedtest/speedtest_engine.dart';

/// YomiHub 0.2.2: Cài đặt › SpeedTest (LibreSpeed).
class SpeedTestScreen extends StatefulWidget {
  const SpeedTestScreen({super.key});
  @override
  State<SpeedTestScreen> createState() => _SpeedTestScreenState();
}

class _SpeedTestScreenState extends State<SpeedTestScreen> {
  SpeedPhase _phase = SpeedPhase.idle;
  double? _live;
  SpeedResult _r = SpeedResult();
  YomiSpeedTest? _test;
  List<YomiSpeedServer> _servers = const [];
  YomiSpeedServer? _server; // null = automatic
  int _seconds = 10;
  List<SpeedResult> _history = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _seconds = YomiPrefs.get<int>('speedtestSeconds', 10);
    try {
      final raw = YomiPrefs.get<String>('speedtestHistory', '[]');
      _history = (jsonDecode(raw) as List).map((e) => SpeedResult.fromJson(e as Map)).toList();
    } catch (_) {}
    YomiSpeedTest.servers().then((l) {
      if (!mounted) return;
      final saved = YomiPrefs.get<String>('speedtestServer', '');
      setState(() {
        _servers = l;
        _server = l.where((s) => s.name == saved).firstOrNull;
      });
    });
  }

  @override
  void dispose() {
    _test?.stop();
    super.dispose();
  }

  bool get _running =>
      _phase == SpeedPhase.selecting ||
      _phase == SpeedPhase.ping ||
      _phase == SpeedPhase.download ||
      _phase == SpeedPhase.upload;

  Future<void> _start() async {
    setState(() {
      _error = null;
      _r = SpeedResult();
    });
    final t = YomiSpeedTest((phase, live, r) {
      if (!mounted) return;
      setState(() {
        _phase = phase;
        _live = live;
        _r = r;
      });
    });
    _test = t;
    try {
      final r = await t.run(_server, each: Duration(seconds: _seconds));
      if (r.downMbps != null && r.upMbps != null) {
        _history = [r, ..._history].take(20).toList();
        await YomiPrefs.set('speedtestHistory', jsonEncode(_history.map((e) => e.toJson()).toList()));
      }
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
    if (mounted) setState(() => _test = null);
  }

  String _phaseLabel() => switch (_phase) {
    SpeedPhase.idle => tr('Sẵn sàng'),
    SpeedPhase.selecting => tr('Đang chọn máy chủ…'),
    SpeedPhase.ping => 'Ping…',
    SpeedPhase.download => tr('Tải xuống…'),
    SpeedPhase.upload => tr('Tải lên…'),
    SpeedPhase.done => tr('Hoàn tất'),
    SpeedPhase.error => tr('Lỗi'),
  };

  String _fmt(double? v, [int d = 1]) => v == null ? '–' : v.toStringAsFixed(d);

  Widget _stat(String label, String value, String unit, IconData icon) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, size: 18, color: cs.primary),
              const SizedBox(height: 4),
              Text(label, style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 2),
              FittedBox(
                child: Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              ),
              Text(unit, style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final gaugeValue = _phase == SpeedPhase.ping ? _live : (_running ? _live : (_r.downMbps));
    final unit = _phase == SpeedPhase.ping ? 'ms' : 'Mbps';
    return Scaffold(
      appBar: AppBar(title: const Text('SpeedTest')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: SizedBox(
              width: 220,
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 220,
                    height: 220,
                    child: CircularProgressIndicator(
                      value: _running
                          ? (_phase == SpeedPhase.ping || gaugeValue == null
                                ? null
                                : min(1.0, log(1 + gaugeValue) / log(1 + 1000)))
                          : 0,
                      strokeWidth: 10,
                      backgroundColor: cs.surfaceContainerHighest,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_fmt(gaugeValue), style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold)),
                      Text(unit),
                      const SizedBox(height: 6),
                      Text(_phaseLabel(), style: TextStyle(color: cs.primary)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _stat('Ping', _fmt(_r.pingMs, 0), 'ms', Icons.network_ping),
              _stat('Jitter', _fmt(_r.jitterMs, 0), 'ms', Icons.swap_vert),
            ],
          ),
          Row(
            children: [
              _stat(tr('Tải xuống'), _fmt(_r.downMbps), 'Mbps', Icons.download),
              _stat(tr('Tải lên'), _fmt(_r.upMbps), 'Mbps', Icons.upload),
            ],
          ),
          if (_r.server != null || _r.ip != null)
            ListTile(
              dense: true,
              leading: const Icon(Icons.dns_outlined),
              title: Text(_r.server ?? ''),
              subtitle: Text([_r.ip, _r.isp].whereType<String>().where((e) => e.isNotEmpty).join(' • ')),
            ),
          if (_error != null)
            ListTile(
              dense: true,
              leading: Icon(Icons.error_outline, color: cs.error),
              title: Text(tr('Không đo được: {p0}', {'p0': _error})),
            ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _running ? () => _test?.stop() : _start,
            icon: Icon(_running ? Icons.stop : Icons.speed),
            label: Text(_running ? tr('Dừng') : tr('Bắt đầu đo')),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _server?.name ?? '',
            isExpanded: true,
            decoration: InputDecoration(labelText: tr('Máy chủ'), border: const OutlineInputBorder()),
            items: [
              DropdownMenuItem(value: '', child: Text(tr('Tự động (ping thấp nhất)'))),
              for (final s in _servers) DropdownMenuItem(value: s.name, child: Text(s.name, overflow: TextOverflow.ellipsis)),
            ],
            onChanged: _running
                ? null
                : (v) {
                    setState(() => _server = _servers.where((s) => s.name == v).firstOrNull);
                    YomiPrefs.set('speedtestServer', v ?? '');
                  },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(tr('Thời gian mỗi bước: {p0} giây', {'p0': _seconds})),
              Expanded(
                child: Slider(
                  value: _seconds.toDouble(),
                  min: 5,
                  max: 20,
                  divisions: 3,
                  onChanged: _running
                      ? null
                      : (v) {
                          setState(() => _seconds = v.round());
                          YomiPrefs.set('speedtestSeconds', _seconds);
                        },
                ),
              ),
            ],
          ),
          if (_history.isNotEmpty) ...[
            const Divider(),
            Row(
              children: [
                Text(tr('Lịch sử'), style: TextStyle(color: cs.primary, fontWeight: FontWeight.bold)),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setState(() => _history = []);
                    YomiPrefs.set('speedtestHistory', '[]');
                  },
                  child: Text(tr('Xoá')),
                ),
              ],
            ),
            for (final h in _history)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.history),
                title: Text('↓ ${_fmt(h.downMbps)}  ↑ ${_fmt(h.upMbps)} Mbps • ${_fmt(h.pingMs, 0)} ms'),
                subtitle: Text('${h.at.toLocal().toString().substring(0, 16)} • ${h.server ?? ''}'),
              ),
          ],
          const SizedBox(height: 8),
          Text(
            tr('Dựa trên LibreSpeed (github.com/librespeed/speedtest). Kết quả bị ảnh hưởng khi VPN / Tor đang bật.'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
