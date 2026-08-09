$ErrorActionPreference = 'Stop'

$RepoRoot = Split-Path -Parent $PSScriptRoot
$Project = Join-Path $RepoRoot 'godot'
$Godot = 'E:\tools\Godot-4.7.1\Godot_v4.7.1-stable_win64_console.exe'

if (-not (Test-Path -LiteralPath $Godot)) {
    throw "Godot runtime missing: $Godot"
}

$tests = @(
    'res://tests/smoke_test.gd',
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

Write-Host "`nV10_QUALITY_GATE_PASS" -ForegroundColor Green
