$ErrorActionPreference = 'Stop'
function Resolve-GodotGui {
    $candidates = @(
        $env:GODOT4_BIN,
        'E:\tools\Godot-4.7.1\Godot_v4.7.1-stable_win64.exe',
        (Join-Path $env:LOCALAPPDATA 'Programs\Godot\Godot.exe')
    )
    foreach ($candidate in $candidates) {
        if ($candidate -and (Test-Path -LiteralPath $candidate)) { return $candidate }
    }
    foreach ($commandName in @('godot4', 'godot')) {
        $command = Get-Command $commandName -ErrorAction SilentlyContinue
        if ($command) { return $command.Source }
    }
    throw 'Godot 4.x not found. Set GODOT4_BIN or add godot4/godot to PATH.'
}
$godot = Resolve-GodotGui
Start-Process -FilePath $godot -WorkingDirectory $PSScriptRoot -ArgumentList @('--path', $PSScriptRoot)
