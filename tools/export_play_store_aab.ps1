param([switch]$ValidateOnly)

$ErrorActionPreference = "Stop"

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$godotPath = Join-Path $projectRoot ".android_setup\GodotPortable\Godot_v4.7.2-stable_win64.exe"
$projectConfig = Join-Path $projectRoot "project.godot"
$versionMatch = Select-String -LiteralPath $projectConfig -Pattern '^config/version="([^"]+)"$'
if (-not $versionMatch) {
	throw "Die Spielversion wurde in project.godot nicht gefunden."
}
$versionName = $versionMatch.Matches[0].Groups[1].Value
$outputPath = Join-Path $projectRoot "build\android\Zombie_Escape_Europe-release-$versionName.aab"
$presetText = [System.IO.File]::ReadAllText((Join-Path $projectRoot "export_presets.cfg"))
$storeHeader = [regex]::Match($presetText, '(?s)\[preset\.1\](.*?)\[preset\.1\.options\]')
$storeOptions = [regex]::Match($presetText, '(?s)\[preset\.1\.options\](.*?)(?:\r?\n\[|\z)')
if (-not $storeHeader.Success -or -not $storeOptions.Success -or $storeHeader.Groups[1].Value -notmatch '(?m)^name="Android Play Store AAB"$') {
	throw "Das Android-Play-Store-Exportprofil wurde nicht gefunden."
}
if ($storeHeader.Groups[1].Value -notmatch '(?m)^custom_features=""$') {
	throw "Das Play-Store-Profil darf keine QA-Merkmale enthalten."
}
$optionsText = $storeOptions.Groups[1].Value
$exportFormatMatch = [regex]::Match($optionsText, '(?m)^gradle_build/export_format=([0-9]+)$')
$targetSdkMatch = [regex]::Match($optionsText, '(?m)^gradle_build/target_sdk="([0-9]+)"$')
$minSdkMatch = [regex]::Match($optionsText, '(?m)^gradle_build/min_sdk="([0-9]+)"$')
$presetVersionMatch = [regex]::Match($optionsText, '(?m)^version/name="([^"]+)"$')
$presetCodeMatch = [regex]::Match($optionsText, '(?m)^version/code=([0-9]+)$')
$packageMatch = [regex]::Match($optionsText, '(?m)^package/unique_name="([^"]+)"$')
if (-not $exportFormatMatch.Success -or [int]$exportFormatMatch.Groups[1].Value -ne 1) {
	throw "Das Play-Store-Profil muss Android App Bundle (AAB) exportieren."
}
if (-not $targetSdkMatch.Success -or [int]$targetSdkMatch.Groups[1].Value -lt 36) {
	throw "Google Play verlangt für neue Apps und Updates derzeit Android API 36 oder höher."
}
if (-not $minSdkMatch.Success -or [int]$minSdkMatch.Groups[1].Value -lt 1 -or [int]$minSdkMatch.Groups[1].Value -gt [int]$targetSdkMatch.Groups[1].Value) {
	throw "Das Play-Store-Profil enthält keinen gültigen Android-Mindest-API-Wert."
}
if (-not $presetVersionMatch.Success -or $presetVersionMatch.Groups[1].Value -ne $versionName) {
	throw "Projektversion und Play-Store-Profil stimmen nicht überein."
}
if (-not $presetCodeMatch.Success -or [int]$presetCodeMatch.Groups[1].Value -lt 1) {
	throw "Der Versionscode im Play-Store-Profil muss positiv sein."
}
if (-not $packageMatch.Success -or $packageMatch.Groups[1].Value -ne "com.zombieescapeeurope.game") {
	throw "Die Paketkennung des Play-Store-Profils stimmt nicht mit der App überein."
}
if ($optionsText -notmatch '(?m)^package/signed=true$' -or $optionsText -notmatch '(?m)^architectures/arm64-v8a=true$' -or $optionsText -notmatch '(?m)^gradle_build/use_gradle_build=true$') {
	throw "Das Play-Store-Profil muss signiert, für arm64-v8a aktiviert und auf Gradle-Build gestellt sein."
}
$qaHeader = [regex]::Match($presetText, '(?s)\[preset\.0\](.*?)\[preset\.0\.options\]')
if (-not $qaHeader.Success -or $qaHeader.Groups[1].Value -notmatch '(?m)^custom_features="qa_release"$') {
	throw "Das interne Android-QA-Profil muss das qa_release-Merkmal enthalten."
}
Write-Host ("AAB-Vorprüfung bestanden: Version {0}, Code {1}, Paket {2}, API {3}–{4}, arm64-v8a, signiert, Format AAB, ohne QA-Merkmale." -f $versionName, $presetCodeMatch.Groups[1].Value, $packageMatch.Groups[1].Value, $minSdkMatch.Groups[1].Value, $targetSdkMatch.Groups[1].Value)
if ($ValidateOnly) {
	exit 0
}

if (-not (Test-Path -LiteralPath $godotPath -PathType Leaf)) {
	$godotPath = (Read-Host "Pfad zur Godot-4.7.2-Windows-Exe").Trim().Trim('"')
	if (-not (Test-Path -LiteralPath $godotPath -PathType Leaf)) {
		throw "Godot-Exe nicht gefunden: $godotPath"
	}
}

$keystorePath = (Read-Host "Vollständiger Pfad zum privaten Upload-Keystore (.jks/.keystore)").Trim().Trim('"')
if (-not (Test-Path -LiteralPath $keystorePath -PathType Leaf)) {
	throw "Keystore-Datei nicht gefunden: $keystorePath"
}

$keyAlias = (Read-Host "Key-Alias").Trim()
if ([string]::IsNullOrWhiteSpace($keyAlias)) {
	throw "Der Key-Alias darf nicht leer sein."
}

$securePassword = Read-Host "Keystore-/Key-Passwort (Eingabe bleibt verborgen)" -AsSecureString
$passwordPointer = [IntPtr]::Zero
$plainPassword = $null
$appDataWasDefined = Test-Path Env:APPDATA
$previousAppData = $env:APPDATA
$godotAppData = Join-Path $projectRoot "build\android\godot_export_userdata"
$portableEditorSettings = Join-Path $projectRoot ".android_setup\GodotPortable\editor_data\editor_settings-4.7.tres"
$installedEditorSettings = if ($appDataWasDefined) {
	Join-Path $previousAppData "Godot\editor_settings-4.7.tres"
} else {
	$null
}
$editorSettingsSource = if (Test-Path -LiteralPath $portableEditorSettings -PathType Leaf) {
	$portableEditorSettings
} elseif ($appDataWasDefined -and (Test-Path -LiteralPath $installedEditorSettings -PathType Leaf)) {
	$installedEditorSettings
} else {
	$null
}
$aabEnvironmentNames = @(
	"GODOT_ANDROID_KEYSTORE_RELEASE_PATH",
	"GODOT_ANDROID_KEYSTORE_RELEASE_USER",
	"GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD"
)
$previousAabEnvironment = @{}
foreach ($name in $aabEnvironmentNames) {
	$previousAabEnvironment[$name] = [Environment]::GetEnvironmentVariable($name, "Process")
}
$exportStartedUtc = [DateTime]::UtcNow
$signatureLogPath = Join-Path $projectRoot "build\android\aab-signature-verify-$versionName.log"

try {
	$godotConfigDirectory = Join-Path $godotAppData "Godot"
	New-Item -ItemType Directory -Path $godotConfigDirectory -Force | Out-Null
	if ($editorSettingsSource) {
		Copy-Item -LiteralPath $editorSettingsSource -Destination (Join-Path $godotConfigDirectory "editor_settings-4.7.tres") -Force
	} else {
		throw "Godot-Editor-Einstellungen fehlen. Richte Android-SDK und Java in Godot ein, bevor du das AAB erstellst."
	}
	if ($securePassword.Length -le 0) {
		throw "Das Keystore-Passwort darf nicht leer sein."
	}
	$env:APPDATA = $godotAppData
	$passwordPointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
	$plainPassword = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($passwordPointer)

	$env:GODOT_ANDROID_KEYSTORE_RELEASE_PATH = $keystorePath
	$env:GODOT_ANDROID_KEYSTORE_RELEASE_USER = $keyAlias
	$env:GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD = $plainPassword

	New-Item -ItemType Directory -Path (Split-Path -Parent $outputPath) -Force | Out-Null
	$stdoutPath = Join-Path $projectRoot "build\android\aab-export-$versionName.stdout.log"
	$stderrPath = Join-Path $projectRoot "build\android\aab-export-$versionName.stderr.log"
	$arguments = '--headless --path "{0}" --export-release "Android Play Store AAB" "{1}"' -f $projectRoot, $outputPath
	$exportProcess = Start-Process -FilePath $godotPath -ArgumentList $arguments -WorkingDirectory $projectRoot -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath -PassThru -WindowStyle Hidden
	# Wait for Godot itself, not its Gradle daemon child. Start-Process -Wait can
	# hold this script open after Godot finishes because Gradle stays resident.
	$exportProcess.WaitForExit()
	$exportExitCode = $exportProcess.ExitCode
	$exportProcess.Dispose()
	if ($exportExitCode -ne 0) {
		throw "Godot-Export ist mit Fehlercode $exportExitCode fehlgeschlagen. Details stehen in $stdoutPath und $stderrPath."
	}
	if (-not (Test-Path -LiteralPath $outputPath -PathType Leaf)) {
		throw "Godot meldete Erfolg, aber die AAB-Datei wurde nicht gefunden: $outputPath"
	}
	$aabFile = Get-Item -LiteralPath $outputPath
	if ($aabFile.LastWriteTimeUtc -lt $exportStartedUtc -or $aabFile.Length -lt 1024) {
		throw "Die AAB-Datei wurde während dieses Exports nicht neu und vollständig geschrieben: $outputPath"
	}

	Add-Type -AssemblyName System.IO.Compression.FileSystem
	$bundleArchive = [System.IO.Compression.ZipFile]::OpenRead($outputPath)
	try {
		$bundleEntries = @($bundleArchive.Entries | ForEach-Object { $_.FullName })
		if ($bundleEntries -notcontains "BundleConfig.pb" -or $bundleEntries -notcontains "base/manifest/AndroidManifest.xml") {
			throw "Die erzeugte Datei enthält keine vollständige Android-App-Bundle-Struktur."
		}
		if (-not ($bundleEntries | Where-Object { $_ -match '^META-INF/[^/]+\.(RSA|DSA|EC)$' })) {
			throw "Die AAB-Datei enthält keine JAR-Signaturdatei. Prüfe Keystore und Exportkonfiguration."
		}
	} finally {
		$bundleArchive.Dispose()
	}

	$javaSettingsText = [System.IO.File]::ReadAllText($editorSettingsSource)
	$javaHomeMatch = [regex]::Match($javaSettingsText, '(?m)^export/android/java_sdk_path\s*=\s*"([^"]+)"$')
	$jarsignerPath = $null
	if ($javaHomeMatch.Success) {
		$javaHomePath = $javaHomeMatch.Groups[1].Value.Replace("/", "\")
		$candidateJarsigner = Join-Path $javaHomePath "bin\jarsigner.exe"
		if (Test-Path -LiteralPath $candidateJarsigner -PathType Leaf) { $jarsignerPath = $candidateJarsigner }
	}
	if ([string]::IsNullOrWhiteSpace($jarsignerPath)) {
		$jarsignerCommand = Get-Command "jarsigner.exe" -ErrorAction SilentlyContinue
		if ($jarsignerCommand) { $jarsignerPath = $jarsignerCommand.Source }
	}
	if ([string]::IsNullOrWhiteSpace($jarsignerPath)) {
		throw "jarsigner.exe wurde in der für Godot eingerichteten Java-Installation nicht gefunden."
	}
	$signatureOutput = & $jarsignerPath -verify -verbose -certs $outputPath 2>&1
	$signatureExitCode = $LASTEXITCODE
	$signatureText = $signatureOutput -join "`n"
	$signatureText | Set-Content -LiteralPath $signatureLogPath -Encoding utf8
	if ($signatureExitCode -ne 0 -or $signatureText -notmatch '(?im)^\s*jar verified\.?\s*$') {
		throw "Die AAB-Signaturprüfung ist fehlgeschlagen. Details stehen in $signatureLogPath"
	}

	[pscustomobject]@{
		Result = "PLAY_STORE_AAB_EXPORT_OK"
		Version = $versionName
		VersionCode = [int]$presetCodeMatch.Groups[1].Value
		TargetSdk = [int]$targetSdkMatch.Groups[1].Value
		BundleConfigurationPresent = $true
		ManifestPresent = $true
		SignatureVerified = $true
		Path = $outputPath
		SizeBytes = $aabFile.Length
		SHA256 = (Get-FileHash -LiteralPath $outputPath -Algorithm SHA256).Hash
		SignatureLog = $signatureLogPath
	} | Format-List
}
finally {
	if ($appDataWasDefined) {
		$env:APPDATA = $previousAppData
	} else {
		Remove-Item Env:APPDATA -ErrorAction SilentlyContinue
	}
	foreach ($name in $aabEnvironmentNames) {
		[Environment]::SetEnvironmentVariable($name, $previousAabEnvironment[$name], "Process")
	}
	if ($passwordPointer -ne [IntPtr]::Zero) {
		[Runtime.InteropServices.Marshal]::ZeroFreeBSTR($passwordPointer)
	}
	if ($securePassword) {
		$securePassword.Dispose()
	}
	$plainPassword = $null
}
