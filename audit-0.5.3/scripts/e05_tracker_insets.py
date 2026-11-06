import sys,os; sys.path.insert(0,os.path.expanduser('~/mnt/A.I Project - YomiHub Project/YomiHub-Project/audit-0.5.3')); from edit import edit
T='lib/modules/manga/detail/widgets/tracker_search_widget.dart'
edit(T,"""  var padding = MediaQuery.of(context).padding;
  return await showDialog(
    context: context,
    builder: (context) => Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        child: SizedBox(
          height: context.height(1) - padding.top - padding.bottom,
          child: Column(""","""  // 0.5.3 (YomiHub Update mục 7): the height was computed from the screen
  // minus the outer padding, which is 0 in edge-to-edge mode (Android 15+),
  // so the search field ended up under the navigation bar / keyboard. The
  // sheet now lives inside a SafeArea and takes the height that is left
  // after the status bar, navigation bar and keyboard.
  return await showDialog(
    context: context,
    useSafeArea: false,
    builder: (context) => Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, box) => SingleChildScrollView(
        child: SizedBox(
          height: box.maxHeight,
          child: Column(""")
edit(T,"""              TrackerWidgetSearch(track: track, itemType: itemType),
            ],
          ),
        ),
      ),
    ),
  );""","""              TrackerWidgetSearch(track: track, itemType: itemType),
            ],
          ),
        ),
          ),
        ),
      ),
    ),
  );""")
M='lib/modules/manga/detail/widgets/tracking_menu.dart'
edit(M,"""  required List<TrackPreference> entries,
}) {
  DraggableMenu.open(""","""  required List<TrackPreference> entries,
}) {
  // 0.5.3: measured on the page that opens the menu - inside the menu route
  // the system padding is already consumed (0), so the last tracker row sat
  // behind the navigation bar.
  final outerBottom = MediaQuery.viewPaddingOf(context).bottom;
  DraggableMenu.open(""")
edit(M,"""                8 + MediaQuery.viewPaddingOf(context).bottom,""","""                8 +
                    (MediaQuery.viewPaddingOf(context).bottom > outerBottom
                        ? MediaQuery.viewPaddingOf(context).bottom
                        : outerBottom),""")
K='lib/modules/more/settings/track/track.dart'
edit(K,"""      appBar: AppBar(title: Text(l10nLocalizations(context)!.tracking)),
      body: SingleChildScrollView(""","""      appBar: AppBar(title: Text(l10nLocalizations(context)!.tracking)),
      // 0.5.3: the last tracker rows stayed under the navigation bar
      body: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: MediaQuery.viewPaddingOf(context).bottom + 16),""")
edit(K,"""        return AlertDialog(
          title: Text(
            l10n.login_into("Kitsu"),""","""        return AlertDialog(
          // 0.5.3: the e-mail / password fields were pushed under the
          // keyboard (fixed 300 px content)
          scrollable: true,
          title: Text(
            l10n.login_into("Kitsu"),""")
D='lib/modules/more/settings/track/manage_trackers/tracking_detail.dart'
edit(D,"""        body: TabBarView(
          controller: _tabBarController,""","""        // 0.5.3: keep the lists clear of the navigation bar
        body: SafeArea(
          top: false,
          child: TabBarView(
          controller: _tabBarController,""")
