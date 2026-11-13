#!/usr/bin/env python3
"""YomiHub A6: đóng gói lại APK để thử trên API 23 mà không cần Gradle.
  repack_apk.py in.apk out.apk [--abi x86_64] [--patch-isar] [--minsdk 23]
                [--replace zipname=file ...] [--add zipname=file ...] [--front-dex classes.dex]
- --patch-isar : vá lib/<abi>/libisar.so có sẵn trong APK (patch_libisar_kernel.py)
- --minsdk N   : sửa minSdkVersion trong AndroidManifest.xml nhị phân
- --front-dex  : chèn dex mới làm classes.dex, đẩy các dex cũ lùi 1 số (lớp trong dex đầu thắng)
- --only-abi   : bỏ lib của ABI khác (giảm dung lượng)
Chữ ký cũ (META-INF/*.SF|RSA|MF) bị bỏ; ký lại bằng zipalign + apksigner.
"""
import sys, zipfile, re, struct, argparse, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from patch_libisar_kernel import patch as patch_isar

def patch_minsdk(axml, new):
    # string pool: tìm chỉ số chuỗi "minSdkVersion"
    assert struct.unpack_from('<H', axml, 0)[0] == 0x0003
    sp = 8
    typ, hsz, size, nstr, nsty, flags, sstart, stystart = struct.unpack_from('<HHIIIIII', axml, sp)
    assert typ == 0x0001
    utf8 = bool(flags & 0x100)
    idx = None
    for i in range(nstr):
        off = sp + sstart + struct.unpack_from('<I', axml, sp + hsz + 4 * i)[0]
        if utf8:
            n = axml[off]; off += 1
            if n & 0x80: off += 1
            n = axml[off]; off += 1
            if n & 0x80: n = ((n & 0x7f) << 8) | axml[off]; off += 1
            s = axml[off:off + n].decode('utf-8', 'replace')
        else:
            n = struct.unpack_from('<H', axml, off)[0]; off += 2
            s = axml[off:off + 2 * n].decode('utf-16le', 'replace')
        if s == 'minSdkVersion': idx = i; break
    assert idx is not None, 'không thấy minSdkVersion'
    b = bytearray(axml); cnt = 0
    pat = re.compile(re.escape(struct.pack('<I', idx)) + rb'\xff\xff\xff\xff\x08\x00\x00\x10(....)', re.S)
    for m in pat.finditer(axml):
        old = struct.unpack('<I', m.group(1))[0]
        struct.pack_into('<I', b, m.start(1), new); cnt += 1
        print(f'manifest: minSdkVersion {old} -> {new}')
    assert cnt == 1, cnt
    return bytes(b)

ap = argparse.ArgumentParser()
ap.add_argument('src'); ap.add_argument('dst')
ap.add_argument('--abi', default='x86_64'); ap.add_argument('--only-abi', action='store_true')
ap.add_argument('--patch-isar', action='store_true'); ap.add_argument('--minsdk', type=int)
ap.add_argument('--replace', action='append', default=[]); ap.add_argument('--add', action='append', default=[])
ap.add_argument('--front-dex')
a = ap.parse_args()
rep = dict(x.split('=', 1) for x in a.replace); add = dict(x.split('=', 1) for x in a.add)
zin = zipfile.ZipFile(a.src); zout = zipfile.ZipFile(a.dst, 'w', allowZip64=False)
def put(name, data, ctype):
    zi = zipfile.ZipInfo(name, (1981, 1, 1, 1, 1, 2)); zi.compress_type = ctype; zi.external_attr = 0o644 << 16
    zout.writestr(zi, data, compresslevel=6)
libctype = zipfile.ZIP_DEFLATED
for it in zin.infolist():
    n = it.filename
    if re.match(r'META-INF/[^/]+\.(SF|RSA|DSA|EC|MF)$', n): continue
    if a.only_abi and n.startswith('lib/') and not n.startswith(f'lib/{a.abi}/'): continue
    if n.startswith('lib/'): libctype = it.compress_type
    data = zin.read(n)
    if n in rep: data = open(rep[n], 'rb').read(); print('replace', n, len(data))
    elif a.patch_isar and n == f'lib/{a.abi}/libisar.so':
        data, off = patch_isar(a.abi, data); print(f'patched {n} @0x{off:x}')
    elif a.minsdk and n == 'AndroidManifest.xml': data = patch_minsdk(data, a.minsdk)
    if a.front_dex:
        m = re.match(r'classes(\d*)\.dex$', n)
        if m: n = 'classes%d.dex' % (int(m.group(1) or 1) + 1); print('dex ->', n)
    put(n, data, it.compress_type)
if a.front_dex: put('classes.dex', open(a.front_dex, 'rb').read(), zipfile.ZIP_DEFLATED); print('front dex added')
for n, f in add.items(): put(n, open(f, 'rb').read(), libctype if n.startswith('lib/') else zipfile.ZIP_DEFLATED); print('add', n)
zout.close(); print('wrote', a.dst, os.path.getsize(a.dst))
