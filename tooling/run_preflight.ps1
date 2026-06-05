# Load registry env changes
. "$PSScriptRoot\setup_env.ps1"

# Load variables into current session
$gstreamerRoot = "$env:LOCALAPPDATA\Programs\gstreamer\1.0\msvc_x86_64"
$wingetLinks = "$env:LOCALAPPDATA\Microsoft\WinGet\Links"

$env:GSTREAMER_1_0_ROOT_MSVC_X86_64 = $gstreamerRoot
$env:GSTREAMER_ROOT_X86_64 = $gstreamerRoot
$env:PKG_CONFIG_PATH = "$gstreamerRoot\lib\pkgconfig"
$env:PATH = "$env:PATH;$gstreamerRoot\bin;$wingetLinks"

# Run preflight
powershell -NoProfile -ExecutionPolicy Bypass -File "$PSScriptRoot\gstreamer_windows_preflight.ps1" -Json
