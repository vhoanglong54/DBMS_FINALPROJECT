[CmdletBinding()]
param(
    [string]$Server = '.\SQLEXPRESS',
    [ValidatePattern('^[A-Za-z0-9_]+$')]
    [string]$DatabaseName = 'GymManagementDB'
)

$ErrorActionPreference = 'Stop'
$sqlcmd = Get-Command sqlcmd -ErrorAction Stop
$sqlVariables = @("DatabaseName=$DatabaseName")
$scripts = @(
    'database\04c_tv4_reporting_views.sql',
    'database\06c_tv4_reporting_procedures.sql',
    'database\08c_tv4_reporting_security_grants.sql'
)

foreach ($relativePath in $scripts) {
    $scriptPath = Join-Path $PSScriptRoot $relativePath
    if (-not (Test-Path -LiteralPath $scriptPath)) {
        throw "Missing required script: $scriptPath"
    }

    Write-Host "Running $relativePath on $Server / $DatabaseName..."
    & $sqlcmd.Source -S $Server -E -b -r 1 -i $scriptPath -v $sqlVariables -f 65001
    if ($LASTEXITCODE -ne 0) {
        throw "Script $relativePath failed with exit code $LASTEXITCODE."
    }
}

Write-Host 'TV4 reporting views, procedures and app permissions installed.' -ForegroundColor Green
