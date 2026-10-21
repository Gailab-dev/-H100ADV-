[CmdletBinding()]
param(
    [ValidateSet('pc','test')][string]$Scope = 'pc',
    [switch]$NoBuild,
    [switch]$BuildOnly,
    [switch]$TestCamera,
    [string]$KakaoKeyFile
)
$ErrorActionPreference = 'Stop'
trap { Write-Host "ERROR: $($_.Exception.Message)"; exit 1 }
if ($TestCamera -and $Scope -ne 'test') { throw 'TestCamera requires -Scope test.' }
$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$localDir = Join-Path $PSScriptRoot 'local'
$envFile = Join-Path $localDir 'pc.env'
function New-HexSecret([int]$Length = 32) {
    $bytes = New-Object byte[] $Length
    $rng = [Security.Cryptography.RandomNumberGenerator]::Create()
    try { $rng.GetBytes($bytes) } finally { $rng.Dispose() }
    return ([BitConverter]::ToString($bytes)).Replace('-', '').ToLowerInvariant()
}
function Invoke-Docker([string[]]$Arguments) {
    # Native stderr is normal for Docker builds. The exit code determines success.
    $previous = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try { & docker @Arguments; $code = $LASTEXITCODE } finally { $ErrorActionPreference = $previous }
    if ($code -ne 0) { throw "Docker failed with exit code $code." }
}
Get-Command docker -ErrorAction Stop | Out-Null
Invoke-Docker @('info','--format','{{.ServerVersion}}')
New-Item -ItemType Directory -Force -Path $localDir | Out-Null
if (-not (Test-Path -LiteralPath $envFile)) {
    $password = '1234'
    $sha = [Security.Cryptography.SHA256]::Create()
    try { $passwordHash = [Convert]::ToBase64String($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($password))) } finally { $sha.Dispose() }
    $key = ''
    if (-not $KakaoKeyFile) {
        $notesName = -join ([char[]]@(0xC7A1,0xC77C))
        $candidateDir = Join-Path $repoRoot $notesName
        if (Test-Path -LiteralPath $candidateDir) {
            foreach ($file in Get-ChildItem -LiteralPath $candidateDir -Filter '*.txt' -File) {
                $content = [IO.File]::ReadAllText($file.FullName)
                $match = [regex]::Match($content, '(?<![a-fA-F0-9])[a-fA-F0-9]{32}(?![a-fA-F0-9])')
                if ($match.Success) { $key = $match.Value; break }
            }
        }
    } else {
        $match = [regex]::Match([IO.File]::ReadAllText($KakaoKeyFile), '(?<![a-fA-F0-9])[a-fA-F0-9]{32}(?![a-fA-F0-9])')
        if (-not $match.Success) { throw 'No 32-character JavaScript key found in the supplied file.' }
        $key = $match.Value
    }
    $videoBytes = New-Object byte[] 32
    $rng = [Security.Cryptography.RandomNumberGenerator]::Create()
    try { $rng.GetBytes($videoBytes) } finally { $rng.Dispose() }
    $lines = @(
        'H100_DB_PASSWORD=' + (New-HexSecret)
        'H100_DB_ROOT_PASSWORD=' + (New-HexSecret)
        'H100_DEMO_PASSWORD_HASH=' + $passwordHash
        'H100_CRYPTO_HASH=' + (New-HexSecret)
        'H100_VIDEO_KEY=' + [Convert]::ToBase64String($videoBytes)
        'H100_AES_KEY=' + (New-HexSecret)
        'H100_TRIGGER_TOKEN=' + (New-HexSecret)
        'H100_DEVICE_HMAC_KEY=' + (New-HexSecret)
        'KAKAO_MAP_JS_KEY=' + $key
    )
    [IO.File]::WriteAllLines($envFile, $lines, (New-Object Text.UTF8Encoding $false))
    [IO.File]::WriteAllLines((Join-Path $localDir 'first-login.txt'), @('Local verification account only','URL: http://localhost:7810','User: admin',('Password: ' + $password)), (New-Object Text.UTF8Encoding $false))
    Write-Host 'Local configuration created. Existing database volumes are never reset.'
}
if (-not ([IO.File]::ReadAllText($envFile) -match '(?m)^H100_TRIGGER_TOKEN=')) {
    [IO.File]::AppendAllText($envFile, ('H100_TRIGGER_TOKEN=' + (New-HexSecret) + "`n"), (New-Object Text.UTF8Encoding $false))
}
if (-not ([IO.File]::ReadAllText($envFile) -match '(?m)^H100_ROI_TOKEN=')) {
    [IO.File]::AppendAllText($envFile, ('H100_ROI_TOKEN=' + (New-HexSecret) + "`n"), (New-Object Text.UTF8Encoding $false))
}
if (-not ([IO.File]::ReadAllText($envFile) -match '(?m)^H100_HMAC_KEYS=')) {
    $deviceKey = [regex]::Match([IO.File]::ReadAllText($envFile), '(?m)^H100_DEVICE_HMAC_KEY=([a-f0-9]{64})').Groups[1].Value
    if (-not $deviceKey) { throw 'The local device HMAC key is missing or invalid.' }
    $mapping = 'H100_HMAC_KEYS={"2026101400001":"' + $deviceKey + '"}'
    [IO.File]::AppendAllText($envFile, ($mapping + "`n"), (New-Object Text.UTF8Encoding $false))
}
$compose = @('compose','--ansi','never','--env-file',$envFile,'-f',(Join-Path $PSScriptRoot 'compose.yml'))
if ($Scope -eq 'test') { $compose += @('-f',(Join-Path $PSScriptRoot 'compose.test-d.yml')) }
if ($TestCamera) { $compose += @('-f',(Join-Path $PSScriptRoot 'compose.camera-test.yml')) }
if (-not $NoBuild) { Invoke-Docker ($compose + @('build')) }
if ($BuildOnly) { Write-Host 'Build completed.'; exit 0 }
Invoke-Docker ($compose + @('up','-d','--no-build','--wait','--wait-timeout','240'))
Write-Host 'H100 PC ready: http://localhost:7810'
Write-Host 'Local credentials: ops/local/first-login.txt'
if ($Scope -eq 'test') { Write-Host 'PC-only D integration endpoint: https://localhost:7812' }
if ($TestCamera) { Write-Host 'Synthetic RTSP test source enabled. This is not a physical camera.' }
exit 0
