$ErrorActionPreference = 'Stop'

$RepoRoot = Split-Path -Parent $PSScriptRoot
$Project = Join-Path $RepoRoot 'godot'
function Resolve-GodotConsole {
    $candidates = @(
        $env:GODOT4_CONSOLE_BIN,
        $env:GODOT4_BIN,
        'E:\tools\Godot-4.7.1\Godot_v4.7.1-stable_win64_console.exe',
        'E:\tools\Godot-4.7.1\Godot_v4.7.1-stable_win64.exe'
    )
    foreach ($candidate in $candidates) {
        if ($candidate -and (Test-Path -LiteralPath $candidate)) { return $candidate }
    }
    foreach ($commandName in @('godot4', 'godot')) {
        $command = Get-Command $commandName -ErrorAction SilentlyContinue
        if ($command) { return $command.Source }
    }
    throw 'Godot 4.x not found. Set GODOT4_CONSOLE_BIN or GODOT4_BIN.'
}
$Godot = Resolve-GodotConsole

$tests = @(
    'res://tests/smoke_test.gd',
	'res://tests/presentation_gate_test.gd',
    'res://tests/penetration_test.gd',
    'res://tests/progression_test.gd',
    'res://tests/asset_contract_test.gd',
    'res://tests/lifecycle_test.gd'
)

& $Godot --headless --editor --path $Project --quit
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

foreach ($test in $tests) {
    Write-Host "`n=== $test ===" -ForegroundColor Cyan
    & $Godot --headless --path $Project --script $test
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

Write-Host "`nV10_CODE_QUALITY_GATE_PASS" -ForegroundColor Green
Write-Host "ART_BUDGET_STATUS=DEFERRED_HIGH_POLY_PROTOTYPES" -ForegroundColor Yellow
