param(
  [string]$DeviceId = "",
  [string]$ApiBaseUrl = "http://127.0.0.1:3000/api/v1",
  [switch]$SkipBuild,
  [switch]$ResetCompetitionData
)

$ErrorActionPreference = "Stop"
$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$mobileRoot = Join-Path $repositoryRoot "apps\mobile"
$adb = Join-Path $env:LOCALAPPDATA "Android\sdk\platform-tools\adb.exe"
$packageName = "com.caremate.competition"
$apk = Join-Path $mobileRoot "build\app\outputs\flutter-apk\app-debug.apk"

if (-not (Test-Path -LiteralPath $adb -PathType Leaf)) {
  throw "Android adb was not found at $adb."
}

$health = Invoke-RestMethod -Uri "$ApiBaseUrl/health" -TimeoutSec 5
$readiness = Invoke-RestMethod -Uri "$ApiBaseUrl/health/readiness" -TimeoutSec 5
if ($health.data.status -ne "ok" -or $readiness.data.status -ne "ready") {
  throw "CareMate API health or readiness failed."
}

if ([string]::IsNullOrWhiteSpace($DeviceId)) {
  $DeviceId = (& $adb devices) |
    Select-String "\sdevice$" |
    ForEach-Object { ($_ -split "\s+")[0] } |
    Select-Object -First 1
}
if ([string]::IsNullOrWhiteSpace($DeviceId)) {
  throw "No authorized Android device is connected."
}

& $adb -s $DeviceId reverse tcp:3000 tcp:3000 | Out-Null
if (-not $SkipBuild) {
  Push-Location $mobileRoot
  try {
    flutter build apk --debug "--dart-define=API_BASE_URL=$ApiBaseUrl" "--dart-define=COMPETITION_DEMO=true"
    if ($LASTEXITCODE -ne 0) { throw "Flutter APK build failed." }
  } finally {
    Pop-Location
  }
}
if (-not (Test-Path -LiteralPath $apk -PathType Leaf)) {
  throw "Competition APK was not found at $apk."
}

& $adb -s $DeviceId install -r $apk
if ($LASTEXITCODE -ne 0) { throw "Competition APK installation failed." }
if ($ResetCompetitionData) {
  & $adb -s $DeviceId shell pm clear $packageName | Out-Null
  if ($LASTEXITCODE -ne 0) { throw "Competition app data reset failed." }
  Write-Output "Reset local data for $packageName only."
}
& $adb -s $DeviceId shell am force-stop $packageName
& $adb -s $DeviceId shell monkey -p $packageName -c android.intent.category.LAUNCHER 1 | Out-Null

Write-Output "CareMate Competition is running on $DeviceId."
Write-Output "Package: $packageName"
Write-Output "API: $ApiBaseUrl"
