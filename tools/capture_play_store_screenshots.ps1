param(
	[Parameter(Mandatory = $true)]
	[string]$ApkPath,
	[string]$OutputDirectory = "",
	[int]$AdbPort = 5041,
	[int]$EmulatorPort = 5562
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
$sdkRoot = Join-Path $env:LOCALAPPDATA "Android\Sdk"
$adb = Join-Path $sdkRoot "platform-tools\adb.exe"
$emulator = Join-Path $sdkRoot "emulator\emulator.exe"
$avdHome = Join-Path $projectRoot "build\android\avd"
$avdName = "ZEE_Test_API_36"
$dataDirectory = Join-Path $projectRoot "build\android\avd_store_screenshots_data"
$logDirectory = Join-Path $projectRoot ("build\android\store_listing_capture_{0}" -f (Get-Date -Format "yyyyMMdd_HHmmss"))
$serial = "emulator-$EmulatorPort"
$package = "com.zombieescapeeurope.game"
$apk = if ([System.IO.Path]::IsPathRooted($ApkPath)) { $ApkPath } else { Join-Path $projectRoot $ApkPath }
if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
	$OutputDirectory = Join-Path "store_listing\de\screenshots" ("capture_{0}" -f (Get-Date -Format "yyyyMMdd_HHmmss"))
}
$outputRoot = if ([System.IO.Path]::IsPathRooted($OutputDirectory)) { $OutputDirectory } else { Join-Path $projectRoot $OutputDirectory }
$emulatorProcess = $null

foreach ($requiredFile in @($adb, $emulator, $apk, (Join-Path $avdHome "$avdName.ini"))) {
	if (-not (Test-Path -LiteralPath $requiredFile -PathType Leaf)) { throw "Benötigte Datei fehlt: $requiredFile" }
}
if (Test-Path -LiteralPath $outputRoot) { throw "Der Screenshot-Ordner existiert bereits; bitte einen neuen Zielordner angeben: $outputRoot" }
New-Item -ItemType Directory -Path $outputRoot, $dataDirectory, $logDirectory -Force | Out-Null

$env:ANDROID_AVD_HOME = $avdHome
$env:ANDROID_SDK_ROOT = $sdkRoot
$env:ANDROID_ADB_SERVER_PORT = [string]$AdbPort

function Invoke-Device {
	param([Parameter(Mandatory = $true)][string[]]$Arguments)
	& $script:adb -P $script:AdbPort -s $script:serial @Arguments
	if ($LASTEXITCODE -ne 0) { throw "ADB-Befehl fehlgeschlagen: $($Arguments -join ' ')" }
}

function Save-StoreScreenshot {
	param([string]$Name)
	$outputPath = Join-Path $script:outputRoot $Name
	$startInfo = [System.Diagnostics.ProcessStartInfo]::new()
	$startInfo.FileName = $script:adb
	$startInfo.Arguments = "-P $($script:AdbPort) -s $($script:serial) exec-out screencap -p"
	$startInfo.UseShellExecute = $false
	$startInfo.RedirectStandardOutput = $true
	$startInfo.RedirectStandardError = $true
	$process = [System.Diagnostics.Process]::new()
	$process.StartInfo = $startInfo
	if (-not $process.Start()) { throw "Screenshot-Abruf konnte nicht starten." }
	$fileStream = [System.IO.File]::Create($outputPath)
	$process.StandardOutput.BaseStream.CopyTo($fileStream)
	$fileStream.Dispose()
	$errorText = $process.StandardError.ReadToEnd()
	$process.WaitForExit()
	if ($process.ExitCode -ne 0) { throw "Screenshot fehlgeschlagen: $errorText" }
	$process.Dispose()
	$bytes = [System.IO.File]::ReadAllBytes($outputPath)
	if ($bytes.Length -lt 8 -or $bytes[0] -ne 137 -or $bytes[1] -ne 80 -or $bytes[2] -ne 78 -or $bytes[3] -ne 71) {
		throw "ADB lieferte für '$Name' keine gültige PNG-Datei."
	}

	Add-Type -AssemblyName System.Drawing
	$sourceImage = [System.Drawing.Image]::FromFile($outputPath)
	if ($sourceImage.Width -ne 1920 -or $sourceImage.Height -ne 1080) {
		$actualSize = "{0}x{1}" -f $sourceImage.Width, $sourceImage.Height
		$sourceImage.Dispose()
		throw "Screenshot '$Name' hat $actualSize statt 1920x1080."
	}
	$temporaryPath = "$outputPath.24bit.png"
	$bitmap = [System.Drawing.Bitmap]::new(1920, 1080, [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
	$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
	$graphics.DrawImage($sourceImage, 0, 0, 1920, 1080)
	$bitmap.Save($temporaryPath, [System.Drawing.Imaging.ImageFormat]::Png)
	$graphics.Dispose()
	$bitmap.Dispose()
	$sourceImage.Dispose()
	Move-Item -LiteralPath $temporaryPath -Destination $outputPath -Force
	Write-Output ("Screenshot: {0}" -f $outputPath)
}

	
try {
	& $adb -P $AdbPort start-server
	if ($LASTEXITCODE -ne 0) { throw "Isolierter ADB-Server konnte nicht starten." }
	$emulatorArgs = @(
		"-avd", $avdName,
		"-datadir", ('"' + $dataDirectory + '"'),
		"-read-only",
		"-port", [string]$EmulatorPort,
		"-no-snapshot",
		"-no-boot-anim",
		"-no-window",
		"-gpu", "host"
	)
	$emulatorProcess = Start-Process -FilePath $emulator -ArgumentList $emulatorArgs -WorkingDirectory (Split-Path -Parent $emulator) -WindowStyle Hidden -RedirectStandardOutput (Join-Path $logDirectory "emulator.stdout.log") -RedirectStandardError (Join-Path $logDirectory "emulator.stderr.log") -PassThru

	$deviceReady = $false
	for ($attempt = 0; $attempt -lt 120; $attempt++) {
		$devices = & $adb -P $AdbPort devices
		if ($devices -match ([regex]::Escape($serial) + "\s+device")) { $deviceReady = $true; break }
		if ($emulatorProcess.HasExited) { throw "AVD wurde vor dem ADB-Verbindungsaufbau beendet." }
		Start-Sleep -Seconds 1
	}
	if (-not $deviceReady) { throw "AVD wurde nicht per ADB erreichbar." }

	$booted = $false
	for ($attempt = 0; $attempt -lt 180; $attempt++) {
		$bootValue = & $adb -P $AdbPort -s $serial shell getprop sys.boot_completed 2>$null
		if ($LASTEXITCODE -eq 0 -and ($bootValue | Out-String).Trim() -eq "1") { $booted = $true; break }
		if ($emulatorProcess.HasExited) { throw "AVD wurde vor Androids Bootabschluss beendet." }
		Start-Sleep -Seconds 1
	}
	if (-not $booted) { throw "Android meldete keinen abgeschlossenen Start." }

	Invoke-Device @("shell", "wm", "size", "1920x1080") | Out-Null
	$screenSize = (Invoke-Device @("shell", "wm", "size") | Out-String)
	if ($screenSize -notmatch 'Override size: 1920x1080') { throw "AVD-Auflösung konnte nicht auf 1920x1080 gesetzt werden: $screenSize" }
	$installedPackage = & $adb -P $AdbPort -s $serial shell pm path $package 2>$null
	if ($LASTEXITCODE -eq 0 -and $installedPackage) { Invoke-Device @("uninstall", $package) | Out-Null }
	Invoke-Device @("install", "-r", $apk) | Out-Null
	Invoke-Device @("logcat", "-c") | Out-Null
	Start-Sleep -Seconds 2
	Invoke-Device @("shell", "am", "start", "-W", "-n", "$package/com.godot.game.GodotAppLauncher") | Out-Null
	Start-Sleep -Seconds 8
	# Android 16 shows the immersive-mode prompt with a button at this position.
	Invoke-Device @("shell", "input", "touchscreen", "tap", "1462", "500") | Out-Null
	# Let the first cold Godot startup finish loading assets before touching the game UI.
	Start-Sleep -Seconds 12
	# Skip the first-drive tutorial if the fresh profile displays it.
	Invoke-Device @("shell", "input", "touchscreen", "tap", "540", "839") | Out-Null
	Start-Sleep -Seconds 3
	Save-StoreScreenshot "02_vehicle_garage.png"

	Invoke-Device @("shell", "input", "touchscreen", "tap", "1780", "425") | Out-Null
	Start-Sleep -Seconds 2
	$mapTouchLog = (Invoke-Device @("logcat", "-d", "-s", "godot:V") | Out-String)
	if ($mapTouchLog -notmatch '\[PERF\] touch_hit=map_open') {
		throw "Die Europakarte reagierte beim Store-Aufnahmelauf nicht auf den Touch."
	}
	Save-StoreScreenshot "03_europe_map.png"
	Invoke-Device @("shell", "input", "touchscreen", "tap", "1790", "1022") | Out-Null
	Start-Sleep -Seconds 2
	Invoke-Device @("shell", "input", "touchscreen", "tap", "1780", "940") | Out-Null
	Start-Sleep -Seconds 3
	$startLog = (Invoke-Device @("logcat", "-d", "-s", "godot:V") | Out-String)
	if ($startLog -notmatch '\[PERF\] touch_hit=start' -or $startLog -notmatch '\[PERF\] run_started_at_m=') {
		throw "Die Fahrt startete beim Store-Aufnahmelauf nicht nachweislich über die Starttaste."
	}
	Invoke-Device @("shell", "input", "touchscreen", "swipe", "1798", "927", "1798", "927", "5500") | Out-Null
	Start-Sleep -Seconds 3
	$driveLog = (Invoke-Device @("logcat", "-d", "-s", "godot:V") | Out-String)
	if ($driveLog -notmatch '\[PERF\] touch_hit=accelerate' -or $driveLog -notmatch '\[PERF\] touch_up=.*action=accelerate') {
		throw "Die Gas-Touchfläche wurde während der Store-Aufnahme nicht gehalten und losgelassen."
	}
	$drivingSpeed = 0.0
	$drivingDistance = 0.0
	for ($attempt = 0; $attempt -lt 8; $attempt++) {
		$frameMatches = [regex]::Matches($driveLog, '\[PERF\] frame .*?speed_x=([-0-9.]+)kmh route=([-0-9.]+)m')
		if ($frameMatches.Count -gt 0) {
			$latestFrame = $frameMatches[$frameMatches.Count - 1]
			$drivingSpeed = [double]::Parse($latestFrame.Groups[1].Value, [System.Globalization.CultureInfo]::InvariantCulture)
			$drivingDistance = [double]::Parse($latestFrame.Groups[2].Value, [System.Globalization.CultureInfo]::InvariantCulture)
		}
		if ($drivingDistance -ge 12.0 -and $drivingSpeed -ge 28.0) { break }
		if ($attempt -lt 7) {
			Invoke-Device @("shell", "input", "touchscreen", "swipe", "1798", "927", "1798", "927", "1800") | Out-Null
			Start-Sleep -Seconds 1
			$driveLog = (Invoke-Device @("logcat", "-d", "-s", "godot:V") | Out-String)
		}
	}
	if ($drivingDistance -lt 12.0 -or $drivingSpeed -lt 28.0) {
		throw "Die Store-Fahransicht ist zu früh aufgenommen worden: $drivingDistance m bei $drivingSpeed km/h."
	}
	Save-StoreScreenshot "01_driving.png"

	[pscustomobject]@{
		Result = "PLAY_STORE_SCREENSHOTS_CAPTURED"
		Display = $screenSize.Trim()
		Avd = $avdName
		OutputDirectory = $outputRoot
		Logs = $logDirectory
		Screenshots = @("01_driving.png", "02_vehicle_garage.png", "03_europe_map.png")
		DrivingSpeedKmh = $drivingSpeed
		DrivingDistanceMeters = $drivingDistance
	} | Format-List
} finally {
	if ($emulatorProcess -and -not $emulatorProcess.HasExited) {
		& $adb -P $AdbPort -s $serial emu kill 2>$null | Out-Null
		if (-not $emulatorProcess.WaitForExit(15000)) { $emulatorProcess.Kill() }
	}
	& $adb -P $AdbPort kill-server 2>$null | Out-Null
}
