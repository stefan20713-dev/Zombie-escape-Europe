param(
	[Parameter(Mandatory = $true)]
	[string]$CaptureDirectory,
	[string]$OutputDirectory = "store_listing/de",
	[switch]$Force
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
$captureRoot = if ([System.IO.Path]::IsPathRooted($CaptureDirectory)) { $CaptureDirectory } else { Join-Path $projectRoot $CaptureDirectory }
$outputRoot = if ([System.IO.Path]::IsPathRooted($OutputDirectory)) { $OutputDirectory } else { Join-Path $projectRoot $OutputDirectory }
$screenshotsRoot = Join-Path $outputRoot "screenshots\0.5.39"
$iconOutput = Join-Path $outputRoot "app_icon_512.png"
$featureOutput = Join-Path $outputRoot "feature_graphic_1024x500.png"
$iconSource = Join-Path $projectRoot "assets\app_icon.png"
$featureSource = Join-Path $projectRoot "assets\loading_splash_0.4.27.png"

$captureFiles = @(
	@{ Source = "01_driving.png"; Destination = "01_fahrt.png" },
	@{ Source = "02_vehicle_garage.png"; Destination = "02_werkstatt.png" },
	@{ Source = "03_europe_map.png"; Destination = "03_europakarte.png" }
)

foreach ($path in @($iconSource, $featureSource) + @($captureFiles | ForEach-Object { Join-Path $captureRoot $_.Source })) {
	if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Benötigte Listing-Quelle fehlt: $path" }
}
if (-not $Force -and ((Test-Path -LiteralPath $iconOutput) -or (Test-Path -LiteralPath $featureOutput) -or (Test-Path -LiteralPath $screenshotsRoot))) {
	throw "Listing-Zieldateien existieren bereits. Nutze -Force nur, wenn du sie gezielt ersetzen möchtest."
}

New-Item -ItemType Directory -Path $outputRoot, $screenshotsRoot -Force | Out-Null
Add-Type -AssemblyName System.Drawing

function Set-HighQualityGraphics {
	param([System.Drawing.Graphics]$Graphics)
	$Graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
	$Graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
	$Graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
	$Graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
}

$sourceIcon = [System.Drawing.Bitmap]::FromFile($iconSource)
$iconBitmap = [System.Drawing.Bitmap]::new(512, 512, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$iconGraphics = [System.Drawing.Graphics]::FromImage($iconBitmap)
try {
	Set-HighQualityGraphics $iconGraphics
	$iconGraphics.Clear([System.Drawing.Color]::Transparent)
	$iconGraphics.DrawImage($sourceIcon, 0, 0, 512, 512)
	$iconBitmap.Save($iconOutput, [System.Drawing.Imaging.ImageFormat]::Png)
} finally {
	$iconGraphics.Dispose()
	$iconBitmap.Dispose()
	$sourceIcon.Dispose()
}

$sourceFeature = [System.Drawing.Bitmap]::FromFile($featureSource)
$featureBitmap = [System.Drawing.Bitmap]::new(1024, 500, [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
$featureGraphics = [System.Drawing.Graphics]::FromImage($featureBitmap)
try {
	Set-HighQualityGraphics $featureGraphics
	$targetAspect = 1024.0 / 500.0
	$sourceAspect = [double]$sourceFeature.Width / [double]$sourceFeature.Height
	if ($sourceAspect -gt $targetAspect) {
		$cropWidth = [int][Math]::Round($sourceFeature.Height * $targetAspect)
		$sourceRect = [System.Drawing.Rectangle]::new([int](($sourceFeature.Width - $cropWidth) / 2), 0, $cropWidth, $sourceFeature.Height)
	} else {
		$cropHeight = [int][Math]::Round($sourceFeature.Width / $targetAspect)
		$sourceRect = [System.Drawing.Rectangle]::new(0, [int](($sourceFeature.Height - $cropHeight) / 2), $sourceFeature.Width, $cropHeight)
	}
	$featureGraphics.DrawImage($sourceFeature, [System.Drawing.Rectangle]::new(0, 0, 1024, 500), $sourceRect, [System.Drawing.GraphicsUnit]::Pixel)
	$featureBitmap.Save($featureOutput, [System.Drawing.Imaging.ImageFormat]::Png)
} finally {
	$featureGraphics.Dispose()
	$featureBitmap.Dispose()
	$sourceFeature.Dispose()
}

$screenshotResults = @()
foreach ($entry in $captureFiles) {
	$sourcePath = Join-Path $captureRoot $entry.Source
	$destinationPath = Join-Path $screenshotsRoot $entry.Destination
	$bitmap = [System.Drawing.Bitmap]::FromFile($sourcePath)
	try {
		if ($bitmap.Width -ne 1920 -or $bitmap.Height -ne 1080) { throw "Screenshot muss 1920x1080 sein: $($entry.Source)" }
		if ($bitmap.PixelFormat -ne [System.Drawing.Imaging.PixelFormat]::Format24bppRgb) { throw "Screenshot muss 24-bit RGB ohne Alpha sein: $($entry.Source)" }
		Copy-Item -LiteralPath $sourcePath -Destination $destinationPath -Force:$Force
		$screenshotResults += [pscustomobject]@{ File = $entry.Destination; Width = $bitmap.Width; Height = $bitmap.Height; PixelFormat = $bitmap.PixelFormat.ToString() }
	} finally {
		$bitmap.Dispose()
	}
}

$iconInfo = [System.Drawing.Bitmap]::FromFile($iconOutput)
$featureInfo = [System.Drawing.Bitmap]::FromFile($featureOutput)
try {
	$iconBytes = (Get-Item -LiteralPath $iconOutput).Length
	if ($iconInfo.Width -ne 512 -or $iconInfo.Height -ne 512 -or $iconInfo.PixelFormat -ne [System.Drawing.Imaging.PixelFormat]::Format32bppArgb -or $iconBytes -gt 1MB) {
		throw "Play-Store-Icon erfüllt 512x512, 32-bit PNG/Alpha oder 1-MB-Limit nicht."
	}
	if ($featureInfo.Width -ne 1024 -or $featureInfo.Height -ne 500 -or $featureInfo.PixelFormat -ne [System.Drawing.Imaging.PixelFormat]::Format24bppRgb) {
		throw "Feature-Grafik erfüllt 1024x500 oder 24-bit RGB ohne Alpha nicht."
	}
} finally {
	$iconInfo.Dispose()
	$featureInfo.Dispose()
}

[pscustomobject]@{
	Result = "PLAY_STORE_ASSET_PACKAGE_READY"
	Icon = $iconOutput
	IconBytes = (Get-Item -LiteralPath $iconOutput).Length
	FeatureGraphic = $featureOutput
	Screenshots = $screenshotResults
} | Format-List
