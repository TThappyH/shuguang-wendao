@echo off
setlocal
set "GODOT=E:\tools\Godot-4.7.1\Godot_v4.7.1-stable_win64.exe"
set "PROJECT=%~dp0."
if not exist "%GODOT%" (
  echo Godot 4.7.1 not found: %GODOT%
  pause
  exit /b 1
)
start "Shuguang Wendao" /D "%~dp0" "%GODOT%" --path "%PROJECT%"
exit /b 0
