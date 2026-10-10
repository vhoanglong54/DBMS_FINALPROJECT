[CmdletBinding()]
param(
    [string]$BaseUrl = 'https://localhost:7195',
    [string]$Username = 'admin',
    [string]$Password = 'Admin@123'
)

$ErrorActionPreference = 'Stop'
$session = New-Object Microsoft.PowerShell.Commands.WebRequestSession

function Invoke-GymRequest([string]$Path) {
    Invoke-WebRequest ($BaseUrl + $Path) -WebSession $session -SkipCertificateCheck
}

$health = Invoke-GymRequest '/health'
$login = Invoke-GymRequest '/account/login'
$match = [regex]::Match($login.Content, 'name="__RequestVerificationToken" type="hidden" value="([^"]+)"')
if (-not $match.Success) { throw 'Không tìm thấy anti-forgery token trên trang login.' }

Invoke-WebRequest ($BaseUrl + '/account/login') -Method Post -WebSession $session -SkipCertificateCheck -Body @{
    Username = $Username
    Password = $Password
    RememberMe = 'false'
    ReturnUrl = ''
    __RequestVerificationToken = $match.Groups[1].Value
} | Out-Null

$paths = @(
    '/', '/Members', '/Memberships', '/Plans', '/Operations',
    '/Operations/CheckIn', '/MemberSearch', '/Reports?type=revenue',
    '/Reports?type=classes', '/Reports?type=attendance'
)

$results = foreach ($path in $paths) {
    $response = Invoke-GymRequest $path
    if ($response.StatusCode -ne 200) { throw "$path trả HTTP $($response.StatusCode)." }
    [pscustomobject]@{ Path=$path; Status=$response.StatusCode; Bytes=$response.Content.Length }
}

if ($health.StatusCode -ne 200) { throw "Health check trả HTTP $($health.StatusCode)." }
$results | Format-Table -AutoSize
Write-Host 'APP SMOKE TEST PASSED.' -ForegroundColor Green
