#!/usr/bin/env python3
"""YomiHub 0.5.6.1 A6: chuẩn bị thư viện gốc đã vá cho APK Android 6.0 (API 23).
  python3 -I prepare_jnilibs23.py <thư_mục_APK_chính> <phiên_bản> <thư_mục_ra>
  vd: prepare_jnilibs23.py output/0.5.6 0.5.6 audit-0.5.7/android6/jnilibs23
Lấy thư viện từ APK Android 7.0+ chính (đã strip, cùng engine/plugin), vá rồi ghi
<ra>/<abi>/*.so + <ra>/MANIFEST.txt (sha256 gốc -> sau vá). build_0561_android6.ps1
chép các tệp này vào jniLibs của build23 (pickFirsts + keepDebugSymbols) và kiểm lại sha.
  libisar.so   : hạ ngưỡng kernel 3.16 -> 3.0 trong libmdbx (patch_libisar_kernel.py)
  libflutter.so: thêm DT_NEEDED libyhcompat.so (x86_64, arm64-v8a); armeabi-v7a chép nguyên (đã strip)
  libtor.so    : thêm DT_NEEDED libyhcompat.so (__write_chk, getifaddrs, freeifaddrs)
  libmpv.so    : thêm DT_NEEDED libyhcompat.so (chỉ armeabi-v7a: fseeko64, ftello64)
  librust_lib_mangayomi.so: chép nguyên (không thiếu ký hiệu API 23; xem A6_FEASIBILITY.md)
  libyhcompat.so: từ compat/<abi>/ (yhcompat.c, NDK 28.2 clang, API 23)
"""
import sys, os, zipfile, hashlib
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from patch_libisar_kernel import patch as patch_isar
from elf_add_needed import add_needed

HERE = os.path.dirname(os.path.abspath(__file__))
ABIS = ['arm64-v8a', 'armeabi-v7a', 'x86_64']
NEED = {'libflutter.so': {'x86_64', 'arm64-v8a'}, 'libtor.so': set(ABIS), 'libmpv.so': {'armeabi-v7a'}}
sha = lambda d: hashlib.sha256(d).hexdigest()

def main(src_dir, ver, out):
    lines = []
    for abi in ABIS:
        apk = os.path.join(src_dir, f'YomiHub-{ver}-{abi}.apk')
        z = zipfile.ZipFile(apk)
        od = os.path.join(out, abi); os.makedirs(od, exist_ok=True)
        def w(name, data, orig, act):
            open(os.path.join(od, name), 'wb').write(data)
            lines.append(f'{abi} {name} {sha(orig) if orig is not None else "-"} {sha(data)} {act}')
            print(abi, name, act, len(data))
        d = z.read(f'lib/{abi}/libisar.so'); p, off = patch_isar(abi, d); w('libisar.so', p, d, f'kernel-check@0x{off:x}')
        for name, abis in NEED.items():
            d = z.read(f'lib/{abi}/{name}')
            if abi in abis:
                p, ch = add_needed(d, 'libyhcompat.so'); assert ch, (abi, name)
                w(name, p, d, 'DT_NEEDED+libyhcompat.so')
            elif name == 'libflutter.so':
                # armeabi-v7a: engine 32-bit không cần shim, nhưng vẫn chép bản đã strip của APK chính
                # (keepDebugSymbols trong build23 sẽ giữ nguyên bản 150 MB chưa strip của AAR nếu thiếu)
                w(name, d, d, 'copy (khong can va)')
        d = z.read(f'lib/{abi}/librust_lib_mangayomi.so'); w('librust_lib_mangayomi.so', d, d, 'copy')
        d = open(os.path.join(HERE, 'compat', abi, 'libyhcompat.so'), 'rb').read(); w('libyhcompat.so', d, None, 'compat/yhcompat.c')
    with open(os.path.join(out, 'MANIFEST.txt'), 'w', newline='\n') as f:
        f.write(f'# nguon: {os.path.abspath(src_dir)} ({ver})  abi ten sha_goc sha_sau_va thao_tac\n')
        f.write('\n'.join(lines) + '\n')

if __name__ == '__main__':
    main(*sys.argv[1:4])
