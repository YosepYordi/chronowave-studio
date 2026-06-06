# Load registry env changes
. "$PSScriptRoot\setup_env.ps1"

$gstreamerRoot = [Environment]::GetEnvironmentVariable("GSTREAMER_1_0_ROOT_MSVC_X86_64", "User")
$pkgConfigPath = [Environment]::GetEnvironmentVariable("PKG_CONFIG_PATH", "User")
$userPath = [Environment]::GetEnvironmentVariable("PATH", "User")

if ($gstreamerRoot -and (Test-Path -LiteralPath $gstreamerRoot)) {
    $env:GSTREAMER_1_0_ROOT_MSVC_X86_64 = $gstreamerRoot
    $env:GSTREAMER_ROOT_X86_64 = $gstreamerRoot
}
if ($pkgConfigPath -and (Test-Path -LiteralPath $pkgConfigPath)) {
    $env:PKG_CONFIG_PATH = $pkgConfigPath
}
if ($userPath) {
    $env:PATH = "$env:PATH;$userPath"
}

# Run preflight
powershell -NoProfile -ExecutionPolicy Bypass -File "$PSScriptRoot\gstreamer_windows_preflight.ps1" -Json
