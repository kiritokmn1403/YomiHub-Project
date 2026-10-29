import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mangayomi/modules/more/settings/general/providers/doh_provider_notifier.dart';
import 'package:mangayomi/modules/more/settings/general/providers/general_state_provider.dart';
import 'package:mangayomi/services/http/doh/doh_custom_store.dart';
import 'package:mangayomi/services/http/doh/doh_providers.dart';

/// YomiHub 0.1.5: "VPN & DNS › DNS" – DNS-over-HTTPS and the DNS provider,
/// moved here from Settings › General.
class YomiDnsSection extends ConsumerWidget {
  const YomiDnsSection({super.key});

  static const _plainPresets = <String, String>{
    '1.1.1.1': 'Cloudflare',
    '8.8.8.8': 'Google',
    '9.9.9.9': 'Quad9',
    '94.140.14.14': 'AdGuard (chặn quảng cáo)',
    '208.67.222.222': 'OpenDNS',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final doh = ref.watch(doHProviderStateProvider);
    final providers = ref.watch(availableDoHProvidersProvider);
    final customDns = ref.watch(customDnsStateProvider);
    final providerName = doh.providerId == DoHProviders.customId
        ? (DohCustomStore.url.trim().isEmpty
              ? tr('Tuỳ chỉnh')
              : tr('Tuỳ chỉnh · {p0}', {'p0': DohCustomStore.url.trim()}))
        : (DoHProviders.byId[doh.providerId ?? 0]?.name ??
              DoHProviders.cloudflare.name);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          secondary: const Icon(Icons.dns_outlined),
          title: const Text('DNS-over-HTTPS (DoH)'),
          subtitle: Text(
            tr('Mã hoá truy vấn tên miền của tiện ích, ảnh và tải xuống – tránh bị nhà mạng chặn/đổi DNS.'),
          ),
          value: doh.enabled,
          onChanged: (v) =>
              ref.read(doHProviderStateProvider.notifier).setDoHEnabled(v),
        ),
        ListTile(
          leading: const Icon(Icons.cloud_queue),
          enabled: doh.enabled,
          title: Text(tr('Nhà cung cấp DNS')),
          subtitle: Text(providerName),
          onTap: () async {
            final picked = await showDialog<int>(
              context: context,
              builder: (ctx) => SimpleDialog(
                title: Text(tr('Nhà cung cấp DNS')),
                children: [
                  for (final p in providers)
                    _choice(ctx, p.id, p.name, doh.providerId ?? 0),
                  _choice(
                    ctx,
                    DoHProviders.customId,
                    tr('Tuỳ chỉnh (URL DoH của bạn)'),
                    doh.providerId ?? 0,
                  ),
                ],
              ),
            );
            if (picked == null || !context.mounted) return;
            if (picked == DoHProviders.customId) {
              final url = await _ask(
                context,
                tr('URL DoH tuỳ chỉnh'),
                DohCustomStore.url,
                'https://example.com/dns-query',
                validator: (v) {
                  final u = Uri.tryParse(v.trim());
                  return u != null && u.scheme == 'https' && u.host.isNotEmpty
                      ? null
                      : tr('Phải là địa chỉ https (DoH dạng JSON)');
                },
              );
              if (url != null) {
                ref
                    .read(doHProviderStateProvider.notifier)
                    .setCustomDoH(url.trim());
              }
            } else {
              ref.read(doHProviderStateProvider.notifier).setDoHProvider(picked);
            }
          },
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.router_outlined),
          enabled: !doh.enabled,
          title: Text(tr('DNS thường (khi tắt DoH)')),
          subtitle: Text(
            customDns.isEmpty
                ? tr('Theo mạng hiện tại')
                : '$customDns${_plainPresets[customDns] == null ? '' : ' · ${tr(_plainPresets[customDns]!)}'}',
          ),
          onTap: () async {
            final v = await showDialog<String>(
              context: context,
              builder: (ctx) => SimpleDialog(
                title: Text(tr('DNS thường')),
                children: [
                  _textChoice(ctx, '', tr('Theo mạng hiện tại'), customDns),
                  for (final e in _plainPresets.entries)
                    _textChoice(ctx, e.key, '${tr(e.value)} – ${e.key}', customDns),
                  SimpleDialogOption(
                    onPressed: () => Navigator.pop(ctx, '\u0000'),
                    child: Text(tr('Nhập địa chỉ khác…')),
                  ),
                ],
              ),
            );
            if (v == null || !context.mounted) return;
            var dns = v;
            if (v == '\u0000') {
              final typed = await _ask(
                context,
                tr('Địa chỉ DNS'),
                customDns,
                '8.8.8.8',
              );
              if (typed == null) return;
              dns = typed.trim();
            }
            ref.read(customDnsStateProvider.notifier).set(dns);
          },
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Text(
            tr('DNS áp dụng cho kết nối của YomiHub. Khi một dịch vụ VPN đang bật, WARP dùng DNS 1.1.1.1 của Cloudflare, còn OpenVPN/WireGuard dùng DNS do máy chủ VPN cấp.'),
            style: theme.textTheme.bodySmall,
          ),
        ),
      ],
    );
  }

  Widget _choice(BuildContext ctx, int id, String name, int current) =>
      SimpleDialogOption(
        onPressed: () => Navigator.pop(ctx, id),
        child: Row(
          children: [
            Expanded(child: Text(name)),
            if (id == current) const Icon(Icons.check, size: 18),
          ],
        ),
      );

  Widget _textChoice(BuildContext ctx, String v, String name, String current) =>
      SimpleDialogOption(
        onPressed: () => Navigator.pop(ctx, v),
        child: Row(
          children: [
            Expanded(child: Text(name)),
            if (v == current) const Icon(Icons.check, size: 18),
          ],
        ),
      );

  static Future<String?> _ask(
    BuildContext context,
    String title,
    String initial,
    String hint, {
    String? Function(String)? validator,
  }) {
    final c = TextEditingController(text: initial);
    String? err;
    return showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: Text(title),
          content: TextField(
            controller: c,
            autofocus: true,
            keyboardType: TextInputType.url,
            decoration: InputDecoration(
              hintText: hint,
              errorText: err,
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(tr('Huỷ')),
            ),
            FilledButton(
              onPressed: () {
                final e = validator?.call(c.text);
                if (e != null) {
                  set(() => err = e);
                  return;
                }
                Navigator.pop(ctx, c.text);
              },
              child: Text(tr('Lưu')),
            ),
          ],
        ),
      ),
    );
  }
}
