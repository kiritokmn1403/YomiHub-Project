#!/usr/bin/env python3
"""YomiHub A6: vá libisar.so (isar_community_flutter_libs 3.3.2, libmdbx 0.13.8)
để mdbx_env_create() không trả MDBX_INCOMPATIBLE trên kernel Linux < 3.16.

libmdbx src/api-env.c:
    if (unlikely(globals.linux_kernel_version < 0x03100000)) { ... return MDBX_INCOMPATIBLE; }
Vá ngưỡng 3.16 -> 3.0 (hằng số so sánh), không đổi kích thước/tệp ELF khác.
Dùng: patch_libisar_kernel.py <abi> <in.so> <out.so>   (abi: x86_64|x86|arm64-v8a|armeabi-v7a)
"""
import re, struct, sys, hashlib

def patch(abi, data):
    b = bytearray(data)
    hits = []
    if abi in ('x86_64', 'x86'):
        # cmp r32, 0x030fffff ; jbe fail
        for m in re.finditer(rb'(?:\x81[\xf8-\xff]|\x3d)\xff\xff\x0f\x03\x0f\x86', data):
            hits.append(m.end() - 6)
        if len(hits) != 1: raise SystemExit(f'{abi}: {len(hits)} hits (cần đúng 1)')
        o = hits[0]; assert b[o:o+4] == b'\xff\xff\x0f\x03'
        b[o:o+4] = b'\xff\xff\xff\x02'          # 0x02ffffff: kernel >= 3.0
    else:
        n = len(data) // 4
        w = struct.unpack_from('<%dI' % n, data)
        for i in range(n - 2):
            if abi == 'arm64-v8a':
                # lsr wA,wB,#20 ; cmp wA,#0x30 ; b.ls
                ok = (w[i] & 0xfffffc00) == 0x53147c00 and (w[i+1] & 0xfffffc1f) == 0x7100c01f and (w[i+2] & 0xff00001f) == 0x54000009
            else:
                # lsr rA,rB,#20 ; cmp rA,#48 ; bls   (mã C của libmdbx ở chế độ ARM)
                ok = (w[i] & 0xffff0ff0) == 0xe1a00a20 and (w[i+1] & 0xfff0ffff) == 0xe3500030 and (w[i+2] & 0xff000000) == 0x9a000000
            if ok: hits.append(i + 1)
        if len(hits) != 1: raise SystemExit(f'{abi}: {len(hits)} hits (cần đúng 1)')
        o = hits[0] * 4
        if abi == 'arm64-v8a':
            v = (w[hits[0]] & ~(0xfff << 10)) | (0x2f << 10)   # cmp wA,#0x2f
        else:
            v = (w[hits[0]] & ~0xff) | 0x2f                    # cmp rA,#47
        struct.pack_into('<I', b, o, v)
    return bytes(b), o

if __name__ == '__main__':
    abi, src, dst = sys.argv[1:4]
    d = open(src, 'rb').read()
    out, off = patch(abi, d)
    open(dst, 'wb').write(out)
    print(f'{abi}: offset 0x{off:x} {d[off:off+4].hex()} -> {out[off:off+4].hex()}  sha256 {hashlib.sha256(d).hexdigest()[:16]} -> {hashlib.sha256(out).hexdigest()[:16]}')
