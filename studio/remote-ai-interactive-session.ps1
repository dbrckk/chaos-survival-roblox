# Only runs in the interactive Windows session. No Roblox auth bypass.
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$StudioExe,
    [Parameter(Mandatory=$true)][string]$Workspace,
    [ValidateRange(2, 40)][int]$LoginWindowMinutes = 10
)
$ErrorActionPreference = "Stop"
$output = Join-Path $Workspace "build\visual-ai-captures"
New-Item -ItemType Directory -Path $output -Force | Out-Null
$statusFile = Join-Path $output "watchdog-status.txt"
$errorFile = Join-Path $output "capture-error.txt"
$passedFile = Join-Path $output "capture-status.txt"
$startedAt = Get-Date

# Both Task Scheduler and Run-key startup are installed for RDP reliability.
# Only one may own the live Roblox Studio session and screenshot files.
$mutex = [System.Threading.Mutex]::new($false, "Local\ChaosSurvivalAIVisualCapture")
$ownsMutex = $false
try {
    $ownsMutex = $mutex.WaitOne(0)
}
catch [System.Threading.AbandonedMutexException] {
    $ownsMutex = $true
}
if (-not $ownsMutex) {
    $mutex.Dispose()
    return
}

function Write-Stage([string]$state) {
    $date = [DateTime]::UtcNow.ToString("o")
    @("stage=$state", "utc=$date") | Set-Content -LiteralPath $statusFile -Encoding utf8
}

function Find-StudioAuthentication {
    $logRoot = Join-Path $env:LOCALAPPDATA "Roblox\logs"
    if (-not (Test-Path $logRoot)) { return $false }
    $recent = Get-ChildItem -LiteralPath $logRoot -File -ErrorAction SilentlyContinue |
        Where-Object {
            $_.LastWriteTime -ge $startedAt.AddSeconds(-15) -and
            $_.Name -match "Studio"
        } | Sort-Object LastWriteTime -Descending | Select-Object -First 4
    foreach ($entry in $recent) {
        try {
            $lines = Get-Content -LiteralPath $entry.FullName -Tail 450 -ErrorAction Stop
            $matches = @($lines | Where-Object { $_ -match "Authenticated\s*:\s*(YES|NO)" })
            if ($matches.Count -gt 0) {
                $last = [regex]::Match($matches[-1], "Authenticated\s*:\s*(YES|NO)")
                if ($last.Success -and $last.Groups[1].Value -eq "YES") {
                    return $true
                }
            }
        } catch {}
    }
    return $false
}

try {
    Write-Stage "STARTED"
    if (-not [Environment]::UserInteractive) {
        throw "GUI_SESSION_MISSING: this is not an interactive Windows logon"
    }
    if (-not (Test-Path -LiteralPath $StudioExe)) {
        throw "STUDIO_MISSING: official Studio binary no longer exists"
    }
    $studioSig = Get-AuthenticodeSignature -LiteralPath $StudioExe
    if ($studioSig.Status -ne "Valid" -or
        $studioSig.SignerCertificate.Subject -notmatch "Roblox") {
        throw "UNTRUSTED_STUDIO: executable must be signed by Roblox"
    }

    $studio = Get-Process -Name "RobloxStudioBeta" -ErrorAction SilentlyContinue |
        Where-Object { $_.MainWindowHandle -ne [IntPtr]::Zero } |
        Select-Object -First 1
    if (-not $studio) {
        Write-Stage "STARTING_ROBLOX_STUDIO"
        $studio = Start-Process -FilePath $StudioExe -PassThru
    }
    Write-Stage "AWAITING_OFFICIAL_ROBLOX_LOGIN"
    $deadline = (Get-Date).AddMinutes($LoginWindowMinutes)
    $isAuthenticated = $false
    while ((Get-Date) -lt $deadline) {
        if ((Test-Path $passedFile) -or (Test-Path $errorFile)) { return }
        if (Find-StudioAuthentication) {
            $isAuthenticated = $true
            break
        }
        Start-Sleep -Seconds 3
    }
    if (-not $isAuthenticated) {
        Write-Stage "AUTH_REQUIRED"
        throw "AUTH_REQUIRED: no logged-in official Studio session"
    }

    Write-Stage "AUTHENTICATED_STARTING_AI_TEST"
    Get-Process -Name "RobloxStudioBeta" -ErrorAction SilentlyContinue |
        Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 3
    $collector = Join-Path $Workspace "studio\capture-ai-visual-review.ps1"
    $place = Join-Path $Workspace "build\ChaosSurvival.rbxlx"
    $test = Join-Path $Workspace "studio\visual-ai-runner.luau"
    Write-Stage "CAPTURING_REAL_GAMEPLAY_PNGS"
    & $collector -StudioExe $StudioExe -PlaceFile $place -RunScriptFile $test -OutputDirectory $output -Count 15 -IntervalSeconds 3
    $images = @(Get-ChildItem -LiteralPath $output -Filter "ai-frame-*.png" -ErrorAction SilentlyContinue)
    if ($images.Count -ne 15) {
        throw "INCOMPLETE_CAPTURE: expected 15 PNGs, found $($images.Count)"
    }
    "PASS" | Set-Content -LiteralPath $passedFile -Encoding utf8
    Write-Stage "CAPTURE_COMPLETE"
}
catch {
    $message = [string]$_.Exception.Message
    # Only upload a coded explanation; never raw local Studio auth logs.
    $reason = if ($message -match "AUTH_REQUIRED") { "AUTH_REQUIRED" }
        elseif ($message -match "GUI_SESSION_MISSING") { "GUI_SESSION_MISSING" }
        elseif ($message -match "STUDIO_MISSING|UNTRUSTED_STUDIO") { "STUDIO_UNAVAILABLE" }
        elseif ($message -match "NO_RENDER_MARKER") { "NO_RENDER_MARKER" }
        elseif ($message -match "NO_RENDERED_WINDOW|WINDOW_NOT_FOREGROUND") { "GUI_CAPTURE_UNAVAILABLE" }
        elseif ($message -match "STUDIO_TEST_FAILED") { "STUDIO_TEST_FAILED" }
        elseif ($message -match "INCOMPLETE_CAPTURE") { "INCOMPLETE_CAPTURE" }
        else { "LOCAL_CAPTURE_FAILURE" }
    Write-Stage $reason
    $reason | Set-Content -LiteralPath $errorFile -Encoding ascii
}
finally {
    if ($ownsMutex) { $mutex.ReleaseMutex() }
    $mutex.Dispose()
}
