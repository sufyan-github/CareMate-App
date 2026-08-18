param(
  [string]$ApiBaseUrl = "http://127.0.0.1:3000/api/v1",
  [string]$DemoPhone = "01700123456",
  [string]$CaregiverPhone = "01800123456",
  [string]$DemoOtp = "123456"
)

$ErrorActionPreference = "Stop"
$headers = @{ "content-type" = "application/json" }
$ownerInstallationId = "COMPETITIONOWNER00000000001"
$caregiverInstallationId = "COMPETITIONCARE000000000001"

function Invoke-CareMatePost {
  param([string]$Path, [hashtable]$Body, [hashtable]$RequestHeaders = $headers)
  Invoke-RestMethod -Method Post -Uri "$ApiBaseUrl$Path" -Headers $RequestHeaders -Body ($Body | ConvertTo-Json -Depth 8)
}

function Invoke-CareMatePatch {
  param([string]$Path, [hashtable]$Body = @{}, [hashtable]$RequestHeaders = $headers)
  Invoke-RestMethod -Method Patch -Uri "$ApiBaseUrl$Path" -Headers $RequestHeaders -Body ($Body | ConvertTo-Json -Depth 8)
}

function New-CareMateDemoSession {
  param(
    [string]$PhoneNumber,
    [string]$InstallationId,
    [string]$DeviceName
  )
  $challenge = Invoke-CareMatePost "/auth/otp/requests" @{
    deviceInstallationId = $InstallationId
    locale = "en-BD"
    phoneNumber = $PhoneNumber
    purpose = "LOGIN"
  }
  Invoke-CareMatePost "/auth/otp/verifications" @{
    challengeId = $challenge.data.challengeId
    device = @{
      appVersion = "1.0.0-competition"
      deviceName = $DeviceName
      installationId = $InstallationId
      platform = "ANDROID"
    }
    otp = $DemoOtp
  }
}

$readiness = Invoke-RestMethod -Uri "$ApiBaseUrl/health/readiness" -TimeoutSec 5
if ($readiness.data.status -ne "ready") { throw "CareMate API is not ready." }

try {
  $dhakaTimeZone = [TimeZoneInfo]::FindSystemTimeZoneById("Asia/Dhaka")
} catch [TimeZoneNotFoundException] {
  $dhakaTimeZone = [TimeZoneInfo]::FindSystemTimeZoneById("Bangladesh Standard Time")
}
$dhakaNow = [TimeZoneInfo]::ConvertTimeFromUtc([DateTime]::UtcNow, $dhakaTimeZone)

$session = New-CareMateDemoSession $DemoPhone $ownerInstallationId "Competition owner setup"
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
$dueMoment = $dhakaNow.AddMinutes(-2)
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
    $dhakaNow.AddHours(1).ToString("HH:mm")
  ) | Sort-Object -Unique
  Invoke-CareMatePost "/medications/$($medication.data.id)/schedules" @{
    activation = "ACTIVATE"
    openEnded = $true
    recurrence = "DAILY"
    startDate = $today
    times = $demoTimes
    timezone = "Asia/Dhaka"
  } $authorization | Out-Null
} else {
  $medication = @{ data = $medications.data[0] }
  if ($null -eq $medication.data.activeSchedule) {
    $today = $dueMoment.ToString("yyyy-MM-dd")
    $demoTimes = @(
      $dueMoment.ToString("HH:mm")
      $dhakaNow.AddHours(1).ToString("HH:mm")
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
}

$inventory = Invoke-RestMethod -Uri "$ApiBaseUrl/patient-profiles/$($profile.data.id)/inventory" -Headers $authorization
$position = @($inventory.data) | Where-Object { $_.medicationId -eq $medication.data.id } | Select-Object -First 1
if ($null -eq $position) { throw "The demo medication inventory position was not created." }
Invoke-CareMatePost "/inventory/$($position.id)/adjustments" @{
  delta = 14
  idempotencyKey = "caremate-competition-opening-$($position.id)"
  note = "Synthetic competition demo stock"
  quantityUnit = $position.quantityUnit
  reason = "OPENING"
} $authorization | Out-Null
if ($position.lowStockThreshold -ne 3) {
  Invoke-CareMatePatch "/inventory/$($position.id)" @{
    expectedVersion = $position.version
    lowStockThreshold = 3
  } $authorization | Out-Null
}

$careInvitations = Invoke-RestMethod -Uri "$ApiBaseUrl/patient-profiles/$($profile.data.id)/care-invitations" -Headers $authorization
$caregiverSuffix = $CaregiverPhone.Substring($CaregiverPhone.Length - 4)
$invitation = @($careInvitations.data) |
  Where-Object {
    $_.inviteePhoneMasked.EndsWith($caregiverSuffix) -and
    @("PENDING", "ACCEPTED") -contains $_.status
  } |
  Select-Object -First 1
if ($null -eq $invitation) {
  $createdInvitation = Invoke-CareMatePost "/patient-profiles/$($profile.data.id)/care-invitations" @{
    phoneNumber = $CaregiverPhone
    permissions = @{
      canManageInventory = $false
      canReceiveMissedDoseAlerts = $true
      canViewDoseOutcomes = $true
      canViewInventory = $true
      canViewMedicationPlan = $true
    }
  } $authorization
  $invitation = $createdInvitation.data
}

$caregiverSession = New-CareMateDemoSession $CaregiverPhone $caregiverInstallationId "Competition caregiver setup"
$caregiverAuthorization = @{
  Authorization = "Bearer $($caregiverSession.data.accessToken)"
  "content-type" = "application/json"
}
if ($invitation.status -eq "PENDING") {
  Invoke-CareMatePatch "/care-invitations/$($invitation.id)/accept" @{} $caregiverAuthorization | Out-Null
}

Write-Output "Competition demo is ready."
Write-Output "Owner phone: $DemoPhone"
Write-Output "Caregiver phone: $CaregiverPhone"
Write-Output "Development OTP: $DemoOtp"
Write-Output "Profile: $($profile.data.displayName)"
Write-Output "Seed target due-dose time: $($dueMoment.ToString('HH:mm')) Asia/Dhaka"
Write-Output "Inventory: 14 $($position.quantityUnit), low-stock threshold 3"
Write-Output "Caregiver access: accepted with plan, outcome, inventory, and alert permissions"
Write-Output "For another clean rehearsal, use a new synthetic phone and reset only com.caremate.competition."
