# YomiHub 0.6.0 Changelog

## New Features
- **Checkbox-based Extension Filters**: All filters in every extension type (Mangayomi, Mihon/Aniyomi/Nekoyomi, Kotatsu) are now checkbox-based. Dropdowns are now checkbox-select, Sort is now checkbox + direction, and Kotatsu genre chips are now 3-state checkboxes (include/exclude/off). Groups ≤ 8 items are expanded, ≥ 15 items have a search box.
- **Google Drive Backup**: Dedicated section in Data & Storage with a Google logo; backup/restore directly via Google Drive account.
- **Browser › Savior – "Scan page for video links"**: Finds m3u8/mp4 links in the page source, configures player (jwplayer sources, og:video, escaped links) before playback; suggests embedded player frame scanning if no direct link is found.
- **Short Video**: Added support for Kwai, RedGifs, xFree, Kwiky, Facebook Reels, Snapchat Spotlight, Moj.
- **Extension Repo Suggestions**: Added Salmanbappi (97 anime sources – Aniyomi) and Secozzi (Jellyfin, Stremio, Torbox).
- **From Mangayomi v0.9.96**: Library reopens at the correct category; tapping a genre tag › "Search in source" now searches the correct genre; last row in library is no longer covered by the floating navigation bar.
- **Android 6.0 APK running on Android 7.0+**: Dialog with "Download standard APK" button opens the latest release page directly.

## Fixes
- **Filters**: Some items couldn't be selected in Mangayomi-style filters; the filter frame now redraws after each tap.
- **Updates**: Resolved 2.7s UI freeze in the Updates tab.
- **Performance**: Reduced lag on startup for devices with high RAM.
- **Filter Resilience**: A broken filter option no longer breaks the entire filter list.
- **JS Extensions**: Fixed PUT/DELETE/PATCH requests incorrectly sent as POST.
- **CBHentai**: Fixed Cloudflare challenge loop.
- **Kotatsu Images**: Improved Kotatsu image handling (e.g., SAYHENTAI) returning error HTML instead of images.
- **Tor**: Changed "connection failed after 90s" from error to warning.
- **Health Connect**: Mindfulness permission reminder limited to once a day.
- **Android 6.0 APK notice**: the "running the Android 6.0 APK" notice no longer stays hidden after 0.5.7 (it was keyed to an old version string).
