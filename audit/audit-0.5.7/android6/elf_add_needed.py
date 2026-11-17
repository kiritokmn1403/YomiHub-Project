#!/usr/bin/env python3
"""YomiHub A6: thêm DT_NEEDED vào một thư viện ELF (thay cho patchelf --add-needed).
  elf_add_needed.py in.so out.so libyhcompat.so
Cách làm: chép .dynstr (+tên mới) và .dynamic (+DT_NEEDED) ra cuối tệp, đổi PT_NOTE thành
PT_LOAD ánh xạ vùng mới, trỏ PT_DYNAMIC + section header .dynamic/.dynstr sang vùng mới
(linker Android 8+ đối chiếu section header với PT_DYNAMIC). Hỗ trợ ELF32/ELF64 little-endian.
Cuối tệp có 16 byte đệm: linker Android 6.0 từ chối PT_LOAD kết thúc đúng tại EOF.
"""
import struct, sys
PT_LOAD, PT_DYNAMIC, PT_NOTE = 1, 2, 4
DT_NULL, DT_NEEDED, DT_STRTAB, DT_STRSZ = 0, 1, 5, 10
SHT_STRTAB, SHT_DYNAMIC = 3, 6

def add_needed(data, name):
    b = bytearray(data)
    assert b[:4] == b'\x7fELF' and b[5] == 1
    is64 = b[4] == 2
    if is64:
        e_phoff, e_shoff = struct.unpack_from('<QQ', b, 0x20)
        e_phentsize, e_phnum, e_shentsize, e_shnum = struct.unpack_from('<HHHH', b, 0x36)
        PH = '<IIQQQQQQ'   # type flags offset vaddr paddr filesz memsz align
        def rph(i):
            t, fl, off, va, pa, fs, ms, al = struct.unpack_from(PH, b, e_phoff + i * e_phentsize); return dict(t=t, fl=fl, off=off, va=va, pa=pa, fs=fs, ms=ms, al=al)
        def wph(i, p): struct.pack_into(PH, b, e_phoff + i * e_phentsize, p['t'], p['fl'], p['off'], p['va'], p['pa'], p['fs'], p['ms'], p['al'])
        SH = '<IIQQQQIIQQ'; DYN = '<qQ'
    else:
        e_phoff, e_shoff = struct.unpack_from('<II', b, 0x1c)
        e_phentsize, e_phnum, e_shentsize, e_shnum = struct.unpack_from('<HHHH', b, 0x2a)
        PH = '<IIIIIIII'   # type offset vaddr paddr filesz memsz flags align
        def rph(i):
            t, off, va, pa, fs, ms, fl, al = struct.unpack_from(PH, b, e_phoff + i * e_phentsize); return dict(t=t, fl=fl, off=off, va=va, pa=pa, fs=fs, ms=ms, al=al)
        def wph(i, p): struct.pack_into(PH, b, e_phoff + i * e_phentsize, p['t'], p['off'], p['va'], p['pa'], p['fs'], p['ms'], p['fl'], p['al'])
        SH = '<IIIIIIIIII'; DYN = '<iI'
    dsz = struct.calcsize(DYN)
    phs = [rph(i) for i in range(e_phnum)]
    idyn = next(i for i, p in enumerate(phs) if p['t'] == PT_DYNAMIC)
    inote = [i for i, p in enumerate(phs) if p['t'] == PT_NOTE]
    assert inote, 'không có PT_NOTE để tái dụng'
    inote = inote[-1]
    loads = [p for p in phs if p['t'] == PT_LOAD]
    def v2o(va):
        for p in loads:
            if p['va'] <= va < p['va'] + p['fs']: return va - p['va'] + p['off']
        raise ValueError(hex(va))
    dyn = phs[idyn]
    ents = []
    for k in range(dyn['fs'] // dsz):
        tag, val = struct.unpack_from(DYN, b, dyn['off'] + k * dsz)
        if tag == DT_NULL: break
        ents.append([tag, val])
    strtab = next(v for t, v in ents if t == DT_STRTAB); strsz = next(v for t, v in ents if t == DT_STRSZ)
    so = v2o(strtab); old = bytes(b[so:so + strsz])
    for t, v in ents:
        if t == DT_NEEDED and old[v:old.index(b'\0', v)].decode() == name: return bytes(b), False
    newstr = old + name.encode() + b'\0'
    page = 0x10000 if is64 else 0x1000
    page = max(page, max(p['al'] for p in loads))
    foff = (len(b) + 15) & ~15
    vaddr = (max(p['va'] + p['ms'] for p in loads) + page - 1) & ~(page - 1)
    vaddr += foff % page                       # p_offset ≡ p_vaddr (mod align)
    str_va = vaddr; dyn_off_in = (len(newstr) + 15) & ~15; dyn_va = vaddr + dyn_off_in
    # DT_NEEDED mới đứng sau các DT_NEEDED sẵn có
    last = max(i for i, e in enumerate(ents) if e[0] == DT_NEEDED)
    ents.insert(last + 1, [DT_NEEDED, strsz])
    for e in ents:
        if e[0] == DT_STRTAB: e[1] = str_va
        elif e[0] == DT_STRSZ: e[1] = len(newstr)
    ents.append([DT_NULL, 0])
    blob = bytearray(newstr) + b'\0' * (dyn_off_in - len(newstr))
    for t, v in ents: blob += struct.pack(DYN, t, v)
    b += b'\0' * (foff - len(b)) + blob
    # Linker Android 6.0 báo "load segment ... past end of file" khi p_offset + p_filesz == kích thước tệp
    # (so sánh >=): chừa thêm 16 byte đệm sau vùng mới.
    b += b'\0' * 16
    wph(inote, dict(t=PT_LOAD, fl=6, off=foff, va=vaddr, pa=vaddr, fs=len(blob), ms=len(blob), al=page))
    wph(idyn, dict(dyn, off=foff + dyn_off_in, va=dyn_va, pa=dyn_va, fs=len(ents) * dsz, ms=len(ents) * dsz))
    # PT_LOAD phải tăng dần theo vaddr: vùng mới ở vaddr cao nhất; nếu PT_NOTE đứng trước các PT_LOAD khác thì hoán đổi vị trí
    phs = [rph(i) for i in range(e_phnum)]
    li = [i for i, p in enumerate(phs) if p['t'] == PT_LOAD]
    order = sorted((phs[i] for i in li), key=lambda p: p['va'])
    for i, p in zip(li, order): wph(i, p)
    # section headers
    for i in range(e_shnum):
        o = e_shoff + i * e_shentsize
        f = list(struct.unpack_from(SH, b, o))   # name type flags addr offset size link info align entsize
        if f[1] == SHT_DYNAMIC:
            f[3], f[4], f[5] = dyn_va, foff + dyn_off_in, len(ents) * dsz
        elif f[1] == SHT_STRTAB and f[3] == strtab:
            f[3], f[4], f[5] = str_va, foff, len(newstr)
        else: continue
        struct.pack_into(SH, b, o, *f)
    return bytes(b), True

if __name__ == '__main__':
    src, dst, name = sys.argv[1:4]
    out, ch = add_needed(open(src, 'rb').read(), name)
    open(dst, 'wb').write(out); print(dst, 'patched' if ch else 'đã có', len(out))
