# Bootstrap a REAL authenticated Windows desktop for an AI-controlled
# Roblox Studio playtest. This script never receives Roblox credentials.
param(
    [Parameter(Mandatory = $true)][string]$StudioExe,
    [Parameter(Mandatory = $true)][string]$Workspace
)
$ErrorActionPreference = "Stop"
if (!(Test-Path -LiteralPath $StudioExe)) { throw "Roblox Studio binary not installed" }
$desktop = [Environment]::GetFolderPath("Desktop")
if (-not $desktop) { $desktop = Join-Path $env:USERPROFILE "Desktop" }
New-Item -ItemType Directory -Path $desktop -Force | Out-Null
$out = Join-Path $Workspace "build\visual-ai-captures"
New-Item -ItemType Directory -Path $out -Force | Out-Null
$helper = Join-Path $desktop "CHAOS_AI_CAPTURE.ps1"
$watcher = Join-Path $desktop "CHAOS_AI_AUTO_START.ps1"
$rootEscaped = $Workspace.Replace("'", "''")
$studioEscaped = $StudioExe.Replace("'", "''")
$helperEscaped = $helper.Replace("'", "''")

$helperText = @'
$ErrorActionPreference = "Stop"
$root = '__ROOT__'
$studio = '__STUDIO__'
$output = Join-Path $root "build\visual-ai-captures"
$collector = Join-Path $root "studio\capture-ai-visual-review.ps1"
$place = Join-Path $root "build\ChaosSurvival.rbxlx"
$runner = Join-Path $root "studio\visual-ai-runner.luau"
try {
    & $collector -StudioExe $studio -PlaceFile $place -RunScriptFile $runner -OutputDirectory $output -Count 15 -IntervalSeconds 3
    "PASS" | Set-Content -LiteralPath (Join-Path $output "capture-status.txt") -Encoding utf8
}
catch {
    ("CAPTURE_FAILED: " + $_.Exception.Message) |
        Set-Content -LiteralPath (Join-Path $output "capture-error.txt") -Encoding utf8
    exit 1
}
'@
$helperText = $helperText.Replace("__ROOT__", $rootEscaped).Replace("__STUDIO__", $studioEscaped)
Set-Content -LiteralPath $helper -Value $helperText -Encoding utf8

$watcherText = @'
# Launch automatically once official Studio reports the user is signed in.
# If the GH runner reconnects rather than logs on, use desktop shortcut.
$root = '__ROOT__'
$helper = '__HELPER__'
$started = Get-Date
$logDir = Join-Path $env:LOCALAPPDATA "Roblox\logs"
$output = Join-Path $root "build\visual-ai-captures"
$status = Join-Path $output "capture-status.txt"
$errorFile = Join-Path $output "capture-error.txt"
while ((Get-Date) -lt $started.AddMinutes(68)) {
    if ((Test-Path $status) -or (Test-Path $errorFile)) { break }
    $authenticated = $false
    if (Test-Path $logDir) {
        $logs = Get-ChildItem -LiteralPath $logDir -File -ErrorAction SilentlyContinue |
            Where-Object {
                $_.LastWriteTime -ge $started.AddMinutes(-2) -and
                $_.Name -match "Studio"
            } | Sort-Object LastWriteTime -Descending | Select-Object -First 3
        foreach ($log in $logs) {
            try {
                $tail = (Get-Content -LiteralPath $log.FullName -Tail 480 -ErrorAction Stop) -join [Environment]::NewLine
                if ($tail -match "Authenticated\s*:\s*YES") {
                    $authenticated = $true
                    break
                }
            } catch {}
        }
    }
    if ($authenticated) {
        Get-Process -Name RobloxStudioBeta -ErrorAction SilentlyContinue |
            Stop-Process -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 3
        & $helper
        break
    }
    Start-Sleep -Seconds 4
}
'@
$watcherText = $watcherText.Replace("__ROOT__", $rootEscaped).Replace("__HELPER__", $helperEscaped)
Set-Content -LiteralPath $watcher -Value $watcherText -Encoding utf8

$runKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
New-Item -Path $runKey -Force | Out-Null
$command = 'powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "' + $watcher + '"'
Set-ItemProperty -Path $runKey -Name "ChaosAIAutoVisualReview" -Value $command

$shortcut = Join-Path $desktop "START_CHAOS_AI_CAPTURE.cmd"
$shortcutLines = @(
    "@echo off",
    'powershell.exe -NoProfile -ExecutionPolicy Bypass -File "' + $helper + '"',
    "pause"
)
Set-Content -LiteralPath $shortcut -Value ($shortcutLines -join [Environment]::NewLine) -Encoding ascii

$info = @(
    "CHAOS SURVIVAL — AI VISUAL QA (15 authentic frames)",
    "",
    "1. Open official Roblox Studio on this Windows desktop.",
    "2. Sign in to Roblox yourself in Studio's official UI.",
    "3. The automated watchdog starts the test when Studio auth succeeds.",
    "4. If not, double-click START_CHAOS_AI_CAPTURE.cmd on the desktop.",
    "5. The local Roblox client follows 3 independently controlled AI bots.",
    "6. Fifteen real rendered gameplay PNG frames and contact sheet are",
    "   automatically uploaded as a GitHub Actions artifact.",
    "",
    "No Roblox credentials, cookies or tokens should be pasted into ChatGPT.",
    "The public game is not modified; only the checked-out local build runs.",
    "Keep the remote Windows RDP session active until capture completes."
)
Set-Content -LiteralPath (Join-Path $desktop "READ_ME_AI_15_CAPTURES.txt") -Value $info -Encoding utf8
Write-Host "Ready: signed-in Studio auto-trigger, secure local capture, fallback desktop shortcut."
