# Step 1: download source + all build tools (no admin needed). Everything goes to D:\yh
. "$PSScriptRoot\common.ps1"
# stop any earlier run of this script
Get-CimInstance Win32_Process | Where-Object { ($_.CommandLine -match 'setup_tools\.ps1' -and $_.ProcessId -ne $PID) -or $_.Name -eq 'curl.exe' } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
Start-Sleep 2
Start-Transcript ("$LOGS\setup_log_{0}.txt" -f (Get-Date -Format HHmmss)) -Force | Out-Null
try {
  Remove-Item "$LOGS\status.txt" -ErrorAction SilentlyContinue
  $d = Get-PSDrive D; Say ("D: free = {0:N1} GB" -f ($d.Free/1GB))
  Say ("RAM = {0:N1} GB, CPU = {1}" -f ((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory/1GB), $env:NUMBER_OF_PROCESSORS)

  # --- MinGit ---
  if (-not (Test-Path "$TOOLS\git\cmd\git.exe")) {
    $g = Gh-Api 'repos/git-for-windows/git/releases/latest'
    $a = $g.assets | Where-Object { $_.name -match '^MinGit-[\d\.]+-64-bit\.zip$' } | Select-Object -First 1
    Remove-Item "$YH\mingit.zip" -ErrorAction SilentlyContinue
    Say "Downloading $($a.name) ($([math]::Round($a.size/1MB)) MB)"
    Get-FileFast $a.browser_download_url "$YH\mingit.zip" 24
    New-Item -ItemType Directory -Force "$TOOLS\git" | Out-Null
    & tar.exe -xf "$YH\mingit.zip" -C "$TOOLS\git"
  }
  git config --global core.longpaths true
  Say "Git OK: $(git --version)"

  # --- Mangayomi source (latest release zip) ---
  $src = "$KIT\src\mangayomi"
  if (-not (Test-Path "$src\pubspec.yaml")) {
    $rel = Gh-Api 'repos/kodjodevf/mangayomi/releases/latest'
    Say "Mangayomi latest release: $($rel.tag_name)"
    if (-not (Test-Path "$YH\mangayomi.zip") -or (Get-Item "$YH\mangayomi.zip").Length -lt 100MB) {
      Get-File "https://codeload.github.com/kodjodevf/mangayomi/zip/refs/tags/$($rel.tag_name)" "$YH\mangayomi.zip"
    }
    Expand-To "$YH\mangayomi.zip" $src
    Set-Content "$KIT\src\BASE_VERSION.txt" $rel.tag_name
  }
  Say "Source OK"

  # --- JDK 17 ---
  if (-not (Test-Path "$TOOLS\jdk\bin\java.exe")) {
    Get-File 'https://aka.ms/download-jdk/microsoft-jdk-17-windows-x64.zip' "$YH\jdk.zip"
    Expand-To "$YH\jdk.zip" "$TOOLS\jdk"
  }
  Say "JDK OK"

  # --- Android SDK ---
  if (-not (Test-Path "$TOOLS\android-sdk\cmdline-tools\latest\bin\sdkmanager.bat")) {
    Get-File 'https://dl.google.com/android/repository/commandlinetools-win-13114758_latest.zip' "$YH\cmdtools.zip"
    New-Item -ItemType Directory -Force "$TOOLS\android-sdk\cmdline-tools" | Out-Null
    Expand-To "$YH\cmdtools.zip" "$TOOLS\android-sdk\cmdline-tools\latest"
  }
  $yes = ("y`n" * 30)
  $yes | & sdkmanager.bat --licenses | Out-Null
  & sdkmanager.bat "platform-tools" "platforms;android-35" "platforms;android-36" "build-tools;35.0.0" "ndk;27.0.12077973" "cmake;3.22.1" | Out-Null
  Say "Android SDK OK"

  # --- Flutter (stable) ---
  if (-not (Test-Path "$TOOLS\flutter\bin\flutter.bat")) {
    $j = Invoke-RestMethod 'https://storage.googleapis.com/flutter_infra_release/releases/releases_windows.json'
    $h = $j.current_release.stable
    $r = $j.releases | Where-Object { $_.hash -eq $h } | Select-Object -First 1
    Say "Flutter $($r.version)"
    Get-File "$($j.base_url)/$($r.archive)" "$YH\flutter.zip"
    Expand-To "$YH\flutter.zip" "$TOOLS\flutter"
  }
  git config --global --add safe.directory '*'
  & flutter.bat config --no-analytics --android-sdk "$TOOLS\android-sdk" | Out-Null
  & flutter.bat --version | Out-File "$LOGS\flutter_version.txt"
  Say "Flutter OK"

  # --- Rust (GNU host = no Visual Studio needed) ---
  # static.rust-lang.org is very slow per connection here, so build a local
  # file:// mirror with segmented downloads and let rustup install from it.
  if (-not (Test-Path "$TOOLS\cargo\bin\rustup.exe")) {
    $mir = "$YH\rustmirror"; New-Item -ItemType Directory -Force "$mir\dist" | Out-Null
    $root = 'https://static.rust-lang.org'
    if (-not (Test-Path "$YH\rustup-init.ok")) {
      Remove-Item "$YH\rustup-init.exe" -ErrorAction SilentlyContinue
      Get-FileFast "$root/rustup/dist/x86_64-pc-windows-gnu/rustup-init.exe" "$YH\rustup-init.exe" 24
      Set-Content "$YH\rustup-init.ok" ok
    }
    Get-File "$root/dist/channel-rust-stable.toml" "$mir\dist\channel-rust-stable.toml"
    Get-File "$root/dist/channel-rust-stable.toml.sha256" "$mir\dist\channel-rust-stable.toml.sha256"
    $toml = Get-Content "$mir\dist\channel-rust-stable.toml" -Raw
    $want = @(
      @('rustc','x86_64-pc-windows-gnu'), @('cargo','x86_64-pc-windows-gnu'),
      @('rust-std','x86_64-pc-windows-gnu'), @('rust-mingw','x86_64-pc-windows-gnu'),
      @('rust-std','aarch64-linux-android'), @('rust-std','armv7-linux-androideabi'),
      @('rust-std','x86_64-linux-android'))
    foreach ($w in $want) {
      $sec = [regex]::Escape("[pkg.$($w[0]).target.$($w[1])]")
      $m = [regex]::Match($toml, "(?s)$sec.*?xz_url = `"([^`"]+)`"")
      if (-not $m.Success) { throw "rust component not found: $($w -join ' ')" }
      $u = $m.Groups[1].Value
      $dst = $mir + ($u.Substring($root.Length) -replace '/','\')
      if (-not (Test-Path $dst)) {
        New-Item -ItemType Directory -Force (Split-Path -Parent $dst) | Out-Null
        Say "  rust: $($w[0]) $($w[1])"
        Get-FileFast $u $dst 64
      }
    }
    $env:RUSTUP_DIST_SERVER = 'file:///' + ($mir -replace '\\','/')
    & "$YH\rustup-init.exe" -y --no-modify-path --profile minimal --default-host x86_64-pc-windows-gnu --default-toolchain stable
    if ($LASTEXITCODE -ne 0) { throw "rustup-init failed" }
    & rustup.exe target add aarch64-linux-android armv7-linux-androideabi x86_64-linux-android
    if ($LASTEXITCODE -ne 0) { throw "rustup target add failed" }
    Remove-Item Env:RUSTUP_DIST_SERVER
  }
  Say "Rust OK: $(rustc --version)"

  # --- MinGW-w64 (GNU dlltool/ld for the Rust windows-gnu host toolchain) ---
  if (-not (Test-Path "$TOOLS\mingw64\bin\dlltool.exe")) {
    $w = Gh-Api 'repos/brechtsanders/winlibs_mingw/releases/latest'
    $a = $w.assets | Where-Object { $_.name -match '^winlibs-x86_64-posix-seh-gcc-.*-mingw-w64ucrt-.*\.zip$' -and $_.name -notmatch 'llvm' } | Select-Object -First 1
    if (-not $a) { $a = $w.assets | Where-Object { $_.name -match '^winlibs-x86_64-.*\.zip$' } | Select-Object -First 1 }
    Say "Downloading $($a.name) ($([math]::Round($a.size/1MB)) MB)"
    Get-FileFast $a.browser_download_url "$YH\mingw.zip" 48
    Expand-To "$YH\mingw.zip" "$TOOLS\mingw64"
  }
  Say "MinGW OK: $(& "$TOOLS\mingw64\bin\dlltool.exe" --version | Select-Object -First 1)"

  # --- inventory of source for patching ---
  Get-ChildItem $src -Recurse -File -Include *.dart,*.gradle,*.kts,*.kt,*.xml,*.yaml,*.arb,*.toml,*.properties |
    Where-Object { $_.FullName -notmatch '\\(\.git|build|\.dart_tool)\\' } |
    ForEach-Object { "{0}`t{1}" -f $_.FullName.Substring($src.Length+1), $_.Length } | Out-File "$LOGS\source_files.txt" -Encoding utf8
  Say "SETUP DONE"
} catch {
  Say "ERROR: $($_.Exception.Message)"
  Say ($_.ScriptStackTrace)
} finally { Stop-Transcript | Out-Null }
