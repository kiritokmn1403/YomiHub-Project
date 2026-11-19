# INTEGRATION.md — Integration with Existing Overlay

## Overview
- This directory `ui_new/` contains proposed code for YomiHub's New Version UI.
- It leverages Material 3 components and maintains compatibility with the existing `YomiUiStyle` switcher.

## Implementation Plan
1. **Module Replacement**: Replace `overlay/lib/yomihub/ui/` with the new design when `YomiUiStyle.newVersion` is active.
2. **Switching Mechanism**: The `YomiUiStyle` enum should be extended/maintained to drive the injection of the `newVersion` UI modules.
3. **Integration Points**:
   - `main.dart`: Injection of `AppNavigation`.
   - `library_view.dart`: Switch between `OldLibrary` and `NewLibrary`.
   - `content_detail_view.dart`: Switch between `OldDetail` and `NewDetail`.

## Files to Replace/Update
- `overlay/lib/yomihub/ui/` (the entire directory needs mapping)
- `overlay/lib/modules/main_view/main_view.dart` (to inject `AppNavigation`)

*Note: No code from here is to be applied directly. This is a proposal only.*
