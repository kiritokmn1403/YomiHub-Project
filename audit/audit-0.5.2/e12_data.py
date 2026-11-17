import sys; sys.path.insert(0,'.')
from edit import edit
F='lib/modules/more/data_and_storage/data_and_storage.dart'
edit(F,"""              title: Text(l10n.download_location),
              subtitle: Text(
                downloadLocationState.$2.isEmpty
                    ? downloadLocationState.$1
                    : downloadLocationState.$2,
                style: TextStyle(fontSize: 11, color: context.secondaryColor),
              ),
            ),
            ListTile(
              title: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: context.secondaryColor,
                    ),
                  ],
                ),
              ),
              subtitle: Text(
                l10n.download_location_info,
                style: TextStyle(fontSize: 11, color: context.secondaryColor),
              ),
            ),""","""              title: Text(l10n.download_location),
              subtitle: Builder(
                builder: (context) {
                  final loc = downloadLocationState.$2.isEmpty
                      ? downloadLocationState.$1
                      : downloadLocationState.$2;
                  // 0.5.2: a custom folder on a removed/replaced SD card
                  // (Note 9: /storage/7563-670C gone, card now 0000-0000)
                  // silently broke downloads - say so under the path.
                  final missing = downloadLocationState.$2.isNotEmpty &&
                      !Directory(downloadLocationState.$2).existsSync();
                  return Text(
                    missing
                        ? '$loc\\n${tr('Thư mục này không còn tồn tại (thẻ nhớ đã tháo hoặc đổi?) – chọn lại vị trí tải xuống.')}'
                        : loc,
                    style: TextStyle(
                      fontSize: 11,
                      color: missing ? Colors.red : context.secondaryColor,
                    ),
                  );
                },
              ),
            ),
            // 0.5.2: icon and note on one line (the icon alone looked like a
            // row whose title was missing, e.g. on a DeX/tablet screen).
            ListTile(
              dense: true,
              leading: Icon(
                Icons.info_outline_rounded,
                color: context.secondaryColor,
              ),
              title: Text(
                l10n.download_location_info,
                style: TextStyle(fontSize: 11, color: context.secondaryColor),
              ),
            ),""")
