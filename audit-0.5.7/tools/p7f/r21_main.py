import io,sys
P='overlay/windows/runner/main.cpp'
s=open(P,encoding='utf-8',newline='').read()
crlf='\r\n' in s
s=s.replace('\r\n','\n')
if 'yh_render' in s: sys.exit('already patched')
def esc(t):
    return ''.join(c if ord(c)<128 and c not in '"\\' else ('\\n' if c=='\n' else '\\u%04X'%ord(c)) for c in t)
MSG=esc("YomiHub không vẽ được giao diện (cửa sổ chỉ một màu) dù đã tự thử lại với các chế độ kết xuất khác.\n\nHãy thử:\n1. Cập nhật driver đồ hoạ (Intel / AMD / NVIDIA) lên bản mới nhất của hãng.\n2. Tắt các phần mềm phủ màn hình (overlay) rồi mở lại YomiHub.\n3. Đặt biến môi trường YOMIHUB_GPU=dgpu hoặc igpu, hoặc YOMIHUB_IMPELLER=1.\n\nNhật ký: %APPDATA%\\YomiHub\\win_render_state.txt")
TITLE=esc("YomiHub – lỗi hiển thị")
INC='''#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <cwchar>
#include <string>
#include <vector>
'''
a='''#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>
'''
assert a in s; s=s.replace(a,INC,1)
HELP=r'''
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
  bool auto_recover = true;
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
      "time=%04d-%02d-%02d %02d:%02d:%02d\r\n",
      result, g.attempt, g.gpu == 2 ? "dgpu" : (g.gpu == 1 ? "igpu" : "default"),
      g.impeller ? 1 : 0, g.auto_recover ? 1 : 0, g.explicit_mode ? 1 : 0,
      g.blank_count, color & 0xFFFFFFu, t.wYear, t.wMonth, t.wDay, t.wHour,
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
  g.auto_recover = Value(cfg, "auto") != "0" && Env(L"YOMIHUB_RENDER_AUTO") != "0";

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
  } else if (last_result == "ok" && last_attempt >= 1 &&
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
// -1 = cannot tell now (window hidden, minimised, covered or in background).
int CheckBlank(unsigned* color_out) {
  HWND top = g.top;
  if (!::IsWindow(top) || !::IsWindowVisible(top) || ::IsIconic(top)) return -1;
  if (::GetForegroundWindow() != top) return -1;
  HWND view = ::FindWindowExW(top, nullptr, L"FLUTTERVIEW", nullptr);
  if (view == nullptr) return -1;
  RECT rc;
  if (!::GetClientRect(view, &rc)) return -1;
  const int w = rc.right - rc.left;
  const int h = rc.bottom - rc.top;
  if (w < 200 || h < 200) return -1;
  POINT origin = {0, 0};
  if (!::ClientToScreen(view, &origin)) return -1;

  HDC screen = ::GetDC(nullptr);
  if (screen == nullptr) return -1;
  int result = -1;
  HDC mem = ::CreateCompatibleDC(screen);
  BITMAPINFO bi;
  std::memset(&bi, 0, sizeof(bi));
  bi.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
  bi.bmiHeader.biWidth = w;
  bi.bmiHeader.biHeight = -h;  // top-down
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
    if (::BitBlt(mem, 0, 0, w, h, screen, origin.x, origin.y, SRCCOPY)) {
      ::GdiFlush();
      const unsigned* px = static_cast<const unsigned*>(bits);
      const int kCols = 48;
      const int kRows = 32;
      int valid = 0;
      bool uniform = true;
      unsigned first = 0;
      for (int r = 0; r < kRows && uniform; r++) {
        for (int c = 0; c < kCols; c++) {
          const int x = (w * (2 * c + 1)) / (2 * kCols);
          const int y = (h * (2 * r + 1)) / (2 * kRows);
          POINT pt = {origin.x + x, origin.y + y};
          HWND at = ::WindowFromPoint(pt);
          if (at == nullptr) continue;  // off-screen
          if (at != view && at != top && !::IsChild(top, at)) continue;  // covered
          const unsigned v = px[static_cast<size_t>(y) * static_cast<size_t>(w) +
                                static_cast<size_t>(x)] & 0x00FFFFFFu;
          if (valid == 0) {
            first = v;
          } else if (v != first) {
            uniform = false;
            break;
          }
          valid++;
        }
      }
      if (!uniform) {
        result = 0;
      } else if (valid >= (kCols * kRows) / 2) {
        result = 1;
        if (color_out != nullptr) *color_out = first;
      }
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
    ::MessageBoxW(g.top, L"@@MSG@@", L"@@TITLE@@", MB_OK | MB_ICONWARNING);
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
'''.replace('@@MSG@@',MSG).replace('@@TITLE@@',TITLE)
a='int APIENTRY wWinMain('
assert s.count(a)==1; s=s.replace(a,HELP.lstrip('\n')+'\n'+a,1)

a='''  if (SendAppLinkToInstance(L"YomiHub")) {
    return EXIT_SUCCESS;
  }
'''
b='''  // YomiHub 0.5.7 (R21): pick the render mode; a relaunch waits here for the
  // previous instance to exit, so the single-instance check below still holds.
  yh_render::Init(command_line);

  if (SendAppLinkToInstance(L"YomiHub")) {
    return EXIT_SUCCESS;
  }
'''
assert s.count(a)==1; s=s.replace(a,b,1)

a='''    const bool want_impeller =
        ::GetEnvironmentVariableW(L"YOMIHUB_IMPELLER", buf, 8) > 0 && buf[0] == L'1';
    project.set_impeller_switch(want_impeller ? flutter::ImpellerSwitch::Enabled
                                              : flutter::ImpellerSwitch::Disabled);
  }
'''
b='''    const bool want_impeller =
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
'''
assert s.count(a)==1; s=s.replace(a,b,1)

a='''  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));
'''
b='''  // The runner's own "--yh-..." switches are not for Dart.
  {
    std::vector<std::string> kept;
    for (const std::string& arg : command_line_arguments) {
      if (arg.compare(0, 5, "--yh-") != 0) kept.push_back(arg);
    }
    command_line_arguments.swap(kept);
  }

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));
'''
assert s.count(a)==1; s=s.replace(a,b,1)

a='''  window.SetQuitOnClose(true);
'''
b='''  window.SetQuitOnClose(true);
  yh_render::Watch(window.GetHandle());
'''
assert s.count(a)==1; s=s.replace(a,b,1)
if crlf: s=s.replace('\n','\r\n')
open(P,'w',encoding='utf-8',newline='').write(s)
assert all(ord(c)<128 for c in s), 'non-ascii'
print('ok',len(s))
