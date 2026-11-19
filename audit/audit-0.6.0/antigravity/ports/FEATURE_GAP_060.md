# FEATURE_GAP_060.md

## Analysis of Project Gaps for YomiHub 0.6.0

This document provides a detailed gap analysis between YomiHub 0.6.0 and several open-source manga/anime/media projects. Each project is analyzed for key features, YomiHub's current implementation status, and proposed integration plans.

### 1. Yomikiru (mienaiyami/yomikiru)
*   **Key Features:** Local file reading (directories), CBZ/CBR/ZIP/RAR/7Z, PDF/EPUB, Reading Layouts (Vertical/LTR/RTL), Zen Mode, Reading History, AniList synchronization.
*   **YomiHub Status:**
    *   Local file reading: Implemented (`overlay/lib/modules/library/providers/file_scanner.dart`). The `file_scanner` handles directory scanning and classification.
    *   CBZ/CBR support: Implemented (`overlay/lib/modules/manga/download/providers/convert_to_cbz.dart`).
    *   AniList sync: Implemented (`overlay/lib/services/trackers/anilist.dart`).
    *   Reading History: Implemented (`overlay/lib/modules/manga/archive_reader/providers/archive_reader_providers.dart`).
*   **Priority:** P2
*   **Gap/Recommendation:** YomiHub already covers most features. Improvements could be made to the local file classification engine to better handle nested folders and unconventional file naming conventions.
*   **Integration Plan:** Further refinement of the `local_file_classifier.dart` provider.

### 2. Yomihon (miyomi.app/software/yomihon)
*   **Key Features:** Modern reader engine, extensibility, cross-platform.
*   **YomiHub Status:**
    *   Reader engine: Implemented (`overlay/lib/modules/manga/reader/reader_view.dart`). This uses `subsampling_scale_image_view` for high-resolution images.
    *   Extensibility: Partially implemented through dynamic repo loading.
*   **Priority:** P1
*   **Gap/Recommendation:** Improve the reader engine's performance for large PDF/EPUB files. Add support for more advanced typography controls similar to Yomihon's implementation.
*   **Integration Plan:** Enhance `reader_view.dart` and the underlying image decoder/renderer.

### 3. Zenshin (hitarth-gg/zenshin)
*   **Key Features:** Anime list management, Torrent streaming, Metadata mapping.
*   **YomiHub Status:**
    *   Anime list management: Implemented (`overlay/lib/modules/tracker_library/tracker_library_screen.dart`).
    *   Torrent integration: Implemented (`overlay/lib/modules/library/providers/add_torrent.dart`).
*   **Priority:** P2
*   **Gap/Recommendation:** Metadata mapping for special episodes could be enhanced. Support for additional torrent streaming protocols like WebTorrent could be added.
*   **Integration Plan:** Update `add_torrent.dart` to support WebTorrent.

### 4. Nyora (Nyora-Manga/*)
*   **Key Features:** Manga tracking, repository management, clean UI.
*   **YomiHub Status:**
    *   Manga tracking: Implemented (`overlay/lib/services/trackers/`).
    *   Repository management: Implemented (`overlay/lib/modules/repositories/`).
*   **Priority:** P2
*   **Gap/Recommendation:** UI enhancements inspired by Nyora's clean interface.
*   **Integration Plan:** UI team to incorporate design elements.

### 5. Nuvio (NuvioMedia/NuvioMobile)
*   **Key Features:** Stremio addon support, trakt integration.
*   **YomiHub Status:**
    *   Trakt integration: Implemented (`overlay/lib/services/trackers/`).
*   **Priority:** P2
*   **Gap/Recommendation:** Stremio addon support is a significant gap.
*   **Integration Plan:** Research feasibility of integrating Stremio API.

### 6. GIF Viewer
*   **Key Features:** Animated image support.
*   **YomiHub Status:** Partially implemented.
*   **Priority:** P3
*   **Gap/Recommendation:** Performance improvements for large GIF/WebP files.
*   **Integration Plan:** Optimize image rendering in reader view.

### 7. Frank Yomik (akitaonrails/FrankYomik)
*   **Key Features:** Image translation, OCR.
*   **YomiHub Status:** Not implemented.
*   **Priority:** P1
*   **Gap/Recommendation:** Image translation/OCR is a key gap.
*   **Integration Plan:** Explore integrating a lightweight OCR engine.

### 8. Browser Fingerprint / Anti-bot Signature
*   **Key Features:** UA/cookie synchronization.
*   **YomiHub Status:** Implemented (`overlay/lib/services/`).
*   **Priority:** P1
*   **Gap/Recommendation:** None, existing implementation is sufficient.

### 9. Video Short Scroll (e.g., ShortStream)
*   **Key Features:** Infinite scroll video UI.
*   **YomiHub Status:** Not implemented.
*   **Priority:** P2
*   **Gap/Recommendation:** UI for short-form video streaming.
*   **Integration Plan:** Design and implement short-form video player UI.

### 10. Get Video URL & Download Video
*   **Key Features:** m3u8 stream sniping, video downloading.
*   **YomiHub Status:** Implemented (`overlay/lib/modules/manga/download/providers/download_provider.dart`).
*   **Priority:** P1
*   **Gap/Recommendation:** Improve stream sniping capabilities.
*   **Integration Plan:** Update `download_provider.dart` for improved HLS stream handling.

*Status key: [ ] = Not implemented, [x] = Implemented*
*Priority: P1 = High, P2 = Medium, P3 = Low*
