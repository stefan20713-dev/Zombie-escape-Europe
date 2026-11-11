param(
	[string]$Version = "0.5.41",
	[string]$ApkPath = "",
	[string]$ArtifactLabel = "",
	[string]$AvdDataDirectory = "",
	[int]$AdbPort = 5039,
	[int]$EmulatorPort = 5558,
	[int]$AppStartupTimeoutSeconds = 180,
	[int]$GasHoldMilliseconds = 3200,
	[switch]$RewardedAdSmoke,
	[int]$RewardedAdTestTimeoutSeconds = 240,
	[switch]$RenderWindow
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
$environmentSdkRoot = [Environment]::GetEnvironmentVariable("ANDROID_SDK_ROOT", "Process")
$installedSdkRoot = Join-Path $env:LOCALAPPDATA "Android\Sdk"
$sdkRoot = if (-not [string]::IsNullOrWhiteSpace($environmentSdkRoot) -and (Test-Path -LiteralPath (Join-Path $environmentSdkRoot "platform-tools\adb.exe") -PathType Leaf)) {
	[System.IO.Path]::GetFullPath($environmentSdkRoot)
} else {
	$installedSdkRoot
}
$adb = Join-Path $sdkRoot "platform-tools\adb.exe"
$emulator = Join-Path $sdkRoot "emulator\emulator.exe"
$avdHome = Join-Path $projectRoot "build\android\avd"
$avdName = "ZEE_Test_API_36"
$dataDirectory = if ([string]::IsNullOrWhiteSpace($AvdDataDirectory)) {
	Join-Path $projectRoot "build\android\avd_touch_data"
} elseif ([System.IO.Path]::IsPathRooted($AvdDataDirectory)) {
	[System.IO.Path]::GetFullPath($AvdDataDirectory)
} else {
	[System.IO.Path]::GetFullPath((Join-Path $projectRoot $AvdDataDirectory))
}
$serial = "emulator-$EmulatorPort"
$package = "com.zombieescapeeurope.game"
$apk = if ([string]::IsNullOrWhiteSpace($ApkPath)) {
	Join-Path $projectRoot "build\android\Zombie_Escape_Europe-debug-$Version.apk"
} elseif ([System.IO.Path]::IsPathRooted($ApkPath)) {
	$ApkPath
} else {
	Join-Path $projectRoot $ApkPath
}
$runLabel = if ([string]::IsNullOrWhiteSpace($ArtifactLabel)) { $Version } else { $ArtifactLabel }
if ($runLabel -notmatch '^[A-Za-z0-9._-]+$') { throw "Ungültige Artefaktbezeichnung: $runLabel" }
$script:runLabel = $runLabel
$logDirectory = Join-Path $projectRoot "build\android"
$stdoutPath = Join-Path $logDirectory "touch_milestone_$runLabel.stdout.log"
$stderrPath = Join-Path $logDirectory "touch_milestone_$runLabel.stderr.log"
$logcatPath = Join-Path $logDirectory "touch_milestone_$runLabel.logcat.txt"
$emulatorProcess = $null

foreach ($requiredPath in @($adb, $emulator, $apk, (Join-Path $avdHome "$avdName.ini"))) {
	if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
		throw "Benötigte QA-Datei fehlt: $requiredPath"
	}
}

New-Item -ItemType Directory -Path $dataDirectory -Force | Out-Null

$env:ANDROID_AVD_HOME = $avdHome
$env:ANDROID_SDK_ROOT = $sdkRoot
$env:ANDROID_ADB_SERVER_PORT = [string]$AdbPort

function Invoke-ADB {
	param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Arguments)
	& $script:adb -P $script:AdbPort -s $script:serial @Arguments
	if ($LASTEXITCODE -ne 0) { throw "ADB-Befehl fehlgeschlagen: $($Arguments -join ' ')" }
}

function Save-Screenshot {
	param([string]$Name)
	$outputPath = Join-Path $script:logDirectory "touch_milestone_$script:runLabel`_$Name.png"
	$processInfo = [System.Diagnostics.ProcessStartInfo]::new()
	$processInfo.FileName = $script:adb
	$processInfo.Arguments = "-P $($script:AdbPort) -s $($script:serial) exec-out screencap -p"
	$processInfo.UseShellExecute = $false
	$processInfo.RedirectStandardOutput = $true
	$processInfo.RedirectStandardError = $true
	$screenProcess = [System.Diagnostics.Process]::new()
	$screenProcess.StartInfo = $processInfo
	if (-not $screenProcess.Start()) { throw "ADB-Screenshotprozess konnte nicht starten." }
	$outputStream = [System.IO.File]::Create($outputPath)
	$screenProcess.StandardOutput.BaseStream.CopyTo($outputStream)
	$outputStream.Dispose()
	$screenError = $screenProcess.StandardError.ReadToEnd()
	$screenProcess.WaitForExit()
	if ($screenProcess.ExitCode -ne 0) { throw "Android-Screenshot fehlgeschlagen: $screenError" }
	$imageBytes = [System.IO.File]::ReadAllBytes($outputPath)
	if ($imageBytes.Length -lt 8 -or $imageBytes[0] -ne 137 -or $imageBytes[1] -ne 80 -or $imageBytes[2] -ne 78 -or $imageBytes[3] -ne 71) {
		throw "ADB lieferte keine gültige PNG-Bilddatei für den Schritt '$Name'."
	}
	return $outputPath
}

function Get-LogcatText {
	param([int]$TailLines = 24000)
	# Some Android 16 emulator builds return an empty dump for `logcat -d -t N`
	# after the game process exits. The device ring buffer is already bounded, so
	# dump it directly and filter the resulting text in PowerShell instead.
	$lines = & $script:adb -P $script:AdbPort -s $script:serial logcat -d
	if ($LASTEXITCODE -ne 0) { throw "Logcat konnte nicht gelesen werden." }
	return ($lines | Out-String)
}

function Get-GodotLogcatText {
	param([int]$TailLines = 12000)
	$lines = & $script:adb -P $script:AdbPort -s $script:serial logcat -d -s godot:V
	if ($LASTEXITCODE -ne 0) { throw "Godot-Logcat konnte nicht gelesen werden." }
	return ($lines | Out-String)
}

function Get-LastSavedMeters {
	$telemetryText = Get-GodotLogcatText
	$savedMeters = -1.0
	foreach ($line in ($telemetryText -split '\r?\n')) {
		$match = [regex]::Match([string]$line, '\[PERF\] save_result=0 .*?meters=([0-9]+(?:\.[0-9]+)?)')
		if ($match.Success) {
			$savedMeters = [double]::Parse($match.Groups[1].Value, [System.Globalization.CultureInfo]::InvariantCulture)
		}
	}
	return $savedMeters
}

function Get-AndroidBackActionCount {
	$actions = @((Get-GodotLogcatText -TailLines 12000) -split '\r?\n' | Where-Object { $_ -match '\[PERF\] android_back_action=' })
	return $actions.Count
}

function Get-RunStartCount {
	$starts = @((Get-GodotLogcatText -TailLines 12000) -split '\r?\n' | Where-Object { $_ -match '\[PERF\] run_started_at_m=' })
	return $starts.Count
}

function Wait-RunStartedAfter {
	param([int]$PreviousCount)
	for ($attempt = 0; $attempt -lt 20; $attempt++) {
		if ((Get-RunStartCount) -gt $PreviousCount) { return }
		if ($emulatorProcess.HasExited) { throw "Der Emulator endete beim erneuten Fahrtstart nach Android-Zurück." }
		Start-Sleep -Seconds 1
	}
	throw "Nach der Rückkehr in die Garage konnte kein neuer Fahrtstart nachgewiesen werden."
}

function Start-GameActivity {
	& $script:adb -P $script:AdbPort -s $script:serial shell am start -W -n "$($script:package)/com.godot.game.GodotAppLauncher"
	if ($LASTEXITCODE -ne 0) { throw "Android konnte die Spielaktivität nicht starten." }
}

function Get-GameProcessId {
	$processOutput = & $script:adb -P $script:AdbPort -s $script:serial shell pidof $script:package 2>$null
	if ($LASTEXITCODE -ne 0) { return "" }
	$processText = ($processOutput | Out-String).Trim()
	if ([string]::IsNullOrWhiteSpace($processText)) { return "" }
	return ($processText -split '\s+')[0]
}

function Test-GodotSceneReadyForProcess {
	param([string]$ProcessId)
	if ([string]::IsNullOrWhiteSpace($ProcessId)) { return $false }
	$lines = & $script:adb -P $script:AdbPort -s $script:serial logcat -d "--pid=$ProcessId" -s godot:V
	if ($LASTEXITCODE -ne 0) { return $false }
	foreach ($line in $lines) {
		if ([string]$line -match '\[PERF\]\s*game_ready_ms=') { return $true }
	}
	return $false
}

function Get-LoadedMetersForProcess {
	param([string]$ProcessId)
	if ([string]::IsNullOrWhiteSpace($ProcessId)) { return -1.0 }
	$lines = & $script:adb -P $script:AdbPort -s $script:serial logcat -d "--pid=$ProcessId" -s godot:V
	if ($LASTEXITCODE -ne 0) { return -1.0 }
	$loadedMeters = -1.0
	foreach ($line in $lines) {
		$match = [regex]::Match([string]$line, '\[PERF\]\s*loaded_progress_m=([0-9]+(?:\.[0-9]+)?)')
		if ($match.Success) {
			$loadedMeters = [double]::Parse($match.Groups[1].Value, [System.Globalization.CultureInfo]::InvariantCulture)
		}
	}
	return $loadedMeters
}

function Get-RunFrameSamples {
	$telemetryText = Get-GodotLogcatText
	return @($telemetryText -split '\r?\n' | Where-Object { $_ -match '\[PERF\]\s*frame wall_delta=' })
}

function Wait-AndroidBackAction {
	param([string]$Action, [string]$State, [string]$Paused, [int]$PreviousCount)
	$expected = "android_back_action=$Action screen=$State paused=$Paused"
	for ($attempt = 0; $attempt -lt 15; $attempt++) {
		$actions = @((Get-GodotLogcatText -TailLines 12000) -split '\r?\n' | Where-Object { $_ -match '\[PERF\] android_back_action=' })
		$newActions = @($actions | Select-Object -Skip $PreviousCount)
		if (($newActions -join "`n") -match [regex]::Escape($expected)) { return }
		if ($emulatorProcess.HasExited) { throw "Der Emulator endete beim Testen der Android-Zurück-Taste." }
		Start-Sleep -Seconds 1
	}
	throw "Android-Zurück-Taste erreichte nicht '$expected'."
}

function Wait-TestAdConsentResolution {
	param([int]$TimeoutSeconds = 20)
	for ($attempt = 0; $attempt -lt $TimeoutSeconds; $attempt++) {
		$godotLog = Get-GodotLogcatText
		if ($godotLog -match '\[AD_QA\] consent_updated status=') {
			Write-Host "UMP-Testgeografie wurde verarbeitet; kein Consent-Tap erforderlich."
			return $true
		}
		if ($godotLog -match '\[AD_QA\] status=.*ohne Werbung weiter') { return $true }
		Start-Sleep -Seconds 1
	}
	Write-Host "UMP-Teststatus wurde nicht rechtzeitig protokolliert; der Emulatorlauf wird fortgesetzt."
	return $false
}

function Wait-TestMobileAdsInitialization {
	param([int]$TimeoutSeconds = 45)
	$lastStatusMessage = ""
	for ($attempt = 0; $attempt -lt $TimeoutSeconds; $attempt++) {
		$godotLog = Get-GodotLogcatText
		if ($godotLog -match '\[AD_QA\] mobile_ads_initialized test_units=true') {
			return $Matches[0]
		}
		if ($godotLog -match '\[AD_QA\] status=Anzeigen konnten nicht gestartet') {
			$lastStatusMessage = $Matches[0]
		}
		Start-Sleep -Seconds 1
	}
	if (-not [string]::IsNullOrWhiteSpace($lastStatusMessage)) { return $lastStatusMessage }
	return "Timeout nach $TimeoutSeconds Sekunden"
}

try {
	& $adb -P $AdbPort start-server
	if ($LASTEXITCODE -ne 0) { throw "Isolierter ADB-Server auf Port $AdbPort konnte nicht starten." }

	$emulatorArgs = @(
		"-avd", $avdName,
		"-datadir", ('"' + $dataDirectory + '"'),
		"-read-only",
		"-port", [string]$EmulatorPort,
		"-no-snapshot",
		"-no-boot-anim",
		"-gpu", "host"
	)
	if (-not $RenderWindow) { $emulatorArgs += "-no-window" }
	$emulatorProcess = Start-Process -FilePath $emulator -ArgumentList $emulatorArgs -WorkingDirectory (Split-Path -Parent $emulator) -WindowStyle Hidden -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath -PassThru

	$deviceReady = $false
	for ($attempt = 0; $attempt -lt 120; $attempt++) {
		$deviceList = & $adb -P $AdbPort devices
		if ($deviceList -match [regex]::Escape($serial) + "\s+device") {
			$deviceReady = $true
			break
		}
		if ($emulatorProcess.HasExited) { throw "Der isolierte Touch-Emulator endete vor dem ADB-Verbindungsaufbau; siehe $stderrPath" }
		Start-Sleep -Seconds 1
	}
	if (-not $deviceReady) { throw "Der isolierte Touch-Emulator wurde nicht per ADB erreichbar." }

	$booted = $false
	for ($attempt = 0; $attempt -lt 180; $attempt++) {
		$previousErrorActionPreference = $ErrorActionPreference
		$ErrorActionPreference = "Continue"
		$bootValue = & $adb -P $AdbPort -s $serial shell getprop sys.boot_completed 2>$null
		$bootCommandExit = $LASTEXITCODE
		$ErrorActionPreference = $previousErrorActionPreference
		if ($bootCommandExit -eq 0 -and ($bootValue | Out-String).Trim() -eq "1") {
			$booted = $true
			break
		}
		if ($emulatorProcess.HasExited) { throw "Der isolierte Touch-Emulator endete vor dem Android-Bootabschluss." }
		Start-Sleep -Seconds 1
	}
	if (-not $booted) { throw "Android meldete keinen abgeschlossenen Start." }

	& $adb -P $AdbPort -s $serial logcat -c
	if ($LASTEXITCODE -ne 0) { throw "Logcat konnte nicht geleert werden." }
	& $adb -P $AdbPort -s $serial install -r $apk
	if ($LASTEXITCODE -ne 0) { throw "Das Debug-APK konnte im isolierten Emulator nicht installiert werden." }
	& $adb -P $AdbPort -s $serial shell pm clear $package
	if ($LASTEXITCODE -ne 0) { throw "Das isolierte QA-App-Profil konnte nicht zurückgesetzt werden." }
	Start-Sleep -Seconds 5
	Start-GameActivity

	$sceneReady = $false
	for ($attempt = 0; $attempt -lt $AppStartupTimeoutSeconds; $attempt++) {
		if ((Get-GodotLogcatText) -match "game_ready_ms=") {
			$sceneReady = $true
			break
		}
		if ($attempt -gt 0 -and $attempt % 15 -eq 0) {
			$previousErrorActionPreference = $ErrorActionPreference
			$ErrorActionPreference = "Continue"
			$gamePid = & $adb -P $AdbPort -s $serial shell pidof $package 2>$null
			$pidCommandExit = $LASTEXITCODE
			$ErrorActionPreference = $previousErrorActionPreference
			if ($pidCommandExit -ne 0 -or [string]::IsNullOrWhiteSpace(($gamePid | Out-String).Trim())) {
				Start-GameActivity
			}
		}
		if ($emulatorProcess.HasExited) { throw "Der Emulator endete während des Spielstarts." }
		Start-Sleep -Seconds 1
	}
	if (-not $sceneReady) { throw "Die Hauptszene meldete sich nicht innerhalb von $AppStartupTimeoutSeconds Sekunden bereit." }
	if ($RewardedAdSmoke) {
		# Android shows a one-time immersive-mode confirmation above the first full-screen ad.
		# Clear it before UMP and Mobile Ads finish so it cannot cover the rewarded video.
		Invoke-ADB shell input touchscreen tap 1702 500 | Out-Null
		Start-Sleep -Milliseconds 700
	}
	$testConsentResolved = Wait-TestAdConsentResolution
	if ($testConsentResolved) { Start-Sleep -Seconds 5 }
	$initialGameProcessId = Get-GameProcessId
	if ([string]::IsNullOrWhiteSpace($initialGameProcessId)) { throw "Android meldete nach dem ersten Szenenstart keinen Spielprozess." }
	$startupGodotLog = Get-GodotLogcatText
	$consentDebugMatch = [regex]::Match($startupGodotLog, '\[AD_QA\] consent_updated status=(\d+)')
	if (-not $consentDebugMatch.Success -or [int]$consentDebugMatch.Groups[1].Value -ne 1) {
		throw "Der isolierte QA-Build hat die konfigurierte UMP-Testgeografie außerhalb des EWR nicht übernommen. $($consentDebugMatch.Value)"
	}
	$mobileAdsInitResult = Wait-TestMobileAdsInitialization
	if ($mobileAdsInitResult -notmatch '\[AD_QA\] mobile_ads_initialized test_units=true') {
		throw "Google Mobile Ads wurde nach der UMP-Testfreigabe im QA-Build nicht initialisiert: $mobileAdsInitResult"
	}
	$startupGodotLog = Get-GodotLogcatText
	$audioStartMatch = [regex]::Match($startupGodotLog, '\[AUDIO_QA\] music_started=(true|false) duration_s=([0-9.]+) crossfade_s=([0-9.]+)')
	if (-not $audioStartMatch.Success -or $audioStartMatch.Groups[1].Value -ne "true" -or [double]::Parse($audioStartMatch.Groups[2].Value, [System.Globalization.CultureInfo]::InvariantCulture) -lt 75.0 -or [double]::Parse($audioStartMatch.Groups[3].Value, [System.Globalization.CultureInfo]::InvariantCulture) -le 0.0) {
		throw "Die Android-Produktionsszene hat den Soundtrack nicht korrekt gestartet: $($audioStartMatch.Value)"
	}
	if ($RewardedAdSmoke) {
		$adShownScreenshot = ""
		$rewardResultScreenshot = ""
		$rewardResultLine = ""
		$rewardFailed = $false
		$rewardCallbackMatch = [System.Text.RegularExpressions.Match]::Empty
		$coinGrantMatch = [System.Text.RegularExpressions.Match]::Empty
		$adDismissed = $false
		$rewardDismissTouchInjected = $false
		for ($attempt = 0; $attempt -lt $RewardedAdTestTimeoutSeconds; $attempt++) {
			$qaGodotLog = Get-GodotLogcatText
			if ($qaGodotLog -match '\[QA_AD_REWARD\] AD_SHOWN' -and [string]::IsNullOrWhiteSpace($adShownScreenshot)) {
				$adShownScreenshot = Save-Screenshot "rewarded_ad_shown"
			}
			$passMatch = [regex]::Match($qaGodotLog, '(?m)^.*\[QA_AD_REWARD\] PASS .*$', [System.Text.RegularExpressions.RegexOptions]::Multiline)
			$failMatch = [regex]::Match($qaGodotLog, '(?m)^.*\[QA_AD_REWARD\] FAIL .*$', [System.Text.RegularExpressions.RegexOptions]::Multiline)
			if ($passMatch.Success) { $rewardResultLine = $passMatch.Value.Trim() }
			if ($failMatch.Success) { $rewardResultLine = $failMatch.Value.Trim(); $rewardFailed = $true; break }
			$rewardCallbackMatch = [regex]::Match($qaGodotLog, '(?m)^.*\[AD_QA\] rewarded_callback_earned run_id=(\d+) amount=(\d+).*$')
			$coinGrantMatch = [regex]::Match($qaGodotLog, '(?m)^.*\[AD_QA\] reward_grant accepted=true run_id=(\d+) amount=(\d+) money=(\d+).*$')
			if ($qaGodotLog -match '\[QA_AD_REWARD\] REWARD_CONFIRMED' -and -not $rewardDismissTouchInjected) {
				# Google test rewarded ads expose a close X only after the reward is granted.
				Invoke-ADB shell input touchscreen tap 2304 63 | Out-Null
				$rewardDismissTouchInjected = $true
			}
			$adDismissed = $qaGodotLog -match '\[AD_QA\] rewarded_ad_dismissed'
			if (-not [string]::IsNullOrWhiteSpace($rewardResultLine) -and $rewardCallbackMatch.Success -and $coinGrantMatch.Success -and $adDismissed) { break }
			if ($emulatorProcess.HasExited) { throw "Der Emulator endete während des Rewarded-Ad-Tests." }
			Start-Sleep -Seconds 1
		}
		if ([string]::IsNullOrWhiteSpace($rewardResultLine)) { throw "Die native Rewarded-Ad-Prüfung meldete innerhalb von $RewardedAdTestTimeoutSeconds Sekunden kein Ergebnis." }
		if ($rewardFailed) { throw "Die native Rewarded-Ad-Prüfung ist fehlgeschlagen: $rewardResultLine" }
		if (-not $rewardCallbackMatch.Success -or [int]$rewardCallbackMatch.Groups[2].Value -ne 500) {
			throw "Der echte Google-Testanzeigen-Reward-Callback mit 500 Münzen wurde nicht geloggt: $($rewardCallbackMatch.Value)"
		}
		if (-not $coinGrantMatch.Success -or [int]$coinGrantMatch.Groups[2].Value -ne 500 -or $coinGrantMatch.Groups[1].Value -ne $rewardCallbackMatch.Groups[1].Value) {
			throw "Der Produktions-Spielstand hat die 500 Münzen nicht für dieselbe fehlgeschlagene Fahrt gutgeschrieben: $($coinGrantMatch.Value)"
		}
		if (-not $adDismissed) { throw "Die Testanzeige wurde nach dem Reward-Callback nicht geschlossen." }
		$rewardResultScreenshot = Save-Screenshot "rewarded_ad_result"
		$godotLogcatText = Get-GodotLogcatText
		$androidLogcatText = Get-LogcatText
		[System.IO.File]::WriteAllText($logcatPath, $androidLogcatText, [System.Text.UTF8Encoding]::new($false))
		if ($androidLogcatText -match 'FATAL EXCEPTION.*com\.zombieescapeeurope\.game|ANR in com\.zombieescapeeurope\.game|Fatal signal.*com\.zombieescapeeurope\.game' -or $godotLogcatText -match 'Shader.*(error|fail)|failed to compile shader') {
			throw "Der Rewarded-Ad-Lauf hat einen Android-Absturz-, ANR- oder Shaderfehler protokolliert."
		}
		[pscustomobject]@{
			Version = $Version
			ArtifactLabel = $runLabel
			ApkPath = $apk
			Avd = $avdName
			MainSceneReady = $sceneReady
			Consent = $consentDebugMatch.Value
			MobileAds = $mobileAdsInitResult
			NativeRewardCallback = $rewardCallbackMatch.Value.Trim()
			ProductionCoinGrant = $coinGrantMatch.Value.Trim()
			RewardedAdDismissed = $adDismissed
			RewardDismissTouchInjected = $rewardDismissTouchInjected
			Result = $rewardResultLine
			AdShownScreenshot = $adShownScreenshot
			RewardResultScreenshot = $rewardResultScreenshot
			Logcat = $logcatPath
			EmulatorStdout = $stdoutPath
			EmulatorStderr = $stderrPath
		} | Format-List
		return
	}
	$startupScreenshot = Save-Screenshot "tutorial"

	# Android at 1080x2400 runs the 1600x720 game viewport at 1.5x.
	# Dismiss the first-run tutorial and enter the garage's primary action.
	Invoke-ADB shell input touchscreen tap 674 839 | Out-Null
	Start-Sleep -Seconds 2
	# A one-time Android immersive-mode confirmation can appear after the game
	# enters full screen. Dismiss it from the noninteractive garage center before
	# testing archive touch or the platform Back request.
	Invoke-ADB shell input touchscreen tap 1702 500 | Out-Null
	Start-Sleep -Milliseconds 700
	$garageScreenshot = Save-Screenshot "garage"
	# The current garage places the archive inside the gear/settings panel.
	# Open that panel first, then capture the archive after its real touch action.
	Invoke-ADB shell input touchscreen tap 2343 59 | Out-Null
	Start-Sleep -Milliseconds 700
	$settingsScreenshot = Save-Screenshot "garage_settings"
	$settingsTouchLog = Get-GodotLogcatText
	if ($settingsTouchLog -notmatch '\[PERF\] touch_hit=garage_settings_toggle') {
		throw "Das Werkstatt-Zahnrad reagierte nicht auf den Android-Touch."
	}
	Invoke-ADB shell input touchscreen tap 2235 495 | Out-Null
	Start-Sleep -Seconds 2
	$archiveScreenshot = Save-Screenshot "archive"
	$archiveTouchLog = Get-GodotLogcatText
	if ($archiveTouchLog -notmatch '\[PERF\] touch_hit=archive_open') {
		throw "Das Funkarchiv reagierte in der Android-Garage nicht auf den Touch-Eingabepunkt."
	}
	$archiveBackActionCount = Get-AndroidBackActionCount
	Invoke-ADB shell input keyevent KEYCODE_BACK | Out-Null
	Wait-AndroidBackAction -Action "archive_close" -State "GARAGE" -Paused "false" -PreviousCount $archiveBackActionCount
	Start-Sleep -Seconds 1
	$archiveBackScreenshot = Save-Screenshot "archive_back_garage"
	# Select the motor category, then press its separate upgrade action in the
	# right-side detail panel before starting the run.
	Invoke-ADB shell input touchscreen tap 150 1000 | Out-Null
	Start-Sleep -Milliseconds 700
	Invoke-ADB shell input touchscreen tap 2100 795 | Out-Null
	Start-Sleep -Seconds 2
	$firstUpgradeLog = Get-GodotLogcatText
	$firstUpgradeScreenshot = Save-Screenshot "first_upgrade"
	if ($firstUpgradeLog -notmatch '\[PERF\] touch_hit=garage_part:engine' -or $firstUpgradeLog -notmatch '\[PERF\] touch_hit=upgrade') {
		throw "Das Motor-Upgrade reagierte in der Android-Garage nicht auf den echten Touch."
	}
	Invoke-ADB shell input touchscreen tap 2202 930 | Out-Null
	Start-Sleep -Seconds 2
	$runScreenshot = Save-Screenshot "run"
	# Android may show a one-time immersive-mode confirmation that intercepts
	# controls near the top edge. A neutral center tap dismisses it if present.
	Invoke-ADB shell input touchscreen tap 1702 500 | Out-Null
	Start-Sleep -Milliseconds 700
	$runReadyScreenshot = Save-Screenshot "run_ready"

	# Hold each native Android touch control long enough for press, held state,
	# and release to pass through Godot's InputEventScreenTouch path. A cold
	# Android 16 AVD can spend over a second between rendered frames, so keep
	# each control down across multiple frames and let input dispatch settle.
	Invoke-ADB shell input touchscreen swipe 2247 927 2247 927 $GasHoldMilliseconds | Out-Null
	Start-Sleep -Milliseconds 300
	$gasScreenshot = Save-Screenshot "gas"
	$frameSamples = Get-RunFrameSamples
	$performanceDiagnosticsPath = Join-Path $logDirectory "touch_milestone_$runLabel`_performance.txt"
	[System.IO.File]::WriteAllLines($performanceDiagnosticsPath, [string[]]$frameSamples, [System.Text.UTF8Encoding]::new($false))
	Invoke-ADB shell input touchscreen swipe 2072 950 2072 950 1600 | Out-Null
	Start-Sleep -Milliseconds 400
	Invoke-ADB shell input touchscreen swipe 2079 804 2079 804 1600 | Out-Null
	Start-Sleep -Milliseconds 400
	Invoke-ADB shell input touchscreen swipe 129 951 129 951 1600 | Out-Null
	Start-Sleep -Milliseconds 400
	Invoke-ADB shell input touchscreen swipe 288 951 288 951 1600 | Out-Null
	Start-Sleep -Milliseconds 400
	Invoke-ADB shell input touchscreen tap 1685 104 | Out-Null
	Start-Sleep -Seconds 1
	$pauseScreenshot = Save-Screenshot "pause"
	# The pause panel is centered in the 1600x720 viewport, rendered at 1.5x on
	# this 2400x1080 AVD. Drag the separate music slider and verify the save marker.
	Invoke-ADB shell input touchscreen swipe 1200 507 1120 507 3200 | Out-Null
	Start-Sleep -Seconds 2
	$pauseMusicVolumeScreenshot = Save-Screenshot "pause_music_volume"
	$musicSettingsLog = Get-GodotLogcatText
	if ($musicSettingsLog -notmatch '\[PERF\] touch_hit=music_volume_slider' -or $musicSettingsLog -notmatch '\[AUDIO_SETTINGS_QA\] music_volume=[0-9.]+ persisted=true') {
		throw "Die Android-Pause hat den Musikregler nicht per Touch geändert und gespeichert."
	}
	Invoke-ADB shell input touchscreen tap 1200 744 | Out-Null
	Start-Sleep -Seconds 1
	$resumeScreenshot = Save-Screenshot "resume"

	# Native Android Back pauses the live run, then returns the paused run to the garage.
	$backActionCount = Get-AndroidBackActionCount
	Invoke-ADB shell input keyevent KEYCODE_BACK | Out-Null
	Wait-AndroidBackAction -Action "pause" -State "RUN" -Paused "true" -PreviousCount $backActionCount
	Start-Sleep -Seconds 1
	$systemBackPauseScreenshot = Save-Screenshot "system_back_pause"
	if ([string]::IsNullOrWhiteSpace((Get-GameProcessId))) { throw "Eine einzelne Android-Zurück-Aktion hat die laufende App unerwartet beendet." }
	$backActionCount = Get-AndroidBackActionCount
	Invoke-ADB shell input keyevent KEYCODE_BACK | Out-Null
	Wait-AndroidBackAction -Action "garage" -State "GARAGE" -Paused "false" -PreviousCount $backActionCount
	# The API-36 headless AVD renders below 1 FPS under test load. Allow the
	# garage transition to reach a rendered frame before taking the screenshot
	# or tapping its start button.
	Start-Sleep -Seconds 5
	$systemBackGarageScreenshot = Save-Screenshot "system_back_garage"
	if ([string]::IsNullOrWhiteSpace((Get-GameProcessId))) { throw "Die Rückkehr zur Garage hat die App unerwartet beendet." }

	# Prove the player can immediately resume the campaign after using system Back.
	$runStartCount = Get-RunStartCount
	Invoke-ADB shell input touchscreen tap 2202 930 | Out-Null
	Wait-RunStartedAfter -PreviousCount $runStartCount

	# Let the restarted run advance under gas, interrupt the app, then verify its private save
	# and launch it from a cold process. Only the disposable AVD profile is used.
	Invoke-ADB shell input touchscreen swipe 2247 927 2247 927 2200 | Out-Null
	$preInterruptionMeters = Get-LastSavedMeters
	& $adb -P $AdbPort -s $serial shell input keyevent KEYCODE_HOME | Out-Null
	Start-Sleep -Seconds 3
	$godotTextAfterPause = Get-GodotLogcatText
	$saveMarkers = @($godotTextAfterPause -split '\r?\n' | Where-Object { $_ -match '\[PERF\] save_result=' })
	$saveDiagnosticsPath = Join-Path $logDirectory "touch_milestone_$runLabel`_save_diagnostics.txt"
	[System.IO.File]::WriteAllLines($saveDiagnosticsPath, [string[]]$saveMarkers, [System.Text.UTF8Encoding]::new($false))
	$savedMeters = Get-LastSavedMeters
	if ($savedMeters -le 0.0) {
		throw "Der Spielstand enthält nach der Android-Unterbrechung keine positive Fahrstrecke. Speicherdiagnose: $saveDiagnosticsPath. Marker: $($saveMarkers -join '; ')"
	}
	if ($savedMeters + 0.1 -lt $preInterruptionMeters) { throw "Der gespeicherte Streckenstand ist nach der Android-Unterbrechung zurückgesprungen." }
	& $adb -P $AdbPort -s $serial shell am force-stop $package
	if ($LASTEXITCODE -ne 0) { throw "Das Spiel konnte für den Kaltstart nicht beendet werden." }
	Start-GameActivity
	$coldGameProcessId = ""
	$coldRelaunchReady = $false
	for ($attempt = 0; $attempt -lt $AppStartupTimeoutSeconds; $attempt++) {
		$candidateProcessId = Get-GameProcessId
		if (-not [string]::IsNullOrWhiteSpace($candidateProcessId) -and $candidateProcessId -ne $initialGameProcessId) {
			$coldGameProcessId = $candidateProcessId
			if (Test-GodotSceneReadyForProcess $coldGameProcessId) {
				$coldRelaunchReady = $true
				break
			}
		}
		if ($attempt -gt 0 -and $attempt % 15 -eq 0 -and [string]::IsNullOrWhiteSpace($candidateProcessId)) {
			Start-GameActivity
		}
		if ($emulatorProcess.HasExited) { throw "Der Emulator endete während des Kaltstarts." }
		Start-Sleep -Seconds 1
	}
	if (-not $coldRelaunchReady) {
		throw "Die Hauptszene wurde nach dem Kaltstart nicht in einem neuen Godot-Prozess bereit. Vorher=$initialGameProcessId, Neu=$coldGameProcessId"
	}
	$restoredMeters = -1.0
	for ($attempt = 0; $attempt -lt 10 -and $restoredMeters -lt 0.0; $attempt++) {
		$restoredMeters = Get-LoadedMetersForProcess $coldGameProcessId
		if ($restoredMeters -lt 0.0) { Start-Sleep -Milliseconds 500 }
	}
	if ($restoredMeters -le 0.0 -or $restoredMeters + 0.1 -lt $savedMeters) {
		$coldGodotLog = & $script:adb -P $script:AdbPort -s $script:serial logcat -d "--pid=$coldGameProcessId" -s godot:V
		$coldDiagnosticsPath = Join-Path $logDirectory "touch_milestone_$runLabel`_cold_start_diagnostics.txt"
		[System.IO.File]::WriteAllLines($coldDiagnosticsPath, [string[]]$coldGodotLog, [System.Text.UTF8Encoding]::new($false))
		throw "Die Fortschrittsprüfung nach Kaltstart blieb uneindeutig. Gespeichert=$savedMeters m, geladene Telemetrie=$restoredMeters m. Prozessbezogene Godot-Logs: $coldDiagnosticsPath"
	}
	$reloadedSettingsLog = Get-GodotLogcatText
	$savedMusicMatches = [regex]::Matches($musicSettingsLog, '\[AUDIO_SETTINGS_QA\] music_volume=([0-9.]+) persisted=true')
	$loadedMusicMatches = [regex]::Matches($reloadedSettingsLog, '\[AUDIO_SETTINGS_QA\] loaded_music_volume=([0-9.]+)')
	if ($savedMusicMatches.Count -lt 1 -or $loadedMusicMatches.Count -lt 1) { throw "Der Kaltstart hat die gespeicherte Musiklautstärke nicht protokolliert." }
	$savedMusicVolume = [double]::Parse($savedMusicMatches[$savedMusicMatches.Count - 1].Groups[1].Value, [System.Globalization.CultureInfo]::InvariantCulture)
	$restoredMusicVolume = [double]::Parse($loadedMusicMatches[$loadedMusicMatches.Count - 1].Groups[1].Value, [System.Globalization.CultureInfo]::InvariantCulture)
	if ([Math]::Abs($savedMusicVolume - $restoredMusicVolume) -gt 0.01) {
		throw "Die Musiklautstärke wurde nach dem Kaltstart nicht wiederhergestellt. Gespeichert=$savedMusicVolume, geladen=$restoredMusicVolume."
	}
	$restoredScreenshot = Save-Screenshot "restored"
	$backActionCount = Get-AndroidBackActionCount
	Invoke-ADB shell input keyevent KEYCODE_BACK | Out-Null
	Wait-AndroidBackAction -Action "quit" -State "GARAGE" -Paused "false" -PreviousCount $backActionCount
	$gameExitedFromGarage = $false
	for ($attempt = 0; $attempt -lt 15; $attempt++) {
		if ([string]::IsNullOrWhiteSpace((Get-GameProcessId))) { $gameExitedFromGarage = $true; break }
		Start-Sleep -Seconds 1
	}
	if (-not $gameExitedFromGarage) { throw "Android-Zurück in der Garage hat das Spiel nicht beendet." }
	$logText = Get-LogcatText
	[System.IO.File]::WriteAllText($logcatPath, $logText, [System.Text.UTF8Encoding]::new($false))

	$expectedTouches = @("archive_open", "garage_part:engine", "upgrade", "accelerate", "brake", "boost", "tilt_left", "tilt_right", "pause_open", "music_volume_slider", "pause_resume")
	$missingTouches = @($expectedTouches | Where-Object { $logText -notmatch [regex]::Escape("touch_hit=$_") })
	# Prefer the explicit start marker, but also accept the recurring game-state
	# telemetry as proof that the run scene became active. Android's small AVD
	# logcat ring can drop early startup lines while retaining later touch input.
	if ($logText -notmatch "run_started_at_m=" -and $logText -notmatch "screen=RUN") {
		throw "Die Starttaste hat keinen Lauf ausgelöst; weder Startmarker noch RUN-Zustand im Logcat."
	}
	if ($missingTouches.Count -gt 0) { throw "Nicht erkannte Android-Touchaktionen: $($missingTouches -join ', ')" }
	if ($logText -notmatch "action_pressed=accelerate" -or $logText -notmatch "touch_up=.*action=accelerate") { throw "Gas wurde nicht als gehaltene und anschließend freigegebene Touchaktion erkannt." }
	if ($initialGameProcessId -eq $coldGameProcessId) { throw "Der Kaltstart hat keine neue Android-Prozess-ID erzeugt." }
	if ($logText -match "\bANR in $([regex]::Escape($package))|Fatal signal|SIGSEGV|shader failed to compile|Program linking failed") {
		throw "Logcat enthält einen Absturz, ANR oder Shaderfehler."
	}

	[pscustomobject]@{
		Version = $Version
		ArtifactLabel = $runLabel
		ApkPath = $apk
		Avd = $avdName
		AvdProfile = "separates beschreibbares Datadir; vorhandene AVD-Definition schreibgeschützt"
		Booted = $booted
		MainSceneReady = $sceneReady
		AudioSystem = $audioStartMatch.Value.Trim()
		InitialGameProcessId = $initialGameProcessId
		RunStarted = $true
		RecognizedTouchActions = ($expectedTouches -join ", ")
		GasHeldAndReleased = $true
		SavedDistanceMeters = $savedMeters
		SavedDistanceBeforeInterruptionMeters = $preInterruptionMeters
		RestoredDistanceMeters = $restoredMeters
		SaveDiagnostics = $saveDiagnosticsPath
		PerformanceDiagnostics = $performanceDiagnosticsPath
		FrameSampleCount = $frameSamples.Count
		ColdRelaunch = $true
		ColdGameProcessId = $coldGameProcessId
		ScreenshotTutorial = $startupScreenshot
		ScreenshotGarage = $garageScreenshot
		ScreenshotArchive = $archiveScreenshot
		ScreenshotArchiveBackToGarage = $archiveBackScreenshot
		ScreenshotFirstUpgrade = $firstUpgradeScreenshot
		ArchiveTouchAndSystemBack = $true
		ScreenshotRun = $runScreenshot
		ScreenshotRunAfterSystemConfirmation = $runReadyScreenshot
		ScreenshotGas = $gasScreenshot
		ScreenshotPause = $pauseScreenshot
		ScreenshotMusicVolume = $pauseMusicVolumeScreenshot
		ScreenshotResume = $resumeScreenshot
		MusicVolumeSavedAndRestored = $true
		MusicVolumeAfterColdStart = $restoredMusicVolume
		SystemBackPausedRun = $true
		SystemBackReturnedToGarage = $true
		SystemBackExitedFromGarage = $gameExitedFromGarage
		ScreenshotSystemBackPause = $systemBackPauseScreenshot
		ScreenshotSystemBackGarage = $systemBackGarageScreenshot
		ScreenshotRestored = $restoredScreenshot
		Logcat = $logcatPath
		EmulatorStdout = $stdoutPath
		EmulatorStderr = $stderrPath
	} | Format-List
} finally {
	if ($null -ne $emulatorProcess -and -not $emulatorProcess.HasExited) {
		try {
			[System.IO.File]::WriteAllText($logcatPath, (Get-LogcatText), [System.Text.UTF8Encoding]::new($false))
		} catch {
			# Preserve the original test error if the emulator has already disconnected.
		}
		& $adb -P $AdbPort -s $serial emu kill 2>$null | Out-Null
		if (-not $emulatorProcess.WaitForExit(20000)) {
			Stop-Process -Id $emulatorProcess.Id -Force -ErrorAction SilentlyContinue
		}
	}
	& $adb -P $AdbPort kill-server 2>$null | Out-Null
}
