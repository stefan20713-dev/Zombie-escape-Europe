param([string]$OutputPath = "")

$ErrorActionPreference = "Stop"
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$projectConfig = Join-Path $projectRoot "project.godot"
$versionMatch = Select-String -LiteralPath $projectConfig -Pattern '^config/version="([^"]+)"$'
if (-not $versionMatch) { throw "Die Spielversion wurde in project.godot nicht gefunden." }
$version = $versionMatch.Matches[0].Groups[1].Value

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
	$OutputPath = Join-Path $projectRoot "Zombie_Escape_Europe_Godot_${version}_Amsterdam.zip"
} elseif (-not [System.IO.Path]::IsPathRooted($OutputPath)) {
	$OutputPath = Join-Path $projectRoot $OutputPath
}
$OutputPath = [System.IO.Path]::GetFullPath($OutputPath)
$rootPrefix = $projectRoot.TrimEnd([System.IO.Path]::DirectorySeparatorChar) + [System.IO.Path]::DirectorySeparatorChar
if (-not $OutputPath.StartsWith($rootPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
	throw "Das Quellpaket muss innerhalb des Godot-Projektordners gespeichert werden: $OutputPath"
}
if (Test-Path -LiteralPath $OutputPath -PathType Container) {
	throw "Der ZIP-Ausgabepfad ist bereits ein Ordner: $OutputPath"
}
if (Test-Path -LiteralPath $OutputPath -PathType Leaf) {
	Remove-Item -LiteralPath $OutputPath
}

$sourceFiles = [System.Collections.Generic.List[string]]::new()
foreach ($fileName in @("CAMPAIGN_DESIGN.md", "export_presets.cfg", "project.godot", "README.md", "REFERENCE_APK_NOTES.md", "ROADMAP.md")) {
	$sourceFiles.Add($fileName)
}
foreach ($directoryName in @("addons", "assets", "scenes", "scripts", "tools")) {
	$directoryPath = Join-Path $projectRoot $directoryName
	Get-ChildItem -LiteralPath $directoryPath -File -Recurse | ForEach-Object {
		$relativePath = [System.IO.Path]::GetRelativePath($projectRoot, $_.FullName).Replace("\", "/")
		if ($relativePath -match '(^|/)\.godot/' -or $relativePath -match '(^|/)build/') { return }
		if ([System.IO.Path]::GetExtension($relativePath) -match '(?i)^\.(apk|aab|jks|keystore)$') { return }
		$sourceFiles.Add($relativePath)
	}
}
foreach ($fileName in @(
	"build/node_smoke_runner.gd",
	"build/vehicle_roster_smoke_0.5.12.gd",
	"build/first_drive_tutorial_smoke_0.5.12.gd",
	"build/challenge_system_smoke_0.5.12.gd",
	"build/physics_tuning_cache_smoke_0.5.16.gd",
	"build/android_back_navigation_smoke_0.5.18.gd",
	"build/upgrade_preview_smoke_0.5.19.gd",
	"build/ending_sequence_smoke_0.5.20.gd",
	"build/first_five_balance_smoke_0.5.20.gd",
	"build/campaign_setpiece_system_smoke_0.5.21.gd",
	"build/road_surface_smoke_0.5.29.gd",
	"build/vehicle_feedback_smoke_0.5.30.gd",
	"build/hill_assist_smoke_0.5.31.gd",
	"build/story_archive_smoke_0.5.28.gd",
	"build/campaign_drivability_sweep_0.5.0.gd",
	"build/campaign_objective_sweep_0.5.23.gd",
	"build/audio_system_smoke_0.5.25.gd",
	"build/audio_system_smoke_0.5.26.gd"
)) {
	$sourceFiles.Add($fileName)
}

$sourceFiles = @($sourceFiles | Sort-Object -Unique)
$forbiddenSourceFiles = @($sourceFiles | Where-Object {
	$_ -match '(^|/)\.godot/' -or $_ -match '(?i)\.(apk|aab|jks|keystore)$'
})
if ($forbiddenSourceFiles.Count -gt 0) {
	throw "Das Quellpaket darf keine Godot-Caches, APK/AAB-Builds oder Keystores enthalten: $($forbiddenSourceFiles -join ', ')"
}
foreach ($relativePath in $sourceFiles) {
	if (-not (Test-Path -LiteralPath (Join-Path $projectRoot $relativePath) -PathType Leaf)) {
		throw "Quellpaket-Datei fehlt: $relativePath"
	}
}

Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive = [System.IO.Compression.ZipFile]::Open($OutputPath, [System.IO.Compression.ZipArchiveMode]::Create)
try {
	foreach ($relativePath in $sourceFiles) {
		$sourcePath = Join-Path $projectRoot $relativePath
		[System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
			$archive,
			$sourcePath,
			$relativePath,
			[System.IO.Compression.CompressionLevel]::Optimal
		) | Out-Null
	}
} finally {
	$archive.Dispose()
}

$verificationArchive = [System.IO.Compression.ZipFile]::OpenRead($OutputPath)
try {
	$unsafeEntries = @($verificationArchive.Entries | Where-Object {
		$entryPath = $_.FullName.Replace("\", "/")
		$entryPath -match '(^|/)\.godot/' -or $entryPath -match '(?i)\.(apk|aab|jks|keystore)$'
	})
	if ($unsafeEntries.Count -gt 0) {
		throw "Das erstellte Quellarchiv enthält Build-Artefakte oder Cache-Dateien: $($unsafeEntries -join ', ')"
	}
} finally {
	$verificationArchive.Dispose()
}

$archiveInfo = Get-Item -LiteralPath $OutputPath
$archiveHash = (Get-FileHash -LiteralPath $OutputPath -Algorithm SHA256).Hash
[pscustomobject]@{
	Result = "GODOT_SOURCE_PACKAGE_OK"
	Version = $version
	Path = $OutputPath
	Entries = $sourceFiles.Count
	SizeBytes = $archiveInfo.Length
	SHA256 = $archiveHash
} | Format-List
