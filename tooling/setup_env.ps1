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

function Clear-ProcessPathIfMissing {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    $value = [Environment]::GetEnvironmentVariable($Name)
    if ($value -and -not (Test-Path -LiteralPath $value)) {
        [Environment]::SetEnvironmentVariable($Name, $null, "Process")
    }
}

function Remove-MissingProcessPathEntries {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    $value = [Environment]::GetEnvironmentVariable($Name)
    if (-not $value) {
        return
    }

    $existing = @($value -split [IO.Path]::PathSeparator | Where-Object {
        $_ -and (Test-Path -LiteralPath $_)
    })

    if ($existing.Count -eq 0) {
        [Environment]::SetEnvironmentVariable($Name, $null, "Process")
        return
    }

    [Environment]::SetEnvironmentVariable($Name, ($existing -join [IO.Path]::PathSeparator), "Process")
}

$gstreamerRoot = Get-FirstExistingPath -Candidates @(
    [Environment]::GetEnvironmentVariable("GSTREAMER_1_0_ROOT_MSVC_X86_64", "User"),
    [Environment]::GetEnvironmentVariable("GSTREAMER_ROOT_X86_64", "User"),
    "D:\ChronoWaveDeps\gstreamer\1.0\msvc_x86_64",
    "E:\ChronoWaveDeps\gstreamer\1.0\msvc_x86_64",
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
    $env:GSTREAMER_1_0_ROOT_MSVC_X86_64 = $gstreamerRoot
    $env:GSTREAMER_ROOT_X86_64 = $gstreamerRoot

    $pkgconfigPath = Join-Path $gstreamerRoot "lib\pkgconfig"
    if (Test-Path -LiteralPath $pkgconfigPath) {
        [Environment]::SetEnvironmentVariable("PKG_CONFIG_PATH", $pkgconfigPath, "User")
        $env:PKG_CONFIG_PATH = $pkgconfigPath
    }

    $gstreamerBin = Join-Path $gstreamerRoot "bin"
    if (Test-Path -LiteralPath $gstreamerBin) {
        $processPathEntries = @($env:PATH -split ';')
        if ($processPathEntries -notcontains $gstreamerBin) {
            $env:PATH = "$env:PATH;$gstreamerBin"
        }
    }

    if (Add-UserPathIfExists -Path $gstreamerBin) {
        Write-Host "Added GStreamer bin directory to User PATH."
    }
} else {
    Write-Host "GStreamer root not found; leaving GSTREAMER_* variables unchanged."
    Clear-ProcessPathIfMissing -Name "GSTREAMER_1_0_ROOT_MSVC_X86_64"
    Clear-ProcessPathIfMissing -Name "GSTREAMER_ROOT_X86_64"
    Remove-MissingProcessPathEntries -Name "PKG_CONFIG_PATH"
}

if ($pkgConfigBin) {
    if (Add-UserPathIfExists -Path $pkgConfigBin) {
        Write-Host "Added pkg-config-lite bin directory to User PATH."
    }
} else {
    Write-Host "pkg-config-lite bin directory not found."
}
