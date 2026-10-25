# Installs an AUTO-START task for the same interactive Windows account that
# signs in through private Tailscale RDP. This fixes the previous empty
# powershell.exe -File '' launcher observed in the user's screenshot.
# Only Roblox's official login UI may authenticate a Roblox account.
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$StudioExe,
    [Parameter(Mandatory=$true)][string]$Workspace
)
$ErrorActionPreference = "Stop"
foreach ($required in @(
    $StudioExe,
    (Join-Path $Workspace "studio\remote-ai-interactive-session.ps1"),
    (Join-Path $Workspace "studio\capture-ai-visual-review.ps1"),
    (Join-Path $Workspace "studio\visual-ai-runner.luau"),
    (Join-Path $Workspace "build\ChaosSurvival.rbxlx")
)) {
    if ([string]::IsNullOrWhiteSpace($required) -or -not (Test-Path -LiteralPath $required)) {
        throw "AI_BOOTSTRAP_INPUT_NOT_FOUND: required local file unavailable"
    }
}

$desktop = [Environment]::GetFolderPath("Desktop")
if (-not $desktop) { $desktop = Join-Path $env:USERPROFILE "Desktop" }
New-Item -ItemType Directory -Path $desktop -Force | Out-Null
$artifactDir = Join-Path $Workspace "build\visual-ai-captures"
New-Item -ItemType Directory -Path $artifactDir -Force | Out-Null

# The official Studio signature was verified by the CI install step.
# Pin the *same* verified executable with a SHA-256 calculated entirely in
# .NET, avoiding the Security module that failed to load in PowerShell 5.1.
$sha = [System.Security.Cryptography.SHA256]::Create()
$stream = $null
try {
    $stream = [System.IO.File]::OpenRead($StudioExe)
    $expectedStudioSha256 = [BitConverter]::ToString(
        $sha.ComputeHash($stream)
    ).Replace("-", "")
}
finally {
    if ($stream) { $stream.Dispose() }
    $sha.Dispose()
}
if ($expectedStudioSha256 -notmatch "^[0-9A-F]{64}$") {
    throw "AI_BOOTSTRAP_INVALID_SIGNED_STUDIO_HASH"
}

$target = Join-Path $Workspace "studio\remote-ai-interactive-session.ps1"
$wrapper = Join-Path $desktop "CHAOS_AI_AUTO_START.ps1"
$escTarget = $target.Replace("'", "''")
$escExe = $StudioExe.Replace("'", "''")
$escRoot = $Workspace.Replace("'", "''")
$script = "& '$escTarget' -StudioExe '$escExe' -Workspace '$escRoot' -ExpectedStudioSha256 '$expectedStudioSha256' -LoginWindowMinutes 10"
Set-Content -LiteralPath $wrapper -Value $script -Encoding utf8
if (-not (Test-Path -LiteralPath $wrapper)) {
    throw "AI_WATCHER_MISSING: wrapper was not saved to the logged-on desktop"
}

# Use EncodedCommand, not -File, so quoting/spaces cannot produce the
# invalid empty path that appeared in the remote PowerShell window.
$entryScript = "& '" + $wrapper.Replace("'", "''") + "'"
$encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($entryScript))
$decoded = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($encoded))
if ($decoded -ne $entryScript -or $decoded -notmatch "CHAOS_AI_AUTO_START.ps1" -or
    [string]::IsNullOrWhiteSpace($encoded)) {
    throw "AI_LAUNCH_ENCODING_FAILED: watcher path failed strict round trip"
}

$arguments = "-NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -EncodedCommand $encoded"
# The workflow's installed PowerShell 7 runs CI checks successfully.
# Prefer the same pwsh binary in the RDP session: Windows PowerShell 5.1
# in the user's screenshot failed to autoload Microsoft.PowerShell.Security.
$psExe = Join-Path $PSHOME "pwsh.exe"
if (-not (Test-Path -LiteralPath $psExe)) {
    $psExe = Join-Path $PSHOME "powershell.exe"
}
if (-not (Test-Path -LiteralPath $psExe)) {
    $psExe = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
}
if (-not (Test-Path -LiteralPath $psExe)) {
    throw "AI_POWERSHELL_MISSING"
}

$runKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
New-Item -Path $runKey -Force | Out-Null
# Remove the older starter that launched Studio separately and could race
# with the new authenticated visual director on RDP login.
Remove-ItemProperty -Path $runKey -Name "ChaosVisualQAStudio" -ErrorAction SilentlyContinue
Remove-ItemProperty -Path $runKey -Name "ChaosAIAutoVisualReview" -ErrorAction SilentlyContinue
$command = '"' + $psExe + '" ' + $arguments
Set-ItemProperty -Path $runKey -Name "ChaosAIVisualReviewV2" -Value $command

# Also register a Task Scheduler OnLogon trigger. Windows remote desktop
# sessions can sometimes reconnect without processing Run keys. Both
# launchers are safe: the task itself avoids duplicate sessions via mutex.
$taskName = "ChaosAIVisualReview"
try {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent().Name
    $taskAction = New-ScheduledTaskAction -Execute $psExe -Argument $arguments
    $taskTrigger = New-ScheduledTaskTrigger -AtLogOn -User $identity
    $taskPrincipal = New-ScheduledTaskPrincipal -UserId $identity -LogonType Interactive -RunLevel Limited
    $taskSettings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan -Minutes 17) -MultipleInstances IgnoreNew
    Register-ScheduledTask -TaskName $taskName -Action $taskAction -Trigger $taskTrigger -Principal $taskPrincipal -Settings $taskSettings -Force | Out-Null
    Write-Host "AI_VISUAL_WATCHER_SCHEDULED: interactive Windows logon"
}
catch {
    # HKCU Run fallback is already registered, so a Group Policy block
    # on scheduled tasks must not prevent the ordinary login launcher.
    Write-Host "AI_VISUAL_WATCHER_TASK_UNAVAILABLE: registry fallback registered"
}

# GitHub-hosted Windows may ALREADY have an unlocked interactive desktop
# under the same runneradmin identity. If so, launch the watcher right now,
# without waiting for RDP logon or any phone interaction. Never attempt
# capture in a non-graphical/session-zero runner.
try {
    $currentSession = (Get-Process -Id $PID).SessionId
    $explorer = @(Get-Process -Name explorer -ErrorAction SilentlyContinue |
        Where-Object { $_.SessionId -eq $currentSession })
    if ($currentSession -gt 0 -and $explorer.Count -gt 0) {
        Start-Process -FilePath $psExe -ArgumentList $arguments -WindowStyle Hidden | Out-Null
        Write-Host "AI_VISUAL_WATCHER_STARTED_IMMEDIATELY: interactive Explorer session detected"
    }
    else {
        Write-Host "AI_VISUAL_WATCHER_DEFERRED: waiting for an interactive Windows logon"
    }
}
catch {
    Write-Host "AI_VISUAL_WATCHER_DEFERRED: guarded Windows OnLogon task will start it"
}

$fallback = Join-Path $desktop "START_CHAOS_AI_CAPTURE.cmd"
$lines = @(
    "@echo off",
    '"' + $psExe + '" ' + $arguments,
    "pause"
)
Set-Content -LiteralPath $fallback -Value ($lines -join [Environment]::NewLine) -Encoding ascii

$instructions = @(
    "CHAOS SURVIVAL - AUTOMATED REAL AI VISUAL QA",
    "",
    "This computer now launches official Roblox Studio automatically.",
    "If Studio is ALREADY signed in, the test will start by itself.",
    "Otherwise Roblox must be authenticated in Studio's official interface.",
    "The account can be authorized from the Android Roblox app if Roblox",
    "offers Quick Login, but no script can bypass account authentication.",
    "",
    "After authentication, 15 real screenshots of AI-driven gameplay will",
    "be captured every 3 seconds and uploaded to GitHub Actions.",
    "No public game is modified. No Roblox cookies or passwords are used.",
    "",
    "Rare startup fallback: START_CHAOS_AI_CAPTURE.cmd.",
    "A missing auth session exits early rather than consuming an hour."
)
Set-Content -LiteralPath (Join-Path $desktop "READ_ME_AI_15_CAPTURES.txt") -Value $instructions -Encoding utf8

# Safe and auditable, no Roblox authentication data in these records.
@(
    "launcher=EncodedCommand",
    "task_name=$taskName",
    "registry_fallback=true",
    "watcher_present=true",
    "utc=$([DateTime]::UtcNow.ToString('o'))"
) | Set-Content -LiteralPath (Join-Path $artifactDir "bootstrap-status.txt") -Encoding utf8

Write-Host "AI_VISUAL_BOOTSTRAP_VERIFIED: no -File argument; wrapper exists; scheduled task and Run fallback attempted."
