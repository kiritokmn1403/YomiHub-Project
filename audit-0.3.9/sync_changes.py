from pathlib import Path
import shutil, hashlib, json
ROOT=Path(__file__).resolve().parent
OVERLAY=ROOT.parent/'overlay'
BUILD=Path(r'D:\A.I Project\yh\build\mangayomi')
WIN=Path(r'D:\A.I Project\yh\buildwin\mangayomi')

for filename in ['onboarding_screen_test.dart','onboarding_back_button_test.dart']:
 target=OVERLAY/'test/widgets'/filename
 target.parent.mkdir(parents=True,exist_ok=True)
 text=(BUILD/'test/widgets'/filename).read_text(encoding='utf-8')
 text=text.replace('Welcome to Mangayomi','Welcome to YomiHub').replace("'Manga'","'Comic'").replace("'Anime'","'Film & Movie'")
 target.write_text(text,encoding='utf-8')

cutoff=(ROOT/'tests-baseline.log').stat().st_ctime
manifest=[]
for top in ['lib','test','assets']:
 for source in (OVERLAY/top).rglob('*'):
  if source.is_file() and source.stat().st_mtime>=cutoff:
   manifest.append(source.relative_to(OVERLAY).as_posix())
manifest.append('pubspec.yaml')
manifest.append('android/app/src/main/res/values/strings.xml')
(ROOT/'changed-files.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
for rel in manifest:
 for name,build in [('android',BUILD),('windows',WIN)]:
  dest=build/rel
  backup=ROOT/'before'/name/rel
  if dest.exists() and hashlib.sha256(dest.read_bytes()).digest()==hashlib.sha256((OVERLAY/rel).read_bytes()).digest():
   continue
  if dest.exists() and not backup.exists():
   backup.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(dest,backup)
  dest.parent.mkdir(parents=True,exist_ok=True)
  shutil.copy2(OVERLAY/rel,dest)
print('Synchronized',len(manifest),'files; originals retained in audit-0.3.9/before')
