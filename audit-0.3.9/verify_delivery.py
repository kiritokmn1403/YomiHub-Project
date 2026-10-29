"""Read-only final checks of existing 0.3.9 packages and their build evidence."""
from pathlib import Path
import hashlib
import json
import argparse
from zipfile import ZipFile

audit = Path(__file__).resolve().parent
project = audit.parent
parser = argparse.ArgumentParser()
parser.add_argument('--revision', choices=['bookmark', 'player-final'], default='bookmark')
args = parser.parse_args()
rows = json.loads((audit / 'SOURCE_MANIFEST.json').read_text(encoding='utf-8'))
for platform in ('windows', 'android'):
    log = audit / f'build-{platform}-{args.revision}.log'
    if platform == 'windows' and args.revision == 'player-final':
        log = audit / 'build-windows-player-final-r2.log'
    content = log.read_text(encoding='utf-8-sig', errors='replace')
    assert 'Built ' in content and 'BUILD FAILED' not in content
    for row in rows:
        source = project / 'overlay' / row['file']
        assert row[platform + '_matches'], row['file']
        assert hashlib.sha256(source.read_bytes()).hexdigest() == row['overlay_sha256']
        if not row['file'].startswith('test/') and not (platform == 'windows' and row['file'].startswith('android/')):
            assert source.stat().st_mtime <= log.stat().st_mtime, row['file']
    for item in json.loads((audit / f'packaged-{platform}.json').read_text(encoding='utf-8')):
        file = project / 'output' / item['file']
        with file.open('rb') as stream:
            assert hashlib.file_digest(stream, 'sha256').hexdigest() == item['sha256'], file
        assert file.stat().st_size == item['bytes']
setup = project / 'output/YomiHub-0.3.9-windows-x64-Setup.exe'
with setup.open('rb') as stream:
    expected = ('0746aa5c936db3269f0c02155c163e92c9c977c0f4644bf9a4c8816efc02f739'
                if args.revision == 'bookmark' else
                json.loads((audit / 'verified-setup-player-final.json').read_text(encoding='utf-8-sig'))['setup_sha256'])
    assert hashlib.file_digest(stream, 'sha256').hexdigest() == expected
with ZipFile(project / 'output/YomiHub-0.3.9-windows-x64.zip') as archive:
    assert archive.testzip() is None
print('PASS: source hashes/build freshness; 3 APK + ZIP + Setup hashes; complete ZIP CRC. See separate APK signature log.')
