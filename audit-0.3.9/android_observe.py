"""Capture the test emulator only; inputs remain separate, observation-led actions."""
from pathlib import Path
import subprocess
import sys
import xml.etree.ElementTree as ET

root = Path(__file__).resolve().parent
label = sys.argv[1] if len(sys.argv) > 1 else 'current'
if not label.replace('-', '').replace('_', '').isalnum():
    raise SystemExit('Use a simple observation label')
adb = ['D:/yh/tools/android-sdk/platform-tools/adb.exe', '-s', 'emulator-5554']
def run(*args):
    return subprocess.run(adb + list(args), check=True, capture_output=True, text=True)
run('shell', 'screencap', '-p', '/sdcard/yh-039-screen.png')
run('pull', '/sdcard/yh-039-screen.png', str(root / f'android-{label}.png'))
print(f'Image: android-{label}.png')
remote_xml = f'/sdcard/yh039-{label}.xml'
dump = run('shell', 'uiautomator', 'dump', remote_xml)
try:
    run('pull', remote_xml, str(root / f'android-{label}.xml'))
except subprocess.CalledProcessError:
    print('Accessibility dump unavailable: ' + dump.stdout.strip())
    raise SystemExit(0)
for node in ET.parse(root / f'android-{label}.xml').iter('node'):
    text = node.get('text') or node.get('content-desc')
    if text and node.get('password') != 'true':
        print(f"{node.get('bounds')} {text[:400]}{' …' if len(text) > 400 else ''}")
