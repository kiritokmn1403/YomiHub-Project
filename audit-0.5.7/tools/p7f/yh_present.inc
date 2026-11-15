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
