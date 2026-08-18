# Competition demo contract

## Purpose

This document is the operational contract for a five-minute physical CareMate demonstration. It prevents feature drift and makes success observable.

## Required environment

- Two authorized Android phones with at least 50% battery, labelled patient (**P**) and caregiver (**C**).
- CareMate competition build installed with a known signing identity.
- Local API healthy and reachable through a verified USB reverse tunnel, or an approved remote demo API.
- Synthetic demo accounts only.
- Development OTP visibly labelled; no claim that an SMS was delivered.
- OpenAI/managed OCR either configured server-side or deliberately disabled with a manual-entry fallback prepared.
- Notifications allowed and exact-alarm readiness checked before judging.
- Competition build compiled with `COMPETITION_DEMO=true`; the trophy action opens the presenter-only five-minute guide.
- API started with the separate server environment value `COMPETITION_DEMO=true`; otherwise the synthetic miss endpoint intentionally returns not found.

## Five-minute script

Run `scripts/prepare-competition-demo.ps1` first. It idempotently prepares the synthetic owner, a due and upcoming dose, 14 tablets of opening stock with a low-stock threshold, and an accepted synthetic caregiver relationship. The script never sends SMS or uses real patient data. `scripts/force-missed-dose.ps1 -Minutes 46` is the deterministic caregiver-alert trigger and is accepted only when the API has `COMPETITION_DEMO=true`.

### 0:00–0:30 — Problem and differentiation

State the problem: medication plans are hard to translate into reliable daily action, especially across connectivity, language and family-care constraints. Show the CareMate promise: reviewed capture, offline reminders, self-reported outcomes, inventory and consent-based caregiver visibility.

### 0:30–1:15 — Safe onboarding

Sign in with the labelled demo OTP. Show English/Bangla selection and the privacy boundary. Select the synthetic Patient Profile.

### 1:15–2:15 — Prescription to verified plan

Capture a prepared synthetic prescription. Point out cloud consent, OCR evidence, confidence wording and the editable unverified draft. Correct one field deliberately. Continue to the medication form and activate a schedule only after explicit review.

### 2:15–3:15 — Today and offline reliability

Show the next Dose Occurrence, snooze it, then disable the API tunnel and confirm another synthetic occurrence. Show “Pending sync”, kill and reopen the app, and prove the saved plan and pending action remain.

### 3:15–4:15 — Live family-care loop

Restore the tunnel and sync. Force a synthetic miss on P. C must show the private alert through the foreground 30-second poll, acknowledge it, and expose the call action. Late-confirm on P, then show the automatically resolved minutes-late state on C. Explain consent, medicine-name redaction, quiet hours, and immediate revocation.

### 4:15–5:00 — Evidence and close

Show the app-based indicator with its numerator, denominator and non-clinical caveat. Close with the architecture, safety boundary and Bangladesh pilot plan. Do not claim clinical validation, production provider approval or market validation.

## Pass criteria

- The full script completes without code changes, database edits or command-line data repair.
- No real phone number, medicine, prescription, caregiver or message is shown.
- Every OCR/AI field remains editable and no schedule activates without confirmation.
- Offline cold start and pending mutation survive one force-stop.
- Restoring connectivity produces one authoritative outcome and one inventory consumption entry.
- Screen text is readable at arm’s length and all primary actions have clear labels.
- The presenter can explain what is implemented, what is simulated and what is externally gated.
- The caregiver loop completes miss → alert → acknowledge → late-confirm → resolve in at most 60 seconds outside quiet hours.
- A caregiver without medication-plan permission sees no medicine name.
- Revoking the caregiver prevents alert reads and all future fan-out immediately.

## Abort and fallback rules

- If cloud OCR fails, say so plainly and use the prepared manual-entry route.
- If the API is unavailable before the offline section, use the saved synthetic plan and explain the local-first boundary.
- If notifications are blocked by device settings, show the readiness screen and the planned reminder list; do not claim an alarm fired.
- If the device cannot be updated because of signing mismatch, use the verified installed build only if its commit is known; otherwise switch to the backup device/video.
- Never use a real prescription to rescue the demo.

## Evidence package

- Commit SHA and APK SHA-256.
- API and Flutter test summaries.
- Physical device model, Android version and readiness results.
- Architecture diagram and data-safety boundaries.
- English and Bangla screenshots of the critical path.
- A two-minute offline backup video recorded from the same verified build.
