[CmdletBinding()]
param([ValidateSet('pc','test')][string]$Scope = 'pc', [switch]$TestCamera)
$ErrorActionPreference = 'Stop'
trap { Write-Host "ERROR: $($_.Exception.Message)"; exit 1 }
$envFile = Join-Path $PSScriptRoot 'local/pc.env'
if (-not (Test-Path -LiteralPath $envFile)) { throw 'Run ops/start.ps1 first.' }
$compose = @('compose','--env-file',$envFile,'-f',(Join-Path $PSScriptRoot 'compose.yml'))
if ($Scope -eq 'test') { $compose += @('-f',(Join-Path $PSScriptRoot 'compose.test-d.yml')) }
if ($TestCamera) { $compose += @('-f',(Join-Path $PSScriptRoot 'compose.camera-test.yml')) }
$ErrorActionPreference = 'Continue'
& docker @compose stop
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Write-Host 'H100 stopped. Database and file volumes preserved.'
exit 0
