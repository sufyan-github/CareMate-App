param(
  [string]$ApiBaseUrl = "http://127.0.0.1:3000/api/v1",
  [string]$DemoPhone = "01700123456",
  [string]$DemoOtp = "123456",
  [ValidateRange(5, 240)]
  [int]$Minutes = 46
)

$ErrorActionPreference = "Stop"
$headers = @{ "content-type" = "application/json" }
$installationId = "COMPETITIONMISS000000000001"

function Invoke-CareMatePost {
  param([string]$Path, [hashtable]$Body, [hashtable]$RequestHeaders = $headers)
  Invoke-RestMethod -Method Post -Uri "$ApiBaseUrl$Path" -Headers $RequestHeaders -Body ($Body | ConvertTo-Json -Depth 8)
}

$readiness = Invoke-RestMethod -Uri "$ApiBaseUrl/health/readiness" -TimeoutSec 5
if ($readiness.data.status -ne "ready") { throw "CareMate API is not ready." }

$challenge = Invoke-CareMatePost "/auth/otp/requests" @{
  deviceInstallationId = $installationId
  locale = "en-BD"
  phoneNumber = $DemoPhone
  purpose = "LOGIN"
}
$session = Invoke-CareMatePost "/auth/otp/verifications" @{
  challengeId = $challenge.data.challengeId
  device = @{
    appVersion = "1.0.0-competition"
    deviceName = "Competition miss trigger"
    installationId = $installationId
    platform = "ANDROID"
  }
  otp = $DemoOtp
}
$authorization = @{
  Authorization = "Bearer $($session.data.accessToken)"
  "content-type" = "application/json"
}
$profiles = Invoke-RestMethod -Uri "$ApiBaseUrl/patient-profiles" -Headers $authorization
$profile = @($profiles.data) | Where-Object { $_.accessRole -eq "OWNER" } | Select-Object -First 1
if ($null -eq $profile) { throw "The synthetic owner profile was not found. Run prepare-competition-demo.ps1 first." }

$result = Invoke-CareMatePost "/patient-profiles/$($profile.id)/dose-occurrences/simulate-miss" @{
  minutesLate = $Minutes
} $authorization

Write-Output "Synthetic missed dose created."
Write-Output "Occurrence: $($result.data.id)"
Write-Output "Status: $($result.data.status)"
Write-Output "Planned: $($result.data.plannedAt)"
Write-Output "Caregiver foreground poll target: within 30 seconds (outside quiet hours)."
