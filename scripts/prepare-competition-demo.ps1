param(
  [string]$ApiBaseUrl = "http://127.0.0.1:3000/api/v1",
  [string]$DemoPhone = "01700123456",
  [string]$DemoOtp = "123456"
)

$ErrorActionPreference = "Stop"
$headers = @{ "content-type" = "application/json" }
$installationId = "COMPETITIONDEMO000000000001"

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
    deviceName = "Competition demo setup"
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
if ($profiles.data.Count -eq 0) {
  $profile = Invoke-CareMatePost "/patient-profiles" @{
    displayName = "CareMate Demo"
    timezone = "Asia/Dhaka"
  } $authorization
} else {
  $profile = @{ data = $profiles.data[0] }
}

$medications = Invoke-RestMethod -Uri "$ApiBaseUrl/patient-profiles/$($profile.data.id)/medications" -Headers $authorization
$dueMoment = (Get-Date).AddMinutes(-2)
if ($medications.data.Count -eq 0) {
  $medication = Invoke-CareMatePost "/patient-profiles/$($profile.data.id)/medications" @{
    displayName = "Napa"
    form = "TABLET"
    instructions = @{
      mealRelation = "AFTER"
      quantityUnit = "TABLET"
      quantityValue = 1
      route = "ORAL"
      sourceText = "Napa 500 mg - one tablet after food"
    }
    notes = "Competition demo data - user reviewed"
    strengthUnit = "mg"
    strengthValue = 500
  } $authorization
  $today = $dueMoment.ToString("yyyy-MM-dd")
  $demoTimes = @(
    $dueMoment.ToString("HH:mm")
    (Get-Date).AddHours(1).ToString("HH:mm")
  ) | Sort-Object -Unique
  Invoke-CareMatePost "/medications/$($medication.data.id)/schedules" @{
    activation = "ACTIVATE"
    openEnded = $true
    recurrence = "DAILY"
    startDate = $today
    times = $demoTimes
    timezone = "Asia/Dhaka"
  } $authorization | Out-Null
}

Write-Output "Competition demo is ready."
Write-Output "Phone: $DemoPhone"
Write-Output "Development OTP: $DemoOtp"
Write-Output "Profile: $($profile.data.displayName)"
Write-Output "Seed target due-dose time: $($dueMoment.ToString('HH:mm')) Asia/Dhaka"
Write-Output "For another clean rehearsal, use a new synthetic phone and reset only com.caremate.competition."
