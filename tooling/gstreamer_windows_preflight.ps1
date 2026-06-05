[CmdletBinding()]
param(
    [switch]$Json
)

$ErrorActionPreference = "Stop"

function Get-ToolCheck {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [string[]]$VersionArguments = @("--version")
    )

    $command = Get-Command $Name -ErrorAction SilentlyContinue | Select-Object -First 1
    $version = $null
    $path = $null

    if ($null -ne $command) {
        $path = $command.Source

        try {
            $output = & $path @VersionArguments 2>&1
            $version = ($output | Select-Object -First 1).ToString().Trim()
        }
        catch {
            $version = "version check failed: $($_.Exception.Message)"
        }
    }

    [pscustomobject]@{
        name = $Name
        found = $null -ne $command
        path = $path
        version = $version
    }
}

function Get-EnvironmentCheck {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    [pscustomobject]@{
        name = $Name
        value = [Environment]::GetEnvironmentVariable($Name)
    }
}

function Get-ExistingCommonRoot {
    $roots = @(
        "C:\gstreamer\1.0\msvc_x86_64",
        "C:\Program Files\gstreamer\1.0\msvc_x86_64",
        "$env:LOCALAPPDATA\Programs\gstreamer\1.0\msvc_x86_64"
    )

    $roots |
        Where-Object { Test-Path -LiteralPath $_ } |
        ForEach-Object {
            [pscustomobject]@{
                root = $_
                bin = Join-Path $_ "bin"
                lib = Join-Path $_ "lib"
                pkgconfig = Join-Path $_ "lib\pkgconfig"
            }
        }
}

$tools = @(
    Get-ToolCheck -Name "gst-launch-1.0"
    Get-ToolCheck -Name "gst-inspect-1.0"
    Get-ToolCheck -Name "pkg-config"
)

$environment = @(
    Get-EnvironmentCheck -Name "GSTREAMER_1_0_ROOT_MSVC_X86_64"
    Get-EnvironmentCheck -Name "GSTREAMER_ROOT_X86_64"
    Get-EnvironmentCheck -Name "PKG_CONFIG_PATH"
)

$commonRoots = @(Get-ExistingCommonRoot)
$missingTools = @($tools | Where-Object { -not $_.found } | ForEach-Object { $_.name })
$status = if ($missingTools.Count -eq 0) { "ready" } else { "missing" }
$nextSteps = New-Object System.Collections.Generic.List[string]

if ($missingTools.Count -gt 0) {
    $nextSteps.Add("Install GStreamer MSVC x86_64 runtime and development files before adding Rust bindings.")
    $nextSteps.Add("Ensure gst-launch-1.0, gst-inspect-1.0, and pkg-config are available on PATH.")
}

if ($commonRoots.Count -gt 0 -and $missingTools.Count -gt 0) {
    $nextSteps.Add("A common GStreamer root exists; add its bin directory to PATH and lib\pkgconfig to PKG_CONFIG_PATH.")
}

if ($missingTools.Count -eq 0) {
    $nextSteps.Add("Run a minimal gst-launch-1.0 pipeline check before enabling Rust GStreamer bindings.")
}

$payload = [pscustomobject]@{
    status = $status
    platform = [pscustomobject]@{
        os = [Environment]::OSVersion.VersionString
        is_windows = [Environment]::OSVersion.Platform -eq [PlatformID]::Win32NT
    }
    tools = $tools
    environment = $environment
    common_roots = $commonRoots
    next_steps = @($nextSteps)
}

if ($Json) {
    $payload | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host "ChronoWave GStreamer Windows preflight: $status"
Write-Host ""
Write-Host "Tools:"
foreach ($tool in $tools) {
    $state = if ($tool.found) { "found" } else { "missing" }
    Write-Host "- $($tool.name): $state $($tool.path)"
}

Write-Host ""
Write-Host "Next steps:"
foreach ($step in $nextSteps) {
    Write-Host "- $step"
}
