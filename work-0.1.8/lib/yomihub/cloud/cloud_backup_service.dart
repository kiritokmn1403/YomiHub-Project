import 'dart:typed_data';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// A backup file stored on a cloud target.
class CloudFile {
  final String id;
  final String name;
  final int size;
  final DateTime? modified;
  CloudFile(this.id, this.name, this.size, this.modified);
}

/// What a provider needs from the user to connect.
enum CloudAuthKind { deviceCode, pasteCode, credentials }

/// One step of an interactive sign-in, shown by the settings screen.
class CloudAuthPrompt {
  /// Where the user must go (device-code / paste-code flows).
  final String? url;

  /// Code to type on that page (device-code flow).
  final String? userCode;
  final String message;
  CloudAuthPrompt({this.url, this.userCode, required this.message});
}

typedef CloudConfig = Map<String, String>;

/// Common interface for every backup target.
abstract class CloudProvider {
  String get id;
  String get displayName;
  CloudAuthKind get authKind;

  /// Fields the user fills in before signing in (client id, server url, ...).
  List<CloudField> get fields;

  /// Short help text: how to obtain the credentials.
  String get help;

  /// Whether files can be listed and downloaded back (restore).
  bool get canRestore => true;

  late CloudConfig config;

  bool get isConnected;

  /// Starts sign-in. For device-code flows this returns the code to show and
  /// [completeAuth] then polls; for paste-code flows [completeAuth] receives
  /// the pasted code; for credential providers it simply verifies them.
  Future<CloudAuthPrompt?> beginAuth();
  Future<void> completeAuth({String? pastedCode});

  Future<void> upload(File file);
  Future<List<CloudFile>> list();
  Future<File> download(CloudFile file, Directory into);
}

class CloudField {
  final String key;
  final String label;
  final bool secret;
  final String? hint;
  const CloudField(this.key, this.label, {this.secret = false, this.hint});
}

const _folderName = 'YomiHub';
final _client = http.Client();

String _q(Map<String, String> m) =>
    m.entries.map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}').join('&');

Map<String, dynamic> _json(http.Response r, String what) {
  if (r.statusCode < 200 || r.statusCode >= 300) {
    throw Exception('$what: HTTP ${r.statusCode} ${r.body.length > 300 ? r.body.substring(0, 300) : r.body}');
  }
  return r.body.isEmpty ? {} : jsonDecode(r.body) as Map<String, dynamic>;
}

/// OAuth token bookkeeping shared by Google Drive / OneDrive / Dropbox.
mixin _OAuth on CloudProvider {
  String get tokenUrl;

  @override
  bool get isConnected => (config['refresh_token'] ?? '').isNotEmpty;

  Map<String, String> get refreshExtra => {};

  Future<String> accessToken() async {
    final exp = int.tryParse(config['expires_at'] ?? '') ?? 0;
    if ((config['access_token'] ?? '').isNotEmpty &&
        DateTime.now().millisecondsSinceEpoch < exp - 60000) {
      return config['access_token']!;
    }
    final r = await _client.post(
      Uri.parse(tokenUrl),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: _q({
        'grant_type': 'refresh_token',
        'refresh_token': config['refresh_token'] ?? '',
        'client_id': config['client_id'] ?? '',
        if ((config['client_secret'] ?? '').isNotEmpty)
          'client_secret': config['client_secret']!,
        ...refreshExtra,
      }),
    );
    _storeTokens(_json(r, '$displayName token refresh'));
    await CloudBackupService.instance.save(this);
    return config['access_token']!;
  }

  void _storeTokens(Map<String, dynamic> t) {
    config['access_token'] = '${t['access_token']}';
    if (t['refresh_token'] != null) config['refresh_token'] = '${t['refresh_token']}';
    final secs = (t['expires_in'] as num?)?.toInt() ?? 3600;
    config['expires_at'] = '${DateTime.now().millisecondsSinceEpoch + secs * 1000}';
  }

  /// RFC 8628 device authorization grant.
  Future<CloudAuthPrompt> _deviceStart(String url, Map<String, String> body) async {
    final r = await _client.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: _q(body),
    );
    final d = _json(r, '$displayName sign-in');
    config['_device_code'] = '${d['device_code']}';
    config['_interval'] = '${d['interval'] ?? 5}';
    config['_device_expires'] =
        '${DateTime.now().millisecondsSinceEpoch + ((d['expires_in'] as num?)?.toInt() ?? 900) * 1000}';
    final verify = '${d['verification_uri'] ?? d['verification_url']}';
    return CloudAuthPrompt(
      url: verify,
      userCode: '${d['user_code']}',
      message: 'Mở ${verify} và nhập mã bên dưới, rồi quay lại app.',
    );
  }

  Future<void> _devicePoll(Map<String, String> extra) async {
    var interval = int.tryParse(config['_interval'] ?? '5') ?? 5;
    final deadline = int.tryParse(config['_device_expires'] ?? '') ?? 0;
    while (DateTime.now().millisecondsSinceEpoch < deadline) {
      await Future.delayed(Duration(seconds: interval));
      final r = await _client.post(
        Uri.parse(tokenUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: _q({
          'grant_type': 'urn:ietf:params:oauth:grant-type:device_code',
          'device_code': config['_device_code'] ?? '',
          'client_id': config['client_id'] ?? '',
          ...extra,
        }),
      );
      final d = r.body.isEmpty ? <String, dynamic>{} : jsonDecode(r.body) as Map<String, dynamic>;
      if (r.statusCode == 200 && d['access_token'] != null) {
        _storeTokens(d);
        config.remove('_device_code');
        return;
      }
      final err = '${d['error']}';
      if (err == 'authorization_pending') continue;
      if (err == 'slow_down') {
        interval += 5;
        continue;
      }
      throw Exception('$displayName: $err ${d['error_description'] ?? ''}');
    }
    throw Exception('$displayName: hết thời gian chờ đăng nhập');
  }
}

// ───────────────────────────── Google Drive ─────────────────────────────

class GoogleDriveProvider extends CloudProvider with _OAuth {
  @override
  String get id => 'gdrive';
  @override
  String get displayName => 'Google Drive';
  @override
  CloudAuthKind get authKind => CloudAuthKind.deviceCode;
  @override
  String get tokenUrl => 'https://oauth2.googleapis.com/token';
  @override
  Map<String, String> get refreshExtra => {};
  @override
  List<CloudField> get fields => const [
        CloudField('client_id', 'Client ID'),
        CloudField('client_secret', 'Client secret', secret: true),
      ];
  @override
  String get help =>
      'Google Cloud Console → APIs & Services → bật "Google Drive API" → Credentials → '
      'Create OAuth client ID → loại "TVs and Limited Input devices". Dán Client ID và Client secret vào đây. '
      'App chỉ dùng quyền drive.file (chỉ thấy file do YomiHub tạo).';

  @override
  Future<CloudAuthPrompt?> beginAuth() => _deviceStart(
        'https://oauth2.googleapis.com/device/code',
        {'client_id': config['client_id'] ?? '', 'scope': 'https://www.googleapis.com/auth/drive.file'},
      );

  @override
  Future<void> completeAuth({String? pastedCode}) =>
      _devicePoll({'client_secret': config['client_secret'] ?? ''});

  Future<Map<String, String>> _h() async => {'Authorization': 'Bearer ${await accessToken()}'};

  Future<String> _folderId() async {
    if ((config['folder_id'] ?? '').isNotEmpty) return config['folder_id']!;
    final q = "name='$_folderName' and mimeType='application/vnd.google-apps.folder' and trashed=false";
    final r = await _client.get(
      Uri.parse('https://www.googleapis.com/drive/v3/files?q=${Uri.encodeQueryComponent(q)}&fields=files(id)'),
      headers: await _h(),
    );
    final files = (_json(r, 'Drive list')['files'] as List?) ?? [];
    String id;
    if (files.isNotEmpty) {
      id = files.first['id'];
    } else {
      final c = await _client.post(
        Uri.parse('https://www.googleapis.com/drive/v3/files?fields=id'),
        headers: {...await _h(), 'Content-Type': 'application/json'},
        body: jsonEncode({'name': _folderName, 'mimeType': 'application/vnd.google-apps.folder'}),
      );
      id = _json(c, 'Drive mkdir')['id'];
    }
    config['folder_id'] = id;
    await CloudBackupService.instance.save(this);
    return id;
  }

  @override
  Future<void> upload(File file) async {
    final folder = await _folderId();
    final boundary = 'yomihub${Random().nextInt(1 << 31)}';
    final meta = jsonEncode({'name': p.basename(file.path), 'parents': [folder]});
    final bytes = await file.readAsBytes();
    final body = BytesBuilder()
      ..add(utf8.encode('--$boundary\r\nContent-Type: application/json; charset=UTF-8\r\n\r\n$meta\r\n'))
      ..add(utf8.encode('--$boundary\r\nContent-Type: application/octet-stream\r\n\r\n'))
      ..add(bytes)
      ..add(utf8.encode('\r\n--$boundary--\r\n'));
    final r = await _client.post(
      Uri.parse('https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart'),
      headers: {...await _h(), 'Content-Type': 'multipart/related; boundary=$boundary'},
      body: body.takeBytes(),
    );
    _json(r, 'Drive upload');
  }

  @override
  Future<List<CloudFile>> list() async {
    final folder = await _folderId();
    final q = "'$folder' in parents and trashed=false";
    final r = await _client.get(
      Uri.parse('https://www.googleapis.com/drive/v3/files?q=${Uri.encodeQueryComponent(q)}'
          '&orderBy=modifiedTime desc&fields=files(id,name,size,modifiedTime)&pageSize=100'),
      headers: await _h(),
    );
    return ((_json(r, 'Drive list')['files'] as List?) ?? [])
        .map((f) => CloudFile(f['id'], f['name'], int.tryParse('${f['size']}') ?? 0,
            DateTime.tryParse('${f['modifiedTime']}')))
        .toList();
  }

  @override
  Future<File> download(CloudFile f, Directory into) async {
    final r = await _client.get(
      Uri.parse('https://www.googleapis.com/drive/v3/files/${f.id}?alt=media'),
      headers: await _h(),
    );
    if (r.statusCode != 200) throw Exception('Drive download: HTTP ${r.statusCode}');
    return File(p.join(into.path, f.name)).writeAsBytes(r.bodyBytes);
  }
}

// ───────────────────────────── OneDrive ─────────────────────────────

class OneDriveProvider extends CloudProvider with _OAuth {
  @override
  String get id => 'onedrive';
  @override
  String get displayName => 'OneDrive';
  @override
  CloudAuthKind get authKind => CloudAuthKind.deviceCode;
  @override
  String get tokenUrl => 'https://login.microsoftonline.com/common/oauth2/v2.0/token';
  static const _scope = 'Files.ReadWrite.AppFolder offline_access';
  @override
  Map<String, String> get refreshExtra => {'scope': _scope};
  @override
  List<CloudField> get fields => const [CloudField('client_id', 'Application (client) ID')];
  @override
  String get help =>
      'portal.azure.com → App registrations → New registration (chọn "Personal Microsoft accounts and '
      'organizational accounts") → Authentication → bật "Allow public client flows". '
      'API permissions: Files.ReadWrite.AppFolder. Dán Application (client) ID vào đây. '
      'Bản sao lưu nằm trong thư mục Apps/YomiHub trên OneDrive.';

  @override
  Future<CloudAuthPrompt?> beginAuth() => _deviceStart(
        'https://login.microsoftonline.com/common/oauth2/v2.0/devicecode',
        {'client_id': config['client_id'] ?? '', 'scope': _scope},
      );

  @override
  Future<void> completeAuth({String? pastedCode}) => _devicePoll({});

  Future<Map<String, String>> _h() async => {'Authorization': 'Bearer ${await accessToken()}'};
  static const _root = 'https://graph.microsoft.com/v1.0/me/drive/special/approot';

  @override
  Future<void> upload(File file) async {
    final name = Uri.encodeComponent(p.basename(file.path));
    final r = await _client.put(
      Uri.parse('$_root:/$name:/content'),
      headers: {...await _h(), 'Content-Type': 'application/octet-stream'},
      body: await file.readAsBytes(),
    );
    _json(r, 'OneDrive upload');
  }

  @override
  Future<List<CloudFile>> list() async {
    final r = await _client.get(
      Uri.parse('$_root/children?\$top=200&\$select=id,name,size,lastModifiedDateTime'),
      headers: await _h(),
    );
    final items = ((_json(r, 'OneDrive list')['value'] as List?) ?? [])
        .map((f) => CloudFile(f['id'], f['name'], (f['size'] as num?)?.toInt() ?? 0,
            DateTime.tryParse('${f['lastModifiedDateTime']}')))
        .toList();
    items.sort((a, b) => (b.modified ?? DateTime(0)).compareTo(a.modified ?? DateTime(0)));
    return items;
  }

  @override
  Future<File> download(CloudFile f, Directory into) async {
    final r = await _client.get(
      Uri.parse('https://graph.microsoft.com/v1.0/me/drive/items/${f.id}/content'),
      headers: await _h(),
    );
    if (r.statusCode != 200) throw Exception('OneDrive download: HTTP ${r.statusCode}');
    return File(p.join(into.path, f.name)).writeAsBytes(r.bodyBytes);
  }
}

// ───────────────────────────── Dropbox ─────────────────────────────

class DropboxProvider extends CloudProvider with _OAuth {
  @override
  String get id => 'dropbox';
  @override
  String get displayName => 'Dropbox';
  @override
  CloudAuthKind get authKind => CloudAuthKind.pasteCode;
  @override
  String get tokenUrl => 'https://api.dropboxapi.com/oauth2/token';
  @override
  List<CloudField> get fields => const [CloudField('client_id', 'App key')];
  @override
  String get help =>
      'dropbox.com/developers/apps → Create app → "Scoped access", "App folder". Tab Permissions: bật '
      'files.content.write và files.content.read. Dán App key vào đây. Bấm Kết nối, cho phép trên trình '
      'duyệt rồi dán mã Dropbox hiển thị vào app.';

  @override
  Future<CloudAuthPrompt?> beginAuth() async {
    final rnd = Random.secure();
    final verifier = base64UrlEncode(List.generate(48, (_) => rnd.nextInt(256))).replaceAll('=', '');
    config['_verifier'] = verifier;
    final challenge = base64UrlEncode(sha256.convert(ascii.encode(verifier)).bytes).replaceAll('=', '');
    final url = 'https://www.dropbox.com/oauth2/authorize?${_q({
      'client_id': config['client_id'] ?? '',
      'response_type': 'code',
      'code_challenge': challenge,
      'code_challenge_method': 'S256',
      'token_access_type': 'offline',
    })}';
    return CloudAuthPrompt(url: url, message: 'Cho phép YomiHub trên trang Dropbox rồi dán mã vào đây.');
  }

  @override
  Future<void> completeAuth({String? pastedCode}) async {
    final r = await _client.post(
      Uri.parse(tokenUrl),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: _q({
        'grant_type': 'authorization_code',
        'code': (pastedCode ?? '').trim(),
        'client_id': config['client_id'] ?? '',
        'code_verifier': config['_verifier'] ?? '',
      }),
    );
    _storeTokens(_json(r, 'Dropbox sign-in'));
    config.remove('_verifier');
  }

  Future<Map<String, String>> _h() async => {'Authorization': 'Bearer ${await accessToken()}'};

  @override
  Future<void> upload(File file) async {
    final r = await _client.post(
      Uri.parse('https://content.dropboxapi.com/2/files/upload'),
      headers: {
        ...await _h(),
        'Content-Type': 'application/octet-stream',
        'Dropbox-API-Arg': jsonEncode({'path': '/${p.basename(file.path)}', 'mode': 'overwrite', 'mute': true}),
      },
      body: await file.readAsBytes(),
    );
    _json(r, 'Dropbox upload');
  }

  @override
  Future<List<CloudFile>> list() async {
    final r = await _client.post(
      Uri.parse('https://api.dropboxapi.com/2/files/list_folder'),
      headers: {...await _h(), 'Content-Type': 'application/json'},
      body: jsonEncode({'path': '', 'limit': 200}),
    );
    final items = ((_json(r, 'Dropbox list')['entries'] as List?) ?? [])
        .where((e) => e['.tag'] == 'file')
        .map((f) => CloudFile(f['path_lower'], f['name'], (f['size'] as num?)?.toInt() ?? 0,
            DateTime.tryParse('${f['server_modified']}')))
        .toList();
    items.sort((a, b) => (b.modified ?? DateTime(0)).compareTo(a.modified ?? DateTime(0)));
    return items;
  }

  @override
  Future<File> download(CloudFile f, Directory into) async {
    final r = await _client.post(
      Uri.parse('https://content.dropboxapi.com/2/files/download'),
      headers: {...await _h(), 'Dropbox-API-Arg': jsonEncode({'path': f.id})},
    );
    if (r.statusCode != 200) throw Exception('Dropbox download: HTTP ${r.statusCode}');
    return File(p.join(into.path, f.name)).writeAsBytes(r.bodyBytes);
  }
}

// ───────────────────────────── WebDAV ─────────────────────────────

class WebDavProvider extends CloudProvider {
  @override
  String get id => 'webdav';
  @override
  String get displayName => 'WebDAV (Nextcloud, pCloud, Koofr, …)';
  @override
  CloudAuthKind get authKind => CloudAuthKind.credentials;
  @override
  List<CloudField> get fields => const [
        CloudField('url', 'Địa chỉ WebDAV', hint: 'https://cloud.example.com/remote.php/dav/files/ten/'),
        CloudField('user', 'Tài khoản'),
        CloudField('password', 'Mật khẩu / app password', secret: true),
      ];
  @override
  String get help => 'Dùng cho mọi dịch vụ hỗ trợ WebDAV. Bản sao lưu được lưu trong thư mục YomiHub.';
  @override
  bool get isConnected => (config['url'] ?? '').isNotEmpty && config['ok'] == '1';

  String get _base {
    var u = config['url'] ?? '';
    if (!u.endsWith('/')) u += '/';
    return '$u$_folderName/';
  }

  Map<String, String> get _h => {
        'Authorization': 'Basic ${base64Encode(utf8.encode('${config['user'] ?? ''}:${config['password'] ?? ''}'))}',
      };

  Future<http.StreamedResponse> _send(String method, String url, {Map<String, String>? headers, List<int>? body}) {
    final req = http.Request(method, Uri.parse(url))..headers.addAll({..._h, ...?headers});
    if (body != null) req.bodyBytes = body;
    return _client.send(req);
  }

  @override
  Future<CloudAuthPrompt?> beginAuth() async => null;

  @override
  Future<void> completeAuth({String? pastedCode}) async {
    final r = await _send('MKCOL', _base);
    // 201 created, 405 already exists
    if (r.statusCode != 201 && r.statusCode != 405 && r.statusCode != 301) {
      throw Exception('WebDAV: HTTP ${r.statusCode}');
    }
    config['ok'] = '1';
  }

  @override
  Future<void> upload(File file) async {
    final r = await _send('PUT', '$_base${Uri.encodeComponent(p.basename(file.path))}',
        headers: {'Content-Type': 'application/octet-stream'}, body: await file.readAsBytes());
    if (r.statusCode >= 300) throw Exception('WebDAV upload: HTTP ${r.statusCode}');
  }

  @override
  Future<List<CloudFile>> list() async {
    final r = await _send('PROPFIND', _base, headers: {'Depth': '1', 'Content-Type': 'application/xml'});
    final xml = await r.stream.bytesToString();
    if (r.statusCode >= 300) throw Exception('WebDAV list: HTTP ${r.statusCode}');
    final out = <CloudFile>[];
    for (final m in RegExp(r'<(?:\w+:)?response>(.*?)</(?:\w+:)?response>', dotAll: true).allMatches(xml)) {
      final block = m.group(1)!;
      final href = RegExp(r'<(?:\w+:)?href>([^<]+)<').firstMatch(block)?.group(1);
      if (href == null || href.endsWith('/')) continue;
      final name = Uri.decodeComponent(href.split('/').last);
      final size = int.tryParse(RegExp(r'<(?:\w+:)?getcontentlength>(\d+)<').firstMatch(block)?.group(1) ?? '') ?? 0;
      final mod = RegExp(r'<(?:\w+:)?getlastmodified>([^<]+)<').firstMatch(block)?.group(1);
      DateTime? dt;
      try {
        dt = mod == null ? null : HttpDate.parse(mod);
      } catch (_) {}
      out.add(CloudFile('$_base${Uri.encodeComponent(name)}', name, size, dt));
    }
    out.sort((a, b) => (b.modified ?? DateTime(0)).compareTo(a.modified ?? DateTime(0)));
    return out;
  }

  @override
  Future<File> download(CloudFile f, Directory into) async {
    final r = await _send('GET', f.id);
    if (r.statusCode != 200) throw Exception('WebDAV download: HTTP ${r.statusCode}');
    final file = File(p.join(into.path, f.name));
    await r.stream.pipe(file.openWrite());
    return file;
  }
}

// ───────────────────────────── Telegram ─────────────────────────────

class TelegramProvider extends CloudProvider {
  @override
  String get id => 'telegram';
  @override
  String get displayName => 'Telegram (bot)';
  @override
  CloudAuthKind get authKind => CloudAuthKind.credentials;
  @override
  bool get canRestore => false;
  @override
  List<CloudField> get fields => const [
        CloudField('token', 'Bot token', secret: true, hint: '123456:ABC-DEF…'),
        CloudField('chat_id', 'Chat ID', hint: 'ID của bạn hoặc của nhóm/kênh'),
      ];
  @override
  String get help =>
      'Tạo bot bằng @BotFather để lấy token. Nhắn /start cho bot, rồi lấy Chat ID của bạn (ví dụ qua '
      '@userinfobot). Mỗi bản sao lưu sẽ được gửi thành file vào cuộc trò chuyện đó (tối đa 50 MB). '
      'Để khôi phục, tải file từ Telegram về rồi dùng "Khôi phục bản sao lưu".';
  @override
  bool get isConnected => config['ok'] == '1';

  @override
  Future<CloudAuthPrompt?> beginAuth() async => null;

  @override
  Future<void> completeAuth({String? pastedCode}) async {
    final r = await _client.get(Uri.parse('https://api.telegram.org/bot${config['token']}/getMe'));
    _json(r, 'Telegram');
    config['ok'] = '1';
  }

  @override
  Future<void> upload(File file) async {
    final req = http.MultipartRequest(
      'POST',
      Uri.parse('https://api.telegram.org/bot${config['token']}/sendDocument'),
    )
      ..fields['chat_id'] = config['chat_id'] ?? ''
      ..fields['caption'] = 'YomiHub backup ${DateTime.now().toLocal()}'
      ..files.add(await http.MultipartFile.fromPath('document', file.path));
    final r = await http.Response.fromStream(await _client.send(req));
    _json(r, 'Telegram upload');
  }

  @override
  Future<List<CloudFile>> list() async => [];
  @override
  Future<File> download(CloudFile file, Directory into) => throw UnsupportedError('Telegram');
}

// ───────────────────────────── Service ─────────────────────────────

class CloudUploadResult {
  final String provider;
  final Object? error;
  CloudUploadResult(this.provider, this.error);
}

class CloudBackupService {
  CloudBackupService._();
  static final instance = CloudBackupService._();
  static const _storage = FlutterSecureStorage();

  final List<CloudProvider> providers = [
    GoogleDriveProvider(),
    OneDriveProvider(),
    DropboxProvider(),
    WebDavProvider(),
    TelegramProvider(),
  ];

  /// Results of the last automatic upload, for the settings screen.
  final ValueNotifier<List<CloudUploadResult>> lastResults = ValueNotifier([]);
  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    for (final pr in providers) {
      try {
        final raw = await _storage.read(key: 'yomihub_cloud_${pr.id}');
        pr.config = raw == null ? {} : Map<String, String>.from(jsonDecode(raw));
      } catch (_) {
        pr.config = {};
      }
    }
    _loaded = true;
  }

  Future<void> save(CloudProvider pr) =>
      _storage.write(key: 'yomihub_cloud_${pr.id}', value: jsonEncode(pr.config));

  Future<void> disconnect(CloudProvider pr) async {
    pr.config = {};
    await _storage.delete(key: 'yomihub_cloud_${pr.id}');
  }

  bool autoUpload(CloudProvider pr) => pr.config['auto'] != '0';

  Future<void> setAutoUpload(CloudProvider pr, bool v) async {
    pr.config['auto'] = v ? '1' : '0';
    await save(pr);
  }

  /// Uploads [path] to every connected target with auto-upload on.
  Future<List<CloudUploadResult>> uploadInBackground(String path, {bool onlyAuto = true}) async {
    await load();
    final results = <CloudUploadResult>[];
    for (final pr in providers.where((e) => e.isConnected && (!onlyAuto || autoUpload(e)))) {
      try {
        await pr.upload(File(path));
        results.add(CloudUploadResult(pr.displayName, null));
      } catch (e) {
        results.add(CloudUploadResult(pr.displayName, e));
      }
    }
    if (results.isNotEmpty) lastResults.value = results;
    return results;
  }

  Future<Directory> tempDir() async {
    final d = Directory(p.join((await getTemporaryDirectory()).path, 'yomihub_cloud'));
    await d.create(recursive: true);
    return d;
  }
}
