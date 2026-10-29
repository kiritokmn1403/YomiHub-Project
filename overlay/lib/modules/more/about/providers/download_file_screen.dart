import 'package:mangayomi/yomihub/update/update_cleanup.dart';
import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';

import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:mangayomi/providers/l10n_providers.dart';
import 'package:mangayomi/utils/platform_utils.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mangayomi/yomihub/update/drive_update.dart';

class DownloadFileScreen extends ConsumerStatefulWidget {
  final (String, String, String, List<dynamic>) updateAvailable;
  const DownloadFileScreen({required this.updateAvailable, super.key});

  @override
  ConsumerState<DownloadFileScreen> createState() => _DownloadFileScreenState();
}

class _DownloadFileScreenState extends ConsumerState<DownloadFileScreen> {
  int _total = 0;
  int _received = 0;
  bool _isDownloading = false;
  bool _isInstalling = false;
  String? _errorMessage;
  String _currentVersion = '';

  http.StreamedResponse? _response;
  StreamSubscription<List<int>>? _subscription;
  final ScrollController _changelogScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadCurrentVersion();
  }

  Future<void> _loadCurrentVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _currentVersion = info.version;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _changelogScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = l10nLocalizations(context)!;
    final updateAvailable = widget.updateAvailable;
    final targetVersion = updateAvailable.$1;
    final changelog = updateAvailable.$2;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 6,
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Header (Icon + Title + Version Badges)
              _buildHeader(context, colorScheme, theme, l10n, targetVersion),
              const SizedBox(height: 18),

              // 2. Changelog / Release Notes Box
              _buildChangelogBox(context, colorScheme, theme, changelog),
              const SizedBox(height: 18),

              // 3. Progress or Error Section
              if (_isDownloading) ...[
                _buildProgressCard(context, colorScheme, theme),
                const SizedBox(height: 18),
              ] else if (_errorMessage != null) ...[
                _buildErrorBanner(context, colorScheme, theme),
                const SizedBox(height: 18),
              ],

              // 4. Action Buttons
              _buildActions(context, colorScheme, l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ColorScheme colorScheme,
    ThemeData theme,
    dynamic l10n,
    String targetVersion,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.system_update_rounded,
            color: colorScheme.primary,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.new_update_available,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (_currentVersion.isNotEmpty) ...[
                    Text(
                      'v$_currentVersion',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 13,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'v$targetVersion',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChangelogBox(
    BuildContext context,
    ColorScheme colorScheme,
    ThemeData theme,
    String changelog,
  ) {
    final cleanNotes = _cleanChangelog(changelog);
    return Flexible(
      child: Container(
        constraints: const BoxConstraints(maxHeight: 220),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        padding: const EdgeInsets.all(14),
        child: Scrollbar(
          controller: _changelogScrollController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _changelogScrollController,
            child: SelectableText(
              cleanNotes.isEmpty
                  ? 'Aucune note de version fournie.'
                  : cleanNotes,
              style: theme.textTheme.bodySmall?.copyWith(
                height: 1.45,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressCard(
    BuildContext context,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    final progress = _total > 0 ? (_received / _total).clamp(0.0, 1.0) : 0.0;
    final percentText = _total > 0
        ? '${(progress * 100).toStringAsFixed(0)}%'
        : '';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                (_total > 0 ? percentText : ''),
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSecondaryContainer,
                ),
              ),
              if (_total > 0 && !_isInstalling)
                Text(
                  '${(_received / 1048576.0).toStringAsFixed(1)} / ${(_total / 1048576.0).toStringAsFixed(1)} MB',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSecondaryContainer.withValues(
                      alpha: 0.8,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _isInstalling ? null : (_total > 0 ? progress : null),
              minHeight: 8,
              backgroundColor: colorScheme.surfaceContainerHighest,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(
    BuildContext context,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: colorScheme.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage ?? '',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(
    BuildContext context,
    ColorScheme colorScheme,
    dynamic l10n,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () async {
            if (_isDownloading) {
              try {
                await _subscription?.cancel();
              } catch (_) {}
            }
            if (context.mounted) {
              Navigator.pop(context);
            }
          },
          child: Text(l10n.cancel),
        ),
        const SizedBox(width: 10),
        if (!_isDownloading)
          FilledButton.icon(
            icon: Icon(
              Platform.isAndroid
                  ? Icons.download_rounded
                  : Icons.open_in_browser_rounded,
              size: 18,
            ),
            label: Text(Platform.isAndroid ? l10n.download : (l10n.download)),
            onPressed: () => _handleDownloadOrOpen(widget.updateAvailable),
          ),
      ],
    );
  }

  String _cleanChangelog(String raw) {
    final lines = raw.split('\n');
    final formatted = <String>[];
    for (var line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('**Full Changelog**') ||
          trimmed.startsWith('Full Changelog:')) {
        continue;
      }
      formatted.add(line);
    }
    return formatted.join('\n').trim();
  }

  Future<void> _handleDownloadOrOpen(
    (String, String, String, List<dynamic>) updateAvailable,
  ) async {
    if (Platform.isAndroid) {
      setState(() {
        _isDownloading = true;
        _errorMessage = null;
      });

      try {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        String apkUrl = '';
        final apks = updateAvailable.$4
            .whereType<String>()
            .where((apk) => apk.toLowerCase().endsWith('.apk'))
            .toList();

        final filteredApks = isTv
            ? apks
                  .where((apk) => apk.toLowerCase().contains('android-tv'))
                  .toList()
            : apks
                  .where((apk) => !apk.toLowerCase().contains('android-tv'))
                  .toList();

        final candidateApks = filteredApks.isNotEmpty ? filteredApks : apks;

        for (String abi in androidInfo.supportedAbis) {
          for (final apk in candidateApks) {
            if (apk.toLowerCase().contains(abi.toLowerCase())) {
              apkUrl = apk;
              break;
            }
          }
          if (apkUrl.isNotEmpty) break;
        }
        if (apkUrl.isEmpty && candidateApks.isNotEmpty) {
          apkUrl = candidateApks.first;
        }

        if (apkUrl.isNotEmpty) {
          await _downloadApk(apkUrl);
        } else {
          await _launchInBrowser(Uri.parse(updateAvailable.$3));
          if (mounted) {
            Navigator.pop(context);
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isDownloading = false;
            _errorMessage = tr('Tải xuống thất bại: {p0}', {'p0': e});
          });
        }
      }
    } else if (Platform.isWindows) {
      await _downloadAndInstallWindowsUpdate(updateAvailable);
    } else {
      await _launchInBrowser(Uri.parse(updateAvailable.$3));
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  Future<void> _downloadAndInstallWindowsUpdate(
    (String, String, String, List<dynamic>) updateAvailable,
  ) async {
    setState(() {
      _isDownloading = true;
      _errorMessage = null;
    });

    try {
      final assets = updateAvailable.$4.whereType<String>().toList();
      String winUrl = '';
      for (final a in assets) {
        final lower = YomiDriveUpdate.fileName(a).toLowerCase();
        if (lower.endsWith('.appxbundle') ||
            lower.endsWith('.msix') ||
            lower.endsWith('.exe')) {
          winUrl = a;
          break;
        }
      }
      if (winUrl.isEmpty) {
        for (final a in assets) {
          final lower = YomiDriveUpdate.fileName(a).toLowerCase();
          if (lower.contains('windows') && lower.endsWith('.zip')) {
            winUrl = a;
            break;
          }
        }
      }
      if (winUrl.isEmpty && assets.isNotEmpty) {
        winUrl = assets.firstWhere(
          (a) =>
              a.toLowerCase().contains('win') ||
              a.toLowerCase().endsWith('.zip'),
          orElse: () => '',
        );
      }

      if (winUrl.isEmpty) {
        await _launchInBrowser(Uri.parse(updateAvailable.$3));
        if (mounted) Navigator.pop(context);
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final name = YomiDriveUpdate.fileName(winUrl);
      final destFile = File(
        p.join(tempDir.path, name.isEmpty ? 'YomiHub-Update.exe' : name),
      );
      final partFile = File('${destFile.path}.part');

      if (await destFile.exists() &&
          await destFile.length() > 5 * 1024 * 1024) {
        setState(() => _isInstalling = true);
        await _runWindowsInstaller(destFile);
        if (mounted) Navigator.pop(context);
        return;
      }

      final sink = partFile.openWrite();
      _response = await http.Client().send(
        http.Request('GET', Uri.parse(winUrl)),
      );
      if (_response!.statusCode != 200) {
        throw Exception('HTTP ${_response!.statusCode}');
      }
      _total = _response!.contentLength ?? 0;
      _received = 0;
      _subscription = _response!.stream.listen(
        (chunk) {
          sink.add(chunk);
          _received += chunk.length;
          if (mounted) setState(() {});
        },
        onDone: () async {
          await sink.flush();
          await sink.close();
          if (await destFile.exists()) await destFile.delete();
          await partFile.rename(destFile.path);
          if (mounted) {
            setState(() => _isInstalling = true);
            await _runWindowsInstaller(destFile);
            if (mounted) Navigator.pop(context);
          }
        },
        onError: (e) async {
          await sink.close();
          if (await partFile.exists()) await partFile.delete();
          if (mounted) {
            setState(() {
              _isDownloading = false;
              _errorMessage = tr('Lỗi tải bản cập nhật: {p0}', {'p0': e});
            });
          }
        },
        cancelOnError: true,
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _errorMessage = tr('Tải xuống thất bại: {p0}', {'p0': e});
        });
      }
    }
  }

  Future<void> _runWindowsInstaller(File installerFile) async {
    final path = installerFile.path;
    final lower = path.toLowerCase();
    if (lower.endsWith('.appxbundle') ||
        lower.endsWith('.msix') ||
        lower.endsWith('.appx')) {
      await Process.start('powershell', [
        '-NoProfile',
        '-ExecutionPolicy',
        'Bypass',
        '-Command',
        'Add-AppxPackage -Path "$path"',
      ]);
    } else if (lower.endsWith('.exe')) {
      await Process.start(path, []);
    } else if (lower.endsWith('.zip')) {
      final tempDir = installerFile.parent.path;
      final currentExe = Platform.resolvedExecutable;
      final currentDir = p.dirname(currentExe);
      final batFile = File(p.join(tempDir, 'yomihub_update.bat'));
      await batFile.writeAsString('''
@echo off
timeout /t 2 /nobreak > NUL
tar -xf "$path" -C "$currentDir"
start "" "$currentExe"
exit
''');
      await Process.start('cmd.exe', ['/c', batFile.path]);
      exit(0);
    }
  }

  /// YomiHub 0.1.6: streams the APK straight to disk (0.1.5 kept the whole
  /// 160 MB file in a List<int> – several times that in RAM – and could be
  /// killed on low-memory phones), names it from the Drive link and resumes
  /// nothing half-written: a .part file is renamed only when complete.
  Future<void> _downloadApk(String url) async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      await Permission.storage.request();
    }
    Directory? dir = Directory('/storage/emulated/0/Download');
    if (!await dir.exists()) dir = await getExternalStorageDirectory();
    final name = YomiDriveUpdate.fileName(url);
    final file = File('${dir!.path}/${name.isEmpty ? "YomiHub.apk" : name}');
    if (await file.exists() && await file.length() > 1024 * 1024) {
      setState(() {
        _isInstalling = true;
      });
      await _installApk(file);
      if (mounted) {
        Navigator.pop(context);
      }
      return;
    }
    final part = File('${file.path}.part');
    final sink = part.openWrite();
    _response = await http.Client().send(http.Request('GET', Uri.parse(url)));
    final ct = _response?.headers['content-type'] ?? '';
    if ((_response?.statusCode ?? 0) != 200 || ct.contains('text/html')) {
      await sink.close();
      if (await part.exists()) await part.delete();
      // Drive answered with a page (quota / sign-in): open it in the browser.
      await _launchInBrowser(Uri.parse(url));
      if (mounted) Navigator.pop(context);
      return;
    }
    setState(() {
      _total = _response?.contentLength ?? 0;
    });
    _subscription = _response?.stream.listen(
      (value) {
        sink.add(value);
        setState(() {
          _received += value.length;
        });
      },
      onError: (e) async {
        await sink.close();
        if (mounted) {
          setState(() {
            _isDownloading = false;
            _errorMessage = tr('Lỗi mạng khi tải bản cập nhật.');
          });
        }
      },
      cancelOnError: true,
    );
    _subscription?.onDone(() async {
      try {
        await sink.flush();
        await sink.close();
        if (mounted) {
          setState(() {
            _isInstalling = true;
          });
        }
        if (await file.exists()) await file.delete();
        await part.rename(file.path);
        await _installApk(file);
        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isDownloading = false;
            _isInstalling = false;
            _errorMessage = tr('Lỗi khi ghi tệp APK.');
          });
        }
      }
    });
  }

  Future<void> _installApk(File file) async {
    // YomiHub 0.1.9: deleted at the next launch once installed
    await YomiUpdateCleanup.remember(file);
    var status = await Permission.requestInstallPackages.status;
    if (!status.isGranted) {
      await Permission.requestInstallPackages.request();
    }
    await ApkInstaller.installApk(file.path);
  }

  Future<void> _launchInBrowser(Uri url) async {
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }
}

class ApkInstaller {
  static const _platform = MethodChannel('com.kodjodevf.mangayomi.apk_install');
  static Future<void> installApk(String filePath) async {
    try {
      await _platform.invokeMethod('installApk', {'filePath': filePath});
    } catch (e) {
      if (kDebugMode) {
        log("Erreur d'installation : $e");
      }
    }
  }
}
