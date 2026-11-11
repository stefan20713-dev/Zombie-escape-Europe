param(
	[string]$Version = "0.5.11",
	[int]$AdbPort = 5038,
	[int]$EmulatorPort = 5556,
	[int]$MemoryMb = 4096,
	[int]$RuntimeSeconds = 25
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
$sdkRoot = Join-Path $env:LOCALAPPDATA "Android\Sdk"
$adb = Join-Path $sdkRoot "platform-tools\adb.exe"
$emulator = Join-Path $sdkRoot "emulator\emulator.exe"
$avdHome = Join-Path $projectRoot "build\android\avd"
$avdName = "ZEE_Test_API_36"
$serial = "emulator-$EmulatorPort"
$apk = Join-Path $projectRoot "build\android\Zombie_Escape_Europe-debug-$Version.apk"
$logDirectory = Join-Path $projectRoot "build\android"
$stdoutPath = Join-Path $logDirectory "avd_smoke_$Version.stdout.log"
$stderrPath = Join-Path $logDirectory "avd_smoke_$Version.stderr.log"
$logcatPath = Join-Path $logDirectory "avd_smoke_$Version.logcat.txt"
$screenshotPath = Join-Path $logDirectory "avd_smoke_$Version.png"
$iniPath = Join-Path $avdHome "$avdName.avd\config.ini"
$emulatorProcess = $null

foreach ($requiredPath in @($adb, $emulator, $apk, $iniPath)) {
	if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
		throw "Benötigte QA-Datei fehlt: $requiredPath"
	}
}

$config = [System.IO.File]::ReadAllText($iniPath)
if ($config -match "(?m)^hw\.ramSize=") {
	$config = [regex]::Replace($config, "(?m)^hw\.ramSize=.*$", "hw.ramSize=$MemoryMb")
} else {
	$config += "`r`nhw.ramSize=$MemoryMb`r`n"
}
[System.IO.File]::WriteAllText($iniPath, $config)

$env:ANDROID_AVD_HOME = $avdHome
$env:ANDROID_SDK_ROOT = $sdkRoot
$env:ANDROID_ADB_SERVER_PORT = [string]$AdbPort

try {
	& $adb -P $AdbPort start-server
	if ($LASTEXITCODE -ne 0) { throw "ADB-Server auf Port $AdbPort konnte nicht starten." }

	$emulatorArgs = @(
		"-avd", $avdName,
		"-port", [string]$EmulatorPort,
		"-no-snapshot",
		"-no-boot-anim",
		"-no-window",
		"-gpu", "host",
		"-verbose"
	)
	$emulatorProcess = Start-Process -FilePath $emulator -ArgumentList $emulatorArgs -WorkingDirectory (Split-Path -Parent $emulator) -WindowStyle Hidden -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath -PassThru

	$deviceReady = $false
	for ($attempt = 0; $attempt -lt 90; $attempt++) {
		$deviceList = & $adb -P $AdbPort devices
		if ($deviceList -match [regex]::Escape($serial) + "\s+device") {
			$deviceReady = $true
			break
		}
		if ($emulatorProcess.HasExited) { throw "Emulator endete vor dem ADB-Verbindungsaufbau; siehe $stderrPath" }
		Start-Sleep -Seconds 1
	}
	if (-not $deviceReady) { throw "Emulator $serial wurde innerhalb von 90 Sekunden nicht per ADB erreichbar." }

	$booted = $false
	for ($attempt = 0; $attempt -lt 150; $attempt++) {
		$bootValue = & $adb -P $AdbPort -s $serial shell getprop sys.boot_completed 2>$null
		if (($bootValue | Out-String).Trim() -eq "1") {
			$booted = $true
			break
		}
		if ($emulatorProcess.HasExited) { throw "Emulator endete vor dem Android-Bootabschluss." }
		Start-Sleep -Seconds 1
	}
	if (-not $booted) { throw "Android meldete nach 150 Sekunden keinen abgeschlossenen Start." }

	& $adb -P $AdbPort -s $serial logcat -c
	if ($LASTEXITCODE -ne 0) { throw "Logcat konnte nicht geleert werden." }
	& $adb -P $AdbPort -s $serial install -r $apk
	if ($LASTEXITCODE -ne 0) { throw "APK-Installation ist fehlgeschlagen." }
	& $adb -P $AdbPort -s $serial shell monkey -p com.zombieescapeeurope.game -c android.intent.category.LAUNCHER 1
	if ($LASTEXITCODE -ne 0) { throw "Android konnte das Spiel nicht starten." }
	Start-Sleep -Seconds $RuntimeSeconds

	$activityState = & $adb -P $AdbPort -s $serial shell dumpsys activity activities
	$packagePid = & $adb -P $AdbPort -s $serial shell pidof com.zombieescapeeurope.game
	& $adb -P $AdbPort -s $serial shell screencap -p /sdcard/zee_android_smoke.png
	if ($LASTEXITCODE -ne 0) { throw "Android-Screenshot konnte nicht aufgenommen werden." }
	& $adb -P $AdbPort -s $serial pull /sdcard/zee_android_smoke.png $screenshotPath
	if ($LASTEXITCODE -ne 0) { throw "Android-Screenshot konnte nicht kopiert werden." }
	& $adb -P $AdbPort -s $serial logcat -d -t 12000 | Set-Content -LiteralPath $logcatPath -Encoding utf8
	if ($LASTEXITCODE -ne 0) { throw "Logcat konnte nicht gespeichert werden." }

	$gameActivity = [bool]($activityState -match "com\.zombieescapeeurope\.game")
	$gameRunning = -not [string]::IsNullOrWhiteSpace(($packagePid | Out-String).Trim())
	$logText = [System.IO.File]::ReadAllText($logcatPath)
	$godotReady = $logText -match "game_ready_ms="
	$shaderFailure = $logText -match "GL_MAX_FRAGMENT_UNIFORM_VECTORS|shader failed to compile|Program linking failed"
	$anr = $logText -match "\bANR in (com\.zombieescapeeurope\.game|com\.google\.android\.apps\.nexuslauncher|com\.android\.systemui)"

	[pscustomobject]@{
		Version = $Version
		Avd = $avdName
		Gpu = "host"
		MemoryMb = $MemoryMb
		Booted = $booted
		InstalledAndLaunched = $true
		GameActivityResumed = $gameActivity
		GameProcessRunning = $gameRunning
		GodotMainSceneReady = $godotReady
		ShaderCompileFailure = $shaderFailure
		ApplicationOrLauncherAnr = $anr
		Screenshot = $screenshotPath
		Logcat = $logcatPath
		EmulatorStdout = $stdoutPath
		EmulatorStderr = $stderrPath
	} | Format-List
} finally {
	if ($null -ne $emulatorProcess -and -not $emulatorProcess.HasExited) {
		& $adb -P $AdbPort -s $serial emu kill 2>$null | Out-Null
		if (-not $emulatorProcess.WaitForExit(20000)) {
			Stop-Process -Id $emulatorProcess.Id -Force -ErrorAction SilentlyContinue
		}
	}
	& $adb -P $AdbPort kill-server 2>$null | Out-Null
}
