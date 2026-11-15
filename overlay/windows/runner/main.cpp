#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <cwchar>
#include <string>
#include <vector>

#include "flutter_window.h"
#include "utils.h"
#include "app_links/app_links_plugin_c_api.h"

bool SendAppLinkToInstance(const std::wstring& title) {
  // Find our exact window
  HWND hwnd = ::FindWindow(L"FLUTTER_RUNNER_WIN32_WINDOW", title.c_str());

  if (hwnd) {
    // Dispatch new link to current window
    SendAppLink(hwnd);

    // (Optional) Restore our window to front in same state
    WINDOWPLACEMENT place = { sizeof(WINDOWPLACEMENT) };
    GetWindowPlacement(hwnd, &place);

    switch(place.showCmd) {
      case SW_SHOWMAXIMIZED:
          ShowWindow(hwnd, SW_SHOWMAXIMIZED);
          break;
      case SW_SHOWMINIMIZED:
          ShowWindow(hwnd, SW_RESTORE);
          break;
      default:
          ShowWindow(hwnd, SW_NORMAL);
          break;
    }

    SetWindowPos(0, HWND_TOP, 0, 0, 0, 0, SWP_SHOWWINDOW | SWP_NOSIZE | SWP_NOMOVE);
    SetForegroundWindow(hwnd);
    // END (Optional) Restore

    // Window has been found, don't create another one.
    return true;
  }

  return false;
}

// ---------------------------------------------------------------------------
// YomiHub 0.5.7.1 (R21) - yh_present: the real cause of the "white window".
//
// Measured on the owner's laptop on 15/11/2026 (audit-0.5.7/notes/NOTES_P7F.md,
// tools/p7f/angletest.cpp): a plain ANGLE program - no Flutter at all - shows
// the same white window when ANGLE presents through the swap chain it always
// creates for a HWND: IDXGIFactory2::CreateSwapChainForHwnd with
// DXGI_SWAP_EFFECT_SEQUENTIAL, BufferCount 1 (the legacy "bitblt" model).
// Rendering is correct (glReadPixels returns the frame, eglSwapBuffers
// succeeds) but the presented image never reaches the desktop compositor;
// Intel GPU, NVIDIA GPU and the WARP software device all behave the same.
// The very same program draws correctly as soon as the swap chain uses the
// flip model (DXGI_SWAP_EFFECT_FLIP_SEQUENTIAL, 2 buffers), also after the
// surface is destroyed and re-created the way Flutter does on a resize.
//
// The Flutter engine links ANGLE statically and offers no switch for this, so
// the runner patches one slot of the DXGI factory vtable inside this process
// only: swap chains asked for with the bitblt model are created with the flip
// model instead (what Microsoft recommends for every Windows 10+ program).
// If the flip model is refused the original request is passed through
// unchanged, so the worst case is the old behaviour.
//
// Off switch: YOMIHUB_PRESENT=blt, or "present=blt" in
// %APPDATA%\YomiHub\win_render.ini.
// ---------------------------------------------------------------------------
#include <dxgi1_2.h>

namespace yh_present {

typedef HRESULT(STDMETHODCALLTYPE* CreateForHwndFn)(
    IDXGIFactory2*, IUnknown*, HWND, const DXGI_SWAP_CHAIN_DESC1*,
    const DXGI_SWAP_CHAIN_FULLSCREEN_DESC*, IDXGIOutput*, IDXGISwapChain1**);

CreateForHwndFn g_original = nullptr;
bool g_installed = false;
volatile LONG g_flip_created = 0;    // swap chains created with the flip model
volatile LONG g_flip_refused = 0;    // flip refused, original request used

HRESULT STDMETHODCALLTYPE CreateForHwnd(
    IDXGIFactory2* factory, IUnknown* device, HWND hwnd,
    const DXGI_SWAP_CHAIN_DESC1* desc,
    const DXGI_SWAP_CHAIN_FULLSCREEN_DESC* fullscreen, IDXGIOutput* output,
    IDXGISwapChain1** swap_chain) {
  if (desc != nullptr && fullscreen == nullptr &&
      (desc->SwapEffect == DXGI_SWAP_EFFECT_SEQUENTIAL ||
       desc->SwapEffect == DXGI_SWAP_EFFECT_DISCARD) &&
      desc->SampleDesc.Count <= 1 && !desc->Stereo &&
      (desc->Format == DXGI_FORMAT_B8G8R8A8_UNORM ||
       desc->Format == DXGI_FORMAT_R8G8B8A8_UNORM ||
       desc->Format == DXGI_FORMAT_R16G16B16A16_FLOAT)) {
    DXGI_SWAP_CHAIN_DESC1 flip = *desc;
    flip.SwapEffect = DXGI_SWAP_EFFECT_FLIP_SEQUENTIAL;
    if (flip.BufferCount < 2) flip.BufferCount = 2;
    flip.SampleDesc.Count = 1;
    flip.SampleDesc.Quality = 0;
    const HRESULT hr = g_original(factory, device, hwnd, &flip, fullscreen,
                                  output, swap_chain);
    if (SUCCEEDED(hr)) {
      ::InterlockedIncrement(&g_flip_created);
      return hr;
    }
    ::InterlockedIncrement(&g_flip_refused);
  }
  return g_original(factory, device, hwnd, desc, fullscreen, output, swap_chain);
}

// Call once, before the Flutter engine is created. Returns true when the
// flip-model redirection is active.
bool Install() {
  if (g_installed) return true;
  HMODULE dxgi = ::LoadLibraryW(L"dxgi.dll");
  if (dxgi == nullptr) return false;
  typedef HRESULT(WINAPI* CreateFactoryFn)(REFIID, void**);
  CreateFactoryFn create_factory = reinterpret_cast<CreateFactoryFn>(
      ::GetProcAddress(dxgi, "CreateDXGIFactory1"));
  if (create_factory == nullptr) return false;
  IDXGIFactory2* factory = nullptr;
  if (FAILED(create_factory(__uuidof(IDXGIFactory2),
                            reinterpret_cast<void**>(&factory))) ||
      factory == nullptr) {
    return false;  // Windows 7 without the platform update: nothing to do
  }
  // IDXGIFactory2 vtable: IUnknown 0-2, IDXGIObject 3-6, IDXGIFactory 7-11,
  // IDXGIFactory1 12-13, IsWindowedStereoEnabled 14, CreateSwapChainForHwnd 15.
  void** vtable = *reinterpret_cast<void***>(factory);
  const int kSlot = 15;
  // Only patch a slot that really points into dxgi.dll (not a wrapper put
  // there by a capture / overlay tool).
  HMODULE owner = nullptr;
  if (!::GetModuleHandleExW(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS |
                                GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT,
                            reinterpret_cast<LPCWSTR>(vtable[kSlot]), &owner) ||
      owner != dxgi) {
    factory->Release();
    return false;
  }
  DWORD old_protect = 0;
  if (!::VirtualProtect(&vtable[kSlot], sizeof(void*), PAGE_READWRITE,
                        &old_protect)) {
    factory->Release();
    return false;
  }
  g_original = reinterpret_cast<CreateForHwndFn>(vtable[kSlot]);
  vtable[kSlot] = reinterpret_cast<void*>(&CreateForHwnd);
  ::VirtualProtect(&vtable[kSlot], sizeof(void*), old_protect, &old_protect);
  g_installed = true;
  // The factory (and so dxgi.dll) is kept for the life of the process.
  return true;
}

}  // namespace yh_present

// ---------------------------------------------------------------------------
// YomiHub 0.5.7 (U14 / R21) - yh_render: render-mode selection + blank-window
// watchdog.
//
// Evidence (audit-0.5.6/notes/NOTES_F.md): on the owner's laptop the window
// sometimes stays one flat colour although Dart runs and the FLUTTERVIEW child
// has the right size; it happened with the integrated GPU (default) AND with
// the NVIDIA GPU forced per-app, with Impeller on and off. So no single GPU
// choice is "the fix": the runner therefore does NOT export
// NvOptimusEnablement / AmdPowerXpressRequestHighPerformance (a static export
// cannot be changed per launch and costs battery). Instead the GPU is chosen
// at run time through the engine's own gpu_preference and, when the view is
// still a single colour 12-20 s after start, the app is relaunched once per
// alternative mode:
//   attempt 0: engine default GPU, Skia        (what 0.4.4 - 0.5.6.1 used)
//   attempt 1: high-performance GPU, Skia
//   attempt 2: low-power GPU, Impeller
// A mode that draws is remembered; when none draws the chain stops for good
// (no relaunch loop) and one message box explains what to do.
// The release engine (Flutter 3.47.6) has no software / WARP switch, so that
// fallback is not available here.
//
// Files in %APPDATA%\YomiHub (never inside the install folder):
//   win_render.ini        user choice, written by Settings > Windows diagnostics
//                         mode=auto|igpu|dgpu   impeller=0|1   auto=0|1
//   win_render_state.txt  written here, shown by the diagnostics screen
// Environment overrides: YOMIHUB_GPU=igpu|dgpu, YOMIHUB_IMPELLER=1,
// YOMIHUB_RENDER_AUTO=0.
// ---------------------------------------------------------------------------
namespace yh_render {

const int kMaxAttempt = 2;
const UINT kTickMs = 4000;
const int kFirstCheckTick = 3;   // 12 s after start
const int kBlankChecksNeeded = 3;  // 12 s, 16 s, 20 s
const int kLastTick = 45;        // stop watching after 3 minutes

struct State {
  int attempt = 0;        // which row of the table above is active
  int gpu = 0;            // 0 engine default, 1 low power, 2 high performance
  bool impeller = false;
  bool auto_recover = false;  // 0.5.7.1: opt-in (auto=1), see Init
  bool flip = true;           // yh_present: flip-model swap chain
  bool explicit_mode = false;
  HWND top = nullptr;
  UINT_PTR timer = 0;
  int tick = 0;
  int blank_checks = 0;
  int blank_count = 0;    // persisted: how many launches ended blank
  bool done = false;
};

State g;

std::wstring Dir() {
  wchar_t buf[MAX_PATH] = {0};
  DWORD n = ::GetEnvironmentVariableW(L"APPDATA", buf, MAX_PATH);
  if (n == 0 || n >= MAX_PATH) return std::wstring();
  std::wstring dir(buf);
  dir += L"\\YomiHub";
  ::CreateDirectoryW(dir.c_str(), nullptr);
  return dir;
}

std::string ReadSmallFile(const std::wstring& path) {
  std::string out;
  if (path.empty()) return out;
  HANDLE h = ::CreateFileW(path.c_str(), GENERIC_READ,
                           FILE_SHARE_READ | FILE_SHARE_WRITE, nullptr,
                           OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, nullptr);
  if (h == INVALID_HANDLE_VALUE) return out;
  char buf[4096];
  DWORD got = 0;
  if (::ReadFile(h, buf, sizeof(buf), &got, nullptr) && got > 0) {
    out.assign(buf, got);
  }
  ::CloseHandle(h);
  return out;
}

// Value of "key=" in a small "key=value" text (one pair per line).
std::string Value(const std::string& text, const char* key) {
  const std::string k = std::string(key) + "=";
  size_t pos = 0;
  while (pos < text.size()) {
    size_t eol = text.find('\n', pos);
    if (eol == std::string::npos) eol = text.size();
    std::string line = text.substr(pos, eol - pos);
    while (!line.empty() && (line.back() == '\r' || line.back() == ' ')) {
      line.pop_back();
    }
    if (line.compare(0, k.size(), k) == 0) return line.substr(k.size());
    pos = eol + 1;
  }
  return std::string();
}

std::string Env(const wchar_t* name) {
  wchar_t buf[32] = {0};
  DWORD n = ::GetEnvironmentVariableW(name, buf, 32);
  std::string out;
  if (n == 0 || n >= 32) return out;
  for (DWORD i = 0; i < n; i++) out.push_back(static_cast<char>(buf[i] & 0x7f));
  return out;
}

void ApplyAttempt(int attempt) {
  g.attempt = attempt;
  if (attempt == 1) {
    g.gpu = 2;
    g.impeller = false;
  } else if (attempt == 2) {
    g.gpu = 1;
    g.impeller = true;
  } else {
    g.attempt = 0;
    g.gpu = 0;
    g.impeller = false;
  }
}

void WriteState(const char* result, unsigned color) {
  const std::wstring dir = Dir();
  if (dir.empty()) return;
  SYSTEMTIME t;
  ::GetLocalTime(&t);
  char buf[512];
  int n = std::snprintf(
      buf, sizeof(buf),
      "result=%s\r\nattempt=%d\r\ngpu=%s\r\nimpeller=%d\r\nauto=%d\r\n"
      "explicit=%d\r\nblank_count=%d\r\ncolor=%06X\r\n"
      "present=%s\r\nflip_swapchains=%ld\r\nflip_refused=%ld\r\n"
      "time=%04d-%02d-%02d %02d:%02d:%02d\r\n",
      result, g.attempt, g.gpu == 2 ? "dgpu" : (g.gpu == 1 ? "igpu" : "default"),
      g.impeller ? 1 : 0, g.auto_recover ? 1 : 0, g.explicit_mode ? 1 : 0,
      g.blank_count, color & 0xFFFFFFu,
      yh_present::g_installed ? "flip" : (g.flip ? "blt(flip unavailable)" : "blt"),
      static_cast<long>(yh_present::g_flip_created),
      static_cast<long>(yh_present::g_flip_refused), t.wYear, t.wMonth, t.wDay, t.wHour,
      t.wMinute, t.wSecond);
  if (n <= 0) return;
  if (n > static_cast<int>(sizeof(buf)) - 1) n = static_cast<int>(sizeof(buf)) - 1;
  const std::wstring path = dir + L"\\win_render_state.txt";
  HANDLE h = ::CreateFileW(path.c_str(), GENERIC_WRITE, FILE_SHARE_READ, nullptr,
                           CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, nullptr);
  if (h == INVALID_HANDLE_VALUE) return;
  DWORD wrote = 0;
  ::WriteFile(h, buf, static_cast<DWORD>(n), &wrote, nullptr);
  ::CloseHandle(h);
}

// Reads "--name=<number>" from the raw command line; -1 when absent.
long ArgNumber(const wchar_t* command_line, const wchar_t* name) {
  if (command_line == nullptr) return -1;
  const wchar_t* p = std::wcsstr(command_line, name);
  if (p == nullptr) return -1;
  p += std::wcslen(name);
  if (*p != L'=') return -1;
  return std::wcstol(p + 1, nullptr, 10);
}

// Decides the render mode for this launch. Call before creating the engine.
void Init(const wchar_t* command_line) {
  // A relaunch waits for the previous (blank) instance to disappear first.
  const long wait_pid = ArgNumber(command_line, L"--yh-wait-pid");
  if (wait_pid > 0) {
    HANDLE parent = ::OpenProcess(SYNCHRONIZE, FALSE, static_cast<DWORD>(wait_pid));
    if (parent != nullptr) {
      ::WaitForSingleObject(parent, 8000);
      ::CloseHandle(parent);
    }
  }

  const std::wstring dir = Dir();
  const std::string cfg =
      dir.empty() ? std::string() : ReadSmallFile(dir + L"\\win_render.ini");
  const std::string st =
      dir.empty() ? std::string() : ReadSmallFile(dir + L"\\win_render_state.txt");

  g.blank_count = std::atoi(Value(st, "blank_count").c_str());
  const std::string last_result = Value(st, "result");
  const int last_attempt = std::atoi(Value(st, "attempt").c_str());

  std::string mode = Value(cfg, "mode");
  const std::string env_gpu = Env(L"YOMIHUB_GPU");
  if (!env_gpu.empty()) mode = env_gpu;
  bool impeller = Value(cfg, "impeller") == "1";
  if (Env(L"YOMIHUB_IMPELLER") == "1") impeller = true;
  // 0.5.7.1 (R21): the relaunch chain only switches GPU / renderer, which was
  // measured NOT to cure the white window (the cause is the swap-chain model,
  // fixed by yh_present). It is therefore opt-in: auto=1 / YOMIHUB_RENDER_AUTO=1.
  g.auto_recover = (Value(cfg, "auto") == "1" || Env(L"YOMIHUB_RENDER_AUTO") == "1") &&
                   Env(L"YOMIHUB_RENDER_AUTO") != "0";
  {
    const std::string present = Value(cfg, "present");
    const std::string env_present = Env(L"YOMIHUB_PRESENT");
    g.flip = !(present == "blt" || env_present == "blt") || env_present == "flip";
  }

  if (mode == "igpu" || mode == "dgpu") {
    // The user chose: use exactly that, never relaunch on our own.
    g.explicit_mode = true;
    g.attempt = 0;
    g.gpu = mode == "dgpu" ? 2 : 1;
    g.impeller = impeller;
    return;
  }

  const long try_arg = ArgNumber(command_line, L"--yh-render-try");
  if (try_arg >= 0 && try_arg <= kMaxAttempt) {
    ApplyAttempt(static_cast<int>(try_arg));
  } else if (g.auto_recover && last_result == "ok" && last_attempt >= 1 &&
             last_attempt <= kMaxAttempt) {
    // A fallback mode drew last time: start with it directly.
    ApplyAttempt(last_attempt);
  } else {
    ApplyAttempt(0);
    if (last_result == "gave_up") g.auto_recover = false;  // no relaunch loop
  }
  if (impeller) {
    // Impeller asked for explicitly (setting / YOMIHUB_IMPELLER=1).
    g.impeller = true;
    g.explicit_mode = true;
  }
}

// 1 = the Flutter view shows one flat colour, 0 = it shows content,
// -1 = cannot tell now (window hidden or minimised).
// 0.5.7.1 (R21): reads the window's own composed image with
// PrintWindow(PW_RENDERFULLCONTENT) instead of copying the screen. The screen
// copy was fooled by anything drawn over the window (a translucent overlay
// made a white view look "not uniform", so "ok" was recorded for a white
// window on 15/11/2026) and needed the window to be in the foreground.
int CheckBlank(unsigned* color_out) {
  HWND top = g.top;
  if (!::IsWindow(top) || !::IsWindowVisible(top) || ::IsIconic(top)) return -1;
  HWND view = ::FindWindowExW(top, nullptr, L"FLUTTERVIEW", nullptr);
  if (view == nullptr) return -1;
  RECT wr;
  RECT vr;
  if (!::GetWindowRect(top, &wr) || !::GetWindowRect(view, &vr)) return -1;
  const int full_w = wr.right - wr.left;
  const int full_h = wr.bottom - wr.top;
  const int vx = vr.left - wr.left;
  const int vy = vr.top - wr.top;
  const int w = vr.right - vr.left;
  const int h = vr.bottom - vr.top;
  if (w < 200 || h < 200 || vx < 0 || vy < 0 || vx + w > full_w ||
      vy + h > full_h) {
    return -1;
  }

  HDC screen = ::GetDC(nullptr);
  if (screen == nullptr) return -1;
  int result = -1;
  HDC mem = ::CreateCompatibleDC(screen);
  BITMAPINFO bi;
  std::memset(&bi, 0, sizeof(bi));
  bi.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
  bi.bmiHeader.biWidth = full_w;
  bi.bmiHeader.biHeight = -full_h;  // top-down
  bi.bmiHeader.biPlanes = 1;
  bi.bmiHeader.biBitCount = 32;
  bi.bmiHeader.biCompression = BI_RGB;
  void* bits = nullptr;
  HBITMAP bmp = mem != nullptr
                    ? ::CreateDIBSection(screen, &bi, DIB_RGB_COLORS, &bits,
                                         nullptr, 0)
                    : nullptr;
  if (bmp != nullptr && bits != nullptr) {
    HGDIOBJ old = ::SelectObject(mem, bmp);
    if (::PrintWindow(top, mem, 0x00000002 /* PW_RENDERFULLCONTENT */)) {
      ::GdiFlush();
      const unsigned* px = static_cast<const unsigned*>(bits);
      const int kCols = 48;
      const int kRows = 32;
      bool uniform = true;
      unsigned first = 0;
      for (int r = 0; r < kRows && uniform; r++) {
        for (int c = 0; c < kCols; c++) {
          const int x = vx + (w * (2 * c + 1)) / (2 * kCols);
          const int y = vy + (h * (2 * r + 1)) / (2 * kRows);
          const unsigned v =
              px[static_cast<size_t>(y) * static_cast<size_t>(full_w) +
                 static_cast<size_t>(x)] & 0x00FFFFFFu;
          if (r == 0 && c == 0) {
            first = v;
          } else if (v != first) {
            uniform = false;
            break;
          }
        }
      }
      result = uniform ? 1 : 0;
      if (uniform && color_out != nullptr) *color_out = first;
    }
    ::SelectObject(mem, old);
  }
  if (bmp != nullptr) ::DeleteObject(bmp);
  if (mem != nullptr) ::DeleteDC(mem);
  ::ReleaseDC(nullptr, screen);
  return result;
}

bool Relaunch(int attempt) {
  wchar_t exe[MAX_PATH] = {0};
  DWORD n = ::GetModuleFileNameW(nullptr, exe, MAX_PATH);
  if (n == 0 || n >= MAX_PATH) return false;
  wchar_t cmd[MAX_PATH + 96] = {0};
  std::swprintf(cmd, MAX_PATH + 96, L"\"%ls\" --yh-render-try=%d --yh-wait-pid=%lu",
                exe, attempt, static_cast<unsigned long>(::GetCurrentProcessId()));
  STARTUPINFOW si;
  std::memset(&si, 0, sizeof(si));
  si.cb = sizeof(si);
  PROCESS_INFORMATION pi;
  std::memset(&pi, 0, sizeof(pi));
  if (!::CreateProcessW(exe, cmd, nullptr, nullptr, FALSE, 0, nullptr, nullptr,
                        &si, &pi)) {
    return false;
  }
  ::CloseHandle(pi.hThread);
  ::CloseHandle(pi.hProcess);
  return true;
}

void Stop() {
  g.done = true;
  if (g.timer != 0) {
    ::KillTimer(nullptr, g.timer);
    g.timer = 0;
  }
}

void CALLBACK OnTick(HWND, UINT, UINT_PTR, DWORD) {
  if (g.done) return;
  g.tick++;
  if (g.tick < kFirstCheckTick) return;
  unsigned color = 0;
  const int blank = CheckBlank(&color);
  if (blank == 0) {
    // The view draws: remember the mode that works.
    WriteState("ok", 0);
    Stop();
    return;
  }
  if (blank < 0) {
    if (g.tick >= kLastTick) {
      WriteState("unknown", 0);
      Stop();
    }
    return;
  }
  g.blank_checks++;
  if (g.blank_checks < kBlankChecksNeeded) return;

  // Three flat-colour checks in a row (>= 8 s apart in total).
  Stop();
  g.blank_count++;
  const bool can_retry =
      g.auto_recover && !g.explicit_mode && g.attempt < kMaxAttempt;
  if (can_retry) {
    WriteState("blank", color);
    if (Relaunch(g.attempt + 1)) {
      // Leave without tearing the engine down: closing a blank window crashes
      // inside flutter_windows.dll (Event Log, 0.4.4 / 0.5.3 / 0.5.6.1).
      ::TerminateProcess(::GetCurrentProcess(), 0);
    }
    return;
  }
  if (g.auto_recover && !g.explicit_mode) {
    WriteState("gave_up", color);
    ::MessageBoxW(g.top, L"YomiHub kh\u00F4ng v\u1EBD \u0111\u01B0\u1EE3c giao di\u1EC7n (c\u1EEDa s\u1ED5 ch\u1EC9 m\u1ED9t m\u00E0u) d\u00F9 \u0111\u00E3 t\u1EF1 th\u1EED l\u1EA1i v\u1EDBi c\u00E1c ch\u1EBF \u0111\u1ED9 k\u1EBFt xu\u1EA5t kh\u00E1c.\n\nH\u00E3y th\u1EED:\n1. C\u1EADp nh\u1EADt driver \u0111\u1ED3 ho\u1EA1 (Intel / AMD / NVIDIA) l\u00EAn b\u1EA3n m\u1EDBi nh\u1EA5t c\u1EE7a h\u00E3ng.\n2. T\u1EAFt c\u00E1c ph\u1EA7n m\u1EC1m ph\u1EE7 m\u00E0n h\u00ECnh (overlay) r\u1ED3i m\u1EDF l\u1EA1i YomiHub.\n3. \u0110\u1EB7t bi\u1EBFn m\u00F4i tr\u01B0\u1EDDng YOMIHUB_GPU=dgpu ho\u1EB7c igpu, ho\u1EB7c YOMIHUB_IMPELLER=1.\n\nNh\u1EADt k\u00FD: %APPDATA%\\YomiHub\\win_render_state.txt", L"YomiHub \u2013 l\u1ED7i hi\u1EC3n th\u1ECB", MB_OK | MB_ICONWARNING);
  } else {
    WriteState("blank", color);
  }
}

void Watch(HWND top) {
  g.top = top;
  WriteState("pending", 0);
  g.timer = ::SetTimer(nullptr, 0, kTickMs, OnTick);
}

}  // namespace yh_render

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Replace "example" with the generated title found as parameter of `window.Create` in this file.
  // You may ignore the result if you need to create another window.
  // YomiHub 0.5.7 (R21): pick the render mode; a relaunch waits here for the
  // previous instance to exit, so the single-instance check below still holds.
  yh_render::Init(command_line);
  // YomiHub 0.5.7.1 (R21): flip-model swap chain - the actual white-window fix.
  if (yh_render::g.flip) yh_present::Install();

  if (SendAppLinkToInstance(L"YomiHub")) {
    return EXIT_SUCCESS;
  }

  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  // YomiHub 0.4.4: Flutter 3.47 renders with Impeller (OpenGLES via ANGLE) on
  // Windows by default. On the owner's laptop (Intel Iris Xe driver
  // 27.20.100.9664 + GTX 1650) the window then stayed white forever while
  // the app kept running (0.4.2/0.4.3/0.4.4, 29/10/2026) and the engine
  // crashed in flutter_windows.dll on close. Use the Skia renderer, which
  // is the long-standing default; YOMIHUB_IMPELLER=1 switches Impeller on.
  {
    wchar_t buf[8] = {0};
    const bool want_impeller =
        (::GetEnvironmentVariableW(L"YOMIHUB_IMPELLER", buf, 8) > 0 && buf[0] == L'1') ||
        yh_render::g.impeller;
    project.set_impeller_switch(want_impeller ? flutter::ImpellerSwitch::Enabled
                                              : flutter::ImpellerSwitch::Disabled);
    // YomiHub 0.5.7 (R21): GPU chosen per launch (see yh_render above).
    if (yh_render::g.gpu == 2) {
      project.set_gpu_preference(flutter::GpuPreference::HighPerformancePreference);
    } else if (yh_render::g.gpu == 1) {
      project.set_gpu_preference(flutter::GpuPreference::LowPowerPreference);
    }
  }

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  // The runner's own "--yh-..." switches are not for Dart.
  {
    std::vector<std::string> kept;
    for (const std::string& arg : command_line_arguments) {
      if (arg.compare(0, 5, "--yh-") != 0) kept.push_back(arg);
    }
    command_line_arguments.swap(kept);
  }

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"YomiHub", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);
  yh_render::Watch(window.GetHandle());

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}