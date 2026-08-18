# CareMate — Implemented App Features

**Status:** Competition-ready MVP implemented  
**Last updated:** 18 August 2026  
**Platforms:** Flutter Android app and NestJS API

## Current product

CareMate is a Bangladesh-first medication-support and family-care application. The implemented app can turn manually entered or extracted prescription information into a user-reviewed medication plan, schedule local reminders, record self-reported dose outcomes offline, track estimated stock, and share approved information with a caregiver.

CareMate does not diagnose, prescribe, check medicine interactions, or prove that medicine was swallowed. Prescription extraction always produces an editable, unverified draft.

## Implementation status

| Area                       | Status               | What is available                                                                |
| -------------------------- | -------------------- | -------------------------------------------------------------------------------- |
| Android application        | Done                 | Flutter Material 3 application with five operational sections                    |
| API                        | Done                 | NestJS modular monolith with versioned `/api/v1` endpoints                       |
| Database                   | Done                 | Prisma-backed SQLite/libSQL schema and tracked migrations                        |
| Authentication             | Done for competition | Bangladesh phone validation and clearly labelled development OTP                 |
| Medication lifecycle       | Done                 | Profiles, medicines, instructions, schedules, occurrences, and dose actions      |
| Offline operation          | Done                 | Encrypted local cache, durable mutation outbox, retry, and conflict handling     |
| Prescription capture       | Done with fallback   | Image capture, on-device OCR, optional cloud providers, and mandatory review     |
| Caregiver access           | Done                 | Invitations, acceptance, permissions, read-only access, audit, and revocation    |
| Inventory and insights     | Done                 | Immutable stock ledger, run-out estimate, low-stock threshold, and indicators    |
| Notifications              | Done locally         | Private Android reminders with confirm, snooze, and skip actions                 |
| Localization/accessibility | Competition ready    | Critical English/Bangla flows, larger text, Simple Mode core, and large controls |
| Competition workflow       | Done                 | Synthetic seed, presenter guide, CI APK, judge script, and device runner         |

## Mobile application

### Authentication and account security

- Bangladesh mobile-number normalization and validation.
- OTP request and verification flow.
- Development OTP is visibly identified as a demo; the app does not claim an SMS was sent.
- Signed access tokens and rotating refresh sessions.
- Secure refresh-token storage on the device.
- Session restoration, sign-out, and automatic access-token refresh.
- Device and session list with individual or all-session revocation.
- Guarded account-deletion request.

### Patient Profile and medication entry

- Create one owned Patient Profile with display name and timezone.
- Open a consented shared Patient Profile as a caregiver.
- Add and edit medications with:
  - Display name and form.
  - Strength and strength unit.
  - Dose quantity and unit.
  - Route and meal relation.
  - Notes and reviewed source text.
- Separate owner management and caregiver read-only behavior.

### Prescription capture and review

- Capture a prescription image or choose one from the gallery.
- On-device text recognition using ML Kit.
- Optional consented server-side OCR through a provider abstraction.
- Google Document AI integration path.
- Optional OpenAI evidence-bound medicine-name extraction.
- Manual text-entry fallback when OCR is unavailable.
- Image validation and provider kill switches.
- Evidence source, confidence wording, warnings, and editable fields.
- Explicit review before information is copied into the medication form.
- No automatic schedule activation from OCR or AI output.

For provider limitations and evaluation requirements, see [OCR model evaluation](OCR_MODEL_EVALUATION.md).

### Medication schedules

- Daily and selected-weekday recurrence.
- Asia/Dhaka and other valid IANA timezone handling.
- Multiple dose times per day.
- Start date, optional end date, open-ended schedules, and excluded dates.
- Deterministic preview showing occurrences and required quantity.
- Explicit schedule activation.
- Pause, resume, edit, and end operations.
- Version checks that prevent stale schedule changes.
- Historical occurrences remain preserved when future plans change.
- Rolling generation of future Dose Occurrences.

### Today and dose actions

- Today view for planned Dose Occurrences.
- Clear planned, confirmed, snoozed, skipped, missed, private, and pending-sync states.
- Self-reported confirm action, including late confirmation.
- Ten-minute snooze.
- Skip action with a safety confirmation.
- Idempotent dose commands to prevent duplicate outcomes.
- Optimistic offline state with visible pending-sync status.
- Manual “Sync now” control and automatic background retry.

### Android reminders

- Local Android notifications remain the reminder authority.
- Notification permission and channel readiness checks.
- Exact-alarm readiness with best-available inexact fallback.
- Private lock-screen text that does not expose the medicine name.
- Confirm, snooze, and skip actions from notifications.
- Rolling 14-day reminder reconciliation.
- Upcoming reminder centre and timing guidance.

### Offline reliability

- SQLCipher-compatible encrypted Drift database.
- Account-bound cached profile, medicines, schedules, and Dose Occurrences.
- Immutable local Sync Mutation outbox.
- Cold-start access to the saved plan when the API is unavailable.
- Offline confirm, snooze, and skip actions survive an app restart.
- Batched server synchronization with idempotency keys.
- Version-aware conflict resolution and safe rollback for rejected changes.
- Android WorkManager background retry when network access returns.

### Inventory and app-based insights

- One quantity-unit-bound Inventory Position per medication.
- Immutable opening, restock, correction, and confirmed-consumption adjustments.
- Exactly-once stock consumption for a confirmed Dose Occurrence.
- Optimistic version checks for low-stock threshold changes.
- Estimated remaining quantity, days remaining, and projected run-out date.
- Seven-day and 30-day app-based adherence indicators.
- Separate on-time, late, skipped, missed, unresolved, future, and cancelled counts.
- Visible numerator, denominator, timezone, exclusions, and non-clinical explanation.

### Consent-based caregiver access

- Invite a caregiver using a different Bangladesh phone number.
- Explicit permissions for:
  - Viewing the medication plan.
  - Viewing self-reported dose outcomes.
  - Receiving missed-dose alerts.
  - Viewing inventory.
  - Managing inventory when specifically allowed.
- Invitation acceptance and decline.
- Read-only shared profile and medication-plan view.
- Immediate owner revocation.
- Invitation lifecycle audit events.
- Demo delivery is labelled as in-app; no SMS delivery is implied.
- Persisted missed-dose caregiver alerts with immutable generated, delivered, acknowledged, and resolved events.
- Configurable 15–60 minute grace window with a 45-minute default.
- Permission-filtered alert fan-out to accepted caregivers only, with immediate revocation enforcement.
- Medicine-name redaction when medication-plan permission is absent.
- Quiet-hour queueing from 22:00 to 07:00 in the Patient Profile timezone.
- Caregiver alert centre with 30-second foreground polling, private local notification, acknowledge, and call actions.
- Automatic “Resolved — taken N minutes late” state after a late self-reported confirmation.
- Competition-only synthetic miss button and `scripts/force-missed-dose.ps1` helper.

The two-device latency, lock-screen, quiet-hour, and revocation rehearsal remains the explicit T0-2 physical acceptance gate. See the [competition master plan](COMPETITION_MASTER_PLAN.md).

### Settings, localization, and accessibility

- English and Bangla critical-path copy.
- Persisted account language preference.
- Larger-text/older-adult display preference.
- Material 3 light and dark themes.
- Minimum 48 logical-pixel primary controls.
- Screen-reader semantics for important status and action elements.
- Status cards that combine icon, title, text, and action instead of color alone.
- Tests for 200% text scaling on the Today dose flow.
- Persisted Simple Mode and Bangla-voice preferences on the account and phone.
- Two-tap Simple Mode entry from the More section.
- One dose per screen with a 144 dp medication pictogram and explicit form label.
- Time-of-day and meal-relation pictograms paired with text.
- Two 76 dp primary dose actions and long-press protection for Skip.
- Always-visible Simple Mode exit control and hidden secondary navigation.
- Deterministic Bangla dose-announcement text with `bn-BD` then `bn-IN` device-voice fallback.

Physical airplane-mode speech, bundled audio fallback, notification-tap speech, pictogram comprehension, and native Bangla review remain explicit T0-1 acceptance gates. See the [competition master plan](COMPETITION_MASTER_PLAN.md).

## API and platform implementation

The backend is a modular NestJS monolith. Implemented modules include:

- Authentication, OTP risk limits, access tokens, and refresh sessions.
- Account preferences, device sessions, and deletion requests.
- Patient Profiles, medications, and Dose Instructions.
- Medication schedules and deterministic occurrence generation.
- Dose lifecycle commands and immutable events.
- Offline Sync Mutation processing.
- Inventory ledger and run-out forecasting.
- App-based reporting.
- Prescription-extraction provider adapters.
- Caregiver invitations, permissions, audit, and authorization.
- Caregiver missed-dose fan-out, quiet-hour delivery, acknowledgement, resolution, and immutable alert audit.
- Device-installation metadata.
- Health, readiness, request IDs, and privacy-safe operational metrics.

The database includes tracked migrations for the foundation schema, authentication, account preferences, care access, prescription extraction, schedules, dose lifecycle, synchronization, device metadata, encrypted push tokens, inventory, Simple Mode preferences, and caregiver alerts.

## Privacy, safety, and operations

- Phone values are encrypted for storage and separately hashed for lookup.
- OTP values are hashed and protected by resend, attempt, and rate limits.
- Refresh tokens rotate, and reuse detection can revoke compromised sessions.
- API responses include a safe correlation request ID.
- Operational diagnostics exclude phone numbers, tokens, prescription content, medicine names, request bodies, headers, URL parameters, and stable user identifiers.
- Cloud OCR and AI extraction have independent server-side enable flags and kill switches.
- Manual medication entry remains available when providers fail.
- Readiness checks report provider availability without exposing secrets.
- The app consistently describes dose confirmations as self-reported outcomes.

See [release hardening](RELEASE_HARDENING.md) for rollback triggers, provider controls, error classes, and performance budgets.

## Competition package

- Separate Android package ID: `com.caremate.competition`.
- Competition name: **CareMate Competition**.
- Competition-only five-step presenter guide opened from the trophy icon.
- The guide is excluded from ordinary builds unless `COMPETITION_DEMO=true` is supplied.
- Idempotent PowerShell seed creates:
  - A synthetic owner and Patient Profile.
  - A reviewed demo medication.
  - A daily schedule with an immediately due target and upcoming occurrences.
  - Fourteen tablets of opening stock.
  - A low-stock threshold of three tablets.
  - A synthetic caregiver with accepted permissions.
- Physical Android runner checks API health, configures `adb reverse`, builds, installs, resets only the competition package when requested, and launches the app.
- CI runs API and Flutter checks and uploads the competition debug APK.

Competition references:

- [Competition demo contract](COMPETITION_DEMO_CONTRACT.md)
- [Five-minute judge script](COMPETITION_JUDGE_SCRIPT.md)
- [Competition one-pager](COMPETITION_ONE_PAGER.md)
- [Physical rehearsal evidence](PHYSICAL_REHEARSAL.md)
- [Competition roadmap](COMPETITION_ROADMAP.md)

## Verification completed

The current working implementation has passed:

- API TypeScript typecheck.
- API unit suite: 59 tests.
- API integration suite: 59 tests.
- API Prisma generation and NestJS build.
- Flutter static analysis with no issues.
- Flutter suite: 62 tests, including reviewed golden tests.
- Android competition debug APK build with `COMPETITION_DEMO=true`.
- Current competition APK: 222,208,109 bytes, SHA-256 `8A489037D09C4621A705DACD85E4D03A2A7EEBE3DDC3C6FDCE0D065FCBF6232C`.
- Competition seed against an isolated in-memory API.
- Competition force-miss helper against the compiled isolated API, producing a synthetic `MISSED` occurrence.
- Two consecutive seed executions using the same synthetic accounts, confirming idempotency.
- Previous two-run physical-device rehearsal on a Motorola edge 60 fusion running Android 16.

## Not implemented or externally gated

The following are intentionally not claimed as complete:

- Production OTP/SMS delivery and provider approval.
- Production Firebase caregiver push delivery.
- Production Android signing and store distribution.
- A validated Bangladesh prescription benchmark using consented, de-identified data.
- Qualified clinical, legal, privacy, and native-language pilot approval.
- Production bKash, bdapps, or subscription charging.
- Pharmacy, clinician, or facility integrations.
- Clinical diagnosis, prescribing, interaction checking, or proof of ingestion.
- A controlled 30–50 patient/caregiver pilot.

These items are pilot or production gates, not blockers for the competition demonstration.

## Run the implemented competition app

Start the API from the repository root:

```powershell
corepack pnpm --filter @caremate/api dev
```

In another PowerShell terminal, prepare the synthetic demonstration:

```powershell
.\scripts\prepare-competition-demo.ps1
```

Connect an authorized Android phone and run:

```powershell
.\scripts\run-competition-device.ps1
```

The normal development and complete verification instructions remain in the project [README](../README.md).
