# Setup GStreamer environment on Windows for Phase 5A
$ErrorActionPreference = "Stop"

# 1. Install pkg-config-lite
Write-Host "Installing pkg-config-lite..."
winget install --id bloodrock.pkg-config-lite --accept-source-agreements --accept-package-agreements --silent

# 2. Install GStreamer Runtime
Write-Host "Installing GStreamer Runtime..."
winget install --id gstreamerproject.gstreamer --accept-source-agreements --accept-package-agreements --silent

# 3. Download GStreamer Devel
$develUrl = "https://gstreamer.freedesktop.org/data/pkg/windows/1.28.3/msvc/gstreamer-1.0-devel-msvc-x86_64-1.28.3.exe"
$tempDir = Join-Path $PSScriptRoot ".gstreamer_temp"
if (-not (Test-Path $tempDir)) {
    New-Item -ItemType Directory -Path $tempDir
}
$installerPath = Join-Path $tempDir "gstreamer-devel-installer.exe"
Write-Host "Downloading GStreamer Devel Installer from $develUrl to $installerPath ..."
Invoke-WebRequest -Uri $develUrl -OutFile $installerPath

# 4. Install GStreamer Devel
Write-Host "Running GStreamer Devel Installer silently..."
$process = Start-Process -FilePath $installerPath -ArgumentList "/VERYSILENT", "/SUPPRESSMSGBOXES", "/NORESTART", "/SP-" -Wait -PassThru
if ($process.ExitCode -ne 0) {
    throw "Devel installer failed with exit code $($process.ExitCode)"
}

# Remove installer temp folder
if (Test-Path $tempDir) {
    Remove-Item -Recurse -Force $tempDir
}

# 5. Locate and Setup environment variables
$root = "C:\gstreamer\1.0\msvc_x86_64"
if (-not (Test-Path $root)) {
    $root = "C:\Program Files\gstreamer\1.0\msvc_x86_64"
}
if (-not (Test-Path $root)) {
    $localRoot = Join-Path $env:LOCALAPPDATA "gstreamer\1.0\msvc_x86_64"
    if (Test-Path $localRoot) {
        $root = $localRoot
    } else {
        throw "GStreamer installation root not found at C:\gstreamer or Program Files or LocalAppData!"
    }
}

Write-Host "GStreamer found at: $root"

# Set User environment variables
Write-Host "Setting environment variables..."
[Environment]::SetEnvironmentVariable("GSTREAMER_1_0_ROOT_MSVC_X86_64", $root, "User")
[Environment]::SetEnvironmentVariable("GSTREAMER_ROOT_X86_64", $root, "User")

$binPath = Join-Path $root "bin"
$currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
if ($currentPath -split ';' -notcontains $binPath) {
    $newPath = "$currentPath;$binPath"
    [Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
    Write-Host "Added $binPath to User PATH."
}

$pkgconfigPath = Join-Path $root "lib\pkgconfig"
[Environment]::SetEnvironmentVariable("PKG_CONFIG_PATH", $pkgconfigPath, "User")
Write-Host "Set PKG_CONFIG_PATH to $pkgconfigPath"

Write-Host "Setup finished successfully. Please restart your terminal/IDE or reload environment variables."
