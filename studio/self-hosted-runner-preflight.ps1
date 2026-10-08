$ErrorActionPreference = "Stop"

Write-Host "Chaos Survival — authenticated Studio runner preflight"

$currentIdentity = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
Write-Host "Windows identity: $currentIdentity"
Write-Host "USERPROFILE: $env:USERPROFILE"
Write-Host "LOCALAPPDATA: $env:LOCALAPPDATA"

$runnerServices = Get-CimInstance Win32_Service -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -like "actions.runner.*" }

if ($runnerServices) {
    foreach ($service in $runnerServices) {
        Write-Host "GitHub runner service: $($service.Name)"
        Write-Host "GitHub runner service account: $($service.StartName)"

        $systemAccounts = @(
            "LocalSystem",
            "NT AUTHORITY\SYSTEM",
            "NT AUTHORITY\NETWORK SERVICE",
            "NT AUTHORITY\LOCAL SERVICE"
        )

        if ($systemAccounts -contains $service.StartName) {
            Write-Host ""
            Write-Host "ACTION REQUIRED:"
            Write-Host "The GitHub Actions runner service is using a Windows system account."
            Write-Host "Studio authentication belongs to a user profile and will not reliably carry over."
            Write-Host "Run the certifying runner interactively under the authenticated Windows user,"
            Write-Host "or reconfigure the runner service to use that same Windows account."
            exit 3
        }
    }
}
else {
    Write-Host "No GitHub runner Windows service detected; interactive runner mode is acceptable."
}

$roots = @(
    "$env:LOCALAPPDATA\Roblox",
    "$env:USERPROFILE\AppData\Local\Roblox",
    "C:\Program Files\Roblox",
    "C:\Program Files (x86)\Roblox"
) | Where-Object { Test-Path $_ }

$studio = $null
foreach ($root in $roots) {
    $candidate = Get-ChildItem $root -Filter "RobloxStudioBeta.exe" -Recurse -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
    if ($candidate) {
        $studio = $candidate
        break
    }
}

if (-not $studio) {
    throw "Roblox Studio not found. Install Studio and sign in with the Windows account that will run the GitHub self-hosted runner."
}

Write-Host "Studio: $($studio.FullName)"
Write-Host "Version: $($studio.VersionInfo.ProductVersion)"

$signature = Get-AuthenticodeSignature $studio.FullName
Write-Host "Signature: $($signature.Status) / $($signature.SignerCertificate.Subject)"
if ($signature.Status -ne "Valid" -or $signature.SignerCertificate.Subject -notmatch "Roblox") {
    throw "Studio executable is not signed by Roblox Corporation."
}

Get-Process -Name "RobloxStudioBeta" -ErrorAction SilentlyContinue |
    Stop-Process -Force -ErrorAction SilentlyContinue

$startedAt = Get-Date
$process = Start-Process -FilePath $studio.FullName -PassThru
$deadline = (Get-Date).AddSeconds(35)
$authState = "UNKNOWN"
$authLog = $null

while ((Get-Date) -lt $deadline) {
    Start-Sleep -Seconds 1

    $logRoot = "$env:LOCALAPPDATA\Roblox\logs"
    if (-not (Test-Path $logRoot)) {
        continue
    }

    $latest = Get-ChildItem $logRoot -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match "Studio" -and $_.LastWriteTime -ge $startedAt } |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1

    if (-not $latest) {
        continue
    }

    $contents = Get-Content $latest.FullName -Raw -ErrorAction SilentlyContinue
    $authLog = $latest.FullName

    $matches = [regex]::Matches($contents, "Authenticated\s*:\s*(YES|NO)")
    if ($matches.Count -gt 0) {
        $authState = $matches[$matches.Count - 1].Groups[1].Value
    }

    if ($authState -eq "YES") {
        break
    }

    if ($authState -eq "NO" -and $contents -match "LoginPageOpenTime|Cookie list not found") {
        break
    }
}

Write-Host "Authentication state: $authState"
if ($authLog) {
    Write-Host "Studio log: $authLog"
}

if (-not $process.HasExited) {
    Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
}

if ($authState -ne "YES") {
    Write-Host ""
    Write-Host "ACTION REQUIRED:"
    Write-Host "1. Open Roblox Studio normally under this same Windows user."
    Write-Host "2. Sign in interactively."
    Write-Host "3. Close Studio."
    Write-Host "4. Run this preflight again."
    Write-Host ""
    Write-Host "Do not place Roblox passwords or session cookies in GitHub secrets."
    exit 2
}

Write-Host "PASS: official Studio is installed and the runner user has an authenticated Studio session."
