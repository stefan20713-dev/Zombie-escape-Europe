param(
	[string]$GodotExecutable = "",
	[string]$OutputPath = "",
	[string]$MainSceneOverride = "",
	[ValidateSet("arm64-v8a", "x86_64")][string]$ReleaseArchitecture = "arm64-v8a",
	[switch]$DebugOnly
)

$ErrorActionPreference = "Stop"
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$projectConfig = Join-Path $projectRoot "project.godot"
$presetConfig = Join-Path $projectRoot "export_presets.cfg"
$defaultGodot = Join-Path $projectRoot ".android_setup\GodotPortable\Godot_v4.7.2-stable_win64.exe"
$editorSettings = Join-Path $projectRoot ".android_setup\GodotPortable\editor_data\editor_settings-4.7.tres"
$qaKeystore = Join-Path $projectRoot ".android_setup\debug.keystore"
$javaHome = Join-Path $projectRoot "build\android\jbr_local_0.4.35"
$gradleUserHome = Join-Path $projectRoot "build\android\gradle_user_home"
$installedSdkRoot = Join-Path $env:LOCALAPPDATA "Android\Sdk"
$portableQaSdkRoot = Join-Path $projectRoot "build\android\sdk_local_0.4.35"
$sdkRoot = if (Test-Path -LiteralPath (Join-Path $installedSdkRoot "build-tools\36.1.0") -PathType Container) {
	$installedSdkRoot
} elseif (Test-Path -LiteralPath (Join-Path $portableQaSdkRoot "build-tools") -PathType Container) {
	$portableQaSdkRoot
} else {
	$installedSdkRoot
}

$versionMatch = Select-String -LiteralPath $projectConfig -Pattern '^config/version="([^"]+)"$'
if (-not $versionMatch) { throw "Die Spielversion wurde in project.godot nicht gefunden." }
$versionName = $versionMatch.Matches[0].Groups[1].Value
$versionCodeMatch = Select-String -LiteralPath $presetConfig -Pattern '^version/code=([0-9]+)$' | Select-Object -First 1
if (-not $versionCodeMatch) { throw "Der Android-Versionscode wurde im Exportprofil nicht gefunden." }
$versionCode = [int]$versionCodeMatch.Matches[0].Groups[1].Value
$presetText = [System.IO.File]::ReadAllText($presetConfig)
$qaPresetHeader = [regex]::Match($presetText, '(?s)\[preset\.0\](.*?)\[preset\.0\.options\]')
$storePresetHeader = [regex]::Match($presetText, '(?s)\[preset\.1\](.*?)\[preset\.1\.options\]')
if (-not $qaPresetHeader.Success -or $qaPresetHeader.Groups[1].Value -notmatch 'custom_features="qa_release"') {
	throw "Das Android-Testprofil muss das qa_release-Merkmal für Release-Telemetrie aktivieren."
}
if (-not $storePresetHeader.Success -or $storePresetHeader.Groups[1].Value -notmatch 'custom_features=""') {
	throw "Das Play-Store-Profil muss frei von QA-Diagnosemerkmalen bleiben."
}

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
	$outputName = if ($DebugOnly) {
		if ([string]::IsNullOrWhiteSpace($MainSceneOverride)) { "Zombie_Escape_Europe-debug-only-$versionName.apk" } else { "Zombie_Escape_Europe-ramp-qa-debug-only-$versionName.apk" }
	} elseif ([string]::IsNullOrWhiteSpace($MainSceneOverride)) {
		"Zombie_Escape_Europe-qa-release-$versionName.apk"
	} else {
		"Zombie_Escape_Europe-qa-ramp-$versionName.apk"
	}
	$outputPath = Join-Path $projectRoot "build\android\$outputName"
} elseif ([System.IO.Path]::IsPathRooted($OutputPath)) {
	$outputPath = $OutputPath
} else {
	$outputPath = Join-Path $projectRoot $OutputPath
}
$outputPath = [System.IO.Path]::GetFullPath($outputPath)
$debugName = if ([string]::IsNullOrWhiteSpace($MainSceneOverride)) {
	"Zombie_Escape_Europe-debug-$versionName.apk"
} else {
	"Zombie_Escape_Europe-ramp-qa-debug-$versionName.apk"
}
$debugApk = if ($DebugOnly) { $outputPath } else { Join-Path $projectRoot "build\android\$debugName" }

$godotPath = $defaultGodot
if (-not [string]::IsNullOrWhiteSpace($GodotExecutable)) {
	$godotPath = (Resolve-Path -LiteralPath $GodotExecutable).Path
}
$godotExportRuntime = Join-Path $projectRoot "build\android\godot_qa_export_runtime"
$godotPortableMarker = Join-Path (Split-Path -Parent $godotPath) "_sc_"
$usePortableGodotData = Test-Path -LiteralPath $godotPortableMarker -PathType Leaf
$requiredPaths = @($godotPath, $editorSettings, $javaHome, $sdkRoot)
if (-not $DebugOnly) { $requiredPaths += $qaKeystore }
foreach ($requiredPath in $requiredPaths) {
	if (-not (Test-Path -LiteralPath $requiredPath)) { throw "Benötigte Android-QA-Datei fehlt: $requiredPath" }
}

$buildToolsRoot = Join-Path $sdkRoot "build-tools"
$buildTools = Get-ChildItem -LiteralPath $buildToolsRoot -Directory | Sort-Object { [version]($_.Name -replace '-.*$', '') } -Descending | Select-Object -First 1
if (-not $buildTools) { throw "Android build-tools wurden nicht gefunden: $buildToolsRoot" }
$aapt = Join-Path $buildTools.FullName "aapt.exe"
$apksigner = Join-Path $buildTools.FullName "apksigner.bat"
$zipalign = Join-Path $buildTools.FullName "zipalign.exe"
foreach ($toolPath in @($aapt, $apksigner, $zipalign)) {
	if (-not (Test-Path -LiteralPath $toolPath -PathType Leaf)) { throw "Android-Prüfwerkzeug fehlt: $toolPath" }
}

$exportRunRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("zombie_escape_europe_qa_release_{0}_{1}" -f $versionName, (Get-Date -Format "yyyyMMdd_HHmmss_fff"))
$exportProjectRoot = Join-Path $exportRunRoot "project"
$exportAppData = Join-Path $exportRunRoot "Roaming"
$exportLocalAppData = Join-Path $exportRunRoot "Local"
$godotConfigDirectory = if ($usePortableGodotData) {
	Join-Path $godotExportRuntime "editor_data"
} else {
	Join-Path $exportAppData "Godot"
}
New-Item -ItemType Directory -Path $godotConfigDirectory, $exportLocalAppData, $exportProjectRoot, (Split-Path -Parent $outputPath), $gradleUserHome -Force | Out-Null
foreach ($rootFile in @("project.godot", "export_presets.cfg")) {
	Copy-Item -LiteralPath (Join-Path $projectRoot $rootFile) -Destination (Join-Path $exportProjectRoot $rootFile) -Force
}
if (-not [string]::IsNullOrWhiteSpace($MainSceneOverride)) {
	if ($MainSceneOverride -notmatch '^res://[A-Za-z0-9_./-]+\.tscn$') {
		throw "Der Szenenpfad muss ein projektinterner res://-Pfad zu einer .tscn-Datei sein: $MainSceneOverride"
	}
	$relativeScenePath = $MainSceneOverride.Substring(6).Replace("/", "\")
	$scenePath = Join-Path $projectRoot $relativeScenePath
	if (-not (Test-Path -LiteralPath $scenePath -PathType Leaf)) { throw "Die Android-QA-Hauptszene wurde nicht gefunden: $scenePath" }
	$exportProjectConfig = Join-Path $exportProjectRoot "project.godot"
	$exportProjectText = [System.IO.File]::ReadAllText($exportProjectConfig)
	$mainSceneSetting = '(?m)^run/main_scene="[^"]+"$'
	if ($exportProjectText -notmatch $mainSceneSetting) { throw "Die kopierte Projektdatei enthält keine run/main_scene-Einstellung." }
	$exportProjectText = [regex]::Replace($exportProjectText, $mainSceneSetting, ('run/main_scene="' + $MainSceneOverride + '"'))
	[System.IO.File]::WriteAllText($exportProjectConfig, $exportProjectText)
}
foreach ($directoryName in @("addons", "android", "assets", "scenes", "scripts")) {
	$sourceDirectory = Join-Path $projectRoot $directoryName
	if (Test-Path -LiteralPath $sourceDirectory -PathType Container) {
		Copy-Item -LiteralPath $sourceDirectory -Destination (Join-Path $exportProjectRoot $directoryName) -Recurse -Force
	}
}
# The Android export does not use the AdMob iOS XCFrameworks. Omitting them
# also keeps Godot's initial scan below Windows' path-length limit in this
# isolated temporary project; the complete plugin remains in the source tree.
$iosFrameworkCopy = [System.IO.Path]::GetFullPath((Join-Path $exportProjectRoot "addons\admob\ios"))
$exportRootPrefix = [System.IO.Path]::GetFullPath($exportProjectRoot).TrimEnd([System.IO.Path]::DirectorySeparatorChar) + [System.IO.Path]::DirectorySeparatorChar
if ($iosFrameworkCopy.StartsWith($exportRootPrefix, [System.StringComparison]::OrdinalIgnoreCase) -and (Test-Path -LiteralPath $iosFrameworkCopy -PathType Container)) {
	Remove-Item -LiteralPath $iosFrameworkCopy -Recurse -Force
}
$exportEditorSettings = Join-Path $godotConfigDirectory "editor_settings-4.7.tres"
Copy-Item -LiteralPath $editorSettings -Destination $exportEditorSettings -Force
$settingsText = [System.IO.File]::ReadAllText($exportEditorSettings)
$javaSettingsPath = $javaHome.Replace("\", "/")
$sdkSettingsPath = $sdkRoot.Replace("\", "/")
$settingsText = [regex]::Replace($settingsText, '(?m)^export/android/java_sdk_path = .*$', ('export/android/java_sdk_path = "' + $javaSettingsPath + '"'))
$settingsText = [regex]::Replace($settingsText, '(?m)^export/android/android_sdk_path = .*$', ('export/android/android_sdk_path = "' + $sdkSettingsPath + '"'))
$safeSaveSetting = 'filesystem/on_save/safe_save_on_backup_then_rename'
if ($settingsText -match ('(?m)^' + [regex]::Escape($safeSaveSetting) + ' = ')) {
	$settingsText = [regex]::Replace($settingsText, '(?m)^' + [regex]::Escape($safeSaveSetting) + ' = .*$', ($safeSaveSetting + ' = false'))
} else {
	$settingsText += "`n$safeSaveSetting = false`n"
}
[System.IO.File]::WriteAllText($exportEditorSettings, $settingsText)

# Run a Godot copy with isolated editor data. Portable installations need their
# `_sc_` marker beside the executable; without it, Godot ignores `editor_data`
# and the SDK settings copied there.
New-Item -ItemType Directory -Path $godotExportRuntime -Force | Out-Null
$godotExportPath = Join-Path $godotExportRuntime (Split-Path -Leaf $godotPath)
if (-not (Test-Path -LiteralPath $godotExportPath -PathType Leaf) -or (Get-Item -LiteralPath $godotExportPath).Length -ne (Get-Item -LiteralPath $godotPath).Length) {
	Copy-Item -LiteralPath $godotPath -Destination $godotExportPath -Force
}
if ($usePortableGodotData -and -not (Test-Path -LiteralPath (Join-Path $godotExportRuntime "_sc_") -PathType Leaf)) {
	Copy-Item -LiteralPath $godotPortableMarker -Destination (Join-Path $godotExportRuntime "_sc_") -Force
}
$templateSource = Join-Path (Split-Path -Parent $godotPath) "editor_data\export_templates"
if (-not (Test-Path -LiteralPath $templateSource -PathType Container)) {
	$templateSource = Join-Path (Split-Path -Parent $editorSettings) "export_templates"
}
if (-not (Test-Path -LiteralPath $templateSource -PathType Container)) { throw "Godot-Android-Exportvorlagen wurden nicht gefunden: $templateSource" }
$templateDestination = Join-Path $godotConfigDirectory "export_templates"
Get-ChildItem -LiteralPath $templateSource -Directory | ForEach-Object {
	$destinationVersion = Join-Path $templateDestination $_.Name
	if (-not (Test-Path -LiteralPath $destinationVersion -PathType Container)) {
		Copy-Item -LiteralPath $_.FullName -Destination $destinationVersion -Recurse -Force
	}
}

$stdoutPath = Join-Path $projectRoot "build\android\release-qa-$versionName.stdout.log"
$stderrPath = Join-Path $projectRoot "build\android\release-qa-$versionName.stderr.log"
$debugStdoutPath = Join-Path $projectRoot "build\android\debug-qa-$versionName.stdout.log"
$debugStderrPath = Join-Path $projectRoot "build\android\debug-qa-$versionName.stderr.log"
$environmentNames = @(
	"APPDATA", "LOCALAPPDATA", "ANDROID_SDK_ROOT", "GRADLE_USER_HOME", "GRADLE_RO_DEP_CACHE", "JAVA_HOME"
)
if (-not $DebugOnly) {
	$environmentNames += @("GODOT_ANDROID_KEYSTORE_RELEASE_PATH", "GODOT_ANDROID_KEYSTORE_RELEASE_USER", "GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD")
}
$previousEnvironment = @{}
foreach ($name in $environmentNames) { $previousEnvironment[$name] = [Environment]::GetEnvironmentVariable($name, "Process") }
$qaSecurePassword = $null
if (-not $DebugOnly) {
	# Read locally as a masked SecureString; never store the QA password in this project.
	$qaSecurePassword = Read-Host "Passwort des lokalen QA-Keystores (Eingabe bleibt verborgen)" -AsSecureString
	if ($qaSecurePassword.Length -le 0) { throw "Das QA-Keystore-Passwort darf nicht leer sein." }
}
$qaPasswordPointer = [IntPtr]::Zero
$qaPasswordPlain = $null
$exportStartedUtc = [DateTime]::UtcNow

try {
	$env:APPDATA = $exportAppData
	$env:LOCALAPPDATA = $exportLocalAppData
	$env:ANDROID_SDK_ROOT = $sdkRoot
	$env:GRADLE_USER_HOME = $gradleUserHome
	$env:GRADLE_RO_DEP_CACHE = Join-Path $env:USERPROFILE ".gradle\caches"
	$env:JAVA_HOME = $javaHome
	if (-not $DebugOnly) {
		# This QA release build uses the local Godot debug key, never the Play-Store upload key.
		$env:GODOT_ANDROID_KEYSTORE_RELEASE_PATH = $qaKeystore
		$env:GODOT_ANDROID_KEYSTORE_RELEASE_USER = "androiddebugkey"
		$qaPasswordPointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($qaSecurePassword)
		$qaPasswordPlain = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($qaPasswordPointer)
		$env:GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD = $qaPasswordPlain
	}
	$debugArguments = @(
		"--headless",
		"--path",
		('"' + $exportProjectRoot + '"'),
		"--export-debug",
		'"Android"',
		('"' + $debugApk + '"')
	) -join " "
	$debugProcess = Start-Process -FilePath $godotExportPath -ArgumentList $debugArguments -WorkingDirectory $exportProjectRoot -RedirectStandardOutput $debugStdoutPath -RedirectStandardError $debugStderrPath -PassThru -WindowStyle Hidden
	if (-not $debugProcess.WaitForExit(900000)) { $debugProcess.Kill(); throw "Godot-Debug-APK-Export dauerte länger als 15 Minuten." }
	$debugExitCode = $debugProcess.ExitCode
	$debugProcess.Dispose()
	if ($debugExitCode -ne 0) {
		Get-Content -LiteralPath $debugStdoutPath -ErrorAction SilentlyContinue
		Get-Content -LiteralPath $debugStderrPath -ErrorAction SilentlyContinue
		throw "Godot-Debug-APK-Export endete mit Exitcode $debugExitCode."
	}
	if ($DebugOnly) {
		if (-not (Test-Path -LiteralPath $debugApk -PathType Leaf)) { throw "Godot meldete Erfolg, aber das Debug-APK fehlt: $debugApk" }
		$debugApkItem = Get-Item -LiteralPath $debugApk
		if ($debugApkItem.LastWriteTimeUtc -lt $exportStartedUtc) { throw "Das Debug-APK wurde während dieses Exportlaufs nicht aktualisiert." }
		$debugBadging = & $aapt dump badging $debugApk 2>&1
		if ($LASTEXITCODE -ne 0) { throw "aapt konnte das Debug-APK nicht lesen: $($debugBadging -join "`n")" }
		$debugBadgingText = $debugBadging -join "`n"
		if ($debugBadgingText -notmatch "package: name='com\.zombieescapeeurope\.game' versionCode='$versionCode' versionName='$([regex]::Escape($versionName))'") {
			throw "Paketkennung oder Versionsdaten des Debug-APKs stimmen nicht."
		}
		if ($debugBadgingText -notmatch "sdkVersion:'28'" -or $debugBadgingText -notmatch "targetSdkVersion:'36'" -or $debugBadgingText -notmatch "application-debuggable") {
			throw "Debuggable-Merkmal, Mindest-API oder Ziel-API des Debug-APKs sind unerwartet."
		}

		$previousJavaHome = [Environment]::GetEnvironmentVariable("JAVA_HOME", "Process")
		$previousPath = [Environment]::GetEnvironmentVariable("PATH", "Process")
		try {
			$env:JAVA_HOME = $javaHome
			$env:PATH = (Join-Path $javaHome "bin") + ";" + $env:PATH
			$debugSignature = & $apksigner verify --verbose --print-certs $debugApk 2>&1
			$debugSignatureExitCode = $LASTEXITCODE
		} finally {
			[Environment]::SetEnvironmentVariable("JAVA_HOME", $previousJavaHome, "Process")
			[Environment]::SetEnvironmentVariable("PATH", $previousPath, "Process")
		}
		if ($debugSignatureExitCode -ne 0) { throw "Die Debug-APK-Signatur konnte nicht verifiziert werden: $($debugSignature -join "`n")" }
		$debugAlignment = & $zipalign -c -P 16 4 $debugApk 2>&1
		if ($LASTEXITCODE -ne 0) { throw "Die 16-KB-Ausrichtung des Debug-APKs ist fehlgeschlagen: $($debugAlignment -join "`n")" }

		Add-Type -AssemblyName System.IO.Compression.FileSystem
		$debugArchive = [System.IO.Compression.ZipFile]::OpenRead($debugApk)
		try {
			$debugAbis = @($debugArchive.Entries | Where-Object { $_.FullName -match '^lib/[^/]+/libgodot_android\.so$' } | ForEach-Object { $_.FullName.Split('/')[1] } | Sort-Object -Unique)
			if (-not $debugAbis.Contains("arm64-v8a") -or -not $debugAbis.Contains("x86_64")) {
				throw "Das Debug-APK muss arm64-v8a und x86_64 enthalten; gefunden: $($debugAbis -join ', ')"
			}
		} finally {
			$debugArchive.Dispose()
		}

		[pscustomobject]@{
			Result = "ANDROID_DEBUG_EXPORT_OK"
			Godot = (& $godotPath --version | Out-String).Trim()
			Version = $versionName
			VersionCode = $versionCode
			Package = "com.zombieescapeeurope.game"
			MinSdk = 28
			TargetSdk = 36
			Architectures = $debugAbis -join ", "
			Debuggable = $true
			SignatureVerified = $true
			AlignedFor16KbPages = $true
			Path = $debugApk
			SizeBytes = $debugApkItem.Length
		} | Format-List
		return
	}

	# Keep the Debug APK universal so it works on desktop emulators. A release
	# QA probe can target either arm64 phones or x86_64 emulators to avoid
	# exporting the unused second native engine library.
	$exportPresetsPath = Join-Path $exportProjectRoot "export_presets.cfg"
	$exportPresetsText = [System.IO.File]::ReadAllText($exportPresetsPath)
	$qaReleaseOptions = [regex]::Match(
		$exportPresetsText,
		'(?s)(\[preset\.0\.options\]\r?\n)(.*?)(?=\r?\n\[preset\.1\])'
	)
	if (-not $qaReleaseOptions.Success) { throw "Das temporäre Android-QA-Exportprofil konnte nicht für $ReleaseArchitecture optimiert werden." }
	$qaOptionsText = $qaReleaseOptions.Groups[2].Value
	$otherArchitecture = if ($ReleaseArchitecture -eq "arm64-v8a") { "x86_64" } else { "arm64-v8a" }
	$selectedArchitecturePattern = "(?m)^architectures/$([regex]::Escape($ReleaseArchitecture))=true\r?`$"
	$otherArchitecturePattern = "(?m)^architectures/$([regex]::Escape($otherArchitecture))=true\r?`$"
	if ($qaOptionsText -notmatch $selectedArchitecturePattern) {
		throw "Das QA-Profil muss $ReleaseArchitecture für diesen Lauf enthalten."
	}
	if ($qaOptionsText -notmatch $otherArchitecturePattern) {
		throw "Das QA-Profil muss beide Architekturprofile enthalten, bevor es isoliert wird."
	}
	$otherArchitectureLine = "(?m)^(architectures/$([regex]::Escape($otherArchitecture))=)true(\r?)`$"
	$qaOptionsText = [regex]::Replace($qaOptionsText, $otherArchitectureLine, '${1}false${2}')
	$exportPresetsText = (
		$exportPresetsText.Substring(0, $qaReleaseOptions.Groups[2].Index) +
		$qaOptionsText +
		$exportPresetsText.Substring($qaReleaseOptions.Groups[2].Index + $qaReleaseOptions.Groups[2].Length)
	)
	[System.IO.File]::WriteAllText($exportPresetsPath, $exportPresetsText)
	Write-Output "QA-Release-APK ABI: $ReleaseArchitecture; Debug-APK ABI: arm64-v8a + x86_64."

	$arguments = @(
		"--headless",
		"--path",
		('"' + $exportProjectRoot + '"'),
		"--export-release",
		'"Android"',
		('"' + $outputPath + '"')
	) -join " "
	$process = Start-Process -FilePath $godotExportPath -ArgumentList $arguments -WorkingDirectory $exportProjectRoot -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath -PassThru -WindowStyle Hidden
	$gradleReleaseApk = Join-Path $exportProjectRoot "android\build\build\outputs\apk\standard\release\android_release.apk"
	$lastCandidateLength = -1L
	$lastCandidateWriteUtc = [DateTime]::MinValue
	$stableCandidateChecks = 0
	$elapsedMilliseconds = 0
	$releaseRecoveredFromGradle = $false
	while ($elapsedMilliseconds -lt 900000) {
		if ($process.WaitForExit(2000)) { break }
		$elapsedMilliseconds += 2000
		if (-not (Test-Path -LiteralPath $gradleReleaseApk -PathType Leaf)) { continue }
		$candidate = Get-Item -LiteralPath $gradleReleaseApk
		if ($candidate.LastWriteTimeUtc -lt $exportStartedUtc -or $candidate.Length -le 0) { continue }
		if ($candidate.Length -eq $lastCandidateLength -and $candidate.LastWriteTimeUtc -eq $lastCandidateWriteUtc) {
			$stableCandidateChecks++
		} else {
			$stableCandidateChecks = 0
			$lastCandidateLength = $candidate.Length
			$lastCandidateWriteUtc = $candidate.LastWriteTimeUtc
		}
		if ($stableCandidateChecks -lt 5) { continue }

		# Godot can remain alive after Gradle has finished writing a complete APK.
		# Recover that stable artifact, then let the normal package/signature/alignment
		# checks below decide whether it is safe to keep.
		Copy-Item -LiteralPath $gradleReleaseApk -Destination $outputPath -Force
		$releaseRecoveredFromGradle = $true
		if (-not $process.HasExited) {
			$process.Kill()
			$process.WaitForExit()
		}
		break
	}
	$processExited = $process.HasExited
	$exitCode = if ($processExited) { $process.ExitCode } else { -1 }
	if (-not $processExited -and -not $releaseRecoveredFromGradle) {
		$process.Kill()
		$process.WaitForExit()
	}
	$process.Dispose()
	if (-not $releaseRecoveredFromGradle -and -not $processExited) {
		throw "Godot-QA-Release-Export dauerte länger als 15 Minuten und es wurde keine fertige Gradle-APK gefunden."
	}
	if ($exitCode -ne 0 -and -not $releaseRecoveredFromGradle) {
		Get-Content -LiteralPath $stdoutPath -ErrorAction SilentlyContinue
		Get-Content -LiteralPath $stderrPath -ErrorAction SilentlyContinue
		throw "Godot-QA-Release-Export endete mit Exitcode $exitCode."
	}
	if ($releaseRecoveredFromGradle) {
		Write-Output "Godot blieb nach dem Gradle-Export aktiv; eine stabile Gradle-APK wird jetzt normal validiert."
	}
} finally {
	foreach ($name in $environmentNames) { [Environment]::SetEnvironmentVariable($name, $previousEnvironment[$name], "Process") }
	if ($qaPasswordPointer -ne [IntPtr]::Zero) {
		[Runtime.InteropServices.Marshal]::ZeroFreeBSTR($qaPasswordPointer)
	}
	if ($qaSecurePassword) { $qaSecurePassword.Dispose() }
	$qaPasswordPlain = $null
}

if (-not (Test-Path -LiteralPath $debugApk -PathType Leaf)) { throw "Godot meldete Erfolg, aber das Debug-APK fehlt: $debugApk" }
$debugApkAfterExport = Get-Item -LiteralPath $debugApk
if ($debugApkAfterExport.LastWriteTimeUtc -lt $exportStartedUtc) { throw "Das Debug-APK wurde während dieses Exportlaufs nicht aktualisiert." }
if (-not (Test-Path -LiteralPath $outputPath -PathType Leaf)) { throw "Godot meldete Erfolg, aber die QA-Release-APK fehlt: $outputPath" }
$apkFileAfterExport = Get-Item -LiteralPath $outputPath
if ($apkFileAfterExport.LastWriteTimeUtc -lt $exportStartedUtc) { throw "Die QA-Release-APK wurde während dieses Exportlaufs nicht aktualisiert." }

$badging = & $aapt dump badging $outputPath 2>&1
if ($LASTEXITCODE -ne 0) { throw "aapt konnte die QA-Release-APK nicht lesen: $($badging -join "`n")" }
$badgingText = $badging -join "`n"
if ($badgingText -notmatch "package: name='com\.zombieescapeeurope\.game' versionCode='$versionCode' versionName='$([regex]::Escape($versionName))'") {
	throw "Paketkennung oder Versionsdaten der QA-Release-APK stimmen nicht."
}
if ($badgingText -notmatch "sdkVersion:'28'" -or $badgingText -notmatch "targetSdkVersion:'36'") {
	throw "Mindest-API oder Ziel-API der QA-Release-APK sind unerwartet."
}
if ($badgingText -match "application-debuggable") { throw "Die QA-Release-APK ist unerwartet als debuggable markiert." }

Add-Type -AssemblyName System.IO.Compression.FileSystem
$apkArchive = [System.IO.Compression.ZipFile]::OpenRead($outputPath)
try {
	$nativeLibraryEntries = @($apkArchive.Entries | Where-Object { $_.FullName -match '^lib/[^/]+/libgodot_android\.so$' })
	$nativeAbis = @($nativeLibraryEntries | ForEach-Object { $_.FullName.Split('/')[1] } | Sort-Object -Unique)
	if ($nativeAbis.Count -ne 1 -or $nativeAbis[0] -ne $ReleaseArchitecture) {
		throw "Die QA-APK muss genau $ReleaseArchitecture enthalten; gefunden: $($nativeAbis -join ', ')"
	}
} finally {
	$apkArchive.Dispose()
}

$previousJavaHome = [Environment]::GetEnvironmentVariable("JAVA_HOME", "Process")
$previousPath = [Environment]::GetEnvironmentVariable("PATH", "Process")
try {
	$env:JAVA_HOME = $javaHome
	$env:PATH = (Join-Path $javaHome "bin") + ";" + $env:PATH
	$releaseSignature = & $apksigner verify --verbose --print-certs $outputPath 2>&1
	if ($LASTEXITCODE -ne 0) { throw "apksigner konnte die QA-Release-APK nicht verifizieren: $($releaseSignature -join "`n")" }
	$debugSignature = & $apksigner verify --verbose --print-certs $debugApk 2>&1
	if ($LASTEXITCODE -ne 0) { throw "Die vorhandene Debug-APK-Signatur kann nicht gelesen werden." }
	$releaseCert = [regex]::Match(($releaseSignature -join "`n"), "Signer #1 certificate SHA-256 digest: ([A-Fa-f0-9]+)")
	$debugCert = [regex]::Match(($debugSignature -join "`n"), "Signer #1 certificate SHA-256 digest: ([A-Fa-f0-9]+)")
	if (-not $releaseCert.Success -or -not $debugCert.Success -or $releaseCert.Groups[1].Value -ne $debugCert.Groups[1].Value) {
		throw "QA-Release-APK und Debug-APK verwenden nicht denselben lokalen Testschlüssel."
	}
} finally {
	[Environment]::SetEnvironmentVariable("JAVA_HOME", $previousJavaHome, "Process")
	[Environment]::SetEnvironmentVariable("PATH", $previousPath, "Process")
}

$alignment = & $zipalign -c -P 16 4 $outputPath 2>&1
if ($LASTEXITCODE -ne 0) { throw "Die 16-KB-APK-Ausrichtung ist fehlgeschlagen: $($alignment -join "`n")" }
$apkItem = Get-Item -LiteralPath $outputPath
[pscustomobject]@{
	Result = "ANDROID_QA_RELEASE_EXPORT_OK"
	Godot = (& $godotPath --version | Out-String).Trim()
	Version = $versionName
	VersionCode = $versionCode
	Package = "com.zombieescapeeurope.game"
	MinSdk = 28
	TargetSdk = 36
	Architecture = $ReleaseArchitecture
	Debuggable = $false
	SignedWithLocalDebugKey = $true
	SignatureSchemeV2 = [bool](($releaseSignature -join "`n") -match "Verified using v2 scheme.*true")
	AlignedFor16KbPages = $true
	Path = $outputPath
	SizeBytes = $apkItem.Length
	SHA256 = (Get-FileHash -LiteralPath $outputPath -Algorithm SHA256).Hash
	DebugApkPath = $debugApk
	DebugApkSizeBytes = $debugApkAfterExport.Length
	DebugApkSHA256 = (Get-FileHash -LiteralPath $debugApk -Algorithm SHA256).Hash
	DebugStdout = $debugStdoutPath
	DebugStderr = $debugStderrPath
	Stdout = $stdoutPath
	Stderr = $stderrPath
} | Format-List
