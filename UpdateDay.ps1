Add-Type -AssemblyName System.Drawing
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class Wallpaper {
    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
}
"@

$folder = "C:\Wallpaper"
$original = "$folder\base.jpg"
$fontPath = "$folder\Anurati.ttf"

# Automatic style font fetch
if (-not (Test-Path $fontPath)) {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/truthstudentministries/jacobdstringfellow/master/fonts/anurati.ttf" -OutFile $fontPath -ErrorAction SilentlyContinue
}

# Date Calculations (Day name only)
$dayName = (Get-Date).DayOfWeek.ToString().ToUpper()
$spacedDay = ($dayName.ToCharArray() -join ' ')
$output = "$folder\current_$dayName.jpg"

# Canvas Setup
$image = [System.Drawing.Image]::FromFile($original)
$graphics = [System.Drawing.Graphics]::FromImage($image)

# Ultra Anti-Aliasing
$graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAlias
$graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
$graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality

# Load Font
$pfc = New-Object System.Drawing.Text.PrivateFontCollection
if (Test-Path $fontPath) {
    $pfc.AddFontFile($fontPath)
    $dayFont = New-Object System.Drawing.Font($pfc.Families[0], 75, [System.Drawing.FontStyle]::Regular)
} else {
    $dayFont = New-Object System.Drawing.Font("Arial", 65, [System.Drawing.FontStyle]::Bold)
}

# Color & Layout (Pure Black Text)
$brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Black)
$sf = New-Object System.Drawing.StringFormat
$sf.Alignment = [System.Drawing.StringAlignment]::Center

# Position Bounding Box (Shifted slightly down to balance the screen now that the date is gone)
$rectDay = New-Object System.Drawing.RectangleF(0, ($image.Height * 0.25), $image.Width, ($image.Height * 0.15))

# Render Day Name
$graphics.DrawString($spacedDay, $dayFont, $brush, $rectDay, $sf)

# Save and Apply
$graphics.Dispose()
$image.Save($output, [System.Drawing.Imaging.ImageFormat]::Jpeg)
$image.Dispose()

# Force background refresh
[Wallpaper]::SystemParametersInfo(0x0014, 0, $output, 0x01 -bor 0x02)

# Aggressive Cleanup Sequence
Start-Sleep -Seconds 2
Get-ChildItem -Path $folder -Filter "current_*.jpg" | 
    Where-Object { $_.Name -ne "current_$dayName.jpg" } | 
    Remove-Item -Force -ErrorAction SilentlyContinue