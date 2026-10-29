"""Create isolated QA device configuration using the already installed system image."""
from pathlib import Path

original = Path('C:/Users/nguye/.android/avd/Medium_Phone.avd/config.ini')
home = Path('D:/A.I Project/yh/avd')
target = home / 'YomiHub039QA.avd'
if target.exists():
    raise SystemExit('QA device already exists; refusing to overwrite it')
settings = {}
for line in original.read_text(encoding='utf-8-sig').splitlines():
    if '=' in line:
        key, value = line.split('=', 1)
        settings[key.strip()] = value.strip()
settings.update({
    'AvdId': 'YomiHub039QA',
    'avd.ini.displayname': 'YomiHub 0.3.9 QA',
    'disk.dataPartition.size': str(12 * 1024**3),
    'fastboot.forceColdBoot': 'yes',
    'fastboot.forceFastBoot': 'no',
    'hw.cpu.ncore': '2',
    'image.sysdir.1': 'C:/Users/nguye/AppData/Local/Android/Sdk/system-images/android-37.0/google_apis_playstore/x86_64/',
})
target.mkdir(parents=True)
(target / 'config.ini').write_text(''.join(f'{k}={v}\n' for k, v in settings.items()), encoding='utf-8')
(home / 'YomiHub039QA.ini').write_text(f'avd.ini.encoding=UTF-8\npath={target}\ntarget=android-37.0\n', encoding='utf-8')
print('Created isolated 12 GB QA configuration; no existing userdata copied or modified.')
