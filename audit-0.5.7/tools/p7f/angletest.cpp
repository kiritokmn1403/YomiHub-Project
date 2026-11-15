// P7F R21: ANGLE presentation test (uses Flutter's libEGL.dll / libGLESv2.dll).
// usage: angletest <mode> <seconds> <logfile>
#include <windows.h>
#include <dxgi1_2.h>
#include <cstdio>
#include <cstdlib>
typedef void* EGLDisplay; typedef void* EGLConfig; typedef void* EGLContext; typedef void* EGLSurface; typedef int EGLint; typedef unsigned EGLBoolean;
static HMODULE egl, gles; static FILE* lg;
#define P(m, n) GetProcAddress(m, n)
static EGLDisplay (WINAPI *eglGetPlatformDisplayEXT)(unsigned, void*, const EGLint*);
static EGLBoolean (WINAPI *eglInitialize)(EGLDisplay, EGLint*, EGLint*);
static EGLBoolean (WINAPI *eglChooseConfig)(EGLDisplay, const EGLint*, EGLConfig*, EGLint, EGLint*);
static EGLContext (WINAPI *eglCreateContext)(EGLDisplay, EGLConfig, EGLContext, const EGLint*);
static EGLSurface (WINAPI *eglCreateWindowSurface)(EGLDisplay, EGLConfig, HWND, const EGLint*);
static EGLBoolean (WINAPI *eglMakeCurrent)(EGLDisplay, EGLSurface, EGLSurface, EGLContext);
static EGLBoolean (WINAPI *eglSwapBuffers)(EGLDisplay, EGLSurface);
static EGLBoolean (WINAPI *eglSwapInterval)(EGLDisplay, EGLint);
static EGLint (WINAPI *eglGetError)();
static void (WINAPI *glClearColor)(float, float, float, float);
static void (WINAPI *glClear)(unsigned);
static void (WINAPI *glEnable)(unsigned);
static void (WINAPI *glDisable)(unsigned);
static void (WINAPI *glScissor)(int, int, int, int);
static void (WINAPI *glViewport)(int, int, int, int);
static const unsigned char* (WINAPI *glGetString)(unsigned);
static unsigned (WINAPI *glGetError)();
static void (WINAPI *glReadPixels)(int,int,int,int,unsigned,unsigned,void*);
static EGLBoolean (WINAPI *eglDestroySurface)(EGLDisplay, EGLSurface);

// ---- flag 8: process-local vtable hook, bitblt-model HWND swap chain -> flip model
typedef HRESULT (STDMETHODCALLTYPE *CreateForHwndFn)(IDXGIFactory2*, IUnknown*, HWND, const DXGI_SWAP_CHAIN_DESC1*, const DXGI_SWAP_CHAIN_FULLSCREEN_DESC*, IDXGIOutput*, IDXGISwapChain1**);
static CreateForHwndFn g_orig;
static HRESULT STDMETHODCALLTYPE HookCreateForHwnd(IDXGIFactory2* f, IUnknown* dev, HWND h, const DXGI_SWAP_CHAIN_DESC1* d, const DXGI_SWAP_CHAIN_FULLSCREEN_DESC* fs, IDXGIOutput* o, IDXGISwapChain1** out) {
  DXGI_SWAP_CHAIN_DESC1 c = *d;
  fprintf(lg, "hook: in effect=%d buffers=%d fmt=%d usage=0x%x scaling=%d alpha=%d flags=0x%x %ux%u\n", d->SwapEffect, d->BufferCount, d->Format, d->BufferUsage, d->Scaling, d->AlphaMode, d->Flags, d->Width, d->Height);
  if (c.SwapEffect == DXGI_SWAP_EFFECT_SEQUENTIAL || c.SwapEffect == DXGI_SWAP_EFFECT_DISCARD) {
    c.SwapEffect = DXGI_SWAP_EFFECT_FLIP_SEQUENTIAL; if (c.BufferCount < 2) c.BufferCount = 2; c.SampleDesc.Count = 1; c.SampleDesc.Quality = 0;
    HRESULT hr = g_orig(f, dev, h, &c, fs, o, out);
    fprintf(lg, "hook: flip hr=0x%lx\n", hr);
    if (SUCCEEDED(hr)) return hr;
  }
  HRESULT hr = g_orig(f, dev, h, d, fs, o, out);
  fprintf(lg, "hook: original hr=0x%lx\n", hr);
  return hr;
}
static void InstallHook() {
  HMODULE dx = LoadLibraryW(L"dxgi.dll"); if (!dx) return;
  typedef HRESULT (WINAPI *CF)(REFIID, void**);
  CF cf = (CF)GetProcAddress(dx, "CreateDXGIFactory1"); if (!cf) return;
  IDXGIFactory2* fac = nullptr;
  if (FAILED(cf(__uuidof(IDXGIFactory2), (void**)&fac)) || !fac) { fprintf(lg, "hook: no IDXGIFactory2\n"); return; }
  void** vt = *(void***)fac;
  DWORD old = 0;
  if (VirtualProtect(&vt[15], sizeof(void*), PAGE_READWRITE, &old)) {
    g_orig = (CreateForHwndFn)vt[15]; vt[15] = (void*)HookCreateForHwnd;
    VirtualProtect(&vt[15], sizeof(void*), old, &old);
    fprintf(lg, "hook: installed\n");
  } else fprintf(lg, "hook: VirtualProtect failed %lu\n", GetLastError());
  // keep the factory alive (and dxgi.dll loaded) for the life of the process
}
static LRESULT CALLBACK WndProc(HWND h, UINT m, WPARAM w, LPARAM l) {
  if (m == WM_DESTROY) { PostQuitMessage(0); return 0; }
  return DefWindowProcW(h, m, w, l);
}
int main(int argc, char** argv) {
  int mode = argc > 1 ? atoi(argv[1]) : 0; int secs = argc > 2 ? atoi(argv[2]) : 6;
  int flags = argc > 4 ? atoi(argv[4]) : 0;
  lg = fopen(argc > 3 ? argv[3] : "angletest.log", "a");
  fprintf(lg, "== mode %d flags %d\n", mode, flags);
  egl = LoadLibraryW(L"libEGL.dll"); gles = LoadLibraryW(L"libGLESv2.dll");
  if (!egl || !gles) { fprintf(lg, "dll load failed %lu\n", GetLastError()); return 2; }
#define L(m, f) *(void**)&f = (void*)P(m, #f); if (!f) { fprintf(lg, "missing %s\n", #f); return 3; }
  L(egl, eglGetPlatformDisplayEXT) L(egl, eglInitialize) L(egl, eglChooseConfig) L(egl, eglCreateContext) L(egl, eglCreateWindowSurface)
  L(egl, eglDestroySurface) L(egl, eglMakeCurrent) L(egl, eglSwapBuffers) L(egl, eglSwapInterval) L(egl, eglGetError)
  L(gles, glClearColor) L(gles, glClear) L(gles, glEnable) L(gles, glDisable) L(gles, glScissor) L(gles, glViewport) L(gles, glGetString) L(gles, glGetError) L(gles, glReadPixels)
  if (flags & 8) InstallHook();
  WNDCLASSW wc = {0}; wc.lpfnWndProc = WndProc; wc.hInstance = GetModuleHandle(0); wc.lpszClassName = L"P7F_ANGLE_TOP"; wc.hCursor = LoadCursor(0, IDC_ARROW);
  wc.hbrBackground = (HBRUSH)GetStockObject(mode == 8 ? BLACK_BRUSH : WHITE_BRUSH);
  RegisterClassW(&wc);
  WNDCLASSW wc2 = {0}; wc2.lpfnWndProc = WndProc; wc2.hInstance = wc.hInstance; wc2.lpszClassName = L"P7F_ANGLE_VIEW"; wc2.style = CS_HREDRAW | CS_VREDRAW;
  RegisterClassW(&wc2);
  wchar_t title[64]; swprintf(title, 64, L"angletest mode %d flags %d", mode, flags);
  HWND top = CreateWindowExW((flags & 2) ? WS_EX_LAYERED : 0, wc.lpszClassName, title, WS_OVERLAPPEDWINDOW, 60, 60, 900, 600, 0, 0, wc.hInstance, 0);
  if (flags & 2) SetLayeredWindowAttributes(top, 0, 255, LWA_ALPHA);
  RECT rc; GetClientRect(top, &rc);
  HWND view = top;
  if (mode != 5) view = CreateWindowExW(0, wc2.lpszClassName, L"VIEW", WS_CHILD | WS_VISIBLE, 0, 0, rc.right, rc.bottom, top, 0, wc.hInstance, 0);
  EGLint a0[] = {0x3203, 0x3208, 0x3204, 11, 0x3205, 0, 0x320F, 1, 0x33A4, 0x33A9, 0x3038};       // flutter: d3d11 + trim + fast path
  EGLint a1[] = {0x3203, 0x3208, 0x3204, 11, 0x3205, 0, 0x3038};                                  // d3d11 plain
  EGLint a2[] = {0x3203, 0x3208, 0x3209, 0x320B, 0x3038};                                         // WARP
  EGLint a4[] = {0x3203, 0x3207, 0x3038};                                                         // d3d9
  const EGLint* da = mode == 1 ? a1 : mode == 2 ? a2 : mode == 4 ? a4 : a0;
  EGLDisplay d = eglGetPlatformDisplayEXT(0x3202, 0, da);
  EGLint maj = 0, min = 0;
  if (!d || !eglInitialize(d, &maj, &min)) { fprintf(lg, "eglInitialize failed 0x%x\n", eglGetError()); fclose(lg); return 4; }
  EGLint ca[] = {0x3024, 8, 0x3023, 8, 0x3022, 8, 0x3021, 8, 0x3040, 4, 0x3033, 4, 0x3038};
  EGLConfig cfg; EGLint n = 0; eglChooseConfig(d, ca, &cfg, 1, &n);
  EGLint cta[] = {0x3098, 2, 0x3038};
  EGLContext ctx = eglCreateContext(d, cfg, 0, cta);
  EGLint sa0[] = {0x3201, 1, 0x3057, rc.right, 0x3056, rc.bottom, 0x3038};
  EGLint sa3[] = {0x3201, 1, 0x3057, rc.right, 0x3056, rc.bottom, 0x33A5, 1, 0x3038};
  EGLint sa7[] = {0x3038};
  EGLSurface s = eglCreateWindowSurface(d, cfg, view, mode == 3 ? sa3 : mode == 7 ? sa7 : sa0);
  fprintf(lg, "egl %d.%d cfgs=%d ctx=%p surf=%p err=0x%x\n", maj, min, n, ctx, s, eglGetError());
  if (!s || !ctx || !eglMakeCurrent(d, s, s, ctx)) { fprintf(lg, "surface/ctx/makecurrent failed 0x%x\n", eglGetError()); fclose(lg); return 5; }
  fprintf(lg, "renderer: %s\n", glGetString(0x1F01));
  eglSwapInterval(d, (flags & 4) ? 1 : 0);
  // like Flutter: render first frame while hidden, then show
  DWORD t0 = GetTickCount(); int frames = 0; bool shown = false; MSG msg;
  for (;;) {
    while (PeekMessageW(&msg, 0, 0, 0, PM_REMOVE)) { if (msg.message == WM_QUIT) goto out; TranslateMessage(&msg); DispatchMessageW(&msg); }
    if (GetTickCount() - t0 > (DWORD)secs * 1000) break;
    if ((flags & 16) && (frames == 60 || frames == 90)) {   // like a Flutter resize: destroy + recreate the window surface
      int w = frames == 60 ? 700 : 1000, h = frames == 60 ? 450 : 640;
      SetWindowPos(top, 0, 0, 0, w, h, SWP_NOMOVE | SWP_NOZORDER); GetClientRect(top, &rc); if (view != top) MoveWindow(view, 0, 0, rc.right, rc.bottom, TRUE);
      eglMakeCurrent(d, 0, 0, 0); eglDestroySurface(d, s);
      EGLint sar[] = {0x3201, 1, 0x3057, rc.right, 0x3056, rc.bottom, 0x3038};
      s = eglCreateWindowSurface(d, cfg, view, sar);
      EGLBoolean mk = s ? eglMakeCurrent(d, s, s, ctx) : 0;
      fprintf(lg, "recreate %dx%d surf=%p makecurrent=%u err=0x%x\n", rc.right, rc.bottom, s, mk, eglGetError());
      if (!mk) break;
    }
    if (mode == 6 && frames >= 1) { Sleep(50); continue; }   // single frame, then idle (like an idle Flutter app)
    glViewport(0, 0, rc.right, rc.bottom);
    glDisable(0x0C11); glClearColor(0.0f, 0.6f, 0.2f, 1.0f); glClear(0x4000);
    glEnable(0x0C11); glScissor(100 + (frames % 50) * 4, 100, 200, 150); glClearColor(0.9f, 0.1f, 0.1f, 1.0f); glClear(0x4000);
    if (frames == 0) { unsigned char px[4] = {0}; glDisable(0x0C11); glReadPixels(10, 10, 1, 1, 0x1908, 0x1401, px); fprintf(lg, "readpixels %d %d %d %d glerr=0x%x\n", px[0], px[1], px[2], px[3], glGetError()); }
    EGLBoolean ok = eglSwapBuffers(d, s);
    if (frames == 0 || !ok) fprintf(lg, "swap %d ok=%u err=0x%x\n", frames, ok, eglGetError());
    frames++;
    if (!shown) { ShowWindow(top, SW_SHOW); ShowWindow(top, SW_SHOWNORMAL); UpdateWindow(top); shown = true; if (flags & 1) SetWindowPos(top, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE); }
    if ((flags & 1) && frames % 10 == 0) SetWindowPos(top, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE);
    Sleep(30);
  }
out:
  fprintf(lg, "frames=%d\n", frames); fclose(lg);
  return 0;
}
