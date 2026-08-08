$ErrorActionPreference = 'Stop'
$godot = 'E:\tools\Godot-4.7.1\Godot_v4.7.1-stable_win64.exe'
if (-not (Test-Path $godot)) {
    throw "Godot 4.7.1 not found at $godot"
}
Start-Process -FilePath $godot -WorkingDirectory $PSScriptRoot -ArgumentList @('--path', $PSScriptRoot)
