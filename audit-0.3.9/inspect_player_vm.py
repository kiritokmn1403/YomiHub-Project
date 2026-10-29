"""Inspect only player state in the local QA debug app, without printing VM tokens."""
import json
import re
import subprocess
import sys
import urllib.parse
import urllib.request

adb = ['D:/yh/tools/android-sdk/platform-tools/adb.exe', '-s', 'emulator-5554']
pid = subprocess.check_output(adb + ['shell', 'pidof', 'com.yomihub.app'], text=True).strip()
log = subprocess.check_output(adb + ['logcat', '-d', '--pid=' + pid, '-s', 'flutter'], text=True, encoding='utf-8', errors='replace')
matches = re.findall(r'http://127\.0\.0\.1:(\d+)/([^\s]+)', log)
if not matches:
    raise SystemExit('No Dart VM service found for the QA app')
port, token = matches[-1]
token = token.rstrip('/')
subprocess.run(adb + ['forward', 'tcp:8181', 'tcp:' + port], check=True, capture_output=True)
base = 'http://127.0.0.1:8181/' + token + '/'

def rpc(method, **params):
    url = base + method + '?' + urllib.parse.urlencode(params)
    with urllib.request.urlopen(url, timeout=15) as response:
        result = json.load(response)
    if 'error' in result:
        raise RuntimeError(result['error'])
    return result['result']

vm = rpc('getVM')
isolate = next(i for i in vm['isolates'] if i['name'] == 'main')
isolate_id = isolate['id']
details = rpc('getIsolate', isolateId=isolate_id)
print('Pause event:', details.get('pauseEvent', {}).get('kind'))
for filename, class_name, expressions in [
    ('anime_player_view.dart', '_AnimeStreamPageState', [
        '_inPip', '_isLocked.value', '_videoTextureVisible',
        '_player.state.position.inSeconds', '_player.state.playing',
        '_player.state.buffering', '_routeExitInProgress',
        'WidgetsBinding.instance.lifecycleState.toString()',
        'WidgetsBinding.instance.framesEnabled', '_revealControls.value',
        'TickerMode.of(context)',
    ]),
    ('widgets/mobile.dart', '_MobileControllerWidgetState', ['visible', 'mount', 'buffering', 'mounted']),
]:
    libraries = [l for l in details['libraries'] if l['uri'].endswith(filename)]
    if not libraries:
        print(filename, 'not loaded')
        continue
    library = rpc('getObject', isolateId=isolate_id, objectId=libraries[0]['id'])
    classes = [c for c in library['classes'] if c['name'] == class_name]
    if not classes:
        print('Classes:', [c['name'] for c in library['classes']])
        continue
    samples = rpc('getInstances', isolateId=isolate_id, objectId=classes[0]['id'], limit=5)['samples']
    for sample in samples:
        print(class_name, sample['id'])
        for expression in expressions:
            value = rpc('evaluate', isolateId=isolate_id, targetId=sample['id'], expression=expression)
            print(expression, value.get('valueAsString', value.get('kind', value.get('type'))))
