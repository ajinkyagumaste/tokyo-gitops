# Company wallpaper for Windows workstations.
# Populate $WallpaperPath with an accessible local image path before deploying.
# Run in the signed-in user's context to change that user's desktop wallpaper.

$WallpaperPath = ''

if ([string]::IsNullOrWhiteSpace($WallpaperPath)) {
    Write-Output 'Wallpaper path is blank. No changes applied.'
    exit 0
}

if (-not (Test-Path -LiteralPath $WallpaperPath -PathType Leaf)) {
    Write-Error "Wallpaper image not found: $WallpaperPath"
    exit 1
}

Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class DesktopWallpaper {
    [DllImport("user32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    public static extern bool SystemParametersInfo(uint action, uint param, string value, uint flags);
}
'@

# SPI_SETDESKWALLPAPER = 20; SPIF_UPDATEINIFILE | SPIF_SENDCHANGE = 3.
if (-not [DesktopWallpaper]::SystemParametersInfo(20, 0, $WallpaperPath, 3)) {
    $errorCode = [Runtime.InteropServices.Marshal]::GetLastWin32Error()
    Write-Error "Failed to set wallpaper (Win32 error $errorCode)."
    exit 1
}

Write-Output 'Company wallpaper applied successfully.'
