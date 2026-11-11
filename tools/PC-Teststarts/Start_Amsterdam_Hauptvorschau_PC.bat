@echo off
setlocal
for %%I in ("%~dp0..\..") do set "PROJECT_DIR=%%~fI"
set "PREVIEW_PROFILE=%PROJECT_DIR%\build\pc_amsterdam_main_preview_profile"
set "APPDATA=%PREVIEW_PROFILE%\Roaming"
set "LOCALAPPDATA=%PREVIEW_PROFILE%\Local"
set "GODOT_EXE=%PROJECT_DIR%\.android_setup\GodotPortable\Godot_v4.7.2-stable_win64.exe"

if not exist "%GODOT_EXE%" (
	echo Godot 4.7.2 wurde im Projektordner nicht gefunden.
	echo Oeffne das Projekt und starte scenes/main.tscn.
	exit /b 1
)

if not exist "%APPDATA%" mkdir "%APPDATA%"
if not exist "%LOCALAPPDATA%" mkdir "%LOCALAPPDATA%"

"%GODOT_EXE%" --path "%PROJECT_DIR%" --scene "res://scenes/main.tscn"
set "PREVIEW_EXIT=%ERRORLEVEL%"
endlocal & exit /b %PREVIEW_EXIT%
