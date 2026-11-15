from ed import *
C='lib/modules/widgets/cover_view_widget.dart'
sub(C,"import 'package:mangayomi/utils/platform_utils.dart';\n",
"import 'package:mangayomi/utils/platform_utils.dart';\nimport 'package:mangayomi/yomihub/prefs/yomi_prefs.dart';\nimport 'package:mangayomi/yomihub/ui/shiori/shiori_tokens.dart';\nimport 'package:mangayomi/yomihub/ui/ui_style.dart';\n")
sub(C,"    FocusManager.instance.addHighlightModeListener(_onHighlightModeChanged);\n  }\n",
"    FocusManager.instance.addHighlightModeListener(_onHighlightModeChanged);\n    _modern = _isModernCover;\n    YomiPrefs.changes.addListener(_onUiStyleChanged);\n  }\n\n  // YomiHub 0.5.7 (U11): Shiori look only for the \"Moi\" UI style and never on\n  // Android TV; the classic card is untouched.\n  bool _modern = false;\n  static bool get _isModernCover => !isTv && YomiUi.isModern;\n\n  void _onUiStyleChanged() {\n    final m = _isModernCover;\n    if (mounted && m != _modern) setState(() => _modern = m);\n  }\n")
sub(C,"    FocusManager.instance.removeHighlightModeListener(_onHighlightModeChanged);\n    super.dispose();",
"    FocusManager.instance.removeHighlightModeListener(_onHighlightModeChanged);\n    YomiPrefs.changes.removeListener(_onUiStyleChanged);\n    super.dispose();")
sub(C,"    final pop = _focused ? 1.06 : 1.0;\n",
"    final pop = _focused ? 1.06 : 1.0;\n    final modern = _modern;\n    final innerRadius = modern ? ShioriShape.cover : 5.0;\n")
sub(C,"                borderRadius: BorderRadius.circular(8),\n",
"                borderRadius: BorderRadius.circular(innerRadius + 3),\n                boxShadow: modern\n                    ? [\n                        BoxShadow(\n                          color: Colors.black.withValues(\n                            alpha: _focused ? 0.20 : 0.10,\n                          ),\n                          blurRadius: _focused ? 12 : 6,\n                          offset: const Offset(0, 2),\n                        ),\n                      ]\n                    : null,\n")
sub(C,"                        borderRadius: BorderRadius.circular(5),\n                        child: ColoredBox(",
"                        borderRadius: BorderRadius.circular(innerRadius),\n                        child: ColoredBox(")
sub(C,"                  Material(\n                borderRadius: BorderRadius.circular(5),",
"                  Material(\n                borderRadius: BorderRadius.circular(innerRadius),")

L='lib/modules/library/widgets/library_entry_utils.dart'
sub(L,"import 'package:mangayomi/utils/extensions/manga_extensions.dart';\n",
"import 'package:mangayomi/utils/extensions/manga_extensions.dart';\nimport 'package:mangayomi/utils/platform_utils.dart';\nimport 'package:mangayomi/yomihub/ui/shiori/shiori_badge.dart';\nimport 'package:mangayomi/yomihub/ui/shiori/shiori_tokens.dart';\nimport 'package:mangayomi/yomihub/ui/ui_style.dart';\n")
sub(L,"  @override\n  Widget build(BuildContext context) {\n    return Container(\n      decoration: BoxDecoration(\n        borderRadius: borderRadius,",
"  @override\n  Widget build(BuildContext context) {\n    // YomiHub 0.5.7 (U11): Shiori badge in the \"Moi\" UI style.\n    if (!isTv && YomiUi.isModern) {\n      return ShioriBadge(\n        count: 0,\n        label: label,\n        kind: icon == null ? ShioriStatusKind.read : ShioriStatusKind.newChapter,\n      );\n    }\n    return Container(\n      decoration: BoxDecoration(\n        borderRadius: borderRadius,")
sub(L,"    return Container(\n      decoration: BoxDecoration(\n        borderRadius: BorderRadius.circular(3),\n        color: context.primaryColor,",
"""    // YomiHub 0.5.7 (U11): in the "Moi" UI style the combined badge is a row
    // of Shiori pills (merged / local / downloaded / unread).
    if (!isTv && YomiUi.isModern) {
      return Wrap(
        spacing: 3,
        runSpacing: 3,
        children: [
          if (isMerged)
            const ShioriBadge(
              count: 0,
              label: 'Hợp nhất',
              kind: ShioriStatusKind.newChapter,
            ),
          if (hasLocal)
            ShioriBadge(
              count: 0,
              label: _withOrigin('Local'),
              kind: ShioriStatusKind.offline,
            ),
          if (downloadCount > 0)
            ShioriBadge(
              count: 0,
              label: hasLocal
                  ? downloadCount.toString()
                  : _withOrigin('↓$downloadCount'),
              kind: ShioriStatusKind.downloaded,
            ),
          if (unreadCount > 0)
            ShioriBadge(count: unreadCount, kind: ShioriStatusKind.unread),
        ],
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        color: context.primaryColor,""")

G='lib/modules/library/widgets/library_gridview_widget.dart'
sub(G,"                                  color: context.themeData.cardColor,\n                                  child: EntryBadgeChip(",
"                                  color: (!isTv && YomiUi.isModern)\n                                      ? null\n                                      : context.themeData.cardColor,\n                                  child: EntryBadgeChip(")
sub(G,"import 'package:mangayomi/utils/platform_utils.dart';\n","import 'package:mangayomi/utils/platform_utils.dart';\nimport 'package:mangayomi/yomihub/ui/ui_style.dart';\n")

U='lib/yomihub/ui/ui_style.dart'
sub(U,"  static YomiUiStyle get style => parse(YomiPrefs.get<Object?>(prefKey, null));",
"  /// Test hook: forces a style without an open prefs box.\n  @visibleForTesting\n  static YomiUiStyle? debugOverride;\n\n  static YomiUiStyle get style =>\n      debugOverride ?? parse(YomiPrefs.get<Object?>(prefKey, null));")
sub(U,"import 'package:flutter/material.dart';\n","import 'package:flutter/foundation.dart';\nimport 'package:flutter/material.dart';\n")

N='lib/modules/more/settings/appearance/custom_navigation_settings.dart'
sub(N,"                SwitchListTile(\n                  value: mergeLibraryNavMobile,","                // YomiHub 0.5.7 (U11): the \"Moi\" UI style already merges the\n                // library, so the switch is hidden there.\n                if (!YomiUi.isModern)\n                SwitchListTile(\n                  value: mergeLibraryNavMobile,")
sub(N,"import 'package:mangayomi/providers/l10n_providers.dart';\n","import 'package:mangayomi/providers/l10n_providers.dart';\nimport 'package:mangayomi/yomihub/ui/ui_style.dart';\n")
