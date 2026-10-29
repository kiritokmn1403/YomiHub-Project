import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';
import 'package:url_launcher/url_launcher.dart';

/// YomiHub 0.2.1: About › "Dự án GitHub đã sử dụng" – every GitHub project
/// YomiHub is built on or took features / ideas from (sheet "Project GitHub"
/// and "Tracker" of the project file, plus the libraries bundled in the app).
class YomiGhProject {
  final String name;
  final List<String> urls;
  const YomiGhProject(this.name, this.urls);
}

class YomiGhGroup {
  final String title;
  final List<YomiGhProject> items;
  const YomiGhGroup(this.title, this.items);
}

const yomiGithubProjects = <YomiGhGroup>[
  YomiGhGroup('Nền tảng & thư viện tích hợp trong YomiHub', [
    YomiGhProject('Mangayomi (nhân ứng dụng)', [
      'https://github.com/kodjodevf/mangayomi',
    ]),
    YomiGhProject('Mangayomi Extensions', [
      'https://github.com/kodjodevf/mangayomi-extensions',
    ]),
    YomiGhProject('M-Extension-Server (plugin m_extension_server)', [
      'https://github.com/kodjodevf/m_extension_server',
    ]),
    YomiGhProject('Kotatsu-Redo parsers', [
      'https://github.com/Kotatsu-Redo/kotatsu-parsers-redo',
    ]),
    YomiGhProject('IReader source-api / extensions', [
      'https://github.com/IReaderorg/IReader-extensions',
    ]),
    YomiGhProject('LNReader plugins', [
      'https://github.com/LNReader/lnreader-plugins',
    ]),
    YomiGhProject('Aidoku sources', [
      'https://github.com/Aidoku-Community/sources',
    ]),
    YomiGhProject('Tor for Android (tor-android)', [
      'https://github.com/guardianproject/tor-android',
    ]),
    YomiGhProject('WireGuard Android tunnel', [
      'https://github.com/WireGuard/wireguard-android',
    ]),
    YomiGhProject('ics-openvpn', ['https://github.com/schwabe/ics-openvpn']),
    YomiGhProject('Xray-core', ['https://github.com/XTLS/Xray-core']),
    YomiGhProject('hev-socks5-tunnel', [
      'https://github.com/heiher/hev-socks5-tunnel',
    ]),
    YomiGhProject('GeckoView (Firefox)', [
      'https://github.com/mozilla-firefox/firefox',
    ]),
    YomiGhProject('media_kit (mpv)', [
      'https://github.com/media-kit/media-kit',
    ]),
    YomiGhProject('Return YouTube Dislike', [
      'https://github.com/Anarios/return-youtube-dislike',
    ]),
    YomiGhProject('SponsorBlock', ['https://github.com/ajayyy/SponsorBlock']),
    YomiGhProject('NanoHTTPD', ['https://github.com/NanoHttpd/nanohttpd']),
    YomiGhProject('OkHttp', ['https://github.com/square/okhttp']),
    YomiGhProject('jsoup', ['https://github.com/jhy/jsoup']),
    YomiGhProject('QuickJS (app.cash.quickjs)', [
      'https://github.com/cashapp/zipline',
    ]),
    YomiGhProject('Flutter', ['https://github.com/flutter/flutter']),
  ]),
  YomiGhGroup('Ứng dụng', [
    YomiGhProject('Aidoku', ['https://github.com/Aidoku/Aidoku']),
    YomiGhProject('Anikku', ['https://github.com/komikku-app/anikku']),
    YomiGhProject('Aniyomi', ['https://github.com/aniyomiorg/aniyomi']),
    YomiGhProject('Kotatsu', ['https://github.com/KotatsuApp']),
    YomiGhProject('Kotatsu Multi Parsers', [
      'https://github.com/Shebyyy/kotatsu-multi-parsers',
    ]),
    YomiGhProject('Miyomi', ['https://github.com/dazedcat19/FMD2']),
    YomiGhProject('Mangayomi', ['https://github.com/kodjodevf/mangayomi']),
    YomiGhProject('Mangayomi Extension Server', [
      'https://github.com/kodjodevf/M-Extension-Server',
    ]),
    YomiGhProject('Mangayomi ApkBridge', [
      'https://github.com/Schnitzel5/ApkBridge',
    ]),
    YomiGhProject('Mangayomi Custom Buttons', [
      'https://github.com/Schnitzel5/mangayomi-custom-buttons',
    ]),
    YomiGhProject('MiHon', ['https://miyomi.app/software/mihon']),
    YomiGhProject('MiHon Proxy Server', [
      'https://github.com/wen-shion/mihon-proxy',
    ]),
    YomiGhProject('Nekoyomi', ['https://github.com/Seguaz/Nekoyomi']),
    YomiGhProject('Tachimanga', ['https://github.com/tachimanga']),
    YomiGhProject('Zenbu', ['https://github.com/meesam4687/zenbu']),
    YomiGhProject('LNReader', ['https://github.com/LNReader/lnreader']),
    YomiGhProject('vBook', ['https://github.com/Darkrai9x/vbook-extensions']),
    YomiGhProject('vBook 2', ['https://github.com/duongden/vbook/']),
    YomiGhProject('Google Play Books Desktop', [
      'https://github.com/TheLox95/Google-Play-Books-Desktop',
    ]),
    YomiGhProject('IReader', ['https://github.com/IReaderorg/Ireader']),
    YomiGhProject('Tachiyomi', ['https://github.com/tachiyomiorg']),
  ]),
  YomiGhGroup('Trình chặn quảng cáo (AdBlock)', [
    YomiGhProject('AdBlock', ['https://github.com/adblockplus']),
    YomiGhProject('uBlock Origin', ['https://github.com/gorhill/uBlock']),
    YomiGhProject('uBlock', ['https://github.com/uBlock-LLC/uBlock']),
    YomiGhProject('Tampermonkey Adblock Script', [
      'https://gist.github.com/DerFichtl/af462414df838ff397603f8bf9db24e3',
    ]),
    YomiGhProject('AdGuard', ['https://github.com/AdguardTeam']),
  ]),
  YomiGhGroup('VPN & DNS', [
    YomiGhProject('Tor Project', [
      'https://github.com/torproject',
      'https://github.com/jeremy-jr-benthum/onion-browser-button/releases',
    ]),
    YomiGhProject('CloudFlare Warp', [
      'https://github.com/topics/cloudflare-warp',
    ]),
    YomiGhProject('HolaVPN', ['https://github.com/hola']),
    YomiGhProject('OpenVPN', ['https://github.com/OpenVPN']),
    YomiGhProject('WireGuard', ['https://github.com/WireGuard']),
    YomiGhProject('SoftEtherVPN', [
      'https://github.com/SoftEtherVPN/SoftEtherVPN/',
    ]),
    YomiGhProject('AdGuardVPN', [
      'https://github.com/AdguardTeam/AdGuardVPNForWindows',
    ]),
    YomiGhProject('Urban VPN', [
      'https://github.com/DanTheSanjiFan/urbanvpn',
      'https://github.com/doxdk/UrbanVPN/blob/main/README.md',
      'https://github.com/VulcanoSoftware/urbanvpn/releases',
      'https://github.com/jamie950315/Urban-Proxy',
      'https://github.com/topics/urban-vpn',
    ]),
  ]),
  YomiGhGroup('YouTube', [
    YomiGhProject('Pure Tuber', [
      'https://github.com/huythai1602/Pure_tuber_app',
    ]),
    YomiGhProject('Pure Tuber 2', ['https://github.com/PureTuber']),
    YomiGhProject('NewPipe', ['https://github.com/TeamNewPipe/NewPipe']),
    YomiGhProject('vancedTube', ['https://github.com/dexter9code/vancedTube']),
    YomiGhProject('YouTube Vanced', ['https://github.com/laynz28/ytvancedx']),
    YomiGhProject('Website', ['https://www.youtube.com/']),
  ]),
  YomiGhGroup('Trình đọc Ebook', [
    YomiGhProject('Sigil', ['https://github.com/Sigil-Ebook/Sigil']),
    YomiGhProject('Calibre', ['https://github.com/kovidgoyal/calibre']),
    YomiGhProject('FBReader', ['https://github.com/FBReader']),
  ]),
  YomiGhGroup('Trình duyệt', [
    YomiGhProject('Chromium', ['https://github.com/chromium/chromium']),
    YomiGhProject('Firefox', ['https://github.com/mozilla-firefox/firefox']),
    YomiGhProject('Coccoc', ['https://github.com/coccoc']),
    YomiGhProject('Browser Fingerprint', [
      'https://github.com/fingerprintjs/fingerprintjs',
      'https://github.com/eisman/fingerprintjs2',
      'https://github.com/niespodd/browser-fingerprinting',
      'https://eisman.github.io/fingerprintjs2/',
    ]),
  ]),
  YomiGhGroup('Cloudflare & Cloudflare Bypass', [
    YomiGhProject('Cloudflare', ['https://github.com/cloudflare']),
    YomiGhProject('CloudScraper', ['https://github.com/VeNoMouS/cloudscraper']),
    YomiGhProject('CloakBrowser', ['https://github.com/CloakHQ/CloakBrowser']),
  ]),
  YomiGhGroup('Trình đọc PDF', [
    YomiGhProject('Foxit Software', ['https://github.com/foxitsoftware']),
    YomiGhProject('PDF24', ['https://github.com/PDF24']),
    YomiGhProject('iLovePDF', ['https://github.com/ilovepdf']),
  ]),
  YomiGhGroup('Hình trong hình (PiP)', [
    YomiGhProject('Picture-in-Picture', [
      'https://gist.github.com/silasmariusz/74cdbd298672c1f6d96f4551c0bd8209',
    ]),
    YomiGhProject('Picture-in-Picture API', [
      'https://gist.github.com/silasmariusz/74cdbd298672c1f6d96f4551c0bd8209',
    ]),
  ]),
  YomiGhGroup('Tính năng khác', [
    YomiGhProject('AirDrop', ['https://github.com/seemoo-lab/opendrop']),
    YomiGhProject('Quickshare', ['https://github.com/ihexxa/quickshare']),
    YomiGhProject('Quickshare 2', ['https://github.com/Martichou/rquickshare']),
    YomiGhProject('VLC', ['https://github.com/videolan/vlc']),
    YomiGhProject('MicroG', ['https://github.com/microg']),
    YomiGhProject('ReVanced Manager', [
      'https://github.com/ReVanced/revanced-manager/',
    ]),
    YomiGhProject('NetSetMan', ['https://github.com/netsynx/NetSetMan']),
    YomiGhProject('Qr Code Generator', [
      'https://github.com/nayuki/QR-Code-generator',
    ]),
    YomiGhProject('Google Lens', [
      'https://gist.github.com/qt-kaneko/d5969bae8c31b306408038581297dd33',
    ]),
    YomiGhProject('Video Short Scroll', [
      'https://github.com/riteshkumar072/ShortStream',
      'https://github.com/dkaoster/scrolly-video',
      'https://gist.github.com/codegenixdev/413d2e995f8f536edc00a8ad62c9049b',
      'https://adncwy.github.io/video-scroller/',
      'https://github.com/Tyson3101/Auto-Youtube-Shorts-Scroller/',
      'https://github.com/KHAJAMOINUDDINKHADRI/Video-Scrolling',
      'https://gist.github.com/Rochdy/aeadab548fb657cb1e90c3b5b1b30038',
      'https://github.com/umair-hashmii/VideoShorts',
    ]),
    // 0.2.2
    YomiGhProject('SpeedTest', ['https://github.com/librespeed/speedtest']),
    YomiGhProject('Runtime Native / Hybrid', [
      'https://github.com/runtimerevolution/hybrid-to-native',
      'https://github.com/focus-creative-games/hybridclr',
      'https://www.hybridclr.cn/en/docs/intro',
      'https://github.com/microsoft/onnxruntime',
      'https://github.com/phi-media-lab/apu-hybrid-runtime-Phi',
      'https://github.com/namdpran8/Setu',
    ]),
  ]),
  YomiGhGroup('Liquid Glass', [
    YomiGhProject('Liquid Glass', [
      'https://github.com/archisvaze/liquid-glass',
    ]),
    YomiGhProject('Liquid Glass 2', [
      'https://github.com/rdev/liquid-glass-react',
    ]),
    YomiGhProject('Liquid Glass 3', [
      'https://dashersw.github.io/liquid-glass-js/',
    ]),
    YomiGhProject('Liduid Glass 4', [
      'https://gist.github.com/leiniaozl229/fd6909f33aca60a03dc947a9225fbaf4',
    ]),
  ]),
  YomiGhGroup('Web Scanner', [
    YomiGhProject('Web Scanner', ['https://github.com/topics/web-scanner']),
    YomiGhProject('Web Scanner 2', [
      'https://github.com/topics/website-vulnerability-scanner',
    ]),
    YomiGhProject('Web Scanner 3', ['https://waymapscanner.github.io/']),
    YomiGhProject('SiteCheck', ['https://github.com/cixtor/sitecheck']),
  ]),
  YomiGhGroup('Dịch hình ảnh', [
    YomiGhProject('Image Translation', [
      'https://github.com/topics/image-to-image-translation',
      'https://github.com/topics/image-translation',
      'https://github.com/phillipi/pix2pix',
      'https://github.com/Utkarsh87',
    ]),
    YomiGhProject('CHAN for Image-to-Image Translation', [
      'https://github.com/fei-aiart/chan',
    ]),
    YomiGhProject('Pix2Pix Image Translation', [
      'https://atikul-islam-sajib.github.io/pix2pix-deploy/',
    ]),
  ]),
  YomiGhGroup('Tải Video (Video Downloader)', [
    YomiGhProject('yt-dlp', ['https://github.com/yt-dlp/yt-dlp']),
    YomiGhProject('Seal (Video Downloader)', [
      'https://github.com/JunkFood02/Seal',
    ]),
    YomiGhProject('Video Downloader', [
      'https://github.com/DennisSnijder/Video-Downloader',
    ]),
    YomiGhProject('ytDownloader', [
      'https://github.com/aandrew-me/ytDownloader',
    ]),
    YomiGhProject('youtube-dl-gui', [
      'https://github.com/jely2002/youtube-dl-gui',
    ]),
    YomiGhProject('Vdown', ['https://github.com/hanyin111/Vdown']),
    YomiGhProject('reclip', ['https://github.com/averygan/reclip']),
    YomiGhProject('media-downloader', [
      'https://github.com/mhogomchungu/media-downloader',
    ]),
    YomiGhProject('video-downloader', [
      'https://github.com/Unrud/video-downloader',
    ]),
  ]),
  YomiGhGroup('Văn phòng & Tài liệu (Office & Documents)', [
    YomiGhProject('LibreOffice', [
      'https://github.com/LibreOffice/core',
      'https://github.com/LibreOffice',
      'https://github.com/gurecn/LibreOffice-android',
    ]),
    YomiGhProject('Apache OpenOffice', [
      'https://github.com/apache/openoffice',
      'https://github.com/apache/openoffice-docs',
    ]),
    YomiGhProject('OnlyOffice', [
      'https://github.com/ONLYOFFICE',
      'https://www.onlyoffice.com/',
    ]),
    YomiGhProject('WPS Office', [
      'https://github.com/wps-office-bizflow-pro',
      'https://github.com/topics/wps-office',
      'https://github.com/Xiao-rx/wps-mcp-server',
      'https://github.com/Bwkyd/wps-skills',
    ]),
    YomiGhProject('MathType', [
      'https://github.com/wiris',
      'https://github.com/wiris/html-integrations',
      'https://github.com/transpect/docx2tex',
    ]),
    YomiGhProject('SheetJS (Excel Engine)', [
      'https://github.com/SheetJS/sheetjs',
    ]),
    YomiGhProject('ExcelJS', ['https://github.com/exceljs/exceljs']),
    YomiGhProject('Apache POI & PDFBox', [
      'https://github.com/apache/poi',
      'https://github.com/apache/pdfbox',
    ]),
    YomiGhProject('OOXML (Office Open XML)', [
      'https://github.com/OfficeDev/Open-XML-SDK',
      'https://github.com/topics/ooxml',
    ]),
    YomiGhProject('ODF (OpenDocument Format)', [
      'https://github.com/topics/opendocument',
      'https://www.oasis-open.org/tc-opendocument/',
    ]),
    YomiGhProject('Craft Project (GridCraft, WordCraft, DeckCraft)', [
      'https://github.com/storytold/gridcraft',
      'https://github.com/storytold/wordcraft',
      'https://github.com/deckcraft-app/deckcraft',
    ]),
    YomiGhProject('VBA & Macro', [
      'https://github.com/hlydecker/vba-macros',
      'https://github.com/NetOfficeFw/vbamc',
      'https://github.com/VBA-tools/VBA-Web',
      'https://github.com/microsoft/vscode',
    ]),
    YomiGhProject('Powerpoint Animation & Automation', [
      'https://github.com/gitbrent/PptxGenJS/',
      'https://github.com/hugohe3/ppt-master',
      'https://github.com/HypertextAssassin0273',
      'https://github.com/HypertextAssassin0273/Unique_PowerPoint_Presentations',
      'https://github.com/singerla/pptx-automizer',
      'https://github.com/sbroenne/mcp-server-powerpoint',
    ]),
    YomiGhProject('Ely Office', [
      'https://github.com/ELY-Open-Source/ElyOffice/',
    ]),
    YomiGhProject('GenOffice', [
      'https://genoffice.ai/',
      'https://github.com/genspark-ai/genoffice',
    ]),
    YomiGhProject('Table Office', [
      'https://github.com/iOfficeAI/OfficeCLI/wiki/word-table',
      'https://github.com/RUCKBReasoning/TableLLM',
      'https://github.com/insightsengineering/rtables.officer',
    ]),
    YomiGhProject('Google Docs, Sheets & Slides API', [
      'https://github.com/googleapis/google-api-dart-client',
      'https://github.com/topics/google-sheets',
      'https://github.com/topics/google-docs',
    ]),
    YomiGhProject('AutoXL & Excel Financial', [
      'https://github.com/MatrixFun/AutoXL',
      'https://fsprojects.github.io/ExcelFinancialFunctions/',
    ]),
  ]),
  YomiGhGroup('Sức khỏe & Quản lý thời gian (Health Connect)', [
    YomiGhProject('Health Connect Samples', [
      'https://github.com/android/health-connect-samples',
    ]),
    YomiGhProject('Health Connect Toolbox', [
      'https://github.com/android/health-connect-toolbox',
    ]),
    YomiGhProject('HCGateway', ['https://github.com/ShuchirJ/HCGateway']),
    YomiGhProject('react-native-health-connect', [
      'https://github.com/matinzd/react-native-health-connect',
    ]),
  ]),
  YomiGhGroup('WiFi & Công cụ mạng', [
    YomiGhProject('WiFiAnalyzer', [
      'https://github.com/VREMSoftwareDevelopment/WiFiAnalyzer',
    ]),
    YomiGhProject('NetSetMan', ['https://github.com/netsynx/NetSetMan']),
    YomiGhProject('Scanners-Box', ['https://github.com/We5ter/Scanners-Box']),
    YomiGhProject('Wifi-Hacking & Pentesting', [
      'https://github.com/ankit0183/Wifi-Hacking',
      'https://github.com/ricardojoserf/wifi-pentesting-guide',
    ]),
    YomiGhProject('lazyaircrack', [
      'https://github.com/3xploitGuy/lazyaircrack',
    ]),
    YomiGhProject('Wifi-Cracker', ['https://github.com/trevatk/Wifi-Cracker']),
    YomiGhProject('WifiForge', [
      'https://github.com/blackhillsinfosec/WifiForge',
    ]),
  ]),
  YomiGhGroup('Tracker (theo dõi tiến độ)', [
    YomiGhProject('Anilist', ['https://github.com/AniList']),
    YomiGhProject('Kitsu', [
      'https://github.com/mralanbourne/kitsutracker-stremio-v2',
    ]),
    YomiGhProject('MyAnimeList', ['https://github.com/MALSync/MALSync']),
    YomiGhProject('Simkl', ['https://api.simkl.org/']),
    YomiGhProject('Trakt', ['https://github.com/trakt']),
    YomiGhProject('MangaUpdates', [
      'https://github.com/jckli/mangaupdates-bot',
      'https://github.com/rheactdev/MangaupdatesTracker',
    ]),
    YomiGhProject('Shikimori', ['https://publicapi.dev/shikimori-api']),
    YomiGhProject('Bangumi', [
      'https://github.com/sean1832/bangumi-tracker',
      'https://clawhub.ai/mountlynx/skills/bangumi-trackr',
      'https://skywork.ai/skillhub/bangumi-tracker/',
    ]),
  ]),
  YomiGhGroup('Đám mây & Đồng bộ dữ liệu (Cloud & Storage)', [
    YomiGhProject('Rclone', ['https://github.com/rclone/rclone']),
    YomiGhProject('Google Workspace', ['https://github.com/googleworkspace']),
    YomiGhProject('StackEdit', ['https://github.com/benweet/stackedit']),
    YomiGhProject('Drive CLI', ['https://github.com/odeke-em/drive']),
    YomiGhProject('Google Drive Ocamlfuse', [
      'https://github.com/astrada/google-drive-ocamlfuse',
    ]),
    YomiGhProject('GDown', ['https://github.com/wkentaro/gdown']),
    YomiGhProject('Cyberduck', ['https://github.com/iterate-ch/cyberduck']),
    YomiGhProject('GAM', ['https://github.com/GAM-team/GAM']),
    YomiGhProject('Hassio Google Drive Backup', [
      'https://github.com/sabeechen/hassio-google-drive-backup',
    ]),
    YomiGhProject('Google Workspace MCP', [
      'https://github.com/taylorwilsdon/google_workspace_mcp',
    ]),
    YomiGhProject('G-Desktop-Suite', [
      'https://github.com/alexkim205/G-Desktop-Suite',
    ]),
    YomiGhProject('OneDrive Client', ['https://github.com/abraunegg/onedrive']),
    YomiGhProject('DriftSync', ['https://github.com/xiaochun-z/driftsync']),
    YomiGhProject('Onedrive Sync Client', [
      'https://github.com/gzxu/onedrive-sync-client',
    ]),
    YomiGhProject('OneDrive-Sync', ['https://github.com/ggobbe/onedrive-sync']),
    YomiGhProject('MediaFire Bulk Downloader', [
      'https://github.com/NicKoehler/mediafire_bulk_downloader',
      'https://github.com/NicKoehler/mediafire_rs',
      'https://github.com/u0feff/MediaFireDownloader',
    ]),
    YomiGhProject('FreeFileSync', ['https://freefilesync.org/']),
    YomiGhProject('DropBox Sync', [
      'https://github.com/harsimrans/DropboxSyncer',
      'https://github.com/maximebf/dboxsync',
    ]),
  ]),
  YomiGhGroup('CamScanner & Quét tài liệu (Document Scanner)', [
    YomiGhProject('Document Scanner', [
      'https://github.com/sourabhkhemka/DocumentScanner',
      'https://github.com/Srinija/SwiftCamScanner',
    ]),
    YomiGhProject('Document-Scanner-and-OCR', [
      'https://github.com/ankitshaw/Document-Scanner-and-OCR',
    ]),
    YomiGhProject('AndroidDocumentFilter', [
      'https://github.com/garg-lucifer/AndroidDocumentFilter',
    ]),
    YomiGhProject('InvoiceMate', [
      'https://github.com/techno-disaster/InvoiceMate',
    ]),
    YomiGhProject('WonderScan', ['https://github.com/devsebastian/WonderScan']),
    YomiGhProject('DocScan-iOS', ['https://github.com/ankityddv/DocScan-iOS']),
    YomiGhProject('Scanny Document Scanner', [
      'https://github.com/AndroidWithRossyn/Scanny-Document-Scanner-CamScanner',
    ]),
    YomiGhProject('CamScanner Watermark Remover', [
      'https://github.com/viveksb007/camScannerWatermarkRemoverAndroid',
      'https://github.com/crabfeather/CSMarkRemover',
    ]),
    YomiGhProject('SimpleScanner', [
      'https://github.com/lxsfful/SimpleScanner',
      'https://github.com/HannaSkief/SimpleCamScanner',
    ]),
    YomiGhProject('PDF Magic Color filter', [
      'https://github.com/hasanfirnas/PDF_Magic-Color_filter',
    ]),
  ]),
  YomiGhGroup('Trí tuệ nhân tạo (A.I Chatbot)', [
    YomiGhProject('Google Gemini', [
      'https://github.com/google-gemini',
      'https://github.com/google-gemini/gemini-cli',
      'https://deepmind.google/models/gemini/',
    ]),
    YomiGhProject('Microsoft Copilot', [
      'https://github.com/features/copilot',
      'https://copilot.com/',
    ]),
    YomiGhProject('OpenAI ChatGPT', [
      'https://github.com/topics/chatgpt',
      'https://github.com/topics/chatgpt-api',
      'https://github.com/NousResearch/hermes-agent',
    ]),
    YomiGhProject('DeepSeek', [
      'https://github.com/deepseek-ai/DeepSeek-V3',
      'https://github.com/deepseek-ai',
    ]),
    YomiGhProject('xAI Grok', [
      'https://github.com/xai-org/grok-build',
      'https://github.com/xai-org/grok-1',
    ]),
    YomiGhProject('Anthropic Claude', [
      'https://github.com/anthropics/claude-code',
      'https://github.com/anthropics/',
    ]),
    YomiGhProject('OpenHay A.I', [
      'https://github.com/openhay-ai',
      'https://github.com/openhay-ai/openhay',
    ]),
  ]),
  YomiGhGroup('Chế độ máy tính để bàn (Android DeX Mode)', [
    YomiGhProject('Android Dex Mode', [
      'https://github.com/Shrey113/Android-Dex',
      'https://github.com/blworld/Shrey113-Android-Dex',
    ]),
    YomiGhProject('Open Android DeX', [
      'https://github.com/dotnetdreamer/open-android-dex',
      'https://github.com/dotnetdreamer/awesome-samsung-dex',
    ]),
    YomiGhProject('DX-Manager', ['https://github.com/maze-mei/DX-Manager']),
    YomiGhProject('Magisk Samsung DeX Standalone', [
      'https://github.com/supermarsx/magisk-samsung-dex-standalone-mode',
    ]),
    YomiGhProject('VSCode on Android', [
      'https://github.com/sumdher/VSCode-on-Android',
    ]),
    YomiGhProject('DeX on Linux & Mac', [
      'https://github.com/gabdevele/DexOnLinux',
      'https://github.com/yongtingzhengcn-web/dex-for-mac',
    ]),
    YomiGhProject('Samsung DeX by Aquino', [
      'https://github.com/Aquino1M/SamsungDexbyAquino',
    ]),
    YomiGhProject('Phone Connect & CrossInput', [
      'https://github.com/JzviaginPhoneConnect/phone-connect',
      'https://github.com/luceat-lux-vestra/crossinput',
    ]),
    YomiGhProject('Android Easy MultiDex', [
      'https://github.com/TangXiaoLv/Android-Easy-MultiDex',
    ]),
    YomiGhProject('Adb Device Manager', [
      'https://github.com/Shrey113/Adb-Device-Manager-2',
    ]),
  ]),
  YomiGhGroup('Trình duyệt – Browser Fingerprint (bổ sung 0.4.4)', [
    YomiGhProject("Donut Browser", ["https://github.com/zhom/donutbrowser"]),
    YomiGhProject("zhaotoday/fingerprint-browser", ["https://github.com/zhaotoday/fingerprint-browser"]),
    YomiGhProject("abrahamjuliot/creepjs", ["https://github.com/abrahamjuliot/creepjs"]),
  ]),
  YomiGhGroup('Widget (giao diện tiện ích) – 0.4.4', [
    YomiGhProject("topics/widget", ["https://github.com/topics/widget"]),
    YomiGhProject("hdodenhof/CircleImageView", ["https://github.com/hdodenhof/CircleImageView"]),
    YomiGhProject("elkowar/eww", ["https://github.com/elkowar/eww"]),
    YomiGhProject("giscus/giscus", ["https://github.com/giscus/giscus"]),
    YomiGhProject("gridstack/gridstack.js", ["https://github.com/gridstack/gridstack.js"]),
    YomiGhProject("alibaba/x-render", ["https://github.com/alibaba/x-render"]),
    YomiGhProject("reown-com/appkit", ["https://github.com/reown-com/appkit"]),
    YomiGhProject("kyleduo/SwitchButton", ["https://github.com/kyleduo/SwitchButton"]),
    YomiGhProject("widget-js/widgets", ["https://github.com/widget-js/widgets"]),
    YomiGhProject("WidgetJS", ["https://kayyraa.github.io/WidgetJS/"]),
    YomiGhProject("AnyChart/AnyChart-Android", ["https://github.com/AnyChart/AnyChart-Android"]),
    YomiGhProject("StackTipsLab/android-ui-tutorials", ["https://github.com/StackTipsLab/android-ui-tutorials"]),
    YomiGhProject("ashutoshgngwr/10-bitClockWidget", ["https://github.com/ashutoshgngwr/10-bitClockWidget"]),
    YomiGhProject("drewk312/VantaMusic", ["https://github.com/drewk312/VantaMusic"]),
    YomiGhProject("rafsanahmad/Dynamic-UI-From-JSON", ["https://github.com/rafsanahmad/Dynamic-UI-From-JSON"]),
    YomiGhProject("dvinfosys/CustomWidgets", ["https://github.com/dvinfosys/CustomWidgets"]),
    YomiGhProject("KWGT-Widgets", ["https://aumgupta.github.io/KWGT-Widgets/"]),
    YomiGhProject("iced-rs/iced", ["https://github.com/iced-rs/iced"]),
  ]),
  YomiGhGroup('Booru App (Booru Project) – 0.4.4', [
    YomiGhProject("TheRealTRYZER/BooruHub", ["https://github.com/TheRealTRYZER/BooruHub"]),
    YomiGhProject("onlymash/BooruHubI18n", ["https://github.com/onlymash/BooruHubI18n"]),
    YomiGhProject("khoadng/Boorusama", ["https://github.com/khoadng/Boorusama"]),
    YomiGhProject("Boorusama releases", ["https://github.com/khoadng/Boorusama/releases"]),
    YomiGhProject("sanfangx/boorusama-ts", ["https://github.com/sanfangx/boorusama-ts"]),
    YomiGhProject("1Git2Clone/boorusama-qt", ["https://github.com/1Git2Clone/boorusama-qt"]),
    YomiGhProject("6-development-guide", ["https://deepwiki.com/khoadng/Boorusama/6-development-guide"]),
    YomiGhProject("SaltedShroom/Booru-Studio", ["https://github.com/SaltedShroom/Booru-Studio"]),
    YomiGhProject("topics/booru", ["https://github.com/topics/booru"]),
    YomiGhProject("danbooru/danbooru", ["https://github.com/danbooru/danbooru"]),
    YomiGhProject("nullxception/boorusphere", ["https://github.com/nullxception/boorusphere"]),
    YomiGhProject("Rule-34/App", ["https://github.com/Rule-34/App"]),
    YomiGhProject("funmaker/Hybooru", ["https://github.com/funmaker/Hybooru"]),
    YomiGhProject("monbooru/monbooru", ["https://github.com/monbooru/monbooru"]),
    YomiGhProject("onlymash/BooruHubDocs", ["https://github.com/onlymash/BooruHubDocs"]),
  ]),
  YomiGhGroup('Tài liệu và dự án tham khảo bổ sung', [
    YomiGhProject("openshelf", ["https://github.com/SanHsien/openshelf"]),
    YomiGhProject("Stop-reading-from-Google-Books", [
      "https://github.com/seanpm2001/Stop-reading-from-Google-Books",
    ]),
    YomiGhProject("highlights-convert", [
      "https://github.com/t27/highlights-convert",
    ]),
    YomiGhProject("ABC", ["https://github.com/TwoSolutions/ABC"]),
    YomiGhProject("google-play-books", [
      "https://github.com/topics/google-play-books",
    ]),
    YomiGhProject("google-play-books", [
      "https://github.com/murazor97dicaprio/google-play-books",
    ]),
    YomiGhProject("Playbook-Analytics", [
      "https://github.com/Brandon123b/Playbook-Analytics",
    ]),
    YomiGhProject("yomirin", ["https://github.com/yukik8/yomirin"]),
    YomiGhProject("google-play-books", [
      "https://github.com/smokehost24k/google-play-books",
    ]),
    YomiGhProject("play-books-frankenstein", [
      "https://github.com/crxssed7/play-books-frankenstein",
    ]),
    YomiGhProject("google-play-books-downloader", [
      "https://github.com/1905/google-play-books-downloader",
    ]),
    YomiGhProject("FewType", ["https://github.com/Ray1979ANYWAY/FewType"]),
    YomiGhProject("Adaptive-Theme", [
      "https://github.com/xLexip/Adaptive-Theme",
    ]),
    YomiGhProject("playbook-android-reader", [
      "https://github.com/laduygaga/playbook-android-reader",
    ]),
    YomiGhProject("google-playbook", [
      "https://github.com/bradlegge/google-playbook",
    ]),
    YomiGhProject("books", ["https://github.com/liyasthomas/books"]),
    YomiGhProject("books", ["https://developers.google.com/books?hl=vi"]),
    YomiGhProject("google-play-book-downloader", [
      "https://github.com/devnoname120/google-play-book-downloader",
    ]),
    YomiGhProject("videodownloader", [
      "https://github.com/ChiefInnovator/videodownloader",
    ]),
    YomiGhProject("github-hosted-runners", [
      "https://docs.github.com/en/actions/reference/runners/github-hosted-runners",
    ]),
    YomiGhProject("building-windows-for-hybrid-intelligence", [
      "https://blogs.windows.com/windowsexperience/2026/10/07/building-windows-for-hybrid-intelligence/",
    ]),
    YomiGhProject("hybrid_oga.html", [
      "https://vgodsoe.github.io/ryzen-ai-documentation/hybrid_oga.html",
    ]),
    YomiGhProject("README.md", [
      "https://github.com/runtimerevolution/hybrid-to-native/blob/main/README.md",
    ]),
    YomiGhProject("pi-pwnbox-rogueap", [
      "https://github.com/koutto/pi-pwnbox-rogueap#wifi-hacking-cheatsheets--mind-map",
    ]),
    YomiGhProject("wifi-hacking.py", [
      "https://github.com/akashblackhat/wifi-hacking.py",
    ]),
    YomiGhProject("repositories", [
      "https://github.com/orgs/LibreOffice/repositories",
    ]),
    YomiGhProject("libreoffice", ["https://github.com/topics/libreoffice"]),
    YomiGhProject("www.git.openoffice.org", [
      "https://www.git.openoffice.org/",
    ]),
    YomiGhProject("openoffice", ["https://github.com/topics/openoffice"]),
    YomiGhProject("excel-functions", [
      "https://github.com/topics/excel-functions",
    ]),
    YomiGhProject("excel-functions-by-category", [
      "https://support.microsoft.com/vi-vn/excel/excel-functions-by-category",
    ]),
    YomiGhProject("danh-sach-cac-ham-trong-excel", [
      "https://excel.net.vn/danh-sach-cac-ham-trong-excel/",
    ]),
    YomiGhProject("excel-functions-alphabetical", [
      "https://support.microsoft.com/vi-vn/excel/excel-functions-alphabetical",
    ]),
    YomiGhProject("ESRkXZpwfgtJk4FZFERr05UBu1SYcWfn5RJxoSmLmmaPSw", [
      "https://1drv.ms/x/c/78d8476b55038486/ESRkXZpwfgtJk4FZFERr05UBu1SYcWfn5RJxoSmLmmaPSw?e=s2fFfN&nav=MTVfezZBRTU3MDkwLTEyMEEtNEY4Qi1BMTEyLTRGQzY5QkU3QTI0M30",
    ]),
    YomiGhProject("cac-ham-trong-excel-va-cac-vi-du-minh-hoa.html", [
      "https://blog.hocexcel.online/cac-ham-trong-excel-va-cac-vi-du-minh-hoa.html",
    ]),
    YomiGhProject("cac-ham-trong-excel", [
      "https://itgo.vn/cac-ham-trong-excel",
    ]),
    YomiGhProject("functions", [
      "https://exceljet.net/functions#:~:text=Complete%20reference%20for%20400%2B%20built-in%20Excel%20functions%2C%20each,1000%2B%20Formulas%2C%20101%20Functions%2C%20and%20New%20Excel%20Functions.",
    ]),
    YomiGhProject("cac-ham-trong-excel", [
      "https://www.ketoan.vn/kien-thuc-excel/cac-ham-trong-excel/",
    ]),
    YomiGhProject("formulas-functions", [
      "https://excelx.com/formulas-functions/",
    ]),
    YomiGhProject("Google-Slides", ["https://github.com/Google-Slides"]),
    YomiGhProject("FlyPPTTimer", ["https://github.com/Hona-Cao/FlyPPTTimer"]),
    YomiGhProject("utools-recent-projects", [
      "https://github.com/LanyuanXiaoyao-Studio/utools-recent-projects",
    ]),
    YomiGhProject("WPS-0DAY-20230809", [
      "https://github.com/b2git/WPS-0DAY-20230809",
    ]),
    YomiGhProject("document-ai-assistant", [
      "https://github.com/linhut/document-ai-assistant",
    ]),
    YomiGhProject("wps-office-all-mui-win-language", [
      "https://github.com/wachin/wps-office-all-mui-win-language",
    ]),
    YomiGhProject("gongwen-skill", ["https://github.com/linhut/gongwen-skill"]),
    YomiGhProject("WPS-AI", ["https://github.com/lewis-hui1202/WPS-AI"]),
    YomiGhProject("iexcel", ["https://github.com/houbb/iexcel"]),
    YomiGhProject("wps-invite", ["https://github.com/chairc/wps-invite"]),
    YomiGhProject("Auto_checkin_release", [
      "https://github.com/yaoysyao/Auto_checkin_release",
    ]),
    YomiGhProject("WPS-Office-2026-Setup-Guide", [
      "https://github.com/Streamesymbolize/WPS-Office-2026-Setup-Guide",
    ]),
    YomiGhProject("dsh-plugin-wps-office-next", [
      "https://github.com/sueccku/dsh-plugin-wps-office-next",
    ]),
    YomiGhProject("custom-seewo-splash-screen", [
      "https://github.com/fengyec2/custom-seewo-splash-screen",
    ]),
    YomiGhProject("wps-alfred-workflow", [
      "https://github.com/zacksleo/wps-alfred-workflow",
    ]),
    YomiGhProject("Jsa-vibcoding-skill", [
      "https://github.com/okazaki112/Jsa-vibcoding-skill",
    ]),
    YomiGhProject("WPS-Office-Pro-Setup", [
      "https://github.com/PlasmaShaper/WPS-Office-Pro-Setup",
    ]),
    YomiGhProject("wps-weboffice", ["https://github.com/eiixy/wps-weboffice"]),
    YomiGhProject("CharFloat", ["https://github.com/Jolly-J/CharFloat"]),
    YomiGhProject("WPS-Office-Pro-Setup", [
      "https://github.com/CreatureFiremanPatch/WPS-Office-Pro-Setup",
    ]),
    YomiGhProject("wps-office-installer", [
      "https://github.com/openSUSE-zh/wps-office-installer",
    ]),
    YomiGhProject("wps-office-12-language-packs", [
      "https://github.com/wachin/wps-office-12-language-packs",
    ]),
    YomiGhProject("WPS-Linux-Russian-MUI", [
      "https://github.com/SnakeSel/WPS-Linux-Russian-MUI",
    ]),
    YomiGhProject("Listary.FileAppPlugin.WPS", [
      "https://github.com/listary/Listary.FileAppPlugin.WPS",
    ]),
    YomiGhProject("wps-bug-ubuntu-fonts", [
      "https://github.com/tranhoangnam712/wps-bug-ubuntu-fonts",
    ]),
    YomiGhProject("zotero-obsidian-codex-word-wps-workflow", [
      "https://github.com/zdzZDZ123/zotero-obsidian-codex-word-wps-workflow",
    ]),
    YomiGhProject("wps-skills-py", [
      "https://github.com/JohnnyYwQ/wps-skills-py",
    ]),
    YomiGhProject("Fidecomiso-LatinTrust", [
      "https://github.com/GoranTopic/Fidecomiso-LatinTrust",
    ]),
    YomiGhProject("Office-backup-utilities", [
      "https://github.com/TonyV2Intl/Office-backup-utilities",
    ]),
    YomiGhProject("CO-WPSppt", ["https://github.com/thenw-123/CO-WPSppt"]),
    YomiGhProject("wps-office-turkish", [
      "https://github.com/osmanonurkoc/wps-office-turkish",
    ]),
    YomiGhProject("mathtype-extension", [
      "https://github.com/transpect/mathtype-extension",
    ]),
    YomiGhProject("moodle-filter_wiris", [
      "https://github.com/wiris/moodle-filter_wiris",
    ]),
    YomiGhProject("moodle-tinymce_tiny_mce_wiris", [
      "https://github.com/wiris/moodle-tinymce_tiny_mce_wiris",
    ]),
    YomiGhProject("mathmodel-pro", [
      "https://github.com/ll2010650-coder/mathmodel-pro",
    ]),
    YomiGhProject("moodle-atto_wiris", [
      "https://github.com/wiris/moodle-atto_wiris",
    ]),
    YomiGhProject("AcuteMSWord", ["https://github.com/aminya/AcuteMSWord"]),
    YomiGhProject("LaTeX", ["https://github.com/HuangCongQing/LaTeX"]),
    YomiGhProject("mathtype-pro", [
      "https://github.com/emblemtaleshadow/mathtype-pro",
    ]),
    YomiGhProject("wiris-moodle-docker", [
      "https://github.com/wiris/wiris-moodle-docker",
    ]),
    YomiGhProject("Math-Editor", ["https://github.com/Jack251970/Math-Editor"]),
    YomiGhProject("Inserting-Math-Formulas-In-MS-Office", [
      "https://github.com/Nick12-hub/Inserting-Math-Formulas-In-MS-Office",
    ]),
    YomiGhProject("word-mathtype-native-equations", [
      "https://github.com/xiao0xiao0/word-mathtype-native-equations",
    ]),
    YomiGhProject("nsfc-md2docx", ["https://github.com/TLE-11/nsfc-md2docx"]),
    YomiGhProject("word-omml-mathtype", [
      "https://github.com/YYK-beep/word-omml-mathtype",
    ]),
    YomiGhProject("YYGPT-mathtype-copy", [
      "https://github.com/yeshen246800-source/YYGPT-mathtype-copy",
    ]),
    YomiGhProject("formula-flow", [
      "https://github.com/goldfish-x/formula-flow",
    ]),
    YomiGhProject("huong-dan-mathtype", [
      "https://softvn.vn/huong-dan-mathtype/",
    ]),
    YomiGhProject("FormulaSnip", ["https://github.com/loLollipop/FormulaSnip"]),
    YomiGhProject("MathType-Cheatsheet", [
      "https://github.com/zxl19/MathType-Cheatsheet",
    ]),
    YomiGhProject("mathtype-for-word", [
      "https://github.com/felimet/mathtype-for-word",
    ]),
    YomiGhProject("poi.apache.org", ["https://poi.apache.org/"]),
    YomiGhProject("PdfBox-Android", [
      "https://github.com/TomRoush/PdfBox-Android",
    ]),
    YomiGhProject("tika.apache.org", ["https://tika.apache.org/"]),
    YomiGhProject("droiddoc", ["https://github.com/youichi-uda/droiddoc"]),
    YomiGhProject("android-microsoft-office-library-doc-docx-xls-ppt-etc", [
      "https://stackoverflow.com/questions/4854947/android-microsoft-office-library-doc-docx-xls-ppt-etc",
    ]),
    YomiGhProject("OpenDocument.droid", [
      "https://github.com/opendocument-app/OpenDocument.droid",
    ]),
    YomiGhProject("DocumentReader", [
      "https://github.com/Asutosh11/DocumentReader",
    ]),
    YomiGhProject("DocViewer", ["https://github.com/Victor2018/DocViewer"]),
    YomiGhProject("Aspose.Words-for-Android", [
      "https://github.com/sabir-aspose/Aspose.Words-for-Android",
    ]),
    YomiGhProject("AndroidPoiWord", [
      "https://github.com/fuweiwei/AndroidPoiWord",
    ]),
    YomiGhProject("WordPress-Android", [
      "https://github.com/wordpress-mobile/WordPress-Android",
    ]),
    YomiGhProject("Aspose_Words_Android", [
      "https://github.com/ashille/Aspose_Words_Android",
    ]),
    YomiGhProject("android-excel", ["https://github.com/lxx328/android-excel"]),
    YomiGhProject("worksheet", ["https://elirehema.github.io/worksheet/"]),
    YomiGhProject("kexcel", ["https://shreyashkore.github.io/kexcel/"]),
    YomiGhProject("142156578", [
      "https://blog.csdn.net/gitblog_00500/article/details/142156578",
    ]),
    YomiGhProject("142242607", [
      "https://blog.csdn.net/gitblog_00797/article/details/142242607",
    ]),
    YomiGhProject("ff700c997a06c2a8a84966f7f0d6f4c3", [
      "https://gist.github.com/mwshubham/ff700c997a06c2a8a84966f7f0d6f4c3",
    ]),
    YomiGhProject("AndroidExcelReadWrite", [
      "https://github.com/yangxiaoge/AndroidExcelReadWrite",
    ]),
    YomiGhProject("ExcelView", ["https://github.com/September26/ExcelView"]),
    YomiGhProject("AndroidXLSViewer", [
      "https://github.com/vkatz/AndroidXLSViewer",
    ]),
    YomiGhProject("ExcelReader", [
      "https://github.com/Srihitha18798/ExcelReader",
    ]),
    YomiGhProject("Android_Excel", [
      "https://github.com/reallin/Android_Excel",
    ]),
    YomiGhProject("Android-Office", [
      "https://github.com/zjtone/Android-Office",
    ]),
    YomiGhProject("android-excel", ["https://github.com/topics/android-excel"]),
    YomiGhProject("android-translations-converter-plugin", [
      "https://github.com/Crustack/android-translations-converter-plugin",
    ]),
    YomiGhProject("MyExcel", ["https://github.com/ma-amin/MyExcel"]),
    YomiGhProject("excelPanel", ["https://github.com/zhouchaoyuan/excelPanel"]),
    YomiGhProject("worksheet", ["https://github.com/elirehema/worksheet"]),
    YomiGhProject("droidslide", ["https://github.com/youichi-uda/droidslide"]),
    YomiGhProject("pptviewer-android", [
      "https://github.com/itsrts/pptviewer-android",
    ]),
    YomiGhProject("droidslide", ["https://y1uda.gumroad.com/l/droidslide"]),
    YomiGhProject("android-java", [
      "https://products.aspose.com/slides/android-java/",
    ]),
    YomiGhProject("PPT-Controller", [
      "https://github.com/ideepu/PPT-Controller",
    ]),
    YomiGhProject("Android-Offic", ["https://github.com/zjtone/Android-Offic"]),
    YomiGhProject("ooxml-tools", ["https://github.com/ooxml-tools"]),
    YomiGhProject("Open-XML-SDK", ["https://github.com/dotnet/Open-XML-SDK"]),
    YomiGhProject("ooxml", ["https://github.com/pterror/ooxml"]),
    YomiGhProject("ooxml-tools", [
      "https://scuderia-fe.github.io/ooxml-tools/",
    ]),
    YomiGhProject("toolbox", ["https://ooxml-tools.github.io/toolbox/"]),
    YomiGhProject("toolbox", ["https://github.com/ooxml-tools/toolbox"]),
    YomiGhProject("ooxml.org", ["https://ooxml.org/"]),
    YomiGhProject("ooxml.silurus.dev", ["https://ooxml.silurus.dev/"]),
    YomiGhProject("office-open-xml-viewer", [
      "https://github.com/yukiyokotani/office-open-xml-viewer",
    ]),
    YomiGhProject("openooxml.com", ["https://openooxml.com/"]),
    YomiGhProject("betteroffice", [
      "https://github.com/openooxml/betteroffice",
    ]),
    YomiGhProject("ooxml-excel-editor", [
      "https://ojadeveloper.github.io/ooxml-excel-editor/",
    ]),
    YomiGhProject("ooxml", ["https://pterror.github.io/ooxml/"]),
    YomiGhProject("odfdo", ["https://github.com/jdum/odfdo"]),
    YomiGhProject("fiduswriter", [
      "https://github.com/fiduswriter/fiduswriter",
    ]),
    YomiGhProject("maltreport", ["https://github.com/oldrev/maltreport"]),
    YomiGhProject("peek", ["https://github.com/corbindavenport/peek"]),
    YomiGhProject("SODS", ["https://github.com/miachm/SODS"]),
    YomiGhProject("rodf", ["https://github.com/westonganger/rodf"]),
    YomiGhProject("fastods", ["https://github.com/jferard/fastods"]),
    YomiGhProject("OpenDocument.core", [
      "https://github.com/opendocument-app/OpenDocument.core",
    ]),
    YomiGhProject("odf-kit", ["https://github.com/GitHubNewbie0/odf-kit"]),
    YomiGhProject("simple-odf", ["https://github.com/connium/simple-odf"]),
    YomiGhProject("pwic", ["https://github.com/gitbra/pwic"]),
    YomiGhProject("odswriter", ["https://github.com/mmulqueen/odswriter"]),
    YomiGhProject("rechenbrett", ["https://github.com/fwilhe2/rechenbrett"]),
    YomiGhProject("opencalc", ["https://github.com/CasualOffice/opencalc"]),
    YomiGhProject("opendocument-security", [
      "https://github.com/nbeguier/opendocument-security",
    ]),
    YomiGhProject("odp2md", ["https://github.com/seichter/odp2md"]),
    YomiGhProject("ElectricalDiagrams", [
      "https://github.com/ma-laforge/ElectricalDiagrams",
    ]),
    YomiGhProject("ods-reader", ["https://github.com/jze/ods-reader"]),
    YomiGhProject("asciidoctor-converter-opendocument", [
      "https://github.com/thom4parisot/asciidoctor-converter-opendocument",
    ]),
    YomiGhProject("iitj_family_tree", [
      "https://github.com/devlup-labs/iitj_family_tree",
    ]),
    YomiGhProject("tidyods", ["https://github.com/mattkerlogue/tidyods"]),
    YomiGhProject("how-to-install-microsoft-visual-basic-for-applicat", [
      "https://learn.microsoft.com/en-us/answers/questions/1852367/how-to-install-microsoft-visual-basic-for-applicat",
    ]),
    YomiGhProject("how-to-enable-macros-in-excel-for-office-365.html", [
      "https://www.techbloat.com/how-to-enable-macros-in-excel-for-office-365.html",
    ]),
    YomiGhProject(
      "how-to-add-vba-to-excel-a-step-by-step-guide-for-beginners",
      [
        "https://www.supportyourtech.com/excel/how-to-add-vba-to-excel-a-step-by-step-guide-for-beginners/",
      ],
    ),
    YomiGhProject("work-with-vba-macros-in-excel-for-the-web", [
      "https://support.microsoft.com/vi-vn/excel/work-with-vba-macros-in-excel-for-the-web",
    ]),
    YomiGhProject(
      "huong-dan-mo-vba-trong-excel-va-tim-hieu-cac-cua-so-lam-viec-trong-vba-7166.html",
      [
        "https://gitiho.com/blog/huong-dan-mo-vba-trong-excel-va-tim-hieu-cac-cua-so-lam-viec-trong-vba-7166.html",
      ],
    ),
    YomiGhProject("VBA", ["https://allenmattson.github.io/VBA/"]),
    YomiGhProject("VBA", ["https://github.com/AllenMattson/VBA"]),
    YomiGhProject(
      "how-to-download-vba-support-library-for-wps-office-a-detailed-guide-quick-tutorials-1878140",
      [
        "https://www.wps.com/academy/how-to-download-vba-support-library-for-wps-office-a-detailed-guide-quick-tutorials-1878140/",
      ],
    ),
    YomiGhProject("office", [
      "https://code.visualstudio.com/docs/other/office",
    ]),
    YomiGhProject("M365-Office-Macros", [
      "https://github.com/TrevorStyler/M365-Office-Macros",
    ]),
    YomiGhProject("Microsoft_Office_Automation_VBA", [
      "https://github.com/ThiagoMaria-SecurityIT/Microsoft_Office_Automation_VBA",
    ]),
    YomiGhProject("office365_amsi_bypass", [
      "https://idafchev.github.io/blog/office365_amsi_bypass/",
    ]),
    YomiGhProject("office-ribbonx-editor.htm", [
      "https://bettersolutions.com/vba/ribbon/office-ribbonx-editor.htm",
    ]),
    YomiGhProject("v1.9.0", [
      "https://github.com/fernandreu/office-ribbonx-editor/releases/tag/v1.9.0",
    ]),
    YomiGhProject("runtime-desktop-6.0.7-windows-x64-installer", [
      "https://dotnet.microsoft.com/en-us/download/dotnet/thank-you/runtime-desktop-6.0.7-windows-x64-installer",
    ]),
    YomiGhProject("5d229d8f5b9981a20c72a821f99400b7", [
      "https://gist.github.com/bran921007/5d229d8f5b9981a20c72a821f99400b7",
    ]),
    YomiGhProject("how-to-put-excel-vba-into-git", [
      "https://stackoverflow.com/questions/36024342/how-to-put-excel-vba-into-git",
    ]),
    YomiGhProject("introduction", [
      "https://pnp.github.io/cli-microsoft365/sample-scripts/introduction/",
    ]),
    YomiGhProject("esbuild", ["https://github.com/evanw/esbuild"]),
    YomiGhProject("content-types", [
      "https://esbuild.github.io/content-types/#ts-vs-tsx",
    ]),
    YomiGhProject("cli-microsoft365", [
      "https://github.com/pnp/cli-microsoft365",
    ]),
    YomiGhProject("PowerpointToPDF", [
      "https://github.com/David-Brewin/PowerpointToPDF",
    ]),
    YomiGhProject("MicroVBA-PowerPoint", [
      "https://github.com/nilostolte/MicroVBA-PowerPoint",
    ]),
    YomiGhProject("getting-started-with-vba-in-office", [
      "https://learn.microsoft.com/en-us/office/vba/library-reference/concepts/getting-started-with-vba-in-office",
    ]),
    YomiGhProject("2020-08-22-ppt-slides", [
      "https://hypertextassassin0273.github.io/mini-projects/2020-08-22-ppt-slides/",
    ]),
    YomiGhProject("PptxGenJS", ["https://gitbrent.github.io/PptxGenJS/"]),
    YomiGhProject("ppt-master-examples", [
      "https://hugohe3.github.io/ppt-master-examples/",
    ]),
    YomiGhProject("4b0e1be7f2dfcc4e51e2ace50426f67d", [
      "https://gist.github.com/pcmoritz/4b0e1be7f2dfcc4e51e2ace50426f67d",
    ]),
    YomiGhProject("scientific-illustrator", [
      "https://github.com/icebird1998/scientific-illustrator",
    ]),
    YomiGhProject("powerpoint-automation", [
      "https://github.com/topics/powerpoint-automation",
    ]),
    YomiGhProject("PPspliT", ["https://github.com/maxonthegit/PPspliT"]),
    YomiGhProject("Instrumenta", ["https://github.com/iappyx/Instrumenta"]),
    YomiGhProject("odin-slides", [
      "https://github.com/leonid20000/odin-slides",
    ]),
    YomiGhProject("ProDeck", [
      "https://github.com/rodrigolourencofarinha/ProDeck",
    ]),
    YomiGhProject("presentation-skill", [
      "https://github.com/siril9/presentation-skill",
    ]),
    YomiGhProject("SlideArchitect", [
      "https://github.com/mrigankad/SlideArchitect",
    ]),
    YomiGhProject("4c2b19f0ff4489c7e1a25720e0c5b964", [
      "https://gist.github.com/whoiscarlo/4c2b19f0ff4489c7e1a25720e0c5b964",
    ]),
    YomiGhProject("pptx-animation-skill", [
      "https://github.com/BramAlkema/pptx-animation-skill",
    ]),
    YomiGhProject("table-samples.md", [
      "https://github.com/OfficeDev/office-scripts-docs/blob/main/docs/resources/samples/table-samples.md",
    ]),
    YomiGhProject("office-table-design", [
      "https://github.com/Lewis4564/office-table-design",
    ]),
    YomiGhProject("ff6839d9593ec8afca0ba97d890cce58", [
      "https://gist.github.com/plembo/ff6839d9593ec8afca0ba97d890cce58",
    ]),
    YomiGhProject("github-microsoft-onedrive", [
      "https://www.ayudo.ai/app-integrations/github-microsoft-onedrive",
    ]),
    YomiGhProject("File-Host", ["https://github.com/sacms/File-Host"]),
    YomiGhProject("mediafire-dl-async", [
      "https://github.com/bayy420-999/mediafire-dl-async",
    ]),
    YomiGhProject("mediafire_folder_downloader", [
      "https://github.com/mehmoodkhanzafarkhel-56/mediafire_folder_downloader",
    ]),
    YomiGhProject("mdl", ["https://github.com/dheison0/mdl"]),
    YomiGhProject("MediaFolderPro", [
      "https://github.com/Hexadecinull/MediaFolderPro",
    ]),
    YomiGhProject("OpenDownloader", [
      "https://github.com/Adolfbeaming31/OpenDownloader",
    ]),
    YomiGhProject("mediafire_py", [
      "https://github.com/retired64/mediafire_py",
    ]),
    YomiGhProject("mediafire-folder-downloader", [
      "https://github.com/GonnAnalytics/mediafire-folder-downloader",
    ]),
    YomiGhProject("mediafire-url-parser", [
      "https://github.com/joaozacchello08/mediafire-url-parser",
    ]),
    YomiGhProject("mediafire-dl", [
      "https://github.com/juvenal-yescas/mediafire-dl",
    ]),
    YomiGhProject("sync", ["https://ndy40.github.io/cairn/docs/sync/"]),
    YomiGhProject("5158985", ["https://gist.github.com/patrickng/5158985"]),
    YomiGhProject("Document-Scanner", [
      "https://github.com/farimarwat/Document-Scanner",
    ]),
    YomiGhProject("Python-Document-Scanner-OpenCV", [
      "https://github.com/ArashNasrEsfahani/Python-Document-Scanner-OpenCV",
    ]),
    YomiGhProject("aasaan", ["https://github.com/Fireboltz/aasaan"]),
    YomiGhProject("LNotes-Linked-Notes", [
      "https://github.com/Gauravv97/LNotes-Linked-Notes",
    ]),
    YomiGhProject("CamScanner", [
      "https://github.com/nimadorostkar/CamScanner",
    ]),
    YomiGhProject("camscanner", [
      "https://github.com/CS-CamScanner/camscanner",
    ]),
    YomiGhProject("2026-10-13-gemini-4-argon-in-github-copilot", [
      "https://github.blog/changelog/2026-10-13-gemini-4-argon-in-github-copilot/",
    ]),
    YomiGhProject("app", ["https://gemini.google.com/app"]),
    YomiGhProject("chat", [
      "https://copilot.com/chat?fromcode=cmmlf487uwy&es=Click&redirfrom=userTypeCookie&redirfrom=cosmicRingCookie",
    ]),
    YomiGhProject("control-review-sources-copilot-chat", [
      "https://support.microsoft.com/en-us/microsoft-365-copilot/control-review-sources-copilot-chat",
    ]),
    YomiGhProject("prompts.chat", ["https://github.com/f/prompts.chat"]),
    YomiGhProject("ChatGPT-API-Python", [
      "https://abdur75648.github.io/ChatGPT-API-Python/",
    ]),
    YomiGhProject("chatgpt.com", ["https://chatgpt.com/"]),
    YomiGhProject("harness", ["https://www.deepseek.com/en/harness/"]),
    YomiGhProject("Deepseek-API", ["https://github.com/sums001/Deepseek-API"]),
    YomiGhProject("chat.deepseek.com", ["https://chat.deepseek.com/"]),
    YomiGhProject("deepseek-excel-data-guide", [
      "https://deepseek-ai.xin/vi/blog/deepseek-excel-data-guide/",
    ]),
    YomiGhProject("open-source", ["https://x.ai/open-source"]),
    YomiGhProject("2026-08-14-grok-4-6-is-now-available-in-github-copilot", [
      "https://github.blog/changelog/2026-08-14-grok-4-6-is-now-available-in-github-copilot/",
    ]),
    YomiGhProject("connectors", ["https://grok.com/connectors"]),
    YomiGhProject("the-5-best-github-repos-for-claude-code", [
      "https://buildwire.ai/blog/the-5-best-github-repos-for-claude-code/",
    ]),
    YomiGhProject("new", ["https://claude.ai/new"]),
    YomiGhProject(
      "2026-09-22-claude-opus-5-5-is-now-available-in-github-copilot",
      [
        "https://github.blog/changelog/2026-09-22-claude-opus-5-5-is-now-available-in-github-copilot/",
      ],
    ),
    YomiGhProject("android-dex-desktop-mode", [
      "https://techydruid.com/android-dex-desktop-mode/",
    ]),
    YomiGhProject("zed-android-port", [
      "https://github.com/Dylanmurzello/zed-android-port",
    ]),
    YomiGhProject("Xreal-tools", ["https://github.com/nudou350/Xreal-tools"]),
    YomiGhProject("dex_feature_enabler", [
      "https://github.com/yukkerike/dex_feature_enabler",
    ]),
    YomiGhProject("momiji", ["https://github.com/yazanj082/momiji"]),
    YomiGhProject("droidpier", ["https://github.com/gysosin/droidpier"]),
    YomiGhProject("Enter2Send", ["https://github.com/ctech1313/Enter2Send"]),
    YomiGhProject("DeXtop-mode", [
      "https://github.com/super-magistro/DeXtop-mode",
    ]),
    YomiGhProject("android-dex", ["https://github.com/Misael-art/android-dex"]),
    YomiGhProject("MyDeX", ["https://github.com/Keremerk/MyDeX"]),
    YomiGhProject("Android-Dex", ["https://shrey113.github.io/Android-Dex/"]),
    YomiGhProject("android-dex", [
      "https://github.com/KaliRootSuperUser/android-dex",
    ]),
    YomiGhProject("deoptfuscator", [
      "https://github.com/Gyoonus/deoptfuscator",
    ]),
    YomiGhProject("AndroidDexEncrypt", [
      "https://github.com/maxwell-nc/AndroidDexEncrypt",
    ]),
    YomiGhProject("LoadDex", ["https://github.com/VincentTung/LoadDex"]),
    YomiGhProject("libdex-ts", ["https://github.com/poping520/libdex-ts"]),
  ]),
];

class GithubProjectsScreen extends StatefulWidget {
  const GithubProjectsScreen({super.key});

  @override
  State<GithubProjectsScreen> createState() => _GithubProjectsScreenState();
}

class _GithubProjectsScreenState extends State<GithubProjectsScreen> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final q = _q.toLowerCase();
    final groups = [
      for (final g in yomiGithubProjects)
        (
          g,
          g.items
              .where(
                (p) =>
                    q.isEmpty ||
                    p.name.toLowerCase().contains(q) ||
                    p.urls.any((u) => u.toLowerCase().contains(q)),
              )
              .toList(),
        ),
    ].where((e) => e.$2.isNotEmpty).toList();
    final total = yomiGithubProjects.fold<int>(0, (a, g) => a + g.items.length);
    return Scaffold(
      appBar: AppBar(title: Text(tr('Dự án GitHub đã sử dụng'))),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              tr(
                'Danh mục {p0} dự án và tài liệu tích hợp hoặc tham khảo. Các liên kết tham khảo không đồng nghĩa với tính năng đã được tích hợp.',
                {'p0': total},
              ),
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                isDense: true,
                prefixIcon: const Icon(Icons.search),
                hintText: tr('Tìm dự án'),
                border: const OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _q = v.trim()),
            ),
          ),
          for (final (g, items) in groups)
            ExpansionTile(
              initiallyExpanded:
                  q.isNotEmpty || identical(g, yomiGithubProjects.first),
              title: Text(
                tr(g.title),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(tr('{p0} dự án', {'p0': items.length})),
              children: [
                for (final p in items)
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.code),
                    title: Text(tr(p.name)),
                    subtitle: Text(
                      p.urls.join('\n'),
                      style: const TextStyle(fontSize: 11),
                    ),
                    onTap: p.urls.isEmpty ? null : () => _open(p.urls.first),
                    onLongPress: p.urls.isEmpty
                        ? null
                        : () {
                            Clipboard.setData(
                              ClipboardData(text: p.urls.join('\n')),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(tr('Đã sao chép liên kết')),
                              ),
                            );
                          },
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _open(String url) async {
    final u = Uri.tryParse(url);
    if (u == null) return;
    try {
      await launchUrl(u, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }
}
