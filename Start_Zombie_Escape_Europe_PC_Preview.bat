@echo off
setlocal
set "PROJECT_DIR=%~dp0"
rem Remove the trailing slash so Windows does not escape the closing quote.
set "PROJECT_DIR=%PROJECT_DIR:~0,-1%"
set "GODOT_EXE=%PROJECT_DIR%\.android_setup\GodotPortable\Godot_v4.7.2-stable_win64.exe"

if not exist "%GODOT_EXE%" (
	echo Godot 4.7.2 wurde im Projektordner nicht gefunden.
	echo Oeffne das Godot-Projekt und starte die Hauptszene manuell.
	pause
	exit /b 1
)

"%GODOT_EXE%" --path "%PROJECT_DIR%" -- --amsterdam-werkstatt
