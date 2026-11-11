@echo off
setlocal
for %%I in ("%~dp0..\..") do set "PROJECT_DIR=%%~fI"
set "GODOT_EXE=%PROJECT_DIR%\.android_setup\GodotPortable\Godot_v4.7.2-stable_win64.exe"

if not exist "%GODOT_EXE%" (
	echo Godot 4.7.2 wurde im Projektordner nicht gefunden.
	echo Oeffne das Projekt, waehle scenes/driving_test.tscn und druecke F6.
	pause
	exit /b 1
)

"%GODOT_EXE%" --path "%PROJECT_DIR%" -- --driving-test
