$gstreamerRoot = "$env:LOCALAPPDATA\Programs\gstreamer\1.0\msvc_x86_64"
$wingetLinks = "$env:LOCALAPPDATA\Microsoft\WinGet\Links"

Write-Host "Configuring GStreamer User Environment Variables..."
[Environment]::SetEnvironmentVariable("GSTREAMER_1_0_ROOT_MSVC_X86_64", $gstreamerRoot, "User")
[Environment]::SetEnvironmentVariable("GSTREAMER_ROOT_X86_64", $gstreamerRoot, "User")
[Environment]::SetEnvironmentVariable("PKG_CONFIG_PATH", "$gstreamerRoot\lib\pkgconfig", "User")

$currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
$binPath = "$gstreamerRoot\bin"
$pathModified = $false
foreach ($p in @($binPath, $wingetLinks)) {
    if ($currentPath -split ';' -notcontains $p) {
        $currentPath = "$currentPath;$p"
        $pathModified = $true
    }
}
if ($pathModified) {
    [Environment]::SetEnvironmentVariable("PATH", $currentPath, "User")
    Write-Host "Updated PATH in User environment registry."
} else {
    Write-Host "PATH in User environment registry is already up to date."
}
