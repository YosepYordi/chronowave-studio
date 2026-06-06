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
    if (($currentPath -split ';') -contains $Path) {
        return $false
    }

    [Environment]::SetEnvironmentVariable("PATH", "$currentPath;$Path", "User")
    return $true
}

$gstreamerRoot = Get-FirstExistingPath -Candidates @(
    "C:\gstreamer\1.0\msvc_x86_64",
    "C:\Program Files\gstreamer\1.0\msvc_x86_64",
    "$env:LOCALAPPDATA\Programs\gstreamer\1.0\msvc_x86_64",
    "$env:LOCALAPPDATA\Programs\gstreamer",
    "$env:LOCALAPPDATA\gstreamer\1.0\msvc_x86_64",
    "$env:LOCALAPPDATA\gstreamer"
)
$pkgConfigBin = Get-FirstExistingPath -Candidates @(
    "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\bloodrock.pkg-config-lite_Microsoft.Winget.Source_8wekyb3d8bbwe\pkg-config-lite-0.28-1\bin",
    "$env:LOCALAPPDATA\Microsoft\WinGet\Links"
)

Write-Host "Configuring GStreamer User Environment Variables..."
if ($gstreamerRoot) {
    [Environment]::SetEnvironmentVariable("GSTREAMER_1_0_ROOT_MSVC_X86_64", $gstreamerRoot, "User")
    [Environment]::SetEnvironmentVariable("GSTREAMER_ROOT_X86_64", $gstreamerRoot, "User")

    $pkgconfigPath = Join-Path $gstreamerRoot "lib\pkgconfig"
    if (Test-Path -LiteralPath $pkgconfigPath) {
        [Environment]::SetEnvironmentVariable("PKG_CONFIG_PATH", $pkgconfigPath, "User")
    }

    if (Add-UserPathIfExists -Path (Join-Path $gstreamerRoot "bin")) {
        Write-Host "Added GStreamer bin directory to User PATH."
    }
} else {
    Write-Host "GStreamer root not found; leaving GSTREAMER_* variables unchanged."
}

if ($pkgConfigBin) {
    if (Add-UserPathIfExists -Path $pkgConfigBin) {
        Write-Host "Added pkg-config-lite bin directory to User PATH."
    }
} else {
    Write-Host "pkg-config-lite bin directory not found."
}
