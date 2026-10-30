import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';
import 'package:mangayomi/utils/log/logger.dart';
import 'package:mangayomi/services/http/m_client.dart';
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
      message: tr('Mở {p0} và nhập mã bên dưới, rồi quay lại app.', {'p0': verify}),
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
    throw Exception(tr('{p0}: hết thời gian chờ đăng nhập', {'p0': displayName}));
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
  List<CloudField> get fields => [
        CloudField('client_id', 'Client ID'),
        CloudField('client_secret', 'Client secret', secret: true),
        CloudField('folder_name', tr('Tên thư mục sao lưu (mặc định YomiHub)'), hint: 'YomiHub'),
        CloudField('keep', tr('Giữ bao nhiêu bản sao lưu gần nhất (mặc định 10, 0 = giữ hết)')),
      ];
  @override
  String get help =>
      tr('Ứng dụng chỉ sử dụng quyền drive.file đối với đúng 1 thư mục cụ thể được bạn cấp quyền (mặc định: YomiHub), hoàn toàn không truy cập tệp tin khác. Nhập Client ID và Client secret (loại TV/Limited Input Devices từ Google Cloud Console) rồi cấp quyền một lần để tự động sao lưu.');

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
    final folderName = (config['folder_name'] ?? '').trim().isNotEmpty
        ? config['folder_name']!.trim()
        : _folderName;
    if ((config['folder_id'] ?? '').isNotEmpty && config['_bound_folder'] == folderName) {
      return config['folder_id']!;
    }
    final q = "name='$folderName' and mimeType='application/vnd.google-apps.folder' and trashed=false";
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
        body: jsonEncode({'name': folderName, 'mimeType': 'application/vnd.google-apps.folder'}),
      );
      id = _json(c, 'Drive mkdir')['id'];
    }
    config['folder_id'] = id;
    config['_bound_folder'] = folderName;
    await CloudBackupService.instance.save(this);
    return id;
  }

  /// 0.1.8 (vBook / FBReader style): resumable upload in 8 MB chunks.
  /// The old single multipart request is limited to 5 MB by Google, so a
  /// backup with covers or a long history failed to upload. Each chunk is
  /// retried, and an interrupted upload resumes where it stopped.
  @override
  Future<void> upload(File file) async {
    final folder = await _folderId();
    final total = await file.length();
    final meta = jsonEncode({
      'name': p.basename(file.path),
      'parents': [folder],
      'appProperties': {'app': 'yomihub', 'device': Platform.localHostname},
    });
    final start = await _client.post(
      Uri.parse('https://www.googleapis.com/upload/drive/v3/files?uploadType=resumable'),
      headers: {
        ...await _h(),
        'Content-Type': 'application/json; charset=UTF-8',
        'X-Upload-Content-Type': 'application/octet-stream',
        'X-Upload-Content-Length': '$total',
      },
      body: meta,
    );
    if (start.statusCode != 200 || start.headers['location'] == null) {
      _json(start, 'Drive upload');
      throw Exception('Drive upload: HTTP ${start.statusCode}');
    }
    final session = Uri.parse(start.headers['location']!);
    const chunk = 8 * 1024 * 1024;
    final raf = await file.open();
    try {
      var pos = 0;
      while (pos < total) {
        final end = min(pos + chunk, total);
        await raf.setPosition(pos);
        final bytes = await raf.read(end - pos);
        http.Response? r;
        for (var attempt = 0; attempt < 4; attempt++) {
          try {
            r = await _client.put(
              session,
              headers: {
                ...await _h(),
                'Content-Length': '${bytes.length}',
                'Content-Range': 'bytes $pos-${end - 1}/$total',
              },
              body: bytes,
            );
            if (r.statusCode < 500) break;
          } catch (_) {
            if (attempt == 3) rethrow;
          }
          await Future.delayed(Duration(seconds: 2 << attempt));
        }
        if (r == null) throw Exception('Drive upload: no response');
        if (r.statusCode == 308) {
          // resume from what Google has
          final range = r.headers['range'];
          pos = range == null ? end : int.parse(range.split('-').last) + 1;
          continue;
        }
        if (r.statusCode == 200 || r.statusCode == 201) {
          pos = total;
          break;
        }
        _json(r, 'Drive upload');
        throw Exception('Drive upload: HTTP ${r.statusCode}');
      }
    } finally {
      await raf.close();
    }
    await _prune();
  }

  /// Keeps the newest [keep] YomiHub backups in the Drive folder.
  int get keep => int.tryParse(config['keep'] ?? '') ?? 10;

  Future<void> _prune() async {
    if (keep <= 0) return;
    try {
      final files = (await list()).where((f) => f.name.endsWith('.backup')).toList();
      for (final f in files.skip(keep)) {
        await delete(f);
      }
    } catch (_) {}
  }

  Future<void> delete(CloudFile f) async {
    final r = await _client.delete(
      Uri.parse('https://www.googleapis.com/drive/v3/files/${f.id}'),
      headers: await _h(),
    );
    if (r.statusCode >= 400 && r.statusCode != 404) {
      throw Exception('Drive delete: HTTP ${r.statusCode}');
    }
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
    // streamed to disk: big backups no longer sit in memory
    final req = http.Request('GET', Uri.parse('https://www.googleapis.com/drive/v3/files/${f.id}?alt=media'))
      ..headers.addAll(await _h());
    final r = await _client.send(req);
    if (r.statusCode != 200) throw Exception('Drive download: HTTP ${r.statusCode}');
    final out = File(p.join(into.path, f.name));
    final sink = out.openWrite();
    await r.stream.pipe(sink);
    return out;
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
      tr('portal.azure.com → App registrations → New registration (chọn "Personal Microsoft accounts and organizational accounts") → Authentication → bật "Allow public client flows". API permissions: Files.ReadWrite.AppFolder. Dán Application (client) ID vào đây. Bản sao lưu nằm trong thư mục Apps/YomiHub trên OneDrive.');

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
      tr('dropbox.com/developers/apps → Create app → "Scoped access", "App folder". Tab Permissions: bật files.content.write và files.content.read. Dán App key vào đây. Bấm Kết nối, cho phép trên trình duyệt rồi dán mã Dropbox hiển thị vào app.');

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
    return CloudAuthPrompt(url: url, message: tr('Cho phép YomiHub trên trang Dropbox rồi dán mã vào đây.'));
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
  List<CloudField> get fields => [
        CloudField('url', tr('Địa chỉ WebDAV'), hint: 'https://cloud.example.com/remote.php/dav/files/ten/'),
        CloudField('user', tr('Tài khoản')),
        CloudField('password', tr('Mật khẩu / app password'), secret: true),
      ];
  @override
  String get help => tr('Dùng cho mọi dịch vụ hỗ trợ WebDAV. Bản sao lưu được lưu trong thư mục YomiHub.');
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

// ───────────────────── Rclone (YomiHub 0.4.4) ─────────────────────

/// Any of rclone's 70+ storage backends (Google Drive, OneDrive, Dropbox,
/// Google Photos, S3, Mega, pCloud, Box, SFTP…) through rclone's remote
/// control API (`rclone rcd`), as in the Rclone / Cyberduck / FreeFileSync
/// projects of the sheet. One rclone instance on a PC or NAS serves every
/// device; nothing has to be registered with each provider.
class RcloneProvider extends CloudProvider {
  @override
  String get id => 'rclone';
  @override
  String get displayName => 'Rclone (Google Drive, OneDrive, Dropbox, Mega, S3… qua rclone rcd)';
  @override
  CloudAuthKind get authKind => CloudAuthKind.credentials;
  @override
  List<CloudField> get fields => [
        CloudField('url', tr('Địa chỉ rclone rcd'), hint: 'http://192.168.1.10:5572'),
        CloudField('remote', tr('Remote và thư mục'), hint: 'gdrive:  hoặc  onedrive:Backups'),
        CloudField('user', tr('Tài khoản (--rc-user)')),
        CloudField('password', tr('Mật khẩu (--rc-pass)'), secret: true),
      ];
  @override
  String get help => tr('Chạy trên máy tính/NAS: rclone rcd --rc-addr :5572 --rc-user TEN --rc-pass MATKHAU --rc-serve. '
      'Remote được tạo bằng "rclone config" (Google Drive, OneDrive, Dropbox, Mega…). Bản sao lưu nằm trong thư mục YomiHub của remote.');
  @override
  bool get isConnected => (config['url'] ?? '').isNotEmpty && config['ok'] == '1';

  String get _url {
    var u = (config['url'] ?? '').trim();
    while (u.endsWith('/')) {
      u = u.substring(0, u.length - 1);
    }
    return u;
  }

  /// "gdrive:Backups" → fs "gdrive:", path "Backups/YomiHub".
  (String, String) get _fsPath {
    final r = (config['remote'] ?? '').trim();
    final i = r.indexOf(':');
    final fs = i < 0 ? '$r:' : r.substring(0, i + 1);
    var base = i < 0 ? '' : r.substring(i + 1);
    while (base.endsWith('/')) {
      base = base.substring(0, base.length - 1);
    }
    return (fs, base.isEmpty ? _folderName : '$base/$_folderName');
  }

  Map<String, String> get _h => {
        if ((config['user'] ?? '').isNotEmpty)
          'Authorization': 'Basic ${base64Encode(utf8.encode('${config['user']}:${config['password'] ?? ''}'))}',
      };

  Future<Map<String, dynamic>> _rc(String cmd, Map<String, dynamic> body) async {
    final r = await _client.post(Uri.parse('$_url/$cmd'),
        headers: {..._h, 'Content-Type': 'application/json'}, body: jsonEncode(body));
    return _json(r, 'rclone $cmd');
  }

  @override
  Future<CloudAuthPrompt?> beginAuth() async => null;

  @override
  Future<void> completeAuth({String? pastedCode}) async {
    if ((config['remote'] ?? '').trim().isEmpty) throw Exception(tr('Chưa nhập remote (ví dụ gdrive:)'));
    await _rc('rc/noop', {});
    final (fs, path) = _fsPath;
    await _rc('operations/mkdir', {'fs': fs, 'remote': path});
    config['ok'] = '1';
  }

  @override
  Future<void> upload(File file) async {
    final (fs, path) = _fsPath;
    final req = http.MultipartRequest('POST',
        Uri.parse('$_url/operations/uploadfile').replace(queryParameters: {'fs': fs, 'remote': path}))
      ..headers.addAll(_h)
      ..files.add(await http.MultipartFile.fromPath('file0', file.path, filename: p.basename(file.path)));
    final r = await http.Response.fromStream(await _client.send(req));
    _json(r, 'rclone upload');
  }

  @override
  Future<List<CloudFile>> list() async {
    final (fs, path) = _fsPath;
    final j = await _rc('operations/list', {'fs': fs, 'remote': path});
    final out = <CloudFile>[];
    for (final e in (j['list'] as List? ?? const [])) {
      if (e is! Map || e['IsDir'] == true) continue;
      out.add(CloudFile('${e['Path']}', '${e['Name']}', (e['Size'] as num?)?.toInt() ?? 0,
          DateTime.tryParse('${e['ModTime'] ?? ''}')));
    }
    out.sort((a, b) => (b.modified ?? DateTime(0)).compareTo(a.modified ?? DateTime(0)));
    return out;
  }

  @override
  Future<File> download(CloudFile f, Directory into) async {
    final (fs, _) = _fsPath;
    // needs `rclone rcd --rc-serve`: GET /[remote:]/path
    final r = await _client.get(Uri.parse('$_url/[$fs]/${f.id.split('/').map(Uri.encodeComponent).join('/')}'), headers: _h);
    if (r.statusCode != 200) throw Exception('rclone download: HTTP ${r.statusCode} (${tr('cần chạy rclone rcd với --rc-serve')})');
    final file = File(p.join(into.path, f.name));
    await file.writeAsBytes(r.bodyBytes, flush: true);
    return file;
  }
}

// ───────────────────── MediaFire (YomiHub 0.4.4) ─────────────────────

/// MediaFire (Mediafire Project of the sheet: mediafire_bulk_downloader),
/// via the public REST API 1.5 with an email + password session (token v1,
/// renewed for every operation so no per-call signature is needed).
class MediaFireProvider extends CloudProvider {
  @override
  String get id => 'mediafire';
  @override
  String get displayName => 'MediaFire';
  @override
  CloudAuthKind get authKind => CloudAuthKind.credentials;
  @override
  List<CloudField> get fields => [
        CloudField('email', 'Email'),
        CloudField('password', tr('Mật khẩu'), secret: true),
        CloudField('app_id', 'Application ID', hint: '42511'),
      ];
  @override
  String get help => tr('Đăng nhập bằng email và mật khẩu MediaFire. Bản sao lưu được tải lên thư mục YomiHub trong tài khoản. '
      'Application ID để trống sẽ dùng mã mặc định của SDK MediaFire (42511).');
  @override
  bool get isConnected => (config['folder_key'] ?? '').isNotEmpty;

  static const _api = 'https://www.mediafire.com/api/1.5';

  Map<String, dynamic> _mf(http.Response r, String what) {
    final j = _json(r, 'MediaFire $what');
    final resp = j['response'] as Map<String, dynamic>? ?? const {};
    if ('${resp['result']}' != 'Success') {
      throw Exception('MediaFire $what: ${resp['message'] ?? resp['error'] ?? 'lỗi'}');
    }
    return resp;
  }

  Future<String> _token() async {
    final email = (config['email'] ?? '').trim();
    final pass = config['password'] ?? '';
    final app = (config['app_id'] ?? '').trim().isEmpty ? '42511' : config['app_id']!.trim();
    final sig = sha1.convert(utf8.encode('$email$pass$app')).toString();
    final r = await _client.post(Uri.parse('$_api/user/get_session_token.php'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: _q({'email': email, 'password': pass, 'application_id': app, 'signature': sig, 'response_format': 'json'}));
    return '${_mf(r, 'đăng nhập')['session_token']}';
  }

  Future<Map<String, dynamic>> _call(String path, String token, Map<String, String> q) async {
    final r = await _client.post(Uri.parse('$_api/$path'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: _q({...q, 'session_token': token, 'response_format': 'json'}));
    return _mf(r, path);
  }

  @override
  Future<CloudAuthPrompt?> beginAuth() async => null;

  @override
  Future<void> completeAuth({String? pastedCode}) async {
    final t = await _token();
    final c = await _call('folder/get_content.php', t, {'content_type': 'folders', 'chunk_size': '1000'});
    final folders = ((c['folder_content'] as Map?)?['folders'] as List?) ?? const [];
    final hit = folders.whereType<Map>().where((f) => f['name'] == _folderName).firstOrNull;
    if (hit != null) {
      config['folder_key'] = '${hit['folderkey']}';
    } else {
      final n = await _call('folder/create.php', t, {'foldername': _folderName});
      config['folder_key'] = '${n['folder_key'] ?? n['folderkey']}';
    }
  }

  @override
  Future<void> upload(File file) async {
    final t = await _token();
    final bytes = await file.readAsBytes();
    final r = await _client.post(
      Uri.parse('$_api/upload/simple.php').replace(queryParameters: {
        'session_token': t,
        'folder_key': config['folder_key'] ?? '',
        'action_on_duplicate': 'replace',
        'response_format': 'json',
      }),
      headers: {
        'Content-Type': 'application/octet-stream',
        'x-filename': p.basename(file.path),
        'x-filesize': '${bytes.length}',
      },
      body: bytes,
    );
    final up = _mf(r, 'upload');
    final key = '${(up['doupload'] as Map?)?['key'] ?? ''}';
    if (key.isEmpty) return;
    // wait until MediaFire has stored the file (status 99 = done)
    for (var i = 0; i < 30; i++) {
      await Future<void>.delayed(const Duration(seconds: 2));
      final pr = await _client.post(Uri.parse('$_api/upload/poll_upload.php'),
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: _q({'key': key, 'session_token': t, 'response_format': 'json'}));
      final d = (_mf(pr, 'poll')['doupload'] as Map?) ?? const {};
      if ('${d['status']}' == '99') {
        final err = '${d['fileerror'] ?? ''}';
        if (err.isNotEmpty && err != '0') throw Exception('MediaFire upload: lỗi tệp $err');
        return;
      }
    }
  }

  @override
  Future<List<CloudFile>> list() async {
    final t = await _token();
    final c = await _call('folder/get_content.php', t,
        {'folder_key': config['folder_key'] ?? '', 'content_type': 'files', 'chunk_size': '1000'});
    final files = ((c['folder_content'] as Map?)?['files'] as List?) ?? const [];
    final out = <CloudFile>[
      for (final f in files.whereType<Map>())
        CloudFile('${f['quickkey']}', '${f['filename']}', int.tryParse('${f['size']}') ?? 0,
            DateTime.tryParse('${f['created'] ?? ''}'.replaceFirst(' ', 'T'))),
    ];
    out.sort((a, b) => (b.modified ?? DateTime(0)).compareTo(a.modified ?? DateTime(0)));
    return out;
  }

  @override
  Future<File> download(CloudFile f, Directory into) async {
    final t = await _token();
    final l = await _call('file/get_links.php', t, {'quick_key': f.id, 'link_type': 'direct_download'});
    final links = (l['links'] as List?) ?? const [];
    final url = links.isEmpty ? '' : '${(links.first as Map)['direct_download'] ?? ''}';
    if (url.isEmpty) throw Exception('MediaFire: không lấy được liên kết tải');
    final r = await _client.get(Uri.parse(url));
    if (r.statusCode != 200) throw Exception('MediaFire download: HTTP ${r.statusCode}');
    final file = File(p.join(into.path, f.name));
    await file.writeAsBytes(r.bodyBytes, flush: true);
    return file;
  }
}

// ───────────────────────────── Telegram ─────────────────────────────

class TelegramProvider extends CloudProvider {
  // 0.4.5 (sheet "YomiHub Update": "Kiểm tra lỗi của tính năng sao lưu bằng
  // Telegram"). Faults found in the 0.4.4 code:
  //  1. Bot API limits: sendDocument accepts ≤ 50 MB and getFile only serves
  //     files ≤ 20 MB, so any backup > 20 MB uploaded but could never be
  //     restored ("file is too big"), > 50 MB failed outright (HTTP 413).
  //     -> backups are sent in parts of 19 MB and joined again on restore.
  //  2. api.telegram.org is blocked by Vietnamese ISPs: a plain http.Client
  //     ignored "VPN & DNS" (Tor / proxy / DoH). -> MClient (same routing as
  //     the extensions); network errors explain that a VPN is needed.
  //  3. Error texts contained the request URL, i.e. the bot token, and were
  //     written to the application log. -> token is masked everywhere.
  //  4. Token / chat id were not trimmed (pasted with spaces/newlines) and the
  //     chat id was never checked: "chat not found" only showed up at the
  //     first backup. -> completeAuth checks getMe + getChat.
  //  5. No timeouts: a stalled upload hung the backup forever.
  static const partSize = 19 * 1024 * 1024;

  @override
  String get id => 'telegram';
  @override
  String get displayName => 'Telegram (bot)';
  @override
  CloudAuthKind get authKind => CloudAuthKind.credentials;
  @override
  bool get canRestore => true;
  @override
  List<CloudField> get fields => [
        CloudField('token', 'Bot token', secret: true, hint: '123456:ABC-DEF…'),
        CloudField('chat_id', 'Chat ID', hint: tr('ID của bạn hoặc của nhóm/kênh')),
      ];
  @override
  String get help =>
      tr('Tạo bot bằng @BotFather để lấy token. Nhắn /start cho bot, rồi lấy Chat ID của bạn (ví dụ qua @userinfobot). Hỗ trợ tự động sao lưu và khôi phục trực tiếp qua Telegram.');
  // 0.4.5 (thử tải lên thật trên Xiaomi 15T, 30/10 14:25): màn hình ghi
  // "Đã kết nối" nhưng cấu hình đã lưu chỉ còn cờ `ok` – không có Bot token /
  // Chat ID. Mọi lần tự sao lưu đều thất bại ("Nhập đủ Bot token và Chat
  // ID") trong khi người dùng tưởng đang sao lưu. Chỉ coi là đã kết nối khi
  // có đủ cả hai; nếu thiếu, màn hình hiện "Chưa kết nối" và nút Kết nối.
  @override
  bool get isConnected => config['ok'] == '1' && _token.isNotEmpty && _chat.isNotEmpty;

  String get _token => (config['token'] ?? '').trim();
  String get _chat => (config['chat_id'] ?? '').trim();
  String _api(String method) => 'https://api.telegram.org/bot$_token/$method';

  http.Client get _tg => MClient.init(reqcopyWith: {'useDartHttpClient': true});

  /// Removes the bot token from any text that may reach the UI or the log.
  String _mask(Object e) => maskToken('$e', _token);

  static String maskToken(String t, String token) {
    if (token.isNotEmpty) t = t.replaceAll(token, '<token>');
    return t.replaceAll(RegExp(r'bot\d+:[A-Za-z0-9_-]{20,}'), 'bot<token>');
  }

  /// `backup.yomihub.part02of05` – parts sort by name and carry their count.
  static String partName(String file, int index, int count) =>
      '$file.part${(index + 1).toString().padLeft(2, '0')}of${count.toString().padLeft(2, '0')}';

  Never _fail(String what, Object e) {
    final msg = _mask(e);
    final l = msg.toLowerCase();
    final net = e is SocketException ||
        e is TimeoutException ||
        e is http.ClientException ||
        l.contains('connection') ||
        l.contains('handshake') ||
        l.contains('failed host lookup');
    throw Exception(net
        ? '$what: $msg – ${tr('Không kết nối được api.telegram.org (thường bị nhà mạng chặn): bật Cloudflare WARP / Tor / Proxy trong "VPN & DNS" rồi thử lại.')}'
        : '$what: $msg');
  }

  Map<String, dynamic> _tgJson(http.Response r, String what) {
    Map<String, dynamic>? d;
    try {
      d = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {}
    if (r.statusCode == 200 && d?['ok'] == true) return d!;
    final desc = d?['description']?.toString() ?? 'HTTP ${r.statusCode}';
    var hint = '';
    final l = desc.toLowerCase();
    if (r.statusCode == 401 || l.contains('unauthorized')) {
      hint = tr('Bot token sai hoặc đã bị thu hồi – lấy lại token từ @BotFather.');
    } else if (l.contains('chat not found')) {
      hint = tr('Không tìm thấy Chat ID – nhắn /start cho bot (hoặc thêm bot vào nhóm/kênh) và kiểm tra lại Chat ID.');
    } else if (l.contains('bot was blocked') || l.contains('forbidden')) {
      hint = tr('Bot không được phép gửi vào cuộc trò chuyện này – bỏ chặn bot / cấp quyền đăng bài cho bot trong kênh.');
    } else if (r.statusCode == 413 || l.contains('too big') || l.contains('too large')) {
      hint = tr('Tệp vượt giới hạn của Telegram Bot API.');
    } else if (r.statusCode == 429) {
      hint = tr('Telegram giới hạn tần suất – thử lại sau ít phút.');
    }
    throw Exception('$what: ${_mask(desc)}${hint.isEmpty ? '' : ' – $hint'}');
  }

  @override
  Future<CloudAuthPrompt?> beginAuth() async => null;

  @override
  Future<void> completeAuth({String? pastedCode}) async {
    config['token'] = _token;
    config['chat_id'] = _chat;
    if (_token.isEmpty || _chat.isEmpty) {
      throw Exception(tr('Nhập đủ Bot token và Chat ID.'));
    }
    try {
      _tgJson(await _tg.get(Uri.parse(_api('getMe'))).timeout(const Duration(seconds: 30)), 'Telegram getMe');
      _tgJson(
          await _tg
              .get(Uri.parse('${_api('getChat')}?chat_id=${Uri.encodeQueryComponent(_chat)}'))
              .timeout(const Duration(seconds: 30)),
          'Telegram getChat');
    } catch (e) {
      config['ok'] = '0';
      if (e is Exception && '$e'.contains('Telegram get')) rethrow;
      _fail('Telegram', e);
    }
    config['ok'] = '1';
  }

  List<Map<String, dynamic>> _getHistory() {
    try {
      final raw = config['_history'];
      if (raw != null && raw.isNotEmpty) {
        return List<Map<String, dynamic>>.from(jsonDecode(raw));
      }
    } catch (_) {}
    return [];
  }

  Future<void> _addHistory(String fileId, String fileName, int size, DateTime date) async {
    final list = _getHistory();
    list.removeWhere((e) => e['name'] == fileName);
    list.insert(0, {
      'id': fileId,
      'name': fileName,
      'size': size,
      'date': date.toIso8601String(),
    });
    if (list.length > 50) list.removeRange(50, list.length);
    config['_history'] = jsonEncode(list);
    await CloudBackupService.instance.save(this);
  }

  Future<Map<String, dynamic>> _sendDocument(String name, List<int> bytes, String caption) async {
    http.MultipartRequest req() => http.MultipartRequest('POST', Uri.parse(_api('sendDocument')))
      ..fields['chat_id'] = _chat
      ..fields['caption'] = caption
      ..fields['disable_notification'] = 'true'
      ..files.add(http.MultipartFile.fromBytes('document', bytes, filename: name));
    for (var attempt = 1;; attempt++) {
      try {
        final r = await http.Response.fromStream(
            await _tg.send(req()).timeout(const Duration(minutes: 5)));
        if (r.statusCode == 429 && attempt < 3) {
          await Future.delayed(const Duration(seconds: 5));
          continue;
        }
        return _tgJson(r, 'Telegram upload');
      } catch (e) {
        if ('$e'.contains('Telegram upload')) rethrow;
        if (attempt >= 3) _fail('Telegram upload', e);
        await Future.delayed(Duration(seconds: 3 * attempt));
      }
    }
  }

  @override
  Future<void> upload(File file) async {
    if (_token.isEmpty || _chat.isEmpty) throw Exception(tr('Nhập đủ Bot token và Chat ID.'));
    final fileName = p.basename(file.path);
    final total = await file.length();
    final stamp = DateTime.now().toLocal().toString().split('.').first;
    if (total <= partSize) {
      final d = await _sendDocument(fileName, await file.readAsBytes(), 'YomiHub backup $stamp');
      final id = d['result']?['document']?['file_id']?.toString() ?? '';
      if (id.isNotEmpty) await _addHistory(id, fileName, total, DateTime.now());
      return;
    }
    final n = (total + partSize - 1) ~/ partSize;
    final ids = <String>[];
    final raf = await file.open();
    try {
      for (var i = 0; i < n; i++) {
        await raf.setPosition(i * partSize);
        final chunk = await raf.read(min(partSize, total - i * partSize));
        final pn = partName(fileName, i, n);
        final d = await _sendDocument(pn, chunk, 'YomiHub backup $stamp – ${i + 1}/$n');
        final id = d['result']?['document']?['file_id']?.toString() ?? '';
        if (id.isEmpty) throw Exception('Telegram upload: ${tr('không nhận được file_id')} ($pn)');
        ids.add(id);
      }
    } finally {
      await raf.close();
    }
    await _addHistory('parts:${ids.join(',')}', fileName, total, DateTime.now());
  }

  static final partRe = RegExp(r'^(.*)\.part(\d+)of(\d+)$');

  @override
  Future<List<CloudFile>> list() async {
    final history = _getHistory();
    final items = <CloudFile>[];
    for (final h in history) {
      final id = h['id']?.toString() ?? '';
      final name = h['name']?.toString() ?? '';
      final size = (h['size'] as num?)?.toInt() ?? 0;
      final dt = DateTime.tryParse(h['date']?.toString() ?? '');
      if (id.isNotEmpty && name.isNotEmpty) {
        items.add(CloudFile(id, name, size, dt));
      }
    }
    // Files the user forwarded / sent to the bot (getUpdates keeps ~24 h;
    // a bot never receives its own messages, so history is the main source).
    try {
      final r = await _tg.get(Uri.parse('${_api('getUpdates')}?limit=100')).timeout(const Duration(seconds: 30));
      if (r.statusCode == 200) {
        final d = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
        final parts = <String, Map<int, Map<String, dynamic>>>{};
        final partCount = <String, int>{};
        for (final item in (d['result'] as List?) ?? const []) {
          final msg = item['message'] ?? item['channel_post'];
          final doc = msg?['document'] as Map<String, dynamic>?;
          if (doc == null) continue;
          final fId = doc['file_id']?.toString() ?? '';
          final fName = doc['file_name']?.toString() ?? '';
          final fSize = (doc['file_size'] as num?)?.toInt() ?? 0;
          final fDate = msg?['date'] != null
              ? DateTime.fromMillisecondsSinceEpoch((msg['date'] as num).toInt() * 1000)
              : null;
          if (fId.isEmpty || !fName.contains('YomiHub')) continue;
          final m = partRe.firstMatch(fName);
          if (m != null) {
            parts.putIfAbsent(m[1]!, () => {})[int.parse(m[2]!)] = {'id': fId, 'size': fSize, 'date': fDate};
            partCount[m[1]!] = int.parse(m[3]!);
          } else if (!items.any((x) => x.id == fId || x.name == fName)) {
            items.add(CloudFile(fId, fName, fSize, fDate));
          }
        }
        parts.forEach((base, got) {
          final n = partCount[base] ?? 0;
          if (n == 0 || got.length != n || items.any((x) => x.name == base)) return;
          final ordered = [for (var i = 1; i <= n; i++) got[i]];
          if (ordered.any((e) => e == null)) return;
          items.add(CloudFile(
            'parts:${ordered.map((e) => e!['id']).join(',')}',
            base,
            ordered.fold<int>(0, (a, e) => a + (e!['size'] as int)),
            ordered.first!['date'] as DateTime?,
          ));
        });
      }
    } catch (_) {}
    items.sort((a, b) => (b.modified ?? DateTime(0)).compareTo(a.modified ?? DateTime(0)));
    return items;
  }

  Future<List<int>> _getFileBytes(String fileId) async {
    try {
      final r = await _tg
          .get(Uri.parse('${_api('getFile')}?file_id=${Uri.encodeQueryComponent(fileId)}'))
          .timeout(const Duration(seconds: 30));
      final data = _tgJson(r, 'Telegram getFile');
      final filePath = data['result']?['file_path']?.toString();
      if (filePath == null || filePath.isEmpty) {
        throw Exception(tr('Không tìm thấy tệp trên Telegram'));
      }
      final dlRes = await _tg
          .get(Uri.parse('https://api.telegram.org/file/bot$_token/$filePath'))
          .timeout(const Duration(minutes: 5));
      if (dlRes.statusCode != 200) {
        throw Exception('Telegram download: HTTP ${dlRes.statusCode}');
      }
      return dlRes.bodyBytes;
    } catch (e) {
      if ('$e'.contains('Telegram ') || '$e'.contains(tr('Không tìm thấy tệp trên Telegram'))) {
        throw Exception(_mask(e));
      }
      _fail('Telegram download', e);
    }
  }

  @override
  Future<File> download(CloudFile file, Directory into) async {
    final dest = File(p.join(into.path, file.name));
    final ids = file.id.startsWith('parts:') ? file.id.substring(6).split(',') : [file.id];
    final sink = dest.openWrite();
    try {
      for (final id in ids) {
        sink.add(await _getFileBytes(id));
      }
      await sink.flush();
    } finally {
      await sink.close();
    }
    if (file.size > 0) {
      final got = await dest.length();
      if (got != file.size) {
        throw Exception('Telegram: ${tr('tệp tải về không đủ dung lượng')} ($got/${file.size} B)');
      }
    }
    return dest;
  }
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
    RcloneProvider(), // 0.4.4
    MediaFireProvider(), // 0.4.4
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
        // 0.4.4: every failed cloud upload goes to the application log
        AppLogger.log('[Đồng bộ đám mây] Không tải bản sao lưu lên ${pr.displayName}: $e', logLevel: LogLevel.error);
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
