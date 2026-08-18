# CareMate Five-Minute Judge Script

Before presenting, start the API with `COMPETITION_DEMO=true`, then run `scripts/prepare-competition-demo.ps1`. In the competition APK, tap the trophy icon at any point to reopen the five-step presenter guide; it is excluded from ordinary builds.

## Before entering the room

- Run `scripts/prepare-competition-demo.ps1` against the local API.
- Run `scripts/run-competition-device.ps1` on both prepared phones and confirm package `com.caremate.competition` is foregrounded.
- Keep the owner signed in on phone **P** and the accepted synthetic caregiver signed in on phone **C**, with **Care** open on C.
- Keep airplane-mode quick settings available; do not expose secrets, tokens, real phone numbers, or real prescriptions.
- Use the synthetic prescription and demo number `01700123456`; development OTP is visibly labelled `123456`.

## 0:00–0:35 — Problem and promise

“A prescription is only the beginning. CareMate helps a Bangladesh household turn reviewed medicine information into reminders, offline action, inventory awareness, and consent-based family support. It does not prescribe or silently trust AI.”

Show the sign-in safety chip and the labelled demo OTP disclosure. Sign in.

## 0:35–1:45 — Review-first prescription

Open **Scan prescription**. Point out:

1. The image is not sent to cloud providers without consent.
2. Medicine candidates show visible evidence and model confidence.
3. The draft remains editable and unverified.
4. A separate medicine form must be reviewed before save.

If providers are unavailable, choose manual prescription text and say: “The safe fallback is a feature, not a failure.”

## 1:45–2:25 — Simple Mode and offline action

On P, enable **More → Simple Mode**, then enable airplane mode. Show one large dose card, play the Bangla prompt, and confirm the dose. Point to **Pending sync** and say: “One tap; recorded locally and encrypted. This is a self-reported action, not proof of ingestion.”

## 2:25–2:55 — Safe recovery

Force-stop and reopen P while it remains offline. Show the saved plan and pending action. Restore connectivity, press **Sync now**, and show one authoritative result.

## 2:55–4:05 — Live family-care loop

On P, open **Care** and tap **Demo: simulate a missed dose now** (or run `scripts/force-missed-dose.ps1 -Minutes 46`). Within 30 seconds C shows a private local notification and an in-app card. Say: “The caregiver sees the medicine only because that exact permission was accepted.”

On C, tap **Acknowledge** and point to **Call patient**. On P, late-confirm the missed dose. Refresh C and show **Resolved — taken 46 minutes late**. State that the action is self-reported and that revoking the caregiver stops alert access and new fan-out immediately.

## 4:05–4:35 — Inventory and transparent insight

Show the stock movement and app-based indicator with its numerator, denominator, timezone, and non-clinical explanation.

## 4:35–5:00 — Honest close

“Working today: the Android app, offline dose actions, Simple Mode, Bangla device voice, consented caregiver alerts, inventory, and transparent reports. Still gated: production SMS and push, clinical validation, native-language review, and our physical acceptance checks. CareMate supports safer routines; it does not diagnose, prescribe, or prove ingestion.”

## Fallback order

1. If cloud OCR fails, use on-device/manual review.
2. If API fails after sign-in, show cached Today and offline dose action.
3. If notification permission is blocked, show readiness guidance and the scheduled plan.
4. If the physical device fails, use the verified APK on the backup phone.
5. If the caregiver alert does not arrive within 30 seconds, pull to refresh once; then use the recorded two-device run without claiming the live channel passed.
6. If both devices fail, play the privacy-reviewed backup recording, then show CI and architecture evidence.

## Backup recording plan

Record one uninterrupted landscape video after the final release SHA is fixed. Blur status-bar identifiers and use only synthetic data. Capture sign-in, OCR/manual fallback, schedule, offline action/resync, caregiver recap, Bangla/larger text, health/readiness, and the release SHA. Store it outside Git and verify playback offline on the presentation laptop.
