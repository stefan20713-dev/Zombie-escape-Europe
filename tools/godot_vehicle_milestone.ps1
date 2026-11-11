param(
	[string]$GodotExecutable = "",
	[string]$RunLabel = "0.5.40",
	[switch]$AudioOnly,
	[switch]$VisualOnly,
	[switch]$AtmosphereOnly,
	[switch]$ProgressSaveOnly,
	[switch]$VehicleRosterOnly,
	[switch]$StartingPackageOnly,
	[switch]$MapLayoutOnly,
	[switch]$DrivingFeelOnly,
	[switch]$StockBalanceOnly,
	[switch]$ZombieLatchOnly,
	[switch]$ZombiePreviewOnly,
	[switch]$ZombieRunPreviewOnly,
	[switch]$NitroVisualOnly,
	[switch]$TireVisualOnly,
	[switch]$StockStartOnly,
	[switch]$ArmorOnly,
	[switch]$RunHudOnly,
	[switch]$TerrainCollisionOnly
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
$defaultGodot = Join-Path $projectRoot ".android_setup\GodotPortable\Godot_v4.7.2-stable_win64.exe"
$godotPath = $defaultGodot
if (-not [string]::IsNullOrWhiteSpace($GodotExecutable)) {
	$godotPath = (Resolve-Path -LiteralPath $GodotExecutable).Path
}
if (-not (Test-Path -LiteralPath $godotPath -PathType Leaf)) {
	throw "Godot 4.7.2 wurde nicht gefunden: $godotPath"
}

$runStamp = Get-Date -Format "yyyyMMdd_HHmmss_fff"
$runStartedUtc = [DateTime]::UtcNow
$runRoot = Join-Path $projectRoot "build\godot_vehicle_milestone_$RunLabel`_$runStamp"
New-Item -ItemType Directory -Path $runRoot -Force | Out-Null

function Invoke-GodotStage {
	param(
		[string]$Name,
		[string[]]$Arguments,
		[string]$SuccessMarker = "",
		[int]$TimeoutSeconds = 120
	)

	$stageRoot = Join-Path $runRoot $Name
	$appDataPath = Join-Path $stageRoot "Roaming"
	$localAppDataPath = Join-Path $stageRoot "Local"
	$stdoutPath = Join-Path $runRoot "$Name.stdout.log"
	$stderrPath = Join-Path $runRoot "$Name.stderr.log"
	New-Item -ItemType Directory -Path $appDataPath -Force | Out-Null
	New-Item -ItemType Directory -Path $localAppDataPath -Force | Out-Null
	$quotedArguments = foreach ($argument in $Arguments) {
		if ($argument -match '[\s"]') { '"' + $argument.Replace('"', '\"') + '"' } else { $argument }
	}
	$startInfo = New-Object System.Diagnostics.ProcessStartInfo
	$startInfo.FileName = $godotPath
	$startInfo.Arguments = $quotedArguments -join " "
	$startInfo.WorkingDirectory = $projectRoot
	$startInfo.UseShellExecute = $false
	$startInfo.CreateNoWindow = $true
	$startInfo.RedirectStandardOutput = $true
	$startInfo.RedirectStandardError = $true
	$startInfo.EnvironmentVariables["APPDATA"] = $appDataPath
	$startInfo.EnvironmentVariables["LOCALAPPDATA"] = $localAppDataPath
	$startInfo.EnvironmentVariables["ZEE_AUTOMATED_QA"] = "1"
	$process = New-Object System.Diagnostics.Process
	$process.StartInfo = $startInfo
	if (-not $process.Start()) { throw "Godot-Abschnitt '$Name' konnte nicht gestartet werden." }
	$stdoutTask = $process.StandardOutput.ReadToEndAsync()
	$stderrTask = $process.StandardError.ReadToEndAsync()
	if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
		$process.Kill()
		$process.WaitForExit()
		Set-Content -LiteralPath $stdoutPath -Value $stdoutTask.Result -Encoding utf8
		Set-Content -LiteralPath $stderrPath -Value $stderrTask.Result -Encoding utf8
		$process.Dispose()
		throw "Godot-Abschnitt '$Name' hat nach $TimeoutSeconds Sekunden nicht beendet. Siehe $stdoutPath und $stderrPath"
	}
	$process.WaitForExit()
	$stdout = $stdoutTask.Result
	$stderr = $stderrTask.Result
	$exitCode = $process.ExitCode
	$process.Dispose()
	Set-Content -LiteralPath $stdoutPath -Value $stdout -Encoding utf8
	Set-Content -LiteralPath $stderrPath -Value $stderr -Encoding utf8
	$joinedOutput = $stdout + "`n" + $stderr
	$joinedOutput | Set-Content -LiteralPath (Join-Path $runRoot "$Name.log") -Encoding utf8
	if ($exitCode -ne 0) {
		throw "Godot-Abschnitt '$Name' endete mit Exitcode $exitCode. Siehe $stdoutPath und $stderrPath"
	}
	if ($joinedOutput -match "(?m)(SCRIPT ERROR|Parse Error|Failed to load script|ERROR: Cannot load)") {
		throw "Godot-Abschnitt '$Name' meldete einen Skript- oder Ladefehler. Siehe $stdoutPath und $stderrPath"
	}
	if (-not [string]::IsNullOrWhiteSpace($SuccessMarker) -and -not $joinedOutput.Contains($SuccessMarker)) {
		throw "Godot-Abschnitt '$Name' erreichte den erwarteten Marker '$SuccessMarker' nicht. Siehe $stdoutPath und $stderrPath"
	}
	Write-Host "BESTANDEN: $Name - $stdoutPath"
	if (-not [string]::IsNullOrWhiteSpace($SuccessMarker)) {
		Write-Host ($joinedOutput -split "`n" | Where-Object { $_.Contains($SuccessMarker) } | Select-Object -Last 1)
	}
}

function Copy-NewAtmosphereGallery {
	param([string]$DestinationDirectory)
	$gallery = Get-ChildItem -LiteralPath (Join-Path $projectRoot "build") -Directory -Filter "atmosphere_visual_review_0.5.40_*" |
		Where-Object { $_.LastWriteTimeUtc -ge $runStartedUtc } |
		Sort-Object LastWriteTimeUtc -Descending |
		Select-Object -First 1
	if (-not $gallery) { throw "Die Atmosphärenprüfung hat keinen neuen Bildordner erzeugt." }
	$imagePath = Join-Path $gallery.FullName "atmosphere_gallery.png"
	if (-not (Test-Path -LiteralPath $imagePath -PathType Leaf)) { throw "Das Atmosphärenbild fehlt: $imagePath" }
	Copy-Item -LiteralPath $imagePath -Destination (Join-Path $DestinationDirectory "atmosphere_gallery.png") -Force
	Write-Host "Atmosphärenbild: $imagePath"
}

if ($AudioOnly) {
	Invoke-GodotStage -Name "12_audio_system" -Arguments @("--headless", "--path", $projectRoot, "--audio-driver", "Dummy", "--quit-after", "600", "--script", "res://tests/node_smoke_runner.gd", "--", "res://tests/audio_system_test.gd") -SuccessMarker "AUDIO_SYSTEM_OK"
	Write-Host "GODOT_AUDIO_MILESTONE_OK $RunLabel"
	exit
}

if ($AtmosphereOnly) {
	Invoke-GodotStage -Name "19_atmosphere_system" -Arguments @("--path", $projectRoot, "--scene", "res://scenes/qa_atmosphere_gallery.tscn") -SuccessMarker "ATMOSPHERE_SYSTEM_OK"
	Copy-NewAtmosphereGallery -DestinationDirectory (Join-Path $runRoot "19_atmosphere_system")
	Write-Host "GODOT_ATMOSPHERE_MILESTONE_OK $RunLabel"
	exit
}

if ($ProgressSaveOnly) {
	Invoke-GodotStage -Name "20_progress_save_recovery" -Arguments @("--headless", "--path", $projectRoot, "--quit-after", "1200", "--script", "res://tests/node_smoke_runner.gd", "--", "res://tests/progress_save_recovery_test.gd") -SuccessMarker "PROGRESS_SAVE_RECOVERY_OK"
	Write-Host "GODOT_PROGRESS_SAVE_MILESTONE_OK $RunLabel"
	exit
}

if ($VehicleRosterOnly) {
	Invoke-GodotStage -Name "01_import" -Arguments @("--headless", "--editor", "--path", $projectRoot, "--import", "--quit")
	Invoke-GodotStage -Name "02_vehicle_roster" -Arguments @("--headless", "--path", $projectRoot, "--quit-after", "1200", "--script", "res://tests/vehicle_roster_test.gd") -SuccessMarker "VEHICLE_ROSTER_OK"
	Write-Host "GODOT_VEHICLE_ROSTER_MILESTONE_OK $RunLabel"
	exit
}

if ($StartingPackageOnly) {
	Invoke-GodotStage -Name "21_starting_hill_package" -Arguments @("--headless", "--path", $projectRoot, "--quit-after", "1200", "--script", "res://tests/node_smoke_runner.gd", "--", "res://tests/starting_hill_package_test.gd") -SuccessMarker "STARTING_HILL_PACKAGE_OK"
	Write-Host "GODOT_STARTING_PACKAGE_MILESTONE_OK $RunLabel"
	exit
}

if ($ZombieLatchOnly) {
	Invoke-GodotStage -Name "01_import" -Arguments @("--headless", "--editor", "--path", $projectRoot, "--import", "--quit")
	Invoke-GodotStage -Name "28_zombie_variant_profiles" -Arguments @("--headless", "--path", $projectRoot, "--quit-after", "1200", "--script", "res://tests/node_smoke_runner.gd", "--", "res://tests/zombie_variants_test.gd") -SuccessMarker "ZOMBIE_VARIANTS_OK"
	Invoke-GodotStage -Name "28_zombie_latch" -Arguments @("--headless", "--path", $projectRoot, "--quit-after", "1200", "--script", "res://tests/node_smoke_runner.gd", "--", "res://tests/zombie_latch_test.gd") -SuccessMarker "ZOMBIE_LATCH_OK"
	Invoke-GodotStage -Name "23_zombie_front_contact" -Arguments @("--headless", "--path", $projectRoot, "--quit-after", "1200", "--script", "res://tests/node_smoke_runner.gd", "--", "res://tests/zombie_collision_once_test.gd") -SuccessMarker "ZOMBIE_COLLISION_ONCE_OK"
	Invoke-GodotStage -Name "30_long_kombi_body_and_wheelbase" -Arguments @("--headless", "--path", $projectRoot, "--quit-after", "1200", "--script", "res://tests/node_smoke_runner.gd", "--", "res://tests/armor_visual_progression_test.gd") -SuccessMarker "KOMBI_ARMOR_VISUAL_PROGRESSION_OK"
	Invoke-GodotStage -Name "31_vehicle_roster_configuration" -Arguments @("--headless", "--path", $projectRoot, "--quit-after", "1200", "--script", "res://tests/vehicle_roster_test.gd") -SuccessMarker "VEHICLE_ROSTER_OK"
	Write-Host "GODOT_ZOMBIE_LATCH_MILESTONE_OK $RunLabel"
	exit
}

if ($ZombiePreviewOnly) {
	Invoke-GodotStage -Name "01_import" -Arguments @("--headless", "--editor", "--path", $projectRoot, "--import", "--quit")
	Invoke-GodotStage -Name "02_zombie_latched_pc_preview" -Arguments @("--path", $projectRoot, "--scene", "res://scenes/qa_zombie_latch_gallery.tscn") -SuccessMarker "ZOMBIE_LATCH_GALLERY_OK" -TimeoutSeconds 120
	$zombiePreviewPath = Join-Path $projectRoot "build\pc_preview_zombie_latched_kombi.png"
	if (-not (Test-Path -LiteralPath $zombiePreviewPath -PathType Leaf)) { throw "Die Godot-Vorschau des angehängten Zombies fehlt: $zombiePreviewPath" }
	Copy-Item -LiteralPath $zombiePreviewPath -Destination (Join-Path $runRoot "02_zombie_latched_pc_preview\pc_preview_zombie_latched_kombi.png") -Force
	Write-Host "GODOT_ZOMBIE_PC_PREVIEW_OK $RunLabel"
	exit
}

if ($ZombieRunPreviewOnly) {
	Invoke-GodotStage -Name "01_import" -Arguments @("--headless", "--editor", "--path", $projectRoot, "--import", "--quit")
	Invoke-GodotStage -Name "02_zombie_run_gallery" -Arguments @("--path", $projectRoot, "--scene", "res://scenes/qa_zombie_run_gallery.tscn") -SuccessMarker "ZOMBIE_RUN_GALLERY_OK"
	$previewPath = Join-Path $projectRoot "build\zombie_run_visual_review_0.5.44.png"
	if (-not (Test-Path -LiteralPath $previewPath -PathType Leaf)) { throw "Godot hat die Zombie-Laufübersicht nicht erzeugt: $previewPath" }
	Copy-Item -LiteralPath $previewPath -Destination (Join-Path $runRoot "02_zombie_run_gallery\zombie_run_visual_review_0.5.44.png") -Force
	Invoke-GodotStage -Name "03_zombie_profiles_and_encounters" -Arguments @("--headless", "--path", $projectRoot, "--quit-after", "1200", "--script", "res://tests/node_smoke_runner.gd", "--", "res://tests/zombie_variants_test.gd") -SuccessMarker "ZOMBIE_VARIANTS_OK"
	Write-Host "GODOT_ZOMBIE_RUN_VISUAL_MILESTONE_OK $RunLabel"
	exit
}

if ($NitroVisualOnly) {
	Invoke-GodotStage -Name "01_import" -Arguments @("--headless", "--editor", "--path", $projectRoot, "--import", "--quit")
	Invoke-GodotStage -Name "02_nitro_visual_gallery" -Arguments @("--path", $projectRoot, "--scene", "res://scenes/qa_nitro_visual_gallery.tscn") -SuccessMarker "ARMOR_VISUAL_GALLERY_OK"
	$previewPath = Join-Path $projectRoot "build\armor_visual_review_0.5.55.png"
	if (-not (Test-Path -LiteralPath $previewPath -PathType Leaf)) { throw "Godot hat die Nitro-Übersicht nicht erzeugt: $previewPath" }
	Copy-Item -LiteralPath $previewPath -Destination (Join-Path $runRoot "02_nitro_visual_gallery\armor_visual_review_0.5.55.png") -Force
	Invoke-GodotStage -Name "03_nitro_upgrade_logic" -Arguments @("--headless", "--path", $projectRoot, "--quit-after", "1200", "--script", "res://tests/node_smoke_runner.gd", "--", "res://tests/upgrade_preview_test.gd") -SuccessMarker "UPGRADE_PREVIEW_OK"
	Write-Host "GODOT_NITRO_VISUAL_MILESTONE_OK $RunLabel"
	exit
}

if ($StockStartOnly) {
	Invoke-GodotStage -Name "01_import" -Arguments @("--headless", "--editor", "--path", $projectRoot, "--import", "--quit")
	Invoke-GodotStage -Name "29_armor_damage_scaling" -Arguments @("--headless", "--path", $projectRoot, "--quit-after", "1200", "--script", "res://tests/node_smoke_runner.gd", "--", "res://tests/vehicle_tuning_cache_test.gd") -SuccessMarker "VEHICLE_TUNING_CACHE_OK"
	Invoke-GodotStage -Name "30_armor_tier_wheel_lock" -Arguments @("--headless", "--path", $projectRoot, "--quit-after", "1200", "--script", "res://tests/node_smoke_runner.gd", "--", "res://tests/armor_visual_progression_test.gd") -SuccessMarker "KOMBI_ARMOR_VISUAL_PROGRESSION_OK"
	Invoke-GodotStage -Name "31_stock_start_mode" -Arguments @("--headless", "--path", $projectRoot, "--quit-after", "1200", "--script", "res://tests/node_smoke_runner.gd", "--", "res://tests/stock_start_mode_test.gd") -SuccessMarker "STOCK_START_MODE_OK"
	Invoke-GodotStage -Name "32_tuning_trial" -Arguments @("--headless", "--path", $projectRoot, "--quit-after", "1200", "--script", "res://tests/node_smoke_runner.gd", "--", "res://tests/tuning_trial_test.gd") -SuccessMarker "TUNING_TRIAL_OK"
	Invoke-GodotStage -Name "34_speed_dependent_zombie_latch" -Arguments @("--headless", "--path", $projectRoot, "--quit-after", "1200", "--script", "res://tests/node_smoke_runner.gd", "--", "res://tests/zombie_latch_test.gd") -SuccessMarker "ZOMBIE_LATCH_OK"
	Invoke-GodotStage -Name "35_failure_coasting" -Arguments @("--headless", "--path", $projectRoot, "--quit-after", "1200", "--script", "res://tests/node_smoke_runner.gd", "--", "res://tests/failure_coast_test.gd") -SuccessMarker "FAILURE_COAST_OK"
	Invoke-GodotStage -Name "36_upgrade_preview_and_nitro_workshop" -Arguments @("--headless", "--path", $projectRoot, "--quit-after", "1200", "--script", "res://tests/node_smoke_runner.gd", "--", "res://tests/upgrade_preview_test.gd") -SuccessMarker "UPGRADE_PREVIEW_OK"
	Invoke-GodotStage -Name "37_real_boost_speed_band" -Arguments @("--headless", "--path", $projectRoot, "--quit-after", "1200", "--script", "res://tests/node_smoke_runner.gd", "--", "res://tests/driving_velocity_test.gd") -SuccessMarker "DRIVING_VELOCITY_OK"
	Invoke-GodotStage -Name "38_locked_nitro_hill_hint" -Arguments @("--headless", "--path", $projectRoot, "--quit-after", "1200", "--script", "res://tests/node_smoke_runner.gd", "--", "res://tests/hill_assist_test.gd") -SuccessMarker "HILL_ASSIST_DIRECTION_OK"
	Invoke-GodotStage -Name "39_air_righting_and_rollover" -Arguments @("--headless", "--path", $projectRoot, "--quit-after", "1200", "--script", "res://tests/node_smoke_runner.gd", "--", "res://tests/air_righting_test.gd") -SuccessMarker "AIR_RIGHTING_OK"
	Invoke-GodotStage -Name "40_pc_screenshot_focus" -Arguments @("--headless", "--path", $projectRoot, "--quit-after", "1200", "--script", "res://tests/node_smoke_runner.gd", "--", "res://tests/pc_focus_screenshot_test.gd") -SuccessMarker "PC_SCREENSHOT_FOCUS_OK"
	Write-Host "GODOT_STOCK_START_MILESTONE_OK $RunLabel"
	exit
}

if ($ArmorOnly) {
	Invoke-GodotStage -Name "01_import" -Arguments @("--headless", "--editor", "--path", $projectRoot, "--import", "--quit")
	Invoke-GodotStage -Name "02_armor_visual_progression" -Arguments @("--headless", "--path", $projectRoot, "--quit-after", "1200", "--script", "res://tests/node_smoke_runner.gd", "--", "res://tests/armor_visual_progression_test.gd") -SuccessMarker "KOMBI_ARMOR_VISUAL_PROGRESSION_OK"
	Invoke-GodotStage -Name "03_armor_damage_scaling" -Arguments @("--headless", "--path", $projectRoot, "--quit-after", "1200", "--script", "res://tests/node_smoke_runner.gd", "--", "res://tests/vehicle_tuning_cache_test.gd") -SuccessMarker "VEHICLE_TUNING_CACHE_OK"
	Invoke-GodotStage -Name "04_zombie_armor_damage" -Arguments @("--headless", "--path", $projectRoot, "--quit-after", "1200", "--script", "res://tests/node_smoke_runner.gd", "--", "res://tests/zombie_latch_test.gd") -SuccessMarker "ZOMBIE_LATCH_OK"
	Invoke-GodotStage -Name "05_single_workshop_page" -Arguments @("--headless", "--path", $projectRoot, "--quit-after", "1200", "--script", "res://tests/node_smoke_runner.gd", "--", "res://tests/upgrade_preview_test.gd") -SuccessMarker "UPGRADE_PREVIEW_OK"
	Invoke-GodotStage -Name "03_armor_visual_gallery" -Arguments @("--path", $projectRoot, "--scene", "res://scenes/qa_armor_gallery.tscn") -SuccessMarker "KOMBI_ARMOR_GALLERY_OK"
	$previewPath = Join-Path $projectRoot "build\armor_visual_review_0.5.43.png"
	if (-not (Test-Path -LiteralPath $previewPath -PathType Leaf)) { throw "Godot hat die Panzerungsübersicht nicht erzeugt: $previewPath" }
	Copy-Item -LiteralPath $previewPath -Destination (Join-Path $runRoot "armor_visual_review_0.5.43.png") -Force
	Write-Host "GODOT_ARMOR_MILESTONE_OK $RunLabel"
	exit
}

if ($RunHudOnly) {
	Invoke-GodotStage -Name "01_import" -Arguments @("--headless", "--editor", "--path", $projectRoot, "--import", "--quit")
	Invoke-GodotStage -Name "41_compact_run_notifications" -Arguments @("--headless", "--path", $projectRoot, "--quit-after", "1200", "--script", "res://tests/node_smoke_runner.gd", "--", "res://tests/run_hud_notification_test.gd") -SuccessMarker "RUN_HUD_NOTIFICATION_OK"
	Write-Host "GODOT_RUN_HUD_MILESTONE_OK $RunLabel"
	exit
}

if ($TerrainCollisionOnly) {
	Invoke-GodotStage -Name "01_import" -Arguments @("--headless", "--editor", "--path", $projectRoot, "--import", "--quit")
	Invoke-GodotStage -Name "42_route_bounded_collision" -Arguments @("--headless", "--path", $projectRoot, "--quit-after", "1200", "--script", "res://tests/node_smoke_runner.gd", "--", "res://tests/terrain_collision_budget_test.gd") -SuccessMarker "TERRAIN_COLLISION_BUDGET_OK"
	Write-Host "GODOT_TERRAIN_COLLISION_MILESTONE_OK $RunLabel"
	exit
}

if ($TireVisualOnly) {
	Invoke-GodotStage -Name "01_import" -Arguments @("--headless", "--editor", "--path", $projectRoot, "--import", "--quit")
	Invoke-GodotStage -Name "02_tire_visual_gallery" -Arguments @("--path", $projectRoot, "--scene", "res://scenes/qa_tire_gallery.tscn") -SuccessMarker "KOMBI_TIRE_GALLERY_OK"
	$previewPath = Join-Path $projectRoot "build\tire_visual_review_0.7.2.png"
	if (-not (Test-Path -LiteralPath $previewPath -PathType Leaf)) { throw "Godot hat die Reifenstufenübersicht nicht erzeugt: $previewPath" }
	Copy-Item -LiteralPath $previewPath -Destination (Join-Path $runRoot "tire_visual_review_0.7.2.png") -Force
	Write-Host "GODOT_TIRE_VISUAL_MILESTONE_OK $RunLabel"
	exit
}

if ($StockBalanceOnly) {
	Invoke-GodotStage -Name "01_import" -Arguments @("--headless", "--editor", "--path", $projectRoot, "--import", "--quit")
	Invoke-GodotStage -Name "15_vehicle_feedback" -Arguments @("--headless", "--path", $projectRoot, "--quit-after", "1200", "--script", "res://tests/node_smoke_runner.gd", "--", "res://tests/vehicle_feedback_test.gd") -SuccessMarker "VEHICLE_FEEDBACK_OK"
	Invoke-GodotStage -Name "25_real_boost_speed_band" -Arguments @("--headless", "--path", $projectRoot, "--quit-after", "1200", "--script", "res://tests/node_smoke_runner.gd", "--", "res://tests/driving_velocity_test.gd") -SuccessMarker "DRIVING_VELOCITY_OK"
	Invoke-GodotStage -Name "30_upgrade_effects" -Arguments @("--headless", "--path", $projectRoot, "--quit-after", "1200", "--script", "res://tests/node_smoke_runner.gd", "--", "res://tests/upgrade_preview_test.gd") -SuccessMarker "UPGRADE_PREVIEW_OK"
	Invoke-GodotStage -Name "28_zombie_latch" -Arguments @("--headless", "--path", $projectRoot, "--quit-after", "1200", "--script", "res://tests/node_smoke_runner.gd", "--", "res://tests/zombie_latch_test.gd") -SuccessMarker "ZOMBIE_LATCH_OK"
	Invoke-GodotStage -Name "23_zombie_front_contact" -Arguments @("--headless", "--path", $projectRoot, "--quit-after", "1200", "--script", "res://tests/node_smoke_runner.gd", "--", "res://tests/zombie_collision_once_test.gd") -SuccessMarker "ZOMBIE_COLLISION_ONCE_OK"
	Invoke-GodotStage -Name "29_stock_start_mode" -Arguments @("--headless", "--path", $projectRoot, "--quit-after", "1200", "--script", "res://tests/node_smoke_runner.gd", "--", "res://tests/stock_start_mode_test.gd") -SuccessMarker "STOCK_START_MODE_OK"
	Write-Host "GODOT_STOCK_BALANCE_MILESTONE_OK $RunLabel"
	exit
}

if ($MapLayoutOnly) {
	Invoke-GodotStage -Name "22_campaign_map_layout" -Arguments @("--headless", "--path", $projectRoot, "--quit-after", "1200", "--script", "res://tests/node_smoke_runner.gd", "--", "res://tests/campaign_map_layout_test.gd") -SuccessMarker "CAMPAIGN_MAP_LAYOUT_OK"
	Write-Host "GODOT_MAP_LAYOUT_MILESTONE_OK $RunLabel"
	exit
}

if ($DrivingFeelOnly) {
	Invoke-GodotStage -Name "01_import" -Arguments @("--headless", "--editor", "--path", $projectRoot, "--import", "--quit")
	Invoke-GodotStage -Name "14_air_righting" -Arguments @("--headless", "--path", $projectRoot, "--quit-after", "1200", "--script", "res://tests/node_smoke_runner.gd", "--", "res://tests/air_righting_test.gd") -SuccessMarker "AIR_RIGHTING_OK"
	Invoke-GodotStage -Name "15_vehicle_feedback" -Arguments @("--headless", "--path", $projectRoot, "--quit-after", "1200", "--script", "res://tests/node_smoke_runner.gd", "--", "res://tests/vehicle_feedback_test.gd") -SuccessMarker "VEHICLE_FEEDBACK_OK"
	Invoke-GodotStage -Name "16_audio_system" -Arguments @("--headless", "--path", $projectRoot, "--audio-driver", "Dummy", "--quit-after", "600", "--script", "res://tests/node_smoke_runner.gd", "--", "res://tests/audio_system_test.gd") -SuccessMarker "AUDIO_SYSTEM_OK"
	Invoke-GodotStage -Name "23_zombie_front_contact" -Arguments @("--headless", "--path", $projectRoot, "--quit-after", "1200", "--script", "res://tests/node_smoke_runner.gd", "--", "res://tests/zombie_collision_once_test.gd") -SuccessMarker "ZOMBIE_COLLISION_ONCE_OK"
	Invoke-GodotStage -Name "28_zombie_latch" -Arguments @("--headless", "--path", $projectRoot, "--quit-after", "1200", "--script", "res://tests/node_smoke_runner.gd", "--", "res://tests/zombie_latch_test.gd") -SuccessMarker "ZOMBIE_LATCH_OK"
	Invoke-GodotStage -Name "29_stock_start_mode" -Arguments @("--headless", "--path", $projectRoot, "--quit-after", "1200", "--script", "res://tests/node_smoke_runner.gd", "--", "res://tests/stock_start_mode_test.gd") -SuccessMarker "STOCK_START_MODE_OK"
	Invoke-GodotStage -Name "24_pc_screenshot_focus" -Arguments @("--headless", "--path", $projectRoot, "--quit-after", "1200", "--script", "res://tests/node_smoke_runner.gd", "--", "res://tests/pc_focus_screenshot_test.gd") -SuccessMarker "PC_SCREENSHOT_FOCUS_OK"
	Invoke-GodotStage -Name "25_real_boost_speed_band" -Arguments @("--headless", "--path", $projectRoot, "--quit-after", "1200", "--script", "res://tests/node_smoke_runner.gd", "--", "res://tests/driving_velocity_test.gd") -SuccessMarker "DRIVING_VELOCITY_OK"
	Invoke-GodotStage -Name "26_starting_hill_package" -Arguments @("--headless", "--path", $projectRoot, "--quit-after", "1200", "--script", "res://tests/node_smoke_runner.gd", "--", "res://tests/starting_hill_package_test.gd") -SuccessMarker "STARTING_HILL_PACKAGE_OK"
	Invoke-GodotStage -Name "27_pc_preview_drive" -Arguments @("--headless", "--path", $projectRoot, "--script", "res://tests/node_smoke_runner.gd", "--", "res://tools/pc_preview_drive_probe.gd") -SuccessMarker "PC_PREVIEW_DRIVE_RESULT" -TimeoutSeconds 180
	Write-Host "GODOT_DRIVING_FEEL_MILESTONE_OK $RunLabel"
	exit
}

if ($VisualOnly) {
	Invoke-GodotStage -Name "11_setpiece_visual_system" -Arguments @("--path", $projectRoot, "--scene", "res://scenes/qa_setpiece_gallery.tscn") -SuccessMarker "SETPIECE_VISUAL_SYSTEM_OK"
	$galleryOutput = Join-Path $projectRoot "build\setpiece_visual_review"
	$galleryStage = Join-Path $runRoot "11_setpiece_visual_system"
	foreach ($pageNumber in 1..4) {
		$pageName = "setpieces_page_{0:D2}.png" -f $pageNumber
		$pagePath = Join-Path $galleryOutput $pageName
		if (-not (Test-Path -LiteralPath $pagePath -PathType Leaf)) { throw "Die visuelle Godot-Prüfung erzeugte '$pageName' nicht." }
		Copy-Item -LiteralPath $pagePath -Destination (Join-Path $galleryStage $pageName) -Force
	}
	Invoke-GodotStage -Name "14_atmosphere_visual_gallery" -Arguments @("--path", $projectRoot, "--scene", "res://scenes/qa_atmosphere_gallery.tscn") -SuccessMarker "ATMOSPHERE_SYSTEM_OK"
	Copy-NewAtmosphereGallery -DestinationDirectory (Join-Path $runRoot "14_atmosphere_visual_gallery")
	Write-Host "GODOT_VISUAL_MILESTONE_OK $RunLabel"
	exit
}

$versionStdout = Join-Path $runRoot "godot_version.stdout.log"
$versionStderr = Join-Path $runRoot "godot_version.stderr.log"
$versionProcess = Start-Process -FilePath $godotPath -ArgumentList "--version" -WorkingDirectory $projectRoot -RedirectStandardOutput $versionStdout -RedirectStandardError $versionStderr -PassThru -WindowStyle Hidden
$versionProcess.WaitForExit()
$godotVersion = (Get-Content -LiteralPath $versionStdout) -join " "
$versionProcess.Dispose()
Write-Host "Godot: $godotVersion"
Write-Host "QA-Protokolle: $runRoot"

Invoke-GodotStage -Name "01_import" -Arguments @("--headless", "--editor", "--path", $projectRoot, "--import", "--quit")
Invoke-GodotStage -Name "02_vehicle_roster" -Arguments @("--headless", "--path", $projectRoot, "--quit-after", "1200", "--script", "res://tests/vehicle_roster_test.gd") -SuccessMarker "VEHICLE_ROSTER_OK"
Invoke-GodotStage -Name "03_first_drive_tutorial" -Arguments @("--headless", "--path", $projectRoot, "--quit-after", "1200", "--script", "res://tests/node_smoke_runner.gd", "--", "res://tests/first_drive_tutorial_test.gd") -SuccessMarker "FIRST_DRIVE_TUTORIAL_OK"
Invoke-GodotStage -Name "04_challenge_system" -Arguments @("--headless", "--path", $projectRoot, "--quit-after", "1200", "--script", "res://tests/node_smoke_runner.gd", "--", "res://tests/challenge_system_test.gd") -SuccessMarker "CHALLENGE_SYSTEM_OK"
Invoke-GodotStage -Name "05_vehicle_tuning_cache" -Arguments @("--headless", "--path", $projectRoot, "--quit-after", "1200", "--script", "res://tests/node_smoke_runner.gd", "--", "res://tests/vehicle_tuning_cache_test.gd") -SuccessMarker "VEHICLE_TUNING_CACHE_OK"
Invoke-GodotStage -Name "06_android_back_navigation" -Arguments @("--headless", "--path", $projectRoot, "--quit-after", "1200", "--script", "res://tests/node_smoke_runner.gd", "--", "res://tests/android_back_navigation_test.gd") -SuccessMarker "ANDROID_BACK_NAVIGATION_OK"
Invoke-GodotStage -Name "07_upgrade_preview" -Arguments @("--headless", "--path", $projectRoot, "--quit-after", "1200", "--script", "res://tests/node_smoke_runner.gd", "--", "res://tests/upgrade_preview_test.gd") -SuccessMarker "UPGRADE_PREVIEW_OK"
Invoke-GodotStage -Name "08_ending_sequence" -Arguments @("--headless", "--path", $projectRoot, "--quit-after", "1200", "--script", "res://tests/node_smoke_runner.gd", "--", "res://tests/ending_sequence_test.gd") -SuccessMarker "ENDING_SEQUENCE_OK"
Invoke-GodotStage -Name "09_first_five_balance" -Arguments @("--headless", "--path", $projectRoot, "--quit-after", "60000", "--script", "res://tests/node_smoke_runner.gd", "--", "res://tests/first_five_balance_test.gd") -SuccessMarker "FIRST_FIVE_BALANCE_OK"
Invoke-GodotStage -Name "10_hill_assist_direction" -Arguments @("--headless", "--path", $projectRoot, "--quit-after", "1200", "--script", "res://tests/node_smoke_runner.gd", "--", "res://tests/hill_assist_test.gd") -SuccessMarker "HILL_ASSIST_DIRECTION_OK"
Invoke-GodotStage -Name "12_campaign_setpiece_system" -Arguments @("--headless", "--path", $projectRoot, "--quit-after", "60000", "--script", "res://tests/node_smoke_runner.gd", "--", "res://tests/campaign_setpiece_system_test.gd") -SuccessMarker "CAMPAIGN_SETPIECE_SYSTEM_OK"
Invoke-GodotStage -Name "13_setpiece_visual_system" -Arguments @("--path", $projectRoot, "--scene", "res://scenes/qa_setpiece_gallery.tscn") -SuccessMarker "SETPIECE_VISUAL_SYSTEM_OK"
$galleryOutput = Join-Path $projectRoot "build\setpiece_visual_review"
	$galleryStage = Join-Path $runRoot "13_setpiece_visual_system"
	foreach ($pageNumber in 1..4) {
	$pageName = "setpieces_page_{0:D2}.png" -f $pageNumber
	$pagePath = Join-Path $galleryOutput $pageName
	if (-not (Test-Path -LiteralPath $pagePath -PathType Leaf)) {
		throw "Die visuelle Godot-Prüfung erzeugte die Seite '$pageName' nicht."
	}
	Copy-Item -LiteralPath $pagePath -Destination (Join-Path $galleryStage $pageName) -Force
}

Invoke-GodotStage -Name "14_road_surface_system" -Arguments @("--headless", "--path", $projectRoot, "--quit-after", "1200", "--script", "res://tests/node_smoke_runner.gd", "--", "res://tests/road_surface_test.gd") -SuccessMarker "ROAD_SURFACE_SYSTEM_OK"
Invoke-GodotStage -Name "15_vehicle_feedback" -Arguments @("--headless", "--path", $projectRoot, "--quit-after", "1200", "--script", "res://tests/node_smoke_runner.gd", "--", "res://tests/vehicle_feedback_test.gd") -SuccessMarker "VEHICLE_FEEDBACK_OK"
Invoke-GodotStage -Name "16_audio_system" -Arguments @("--headless", "--path", $projectRoot, "--audio-driver", "Dummy", "--quit-after", "600", "--script", "res://tests/node_smoke_runner.gd", "--", "res://tests/audio_system_test.gd") -SuccessMarker "AUDIO_SYSTEM_OK"
Invoke-GodotStage -Name "17_story_archive" -Arguments @("--headless", "--path", $projectRoot, "--quit-after", "1200", "--script", "res://tests/node_smoke_runner.gd", "--", "res://tests/story_archive_test.gd") -SuccessMarker "STORY_ARCHIVE_OK"
Invoke-GodotStage -Name "19_atmosphere_system" -Arguments @("--path", $projectRoot, "--scene", "res://scenes/qa_atmosphere_gallery.tscn") -SuccessMarker "ATMOSPHERE_SYSTEM_OK"
Copy-NewAtmosphereGallery -DestinationDirectory (Join-Path $runRoot "19_atmosphere_system")
Invoke-GodotStage -Name "20_progress_save_recovery" -Arguments @("--headless", "--path", $projectRoot, "--quit-after", "1200", "--script", "res://tests/node_smoke_runner.gd", "--", "res://tests/progress_save_recovery_test.gd") -SuccessMarker "PROGRESS_SAVE_RECOVERY_OK"
Invoke-GodotStage -Name "21_starting_hill_package" -Arguments @("--headless", "--path", $projectRoot, "--quit-after", "1200", "--script", "res://tests/node_smoke_runner.gd", "--", "res://tests/starting_hill_package_test.gd") -SuccessMarker "STARTING_HILL_PACKAGE_OK"
Invoke-GodotStage -Name "22_campaign_map_layout" -Arguments @("--headless", "--path", $projectRoot, "--quit-after", "1200", "--script", "res://tests/node_smoke_runner.gd", "--", "res://tests/campaign_map_layout_test.gd") -SuccessMarker "CAMPAIGN_MAP_LAYOUT_OK"
Invoke-GodotStage -Name "23_zombie_front_contact" -Arguments @("--headless", "--path", $projectRoot, "--quit-after", "1200", "--script", "res://tests/node_smoke_runner.gd", "--", "res://tests/zombie_collision_once_test.gd") -SuccessMarker "ZOMBIE_COLLISION_ONCE_OK"
Invoke-GodotStage -Name "28_zombie_variant_profiles" -Arguments @("--headless", "--path", $projectRoot, "--quit-after", "1200", "--script", "res://tests/node_smoke_runner.gd", "--", "res://tests/zombie_variants_test.gd") -SuccessMarker "ZOMBIE_VARIANTS_OK"
Invoke-GodotStage -Name "24_pc_screenshot_focus" -Arguments @("--headless", "--path", $projectRoot, "--quit-after", "1200", "--script", "res://tests/node_smoke_runner.gd", "--", "res://tests/pc_focus_screenshot_test.gd") -SuccessMarker "PC_SCREENSHOT_FOCUS_OK"
Invoke-GodotStage -Name "25_real_boost_speed_band" -Arguments @("--headless", "--path", $projectRoot, "--quit-after", "1200", "--script", "res://tests/node_smoke_runner.gd", "--", "res://tests/driving_velocity_test.gd") -SuccessMarker "DRIVING_VELOCITY_OK"

Write-Host "GODOT_VEHICLE_MILESTONE_OK $RunLabel"
