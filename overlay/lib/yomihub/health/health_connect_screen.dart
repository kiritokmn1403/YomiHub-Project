import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mangayomi/yomihub/health/health_connect_service.dart';
import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';
import 'package:mangayomi/yomihub/ui/liquid_glass.dart';

class HealthConnectScreen extends StatefulWidget {
  const HealthConnectScreen({super.key});

  @override
  State<HealthConnectScreen> createState() => _HealthConnectScreenState();
}

class _HealthConnectScreenState extends State<HealthConnectScreen> {
  final _service = HealthConnectService.instance;
  late bool _enabled;
  late bool _autoSync;
  late bool _eyeCare;
  late int _reminderInterval;
  late int _goalMinutes;
  bool _isAvailable = false;
  Map<String, dynamic> _hc = const {};

  @override
  void initState() {
    super.initState();
    _enabled = _service.isEnabled;
    _autoSync = _service.autoSync;
    _eyeCare = _service.eyeCareReminder;
    _reminderInterval = _service.reminderIntervalMinutes;
    _goalMinutes = _service.dailyGoalMinutes;

    if (Platform.isAndroid) {
      _refreshHc();
    }
  }

  Future<void> _refreshHc() async {
    final v = await _service.isHealthConnectAvailable();
    final st = await _service.status();
    if (mounted) setState(() { _isAvailable = v; _hc = st; });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final readingMin = _service.todayReadingMinutes;
    final watchingMin = _service.todayWatchingMinutes;
    final totalMin = readingMin + watchingMin;
    final progress = _goalMinutes > 0 ? (totalMin / _goalMinutes).clamp(0.0, 1.0) : 0.0;

    final body = SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner thông tin
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  cs.primary.withValues(alpha: 0.15),
                  cs.secondary.withValues(alpha: 0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: cs.primary.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.favorite_rounded, color: cs.primary, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('Chăm sóc sức khỏe & Health Connect'),
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tr('Theo dõi thời lượng đọc/xem lành mạnh, nhắc nhở bảo vệ mắt và đồng bộ với Android Health Connect.'),
                        style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Thống kê hôm nay
          Text(
            tr('Thống kê hôm nay'),
            style: theme.textTheme.titleSmall?.copyWith(color: cs.primary, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatColumn(
                        icon: Icons.menu_book_rounded,
                        color: Colors.blueAccent,
                        title: tr('Đọc truyện'),
                        value: '$readingMin ${tr('phút')}',
                      ),
                      Container(height: 40, width: 1, color: cs.outlineVariant.withValues(alpha: 0.5)),
                      _buildStatColumn(
                        icon: Icons.movie_outlined,
                        color: Colors.purpleAccent,
                        title: tr('Xem phim'),
                        value: '$watchingMin ${tr('phút')}',
                      ),
                      Container(height: 40, width: 1, color: cs.outlineVariant.withValues(alpha: 0.5)),
                      _buildStatColumn(
                        icon: Icons.timer_outlined,
                        color: cs.primary,
                        title: tr('Tổng cộng'),
                        value: '$totalMin ${tr('phút')}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        tr('Mục tiêu hàng ngày ({p0} phút)', {'p0': _goalMinutes}),
                        style: theme.textTheme.bodySmall,
                      ),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, color: cs.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: cs.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        progress >= 1.0 ? Colors.orange : cs.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Tùy chọn cài đặt
          Text(
            tr('Cài đặt & Đồng bộ'),
            style: theme.textTheme.titleSmall?.copyWith(color: cs.primary, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: Text(tr('Kích hoạt Health Connect')),
                  subtitle: Text(tr('Ghi nhận dữ liệu nghỉ ngơi và đồng bộ với nền tảng sức khỏe hệ điều hành')),
                  value: _enabled,
                  onChanged: (v) {
                    setState(() => _enabled = v);
                    _service.isEnabled = v;
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: Text(tr('Nhắc nhở bảo vệ mắt (Quy tắc 20-20-20)')),
                  subtitle: Text(tr('Thông báo tạm dừng để nhìn xa sau một khoảng thời gian đọc/xem liên tục')),
                  value: _eyeCare,
                  onChanged: (v) {
                    setState(() => _eyeCare = v);
                    _service.eyeCareReminder = v;
                  },
                ),
                if (_eyeCare) ...[
                  const Divider(height: 1),
                  ListTile(
                    title: Text(tr('Khoảng thời gian nhắc nhở')),
                    subtitle: Text(tr('Nhắc sau mỗi {p0} phút đọc/xem liên tục', {'p0': _reminderInterval})),
                    trailing: DropdownButton<int>(
                      value: _reminderInterval,
                      underline: const SizedBox.shrink(),
                      items: const [
                        DropdownMenuItem(value: 20, child: Text('20 phút')),
                        DropdownMenuItem(value: 30, child: Text('30 phút')),
                        DropdownMenuItem(value: 45, child: Text('45 phút')),
                        DropdownMenuItem(value: 60, child: Text('60 phút')),
                      ],
                      onChanged: (v) {
                        if (v != null) {
                          setState(() => _reminderInterval = v);
                          _service.reminderIntervalMinutes = v;
                        }
                      },
                    ),
                  ),
                ],
                const Divider(height: 1),
                ListTile(
                  title: Text(tr('Mục tiêu thời gian trong ngày')),
                  subtitle: Text(tr('Giới hạn lành mạnh: {p0} phút/ngày', {'p0': _goalMinutes})),
                  trailing: DropdownButton<int>(
                    value: _goalMinutes,
                    underline: const SizedBox.shrink(),
                    items: const [
                      DropdownMenuItem(value: 60, child: Text('60 phút')),
                      DropdownMenuItem(value: 90, child: Text('90 phút')),
                      DropdownMenuItem(value: 120, child: Text('120 phút')),
                      DropdownMenuItem(value: 180, child: Text('180 phút')),
                      DropdownMenuItem(value: 240, child: Text('240 phút')),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => _goalMinutes = v);
                        _service.dailyGoalMinutes = v;
                      }
                    },
                  ),
                ),
                if (Platform.isAndroid) ...[
                  const Divider(height: 1),
                  SwitchListTile(
                    title: Text(tr('Tự động đồng bộ ngầm')),
                    subtitle: Text(tr('Gửi phiên giải trí lành mạnh sang Health Connect khi thoát màn hình')),
                    value: _autoSync,
                    onChanged: (v) {
                      setState(() => _autoSync = v);
                      _service.autoSync = v;
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.settings_system_daydream_rounded),
                    title: Text(tr('Cài đặt hệ thống Health Connect')),
                    subtitle: Text(
                      _isAvailable
                          ? tr('Health Connect đã sẵn sàng trên thiết bị')
                          : tr('Mở trang cài đặt hoặc tải từ Google Play Store'),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _service.openHealthConnectSettings(),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(_hc['granted'] == true ? Icons.verified_user_rounded : Icons.lock_open_rounded),
                    title: Text(tr('Quyền ghi phiên "Chánh niệm"')),
                    subtitle: Text(_hc['canWrite'] != true
                        ? tr('Thiết bị này chưa hỗ trợ ghi phiên (cần Android 14 trở lên với Health Connect bản mới). Thời gian đọc/xem vẫn được tính trong YomiHub.')
                        : (_hc['granted'] == true
                            ? tr('Đã cấp quyền – thời gian đọc/xem được ghi vào Health Connect')
                            : tr('Chạm để cấp quyền cho YomiHub'))),
                    onTap: _hc['canWrite'] == true && _hc['granted'] != true
                        ? () async {
                            await _service.requestPermission();
                            await Future.delayed(const Duration(seconds: 2));
                            await _refreshHc();
                          }
                        : null,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Health Connect')),
      ),
      body: Consumer(
        builder: (context, ref, _) {
          final g = ref.watch(liquidGlassProvider);
          if (g.enabled) {
            return LiquidGlassBackdrop(child: body);
          }
          return body;
        },
      ),
    );
  }

  Widget _buildStatColumn({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 6),
        Text(title, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 2),
        Text(value, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
