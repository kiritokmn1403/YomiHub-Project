"""Package only binaries produced by the final successful 0.3.9 builds."""
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
import argparse
import hashlib
import json
import shutil

audit = Path(__file__).resolve().parent
project = audit.parent
output = project / 'output'
version = '0.3.9'
parser = argparse.ArgumentParser()
parser.add_argument('platform', choices=['windows', 'android'])
parser.add_argument('--revision', choices=['final', 'bookmark', 'player-final'], default='final')
args = parser.parse_args()
log = audit / f'build-{args.platform}-{args.revision}.log'
if args.platform == 'windows' and args.revision == 'player-final':
    log = audit / 'build-windows-player-final-r2.log'
text = log.read_text(encoding='utf-8-sig', errors='replace')
if 'Built ' not in text or 'BUILD FAILED' in text:
    raise SystemExit(f'No successful final build in {log}')
manifest = json.loads((audit / 'SOURCE_MANIFEST.json').read_text(encoding='utf-8'))
production = [row for row in manifest if not row['file'].startswith('test/')
              and (args.platform == 'android' or not row['file'].startswith('android/'))]
for row in production:
    source = project / 'overlay' / row['file']
    if source.stat().st_mtime > log.stat().st_mtime:
        raise SystemExit(f'Production source changed after build: {row["file"]}')
    if hashlib.sha256(source.read_bytes()).hexdigest() != row['overlay_sha256']:
        raise SystemExit(f'Source verification is stale: {row["file"]}')
    if not row[args.platform + '_matches']:
        raise SystemExit(f'Build source differs from overlay: {row["file"]}')
output.mkdir(exist_ok=True)
artifacts = []
if args.platform == 'windows':
    release = Path('D:/A.I Project/yh/buildwin/mangayomi/build/windows/x64/runner/Release')
    for required in ['YomiHub.exe', 'data/app.so', 'flutter_windows.dll', 'yomihub_bin/bridge']:
        if not (release / required).exists():
            raise SystemExit(f'Missing runtime component: {required}')
    target = output / f'YomiHub-{version}-windows-x64.zip'
    with ZipFile(target, 'w', ZIP_DEFLATED, compresslevel=6) as archive:
        for file in sorted(release.rglob('*')):
            if file.is_file() and file.suffix.lower() not in ['.pdb', '.ilk', '.exp', '.lib']:
                archive.write(file, file.relative_to(release).as_posix())
    with ZipFile(target) as archive:
        if archive.testzip() is not None:
            raise SystemExit('ZIP verification failed')
    artifacts.append(target)
else:
    release = Path('D:/A.I Project/yh/build/mangayomi/build/app/outputs/flutter-apk')
    for abi in ['armeabi-v7a', 'arm64-v8a', 'x86_64']:
        source = release / f'app-{abi}-release.apk'
        if source.stat().st_mtime < max((project / 'overlay' / row['file']).stat().st_mtime for row in production):
            raise SystemExit(f'Stale APK: {source}')
        target = output / f'YomiHub-{version}-{abi}.apk'
        shutil.copy2(source, target)
        artifacts.append(target)
records = []
for artifact in artifacts:
    digest = hashlib.file_digest(artifact.open('rb'), 'sha256').hexdigest()
    records.append({'file': artifact.name, 'bytes': artifact.stat().st_size, 'sha256': digest})
(audit / f'packaged-{args.platform}.json').write_text(json.dumps(records, indent=2), encoding='utf-8')
print(json.dumps(records, indent=2))
