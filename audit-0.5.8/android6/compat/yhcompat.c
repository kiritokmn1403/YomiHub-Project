// YomiHub 0.4.3 – Android 6.0 (API 23) compatibility shim for libflutter.so.
// YomiHub 0.5.6.1 (A6): them fseeko64/ftello64 cho 32-bit (libmpv armeabi-v7a can API 24);
// cung dung cho libtor.so (__write_chk, getifaddrs, freeifaddrs).
// The Flutter engine shipped with Flutter 3.47 is linked against API 24 and
// imports four libc symbols that Android 6.0 does not have. This library
// provides them: on API 24+ every call is forwarded to the real libc
// function, on API 23 a safe fallback is used.
#include <dlfcn.h>
#include <errno.h>
#include <stdio.h>
#include <unistd.h>
#include <stddef.h>
#include <stdint.h>
#include <sys/types.h>

struct ifaddrs;

static void* libc_sym(const char* name) {
  static void* h = NULL;
  if (!h) h = dlopen("libc.so", RTLD_NOW | RTLD_NOLOAD);
  if (!h) h = dlopen("libc.so", RTLD_NOW);
  return h ? dlsym(h, name) : NULL;
}

__attribute__((visibility("default")))
size_t __fwrite_chk(const void* buf, size_t size, size_t count, FILE* stream, size_t buf_size) {
  typedef size_t (*fn)(const void*, size_t, size_t, FILE*, size_t);
  static fn real = (fn)-1;
  if (real == (fn)-1) real = (fn)libc_sym("__fwrite_chk");
  if (real && (void*)real != (void*)&__fwrite_chk) return real(buf, size, count, stream, buf_size);
  return fwrite(buf, size, count, stream);
}

__attribute__((visibility("default")))
ssize_t __write_chk(int fd, const void* buf, size_t count, size_t buf_size) {
  typedef ssize_t (*fn)(int, const void*, size_t, size_t);
  static fn real = (fn)-1;
  if (real == (fn)-1) real = (fn)libc_sym("__write_chk");
  if (real && (void*)real != (void*)&__write_chk) return real(fd, buf, count, buf_size);
  return write(fd, buf, count);
}

__attribute__((visibility("default")))
int getifaddrs(struct ifaddrs** out) {
  typedef int (*fn)(struct ifaddrs**);
  static fn real = (fn)-1;
  if (real == (fn)-1) real = (fn)libc_sym("getifaddrs");
  if (real && (void*)real != (void*)&getifaddrs) return real(out);
  if (out) *out = NULL;
  errno = ENOSYS;  // Android 6.0: network interface listing unavailable
  return -1;
}

__attribute__((visibility("default")))
void freeifaddrs(struct ifaddrs* p) {
  typedef void (*fn)(struct ifaddrs*);
  static fn real = (fn)-1;
  if (real == (fn)-1) real = (fn)libc_sym("freeifaddrs");
  if (real && (void*)real != (void*)&freeifaddrs) real(p);
}

#if !defined(__LP64__)
// Android 6.0 32-bit: fseeko64/ftello64 chi co tu API 24. Du phong: fseeko/ftello 32-bit
// (tep > 2 GiB tra EOVERFLOW). API 24+: chuyen thang sang ham that cua libc.
__attribute__((visibility("default")))
int fseeko64(FILE* fp, off64_t off, int whence) {
  typedef int (*fn)(FILE*, off64_t, int);
  static fn real = (fn)-1;
  if (real == (fn)-1) real = (fn)libc_sym("fseeko64");
  if (real && (void*)real != (void*)&fseeko64) return real(fp, off, whence);
  if (off > (off64_t)INT32_MAX || off < (off64_t)INT32_MIN) { errno = EOVERFLOW; return -1; }
  return fseeko(fp, (off_t)off, whence);
}

__attribute__((visibility("default")))
off64_t ftello64(FILE* fp) {
  typedef off64_t (*fn)(FILE*);
  static fn real = (fn)-1;
  if (real == (fn)-1) real = (fn)libc_sym("ftello64");
  if (real && (void*)real != (void*)&ftello64) return real(fp);
  return (off64_t)ftello(fp);
}
#endif
