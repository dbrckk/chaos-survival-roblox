# Generate a per-arena Studio CLI runner WITHOUT modifying checked-in code.
# Caller owns source_sha in GitHub Actions; no Roblox credentials are touched.
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("Classic", "Towers", "Crossroads", "Orbital", "Harbor")]
    [string]$Arena,
    [Parameter(Mandatory=$true)][string]$OutputPath
)
$ErrorActionPreference = "Stop"
$sourcePath = Join-Path $PSScriptRoot "visual-ai-runner.luau"
$source = Get-Content -LiteralPath $sourcePath -Raw -Encoding UTF8
$needle = 'arenaVariant = "Harbor",'
$count = [regex]::Matches($source, [regex]::Escape($needle)).Count
if ($count -ne 1) {
    throw "UNSAFE_STUDIO_ARENA_RUNNER: expected exactly one vetted arena field; got $count"
}
$parent = Split-Path -Parent $OutputPath
New-Item -ItemType Directory -Force -Path $parent | Out-Null
$selected = 'arenaVariant = "' + $Arena + '",'
$runner = $source.Replace($needle, $selected)
if (-not $runner.Contains($selected)) {
    throw "STUDIO_ARENA_RUNNER_WRITE_FAILED"
}
# Keep the caller's chosen arena and upstream suite/timeout intact.
Set-Content -LiteralPath $OutputPath -Value $runner -Encoding UTF8
Write-Host "STUDIO_ARENA_RUNNER_READY arena=$Arena"
