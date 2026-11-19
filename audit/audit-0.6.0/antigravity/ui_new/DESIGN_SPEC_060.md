# DESIGN_SPEC_060.md — YomiHub New Version (Material 3)

## 1. Design Principles (Material 3)
- Unified, fluid layout adapted to platform (mobile, TV, desktop).
- High contrast, focus-friendly for D-pad navigation.
- Consistent design language across manga/anime/novel modules.

## 2. Layout Structure
- **Global Navigation**: NavigationRail (Desktop/TV) / NavigationBar (Mobile) with icons (Library, Updates, History, Browse, More).
- **Library View**: Adaptive GridView.
- **Content Detail View**: Unified header (with "Select Source" for merge, adaptive banner) + segmented content (Chapters, Info, Tracker, etc.).
- **Reader/Player**: Minimalist controls, swipe gestures for mobile, mouse focus for desktop, D-pad events for TV.

## 3. Platform Adaptations
- **Mobile**: Touch-first, bottom nav.
- **Windows**: Multi-window support, mouse focus, wide grid.
- **Android TV**: D-pad focus states, no Comic/Novel/Play Books/Booru, large touch targets.

## 4. Feature Switcher
- Keep `YomiUiStyle.oldVersion` and `YomiUiStyle.newVersion`.
- Global settings toggle + individual module override if necessary.
