from pathlib import Path
import hashlib
import csv
import json

root = Path(__file__).resolve().parent
output = root.parent / 'output'
files = sorted(p for p in output.glob('*0.3.9*') if p.suffix.lower() in {'.apk', '.exe', '.zip'})
rows = []
for file in files:
    with file.open('rb') as stream:
        digest = hashlib.file_digest(stream, 'sha256').hexdigest()
    rows.append({'file': file.name, 'bytes': file.stat().st_size, 'sha256': digest})
with (output / 'checksums_0.3.9.csv').open('w', newline='', encoding='utf-8-sig') as stream:
    writer = csv.DictWriter(stream, fieldnames=['file', 'bytes', 'sha256'])
    writer.writeheader()
    writer.writerows(rows)
(output / 'SHA256SUMS-0.3.9.txt').write_text(''.join(f"{r['sha256']}  {r['file']}\n" for r in rows), encoding='utf-8')
print(json.dumps(rows, indent=2))
