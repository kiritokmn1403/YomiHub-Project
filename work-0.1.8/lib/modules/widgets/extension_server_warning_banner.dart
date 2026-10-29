import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mangayomi/yomihub/mes/yomi_mes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mangayomi/modules/more/settings/browse/providers/browse_state_provider.dart';
import 'package:mangayomi/providers/l10n_providers.dart';
import 'package:mangayomi/utils/extensions/build_context_extensions.dart';
import 'package:mangayomi/utils/platform_utils.dart';

class ExtensionServerWarningBanner extends ConsumerWidget {
  const ExtensionServerWarningBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isDesktop) return const SizedBox.shrink();

    // YomiHub 0.1.7: Windows uses YomiMes (bundled / auto-installed
    // server, or ApkBridge) – only warn when there is no server at all and
    // the user hasn't switched to ApkBridge.
    if (Platform.isWindows) {
      return FutureBuilder<bool>(
        future: YomiMes.open().then(
          (_) async => !YomiMes.embedded ||
              await YomiMes.locateWindows(jre: YomiMes.configuredJre, jar: YomiMes.configuredJar),
        ),
        builder: (context, snap) =>
            (snap.data ?? true) ? const SizedBox.shrink() : _banner(context),
      );
    }

    final installedAsync = ref.watch(isExtensionServerInstalledStreamProvider);

    return installedAsync.when(
      data: (isInstalled) {
        if (isInstalled) return const SizedBox.shrink();
        return _banner(context);
      },
      error: (error, stackTrace) => const SizedBox.shrink(),
      loading: () => const SizedBox.shrink(),
    );
  }

  Widget _banner(BuildContext context) {
        final l10n = context.l10n;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.amber.withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.amber,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.android_proxy_server_mihon,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.extension_server_intro_with_jre,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.secondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => context.push('/extensionServer'),
                icon: const Icon(Icons.download_outlined, size: 18),
                label: Text(
                  l10n.download,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        );
  }
}
