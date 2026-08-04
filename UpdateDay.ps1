# ================================
# Dynamic Wallpaper v2.0
# Optimized for Windows 10
# ================================

$ErrorActionPreference = "Stop"

$folder = "C:\Wallpaper"
$baseImage = "$folder\base.jpg"
$fontPath = "$folder\Anurati.ttf"
$output = "$folder\current.png"
$log = "$folder\performance.log"
$errorLog = "$folder\error_log.txt"

$sw = [System.Diagnostics.Stopwatch]::StartNew()

try {

Add-Type -AssemblyName System.Drawing

Add-Type @"
using System;
using System.Runtime.InteropServices;

public class Wallpaper {
    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern bool SystemParametersInfo(
        int uAction,
        int uParam,
        string lpvParam,
        int fuWinIni
    );
}
"@

# --------------------------
# Load Image
# --------------------------

$image = [System.Drawing.Bitmap]::FromFile($baseImage)
$graphics = [System.Drawing.Graphics]::FromImage($image)

$graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
$graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit
$graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

# --------------------------
# Day Text
# --------------------------

$day = (Get-Date).DayOfWeek.ToString().ToUpper()
$text = ($day.ToCharArray() -join " ")

# --------------------------
# Font
# --------------------------

$pfc = New-Object System.Drawing.Text.PrivateFontCollection
$pfc.AddFontFile($fontPath)

$fontSize = [math]::Round($image.Width * 0.042)

$font = New-Object System.Drawing.Font(
    $pfc.Families[0],
    $fontSize,
    [System.Drawing.FontStyle]::Regular,
    [System.Drawing.GraphicsUnit]::Pixel
)

# --------------------------
# Measure Text
# --------------------------

$size = $graphics.MeasureString($text,$font)

$x = ($image.Width - $size.Width)/2
$y = ($image.Height*0.225)-($size.Height/2)

$brush = New-Object System.Drawing.SolidBrush(
    [System.Drawing.Color]::FromArgb(15,15,15)
)

$graphics.DrawString(
    $text,
    $font,
    $brush,
    $x,
    $y
)

# --------------------------
# Save PNG
# --------------------------

$image.Save(
    $output,
    [System.Drawing.Imaging.ImageFormat]::Png
)

# --------------------------
# Cleanup
# --------------------------

$brush.Dispose()
$font.Dispose()
$graphics.Dispose()
$image.Dispose()
$pfc.Dispose()

# --------------------------
# Apply Wallpaper
# --------------------------

[Wallpaper]::SystemParametersInfo(
    20,
    0,
    $output,
    3
) | Out-Null

$sw.Stop()

@"
=================================
$(Get-Date)
Execution Time : $($sw.ElapsedMilliseconds) ms
Wallpaper : SUCCESS
=================================

"@ | Out-File $log -Append

}
catch{

$sw.Stop()

@"
=================================
$(Get-Date)

FAILED

$($_.Exception.Message)

Execution Time :
$($sw.ElapsedMilliseconds) ms

=================================

"@ | Out-File $errorLog -Append

}