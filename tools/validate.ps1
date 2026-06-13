# Validate all GDScript files using Godot headless.
# Usage: .\tools\validate.ps1
# Optional: .\tools\validate.ps1 -GodotPath "C:\path\to\Godot.exe"

param(
    [string]$GodotPath = ""
)

$ProjectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $ProjectRoot

function Find-Godot {
    param([string]$ExplicitPath)

    if ($ExplicitPath -and (Test-Path $ExplicitPath)) {
        return $ExplicitPath
    }

    $candidates = @(
        $env:GODOT_PATH,
        (Get-Command godot -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source),
        "$env:LOCALAPPDATA\Programs\Godot Engine\Godot_v4.6-stable_win64.exe",
        "$env:LOCALAPPDATA\Programs\Godot\Godot_v4.6-stable_win64.exe",
        "C:\Program Files\Godot\Godot_v4.6-stable_win64.exe"
    )

    foreach ($path in $candidates) {
        if ($path -and (Test-Path $path)) {
            return $path
        }
    }

    $found = Get-ChildItem -Path "$env:LOCALAPPDATA\Programs" -Recurse -Filter "Godot*.exe" -ErrorAction SilentlyContinue |
        Select-Object -First 1 -ExpandProperty FullName
    if ($found) { return $found }

    return $null
}

$godot = Find-Godot -ExplicitPath $GodotPath
if (-not $godot) {
    Write-Error @"
Godot executable not found.
Set -GodotPath or env var GODOT_PATH, e.g.:
  `$env:GODOT_PATH = 'C:\path\to\Godot.exe'
  .\tools\validate.ps1
"@
    exit 1
}

Write-Host "Using Godot: $godot"
& $godot --headless --path $ProjectRoot --script res://tools/validate_project.gd
exit $LASTEXITCODE
