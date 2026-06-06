# Setup GStreamer environment on Windows for Phase 5A.
[CmdletBinding()]
param(
    [string]$Version = "1.28.3",
    [string]$InstallRoot = (Join-Path $env:LOCALAPPDATA "Programs\gstreamer\1.0\msvc_x86_64"),
    [string]$LogDirectory = ([IO.Path]::GetTempPath()),
    [int]$RequiredFreeGB = 6
)

$ErrorActionPreference = "Stop"

function Get-FirstExistingPath {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Candidates
    )

    foreach ($candidate in $Candidates) {
        if ($candidate -and (Test-Path -LiteralPath $candidate)) {
            return $candidate
        }
    }

    return $null
}

function Add-UserPathIfExists {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return $false
    }

    $currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
    $pathEntries = @()
    if ($currentPath) {
        $pathEntries = @($currentPath -split ';')
    }

    if ($pathEntries -contains $Path) {
        return $false
    }

    $newPath = if ($currentPath) { "$currentPath;$Path" } else { $Path }
    [Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
    return $true
}

function Assert-PathDriveHasFreeSpace {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$Purpose
    )

    $root = [IO.Path]::GetPathRoot([IO.Path]::GetFullPath($Path))
    $driveName = $root.TrimEnd('\').TrimEnd(':')
    $drive = Get-PSDrive -Name $driveName -ErrorAction Stop
    $freeGb = [math]::Round($drive.Free / 1GB, 2)

    if ($freeGb -lt $RequiredFreeGB) {
        throw "$Purpose requires at least $RequiredFreeGB GB free on $root, but only $freeGb GB are available."
    }
}

function Install-WinGetPackage {
    param(
        [Parameter(Mandatory = $true)]
        [string]$PackageId,

        [string]$ProvidesCommand
    )

    if ($ProvidesCommand -and (Get-Command $ProvidesCommand -ErrorAction SilentlyContinue)) {
        Write-Host "$ProvidesCommand already available; skipping winget package $PackageId."
        return
    }

    $winget = Get-Command winget -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($null -eq $winget) {
        Write-Host "winget not found; skipping $PackageId."
        return
    }

    Write-Host "Installing or confirming $PackageId..."
    & $winget.Source install --id $PackageId --accept-source-agreements --accept-package-agreements --silent
    if ($LASTEXITCODE -ne 0) {
        Write-Host "winget returned exit code $LASTEXITCODE for $PackageId; continuing with direct GStreamer installers when possible."
    }
}

function Test-RemoteFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Url
    )

    try {
        $response = Invoke-WebRequest -Method Head -Uri $Url -TimeoutSec 30
        return $response.StatusCode -ge 200 -and $response.StatusCode -lt 400
    }
    catch {
        return $false
    }
}

function Invoke-SilentInstaller {
    param(
        [Parameter(Mandatory = $true)]
        [string]$InstallerPath,

        [Parameter(Mandatory = $true)]
        [string]$DisplayName
    )

    if (-not (Test-Path -LiteralPath $LogDirectory)) {
        New-Item -ItemType Directory -Path $LogDirectory | Out-Null
    }

    $logName = "chronowave-$($DisplayName.ToLowerInvariant() -replace '[^a-z0-9]+', '-')-install.log"
    $logPath = Join-Path $LogDirectory $logName

    Write-Host "Running $DisplayName installer silently..."
    if ([IO.Path]::GetExtension($InstallerPath) -ieq ".msi") {
        $arguments = @("/i", $InstallerPath, "/qn", "/norestart", "/L*v", $logPath)
        $process = Start-Process -FilePath "msiexec.exe" -ArgumentList $arguments -Wait -PassThru -WindowStyle Hidden
    } else {
        $quotedInstallRoot = "/DIR=""$InstallRoot"""
        $quotedLogPath = "/LOG=""$logPath"""
        $arguments = @(
            "/VERYSILENT",
            "/SUPPRESSMSGBOXES",
            "/NORESTART",
            "/SP-",
            "/CURRENTUSER",
            $quotedInstallRoot,
            $quotedLogPath
        )
        $process = Start-Process -FilePath $InstallerPath -ArgumentList $arguments -Wait -PassThru -WindowStyle Hidden
    }

    if ($process.ExitCode -ne 0) {
        throw "$DisplayName installer failed with exit code $($process.ExitCode). See log: $logPath"
    }
}

function Download-Installer {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Url,

        [Parameter(Mandatory = $true)]
        [string]$Destination
    )

    Write-Host "Downloading $Url..."
    $curl = Get-Command curl.exe -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($null -ne $curl) {
        & $curl.Source --fail --location --retry 3 --retry-delay 5 --output $Destination $Url
        if ($LASTEXITCODE -ne 0) {
            throw "curl failed to download $Url with exit code $LASTEXITCODE."
        }
    } else {
        Invoke-WebRequest -Uri $Url -OutFile $Destination
    }

    $expectedHash = Get-RemoteSha256 -Url $Url
    if ($expectedHash) {
        $actualHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $Destination).Hash.ToLowerInvariant()
        if ($actualHash -ne $expectedHash) {
            throw "Installer hash mismatch for $Url. Expected $expectedHash but got $actualHash."
        }

        Write-Host "Verified SHA256 for $(Split-Path -Leaf $Destination)."
    } else {
        Write-Host "No SHA256 sidecar found for $Url; continuing without hash verification."
    }
}

function Get-RemoteSha256 {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Url
    )

    try {
        $response = Invoke-WebRequest -Uri "$Url.sha256sum" -TimeoutSec 60
        $content = if ($response.Content -is [byte[]]) {
            [Text.Encoding]::ASCII.GetString($response.Content)
        } else {
            [string]$response.Content
        }

        if ($content -match '([a-fA-F0-9]{64})') {
            return $matches[1].ToLowerInvariant()
        }
    }
    catch {
        return $null
    }

    return $null
}

$existingRoot = Get-FirstExistingPath -Candidates @(
    "C:\gstreamer\1.0\msvc_x86_64",
    "C:\Program Files\gstreamer\1.0\msvc_x86_64",
    $InstallRoot,
    "D:\ChronoWaveDeps\gstreamer\1.0\msvc_x86_64",
    "E:\ChronoWaveDeps\gstreamer\1.0\msvc_x86_64",
    "$env:LOCALAPPDATA\Programs\gstreamer",
    "$env:LOCALAPPDATA\gstreamer\1.0\msvc_x86_64",
    "$env:LOCALAPPDATA\gstreamer"
)

if (-not $existingRoot) {
    Assert-PathDriveHasFreeSpace -Path $InstallRoot -Purpose "GStreamer installation"
    Assert-PathDriveHasFreeSpace -Path ([IO.Path]::GetTempPath()) -Purpose "GStreamer installer download"

    Install-WinGetPackage -PackageId "bloodrock.pkg-config-lite" -ProvidesCommand "pkg-config"

    $baseUrl = "https://gstreamer.freedesktop.org/data/pkg/windows/$Version/msvc"
    $runtimeUrl = "$baseUrl/gstreamer-1.0-msvc-x86_64-$Version.exe"
    $develUrlCandidates = @(
        "$baseUrl/gstreamer-1.0-devel-msvc-x86_64-$Version.exe",
        "$baseUrl/gstreamer-1.0-devel-msvc-x86_64-$Version.msi"
    )
    $develUrl = $develUrlCandidates | Where-Object { Test-RemoteFile -Url $_ } | Select-Object -First 1
    $tempDir = Join-Path ([IO.Path]::GetTempPath()) ("chronowave-gstreamer-" + [guid]::NewGuid().ToString("N"))

    New-Item -ItemType Directory -Path $tempDir | Out-Null
    try {
        $runtimeInstaller = Join-Path $tempDir "gstreamer-runtime-installer.exe"
        $develInstaller = $null

        Download-Installer -Url $runtimeUrl -Destination $runtimeInstaller
        Invoke-SilentInstaller -InstallerPath $runtimeInstaller -DisplayName "GStreamer runtime"

        if ($develUrl) {
            $develExtension = [IO.Path]::GetExtension($develUrl)
            $develInstaller = Join-Path $tempDir "gstreamer-devel-installer$develExtension"
            Download-Installer -Url $develUrl -Destination $develInstaller
            Invoke-SilentInstaller -InstallerPath $develInstaller -DisplayName "GStreamer development"
        } else {
            Write-Host "No separate GStreamer development installer was published for $Version in $baseUrl."
            Write-Host "The setup will continue and then verify whether the installed package contains lib\pkgconfig."
        }
    }
    finally {
        if (Test-Path -LiteralPath $tempDir) {
            Remove-Item -Recurse -Force -LiteralPath $tempDir
        }
    }
}

$root = Get-FirstExistingPath -Candidates @(
    $InstallRoot,
    "D:\ChronoWaveDeps\gstreamer\1.0\msvc_x86_64",
    "E:\ChronoWaveDeps\gstreamer\1.0\msvc_x86_64",
    "C:\gstreamer\1.0\msvc_x86_64",
    "C:\Program Files\gstreamer\1.0\msvc_x86_64",
    "$env:LOCALAPPDATA\Programs\gstreamer",
    "$env:LOCALAPPDATA\gstreamer\1.0\msvc_x86_64",
    "$env:LOCALAPPDATA\gstreamer"
)

if (-not $root) {
    throw "GStreamer installation root not found after setup."
}

Write-Host "GStreamer found at: $root"

[Environment]::SetEnvironmentVariable("GSTREAMER_1_0_ROOT_MSVC_X86_64", $root, "User")
[Environment]::SetEnvironmentVariable("GSTREAMER_ROOT_X86_64", $root, "User")

$binPath = Join-Path $root "bin"
if (Add-UserPathIfExists -Path $binPath) {
    Write-Host "Added $binPath to User PATH."
}

$pkgconfigPath = Join-Path $root "lib\pkgconfig"
if (Test-Path -LiteralPath $pkgconfigPath) {
    [Environment]::SetEnvironmentVariable("PKG_CONFIG_PATH", $pkgconfigPath, "User")
    Write-Host "Set PKG_CONFIG_PATH to $pkgconfigPath"
} else {
    throw "GStreamer pkgconfig directory was not found at $pkgconfigPath. Install the development files before validating Rust bindings."
}

Write-Host "Setup finished successfully. Restart the terminal/IDE or run tooling\run_preflight.ps1 to reload environment variables."
