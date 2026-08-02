Add-Type -AssemblyName System.Drawing
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class Wallpaper {
    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
}
"@

try {
    $folder = "C:\Wallpaper"
    $fontPath = "$folder\Anurati.ttf"

    # Find the base image
    $baseFile = Get-ChildItem -Path $folder | Where-Object { $_.BaseName -eq "base" -and ($_.Extension -in ".jpg", ".jpeg", ".png") } | Select-Object -First 1
    if (-not $baseFile) { throw "Base wallpaper image not found!" }

    $original = $baseFile.FullName
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

    # Load Font & CALCULATE JUICY DYNAMIC SIZE (Tied to image width to prevent clipping)
    $pfc = New-Object System.Drawing.Text.PrivateFontCollection
    if (Test-Path $fontPath) {
        $pfc.AddFontFile($fontPath)
        # 0.0420 is the sweet-spot ratio for the elegant wide Anurati look
        $dynamicSize = [int]($image.Width * 0.042)
        $dayFont = New-Object System.Drawing.Font($pfc.Families[0], $dynamicSize, [System.Drawing.FontStyle]::Regular)
    } else {
        $dynamicSize = [int]($image.Width * 0.038)
        $dayFont = New-Object System.Drawing.Font("Arial", $dynamicSize, [System.Drawing.FontStyle]::Bold)
    }

    # Color & Layout (Pure Black Text)
    $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Black)
    $sf = New-Object System.Drawing.StringFormat
    $sf.Alignment = [System.Drawing.StringAlignment]::Center

    # Bounding Box (Adjusted to 22% down from top, with expanded height to fit the large font safely)
    $rectDay = New-Object System.Drawing.RectangleF(0, ($image.Height * 0.22), $image.Width, ($image.Height * 0.18))

    # Render Day Name
    $graphics.DrawString($spacedDay, $dayFont, $brush, $rectDay, $sf)

    # Save and Close
    $graphics.Dispose()
    $image.Save($output, [System.Drawing.Imaging.ImageFormat]::Jpeg)
    $image.Dispose()

    # Force background refresh
    [Wallpaper]::SystemParametersInfo(0x0014, 0, $output, 0x01 -bor 0x02)

    # Clean up old day files safely
    Start-Sleep -Seconds 2
    Get-ChildItem -Path $folder -Filter "current_*.jpg" | 
        Where-Object { $_.Name -ne "current_$dayName.jpg" } | 
        Remove-Item -Force -ErrorAction SilentlyContinue

} catch {
    "[$([DateTime]::Now)] Error occurred: $_" | Out-File -FilePath "$folder\error_log.txt" -Append
}