# Capture REAL pixels from a signed-in, interactively rendered Windows
# Roblox Studio test. No generated illustration, cloud upload, or imitation.
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$StudioExe,
    [Parameter(Mandatory = $true)][string]$PlaceFile,
    [Parameter(Mandatory = $true)][string]$RunScriptFile,
    [Parameter(Mandatory = $true)][string]$OutputDirectory,
    [ValidateRange(15, 15)][int]$Count = 15,
    [ValidateRange(2, 8)][int]$IntervalSeconds = 3
)
$ErrorActionPreference = "Stop"
if (-not [Environment]::UserInteractive) {
    throw "NO_INTERACTIVE_DESKTOP: authentic Roblox 3D screenshots cannot be captured in a headless Windows runner."
}
foreach ($source in @($StudioExe, $PlaceFile, $RunScriptFile)) {
    if (!(Test-Path $source)) { throw "Missing exact-SHA input: $source" }
}
New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null
$OutputDirectory = (Resolve-Path $OutputDirectory).Path
$stdout = Join-Path $OutputDirectory "studio-stdout.log"
$stderr = Join-Path $OutputDirectory "studio-stderr.log"
$engineLog = Join-Path $OutputDirectory "studio-run-script.log"
$manifest = Join-Path $OutputDirectory "frames.tsv"
$probeStartedAt = Get-Date
(@("index", "utc", "window_title", "width", "height", "sha256") -join [char]9) |
    Set-Content -Path $manifest -Encoding utf8

Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public static class ChaosScreenNative {
    [StructLayout(LayoutKind.Sequential)]
    public struct Rect { public int Left, Top, Right, Bottom; }
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hwnd, out Rect rect);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr hwnd);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hwnd);
    [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
}
"@

function Read-Output {
    $builder = [System.Text.StringBuilder]::new()
    foreach ($path in @($engineLog, $stdout, $stderr)) {
        if (Test-Path $path) {
            try {
                [void]$builder.AppendLine((Get-Content -LiteralPath $path -Raw -ErrorAction Stop))
            }
            catch {}
        }
    }
    # Child Studio client/server DataModels sometimes log only to their
    # separate Roblox log files, not the outer RunScript output stream.
    # Inspect only new local Studio logs and never upload account secrets.
    $robloxLogs = Join-Path $env:LOCALAPPDATA "Roblox\\logs"
    if (Test-Path $robloxLogs) {
        $latest = Get-ChildItem -LiteralPath $robloxLogs -File -ErrorAction SilentlyContinue |
            Where-Object {
                $_.LastWriteTime -ge $probeStartedAt.AddSeconds(-5) -and
                $_.Name -match "(Studio|Client|Player)"
            } |
            Sort-Object LastWriteTime -Descending |
            Select-Object -First 3
        foreach ($item in $latest) {
            try {
                $tail = Get-Content -LiteralPath $item.FullName -Tail 150 -ErrorAction Stop
                [void]$builder.AppendLine(($tail -join [Environment]::NewLine))
            }
            catch {}
        }
    }
    return $builder.ToString()
}

function Find-RenderedStudioWindow {
    # Roblox tests sometimes render their play client in a separate
    # window. Prefer that. Never capture unrelated desktop windows.
    $found = @()
    foreach ($name in @("RobloxStudioBeta", "RobloxPlayerBeta")) {
        foreach ($proc in @(Get-Process -Name $name -ErrorAction SilentlyContinue)) {
            try {
                $handle = $proc.MainWindowHandle
                if ($handle -eq [IntPtr]::Zero) { continue }
                if (-not [ChaosScreenNative]::IsWindowVisible($handle)) { continue }
                $rect = New-Object ChaosScreenNative+Rect
                if (-not [ChaosScreenNative]::GetWindowRect($handle, [ref]$rect)) {
                    continue
                }
                $width = $rect.Right - $rect.Left
                $height = $rect.Bottom - $rect.Top
                if ($width -lt 640 -or $height -lt 360) { continue }
                $title = [string]$proc.MainWindowTitle
                if ($title -match "(Login|Log in|Sign in|Connexion)") { continue }
                $score = $width * $height
                if ($title -match "(Play|Client|Test|ChaosSurvival)") {
                    $score += 100000000
                }
                $found += [pscustomobject]@{
                    Handle = $handle
                    Rect = $rect
                    Width = $width
                    Height = $height
                    Title = $title
                    Score = $score
                }
            }
            catch {}
        }
    }
    return $found | Sort-Object Score -Descending | Select-Object -First 1
}

Write-Host "Starting exact-SHA Studio AI visual session. Public Roblox place unchanged."
$launchArgs = @(
    "--task", "RunScript",
    "--localPlaceFile", $PlaceFile,
    "--runScriptFile", $RunScriptFile,
    "--outputFile", $engineLog,
    "--quitAfterExecution"
)
$studio = Start-Process -FilePath $StudioExe -ArgumentList $launchArgs -PassThru -RedirectStandardOutput $stdout -RedirectStandardError $stderr
try {
    $ready = $false
    $deadline = (Get-Date).AddSeconds(90)
    while ((Get-Date) -lt $deadline) {
        $log = Read-Output
        if ($log -match "CHAOS_VISUAL_AI_CAPTURE_MARKER\s+01/15" -or
            $log -match "CHAOS_VISUAL_AI_FRAME\s+01/15") {
            $ready = $true
            break
        }
        if ($log -match "Authenticated\s*:\s*NO") {
            throw "AUTH_REQUIRED: Studio has no authenticated user session."
        }
        if ($studio.HasExited) {
            throw "Studio exited before its first AI-rendered viewpoint."
        }
        Start-Sleep -Milliseconds 500
    }
    if (-not $ready) {
        throw "NO_RENDER_MARKER: Studio never reported the first AI visual frame."
    }

    $hashes = @()
    $began = [DateTime]::UtcNow
    for ($i = 1; $i -le $Count; $i++) {
        $target = $began.AddSeconds(($i - 1) * $IntervalSeconds)
        while ([DateTime]::UtcNow -lt $target) {
            Start-Sleep -Milliseconds 90
        }
        if ($studio.HasExited) {
            throw "Studio exited before image $i / $Count could be recorded."
        }
        $window = Find-RenderedStudioWindow
        if ($null -eq $window) {
            throw "NO_RENDERED_WINDOW: no visible Roblox Studio/client window for frame $i."
        }
        [void][ChaosScreenNative]::SetForegroundWindow($window.Handle)
        Start-Sleep -Milliseconds 90
        if ([ChaosScreenNative]::GetForegroundWindow() -ne $window.Handle) {
            throw "WINDOW_NOT_FOREGROUND: refusing to capture another app."
        }

        $bitmap = [System.Drawing.Bitmap]::new($window.Width, $window.Height)
        try {
            $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
            try {
                $origin = [System.Drawing.Point]::new($window.Rect.Left, $window.Rect.Top)
                $destination = [System.Drawing.Point]::new(0, 0)
                $dimensions = [System.Drawing.Size]::new($window.Width, $window.Height)
                $graphics.CopyFromScreen($origin, $destination, $dimensions)
            }
            finally { $graphics.Dispose() }
            $file = Join-Path $OutputDirectory ("ai-frame-{0:D2}.png" -f $i)
            $bitmap.Save($file, [System.Drawing.Imaging.ImageFormat]::Png)
        }
        finally { $bitmap.Dispose() }

        $hash = (Get-FileHash -Algorithm SHA256 -Path $file).Hash
        $name = ($window.Title -replace "[\t\r\n]", " ").Trim()
        $utc = [DateTime]::UtcNow.ToString("o")
        (@("$i", $utc, $name, "$($window.Width)", "$($window.Height)", $hash) -join [char]9) |
            Add-Content -LiteralPath $manifest -Encoding utf8
        $hashes += $hash
        Write-Host ("CHAOS_VISUAL_AI_REAL_PNG {0:D2}/{1:D2} {2} {3}x{4}" -f
            $i, $Count, (Split-Path $file -Leaf), $window.Width, $window.Height)
    }

    if (@($hashes | Select-Object -Unique).Count -lt 8) {
        throw "STATIC_DESKTOP: fewer than eight distinct frames of a changing scene."
    }

    $finishBy = (Get-Date).AddSeconds(55)
    while ((Get-Date) -lt $finishBy) {
        $log = Read-Output
        if ($log -match "CHAOS_VISUAL_AI_OK") { break }
        if ($log -match "CHAOS_VISUAL_AI_FAILED") { break }
        if ($studio.HasExited) { break }
        Start-Sleep -Milliseconds 500
    }
    if ((Read-Output) -notmatch "CHAOS_VISUAL_AI_OK") {
        throw "STUDIO_TEST_FAILED: screenshot files cannot be certified without StudioTestService PASS."
    }

    $countFiles = @(Get-ChildItem -LiteralPath $OutputDirectory -Filter "ai-frame-*.png").Count
    if ($countFiles -ne $Count) {
        throw "INCOMPLETE_CAPTURE: $countFiles of $Count expected real PNG files."
    }
    Write-Host "CHAOS_VISUAL_AI_REAL_SCREENSHOTS_OK: $Count real PNGs and engine PASS."
}
finally {
    if ($studio -and -not $studio.HasExited) {
        Stop-Process -Id $studio.Id -Force -ErrorAction SilentlyContinue
    }
}
