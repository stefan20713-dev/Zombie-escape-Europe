@echo off
setlocal
set "PROJECT_DIR=%~dp0"
set "PROJECT_DIR=%PROJECT_DIR:~0,-1%"
set "GODOT_EXE=%PROJECT_DIR%\.android_setup\GodotPortable\Godot_v4.7.2-stable_win64.exe"
if not exist "%GODOT_EXE%" (
    echo Godot 4.7.2 wurde nicht gefunden.
    pause
    exit /b 1
)
"%GODOT_EXE%" --path "%PROJECT_DIR%" res://levels/utrecht/preview.tscn
