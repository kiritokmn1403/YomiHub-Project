// YomiHub 0.6.4 – R7 Frank Yomik (self-hosted manga translation server) client.
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mangayomi/yomihub/reader/frank_yomik.dart';

void main() {
  test('job id and status parsing tolerate the field names', () {
    expect(FrankYomikClient.jobIdOf('{"job_id":"j1"}'), 'j1');
    expect(FrankYomikClient.jobIdOf('{"id":42}'), '42');
    expect(FrankYomikClient.jobIdOf('{"job":{"id":"x"}}'), 'x');
    expect(FrankYomikClient.jobIdOf('nope'), isNull);
    expect(FrankYomikClient.statusOf('{"status":"completed"}'), FrankJobState.done);
    expect(FrankYomikClient.statusOf('{"job":{"state":"ERROR"}}'), FrankJobState.failed);
    expect(FrankYomikClient.statusOf('{"status":"processing"}'), FrankJobState.pending);
  });

  test('upload → poll → processed image, with Bearer token and pipeline', () async {
    final result = Uint8List.fromList([137, 80, 78, 71, 1, 2, 3]);
    var polls = 0;
    String? auth, body;
    final mock = MockClient((r) async {
      auth = r.headers['Authorization'];
      if (r.method == 'POST' && r.url.path == '/api/v1/jobs') {
        body = latin1.decode(r.bodyBytes);
        return http.Response('{"job_id":"j9"}', 202);
      }
      if (r.url.path == '/api/v1/jobs/j9') {
        polls++;
        return http.Response(jsonEncode({'status': polls < 3 ? 'processing' : 'done'}), 200);
      }
      if (r.url.path == '/api/v1/jobs/j9/image') return http.Response.bytes(result, 200);
      return http.Response('?', 404);
    });
    final c = FrankYomikClient(base: 'http://srv:8080/', bearer: 't0k', client: mock, pollEvery: Duration.zero);
    final out = await c.process(Uint8List.fromList([1, 2, 3]), pipelineName: 'webtoon');
    expect(out, result);
    expect(polls, 3);
    expect(auth, 'Bearer t0k');
    expect(body, contains('name="pipeline"'));
    expect(body, contains('webtoon'));
  });

  test('a refused token and a failed job are reported, not hung', () async {
    final denied = FrankYomikClient(base: 'http://srv', client: MockClient((_) async => http.Response('', 401)));
    expect(() => denied.process(Uint8List(1)), throwsA(isA<FrankYomikException>()));
    final failed = FrankYomikClient(
      base: 'http://srv',
      pollEvery: Duration.zero,
      client: MockClient((r) async => r.method == 'POST'
          ? http.Response('{"id":"a"}', 200)
          : http.Response('{"status":"failed","error":"no GPU"}', 200)),
    );
    await expectLater(failed.process(Uint8List(1)), throwsA(isA<FrankYomikException>()));
    final slow = FrankYomikClient(
      base: 'http://srv',
      pollEvery: Duration.zero,
      timeout: const Duration(milliseconds: 50),
      client: MockClient((r) async => r.method == 'POST' ? http.Response('{"id":"a"}', 200) : http.Response('{"status":"queued"}', 200)),
    );
    await expectLater(slow.process(Uint8List(1)), throwsA(isA<FrankYomikException>()));
  });
}
