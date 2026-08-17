# CareMate Five-Minute Judge Script

## Before entering the room

- Run `scripts/prepare-competition-demo.ps1` against the local API.
- Run `scripts/run-competition-device.ps1` and confirm package `com.caremate.competition` is foregrounded.
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

## 1:45–2:35 — Deterministic reminders

Show the reviewed Napa entry and its seeded due-now Asia/Dhaka schedule. Explain that Android schedules local reminders; the server does not need to be reachable at dose time.

## 2:35–3:25 — Offline dose action

Disable network or stop API access. Confirm, snooze, or skip the due demo dose. Show **Pending sync** and the saved-phone explanation. Restore connectivity, press **Sync now**, and show the resolved state.

## 3:25–4:15 — Consent-based care

Open **Care**, enter the synthetic caregiver number, choose permissions, and stop at the recap. Read the acceptance boundary: no access begins until the recipient accepts; no SMS is claimed in this demo. Confirm, show pending state, then show revocation.

## 4:15–4:45 — Bangladesh and accessibility

Open **More → Language**, select বাংলা, and enable larger text. Return to Today to show immediate Bangla navigation and reflow. Explain that interface translation never changes medicine names or medical meaning and still requires native review before a pilot.

## 4:45–5:00 — Close

“CareMate’s advantage is not an AI claim. It is the complete trust loop: visible evidence, human review, deterministic reminders, offline resilience, and patient-controlled family care.”

## Fallback order

1. If cloud OCR fails, use on-device/manual review.
2. If API fails after sign-in, show cached Today and offline dose action.
3. If notification permission is blocked, show readiness guidance and the scheduled plan.
4. If the physical device fails, use the verified APK on the backup phone.
5. If both devices fail, play the privacy-reviewed backup recording, then show CI and architecture evidence.

## Backup recording plan

Record one uninterrupted landscape video after the final release SHA is fixed. Blur status-bar identifiers and use only synthetic data. Capture sign-in, OCR/manual fallback, schedule, offline action/resync, caregiver recap, Bangla/larger text, health/readiness, and the release SHA. Store it outside Git and verify playback offline on the presentation laptop.
