/// YomiHub 0.5.6 (sheet "YomiHub Update" row 13): Comic, Film & Movie, Novel
/// and Google Play Books share one navigation entry, "Thư Viện (Library)".
///
/// Modelled on the navigation groups of Mangayomi 0.9.95
/// (`lib/modules/main_view/nav_groups.dart`: Library = the three
/// libraries, Activity = Updates + History), extended with Play Books and
/// with YomiHub's feature switches and Android TV rule.
///
/// The screens keep their own routes (and their own StatefulShellBranch, so
/// each keeps its state); only the navigation bar / rail is folded. This
/// file is pure Dart so the rules can be unit tested without the shell.
library;

/// Pseudo destination "Thư Viện" of the navigation bar / rail.
const kLibraryHubNav = '_libraryHub';

/// Pseudo destination "Hoạt động" (Updates + History, Mangayomi layout).
const kActivityNav = '_activity';

/// The routes grouped under "Thư Viện", in their default order.
const kLibraryHubRoutes = <String>[
  '/MangaLibrary',
  '/AnimeLibrary',
  '/NovelLibrary',
  '/playBooks',
];

/// The routes grouped under "Hoạt động".
const kActivityRoutes = <String>['/updates', '/history'];

/// The only library kept on Android TV (sheet row 13: TV = Film & Movie).
const kLibraryHubTvRoute = '/AnimeLibrary';

bool _same(String a, String b) => a.toLowerCase() == b.toLowerCase();

bool _hidden(String nav, List<String> hidden) =>
    hidden.any((h) => _same(h, nav));

/// Whether [location] is one of the screens grouped under "Thư Viện".
bool isLibraryHubRoute(String? location) =>
    location != null && kLibraryHubRoutes.contains(location);

/// Whether [location] is Updates or History.
bool isActivityRoute(String? location) =>
    location != null && kActivityRoutes.contains(location);

/// The sub-tabs of "Thư Viện": the grouped routes in the user's navigation
/// [order], without the ones switched off in "Bật/Tắt tính năng" ([hidden])
/// and, on TV, without everything but Film & Movie.
List<String> libraryHubTabs({
  required List<String> order,
  required List<String> hidden,
  required bool tv,
}) {
  final tabs = <String>[
    ...order.where(kLibraryHubRoutes.contains),
    // a saved order from an older version may miss a route
    ...kLibraryHubRoutes.where((r) => !order.contains(r)),
  ];
  return [
    for (final t in tabs)
      if (!_hidden(t, hidden) && (!tv || t == kLibraryHubTvRoute)) t,
  ];
}

/// The sub-tabs of "Hoạt động" in the Mangayomi layout: Updates and History
/// in the user's [order]. Empty unless both are visible ("a group with
/// fewer than two visible members is left alone"), on TV (which keeps one
/// destination per route, as upstream) and in the classic layout.
List<String> activityTabs({
  required List<String> order,
  required List<String> hidden,
  required bool tv,
  required bool modern,
}) {
  if (!modern || tv) return const [];
  final tabs = [
    for (final r in order)
      if (kActivityRoutes.contains(r) && !_hidden(r, hidden)) r,
  ];
  return tabs.length < 2 ? const [] : tabs;
}

/// The destinations of the main navigation bar / rail.
///
/// The first grouped route in [order] becomes the group's entry (so the
/// user's ordering still decides where it sits) and the group's other
/// routes are dropped. Hidden entries are removed. Classic layout
/// ([modern] false): `/history` is not a tab (YomiHub 0.4.3). Mangayomi
/// layout: History is a tab again and joins Updates under [kActivityNav].
/// On TV, Booru goes too. With no visible library there is no "Thư Viện".
List<String> buildMainNav({
  required List<String> order,
  required List<String> hidden,
  required bool tv,
  required bool modern,
}) {
  final libs = libraryHubTabs(order: order, hidden: hidden, tv: tv);
  final activity = activityTabs(
    order: order,
    hidden: hidden,
    tv: tv,
    modern: modern,
  );
  final out = <String>[];
  for (final nav in order) {
    if (kLibraryHubRoutes.contains(nav)) {
      if (libs.isNotEmpty && !out.contains(kLibraryHubNav)) {
        out.add(kLibraryHubNav);
      }
      continue;
    }
    if (_hidden(nav, hidden)) continue;
    if (nav == '/history' && !modern) continue;
    if (tv && nav == '/booru') continue;
    if (activity.contains(nav)) {
      if (!out.contains(kActivityNav)) out.add(kActivityNav);
      continue;
    }
    out.add(nav);
  }
  // a saved order without any library route still gets the entry
  if (libs.isNotEmpty && !out.contains(kLibraryHubNav)) {
    out.insert(0, kLibraryHubNav);
  }
  return out;
}

/// The navigation entry of [dest] that represents [location]: the group's
/// entry for a grouped route (when the group is on the bar), else the
/// location itself.
String? navKeyForLocation(String? location, List<String> dest) {
  if (isLibraryHubRoute(location) && dest.contains(kLibraryHubNav)) {
    return kLibraryHubNav;
  }
  if (isActivityRoute(location) && dest.contains(kActivityNav)) {
    return kActivityNav;
  }
  return location;
}

/// Where tapping a group leads: the member used last when it is still
/// available, else the first one; null when the group is empty.
String? libraryHubTarget(List<String> tabs, String? last) {
  if (tabs.isEmpty) return null;
  return (last != null && tabs.contains(last)) ? last : tabs.first;
}

/// State shared between the navigation shell and its bar / rail.
class YomiLibraryHub {
  YomiLibraryHub._();

  /// The library sub-tabs currently available (set by the shell).
  static List<String> tabs = const [];

  /// The Activity sub-tabs currently available (empty = not grouped).
  static List<String> activity = const [];

  /// The library / activity screen the user looked at last in this run.
  static String? last;
  static String? lastActivity;

  /// Remembers [location] when it is a grouped screen.
  static void visit(String? location) {
    if (isLibraryHubRoute(location)) last = location;
    if (isActivityRoute(location)) lastActivity = location;
  }

  /// The sub-tabs to show above [location] (empty = no strip): the group
  /// [location] belongs to, when it has at least two members.
  static List<String> stripFor(String? location) {
    if (isLibraryHubRoute(location)) {
      return tabs.length > 1 ? tabs : const [];
    }
    if (isActivityRoute(location)) return activity;
    return const [];
  }

  /// Turns a navigation entry into a route that can be opened.
  static String? resolve(String nav) => switch (nav) {
    kLibraryHubNav => libraryHubTarget(tabs, last),
    kActivityNav => libraryHubTarget(activity, lastActivity),
    _ => nav,
  };
}
