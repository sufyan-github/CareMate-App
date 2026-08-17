# CareMate

CareMate is a Bangladesh-first medication-support and family-care platform specification. It covers prescription capture and confirmation, offline medication reminders, dose reporting, caregiver escalation, inventory, authentication by OTP, and provider-independent subscriptions.

## Documentation

- [Complete product and technical specification](outputs/CareMate_COMPLETE_SPECIFICATION.md)
- [Discovery report](outputs/CareMate_DISCOVERY_REPORT.md)
- [Research evidence](outputs/CareMate_RESEARCH_EVIDENCE.md)
- [Canonical domain context](CONTEXT.md)

## Implemented segments

- NestJS API with tracked libSQL/Turso migrations and database health checks
- Android-first Flutter application shell with accessible Material 3 UI
- Bangladesh phone normalization and development OTP authentication
- Encrypted phone storage, hashed OTPs, request throttling, and attempt lockout
- Signed access tokens, rotating refresh tokens, reuse detection, and device sessions
- Secure mobile refresh-token storage, session restore, and sign-out flow
- Patient profile onboarding with timezone-aware, versioned updates
- Owner-authorized medication records and explicit dose instructions
- Mobile medication entry and list experience backed by the API
- Deterministic daily or selected-weekday schedule preview with skipped dates,
  quantity planning, explicit activation, rolling open-ended Dose Occurrences,
  and timezone-correct UTC conversion
- Versioned schedule editing plus pause, resume, and end controls that preserve
  historical occurrences and only replace eligible future Dose Occurrences
- Versioned, idempotent Dose Occurrence commands for self-reported confirm,
  snooze, skip, automatic missed classification, and preserved late outcomes
- Immutable medication inventory ledgers with unit-bound opening/restock/
  correction entries, exactly-once confirmed-dose consumption, low-stock
  thresholds, and schedule-based estimated run-out forecasts
- Transparent 7/30-day app-based adherence indicators with explicit numerator,
  denominator, timezone, outcome breakdown, exclusions, and non-clinical copy
- Android local notifications with private lock-screen copy, confirm/snooze/
  skip actions, exact-alarm readiness, best-allowed inexact fallback, and a
  rolling 14-day reconciliation window
- Operational Today dose actions and notification centre with explicit
  permission/timing guidance and upcoming planned reminders
- Account-scoped, SQLCipher-compatible Drift storage for the saved profile,
  medication plan, Dose Occurrences, and immutable offline Sync Mutations
- Local-first dose actions with optimistic pending state, safe rollback on
  rejection, authoritative conflict resolution, manual sync, and encrypted
  cold-start use when the API is unreachable
- Batched idempotent Sync Mutation API, session-bound device installation
  registration, rotating background token refresh, and constrained Android
  WorkManager retries
- Separate caregiver permissions for medication-plan timing and private
  self-reported dose outcomes
- Prescription capture with on-device fallback, explicit cloud consent,
  Bangladesh-capable Document AI integration, evidence-bound OpenAI
  structuring, image validation, and mandatory human review
- Consent-based caregiver invitations, acceptance/decline, granular
  permissions, audit events, read-only shared plans, and immediate revocation
- Account-persisted language/privacy preferences, real device sessions,
  per-session/all-session revocation, and guarded deletion requests

## Run locally

1. Copy `.env.example` to `.env` or create the ignored
   `caremate-secrets.env`. Set `TURSO_DATABASE_URL`, `TURSO_AUTH_TOKEN`, and
   unique 32+ character signing/encryption secrets. Never commit this file.
2. From the repository root, install dependencies with `pnpm install`.
3. Start the API in terminal one:

   ```bash
   pnpm --filter @caremate/api dev
   ```

4. Confirm the API and database are ready:

   ```bash
   curl http://127.0.0.1:3000/api/v1/health
   ```

5. Start an Android emulator in terminal two:

   ```bash
   cd apps/mobile
   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1
   ```

For a USB-connected physical Android phone with USB debugging authorized, keep
the API running and use:

```bash
./scripts/run-physical-android.sh
```

The script validates API health, discovers the phone, configures `adb reverse`
for port 3000, and starts Flutter with the correct physical-device API URL.

## Test and verify

Run the complete automated checks:

```bash
pnpm --filter @caremate/api test:integration
cd apps/mobile
flutter analyze
flutter test
flutter build apk --debug
```

With `.env.example` development defaults, enter any valid Bangladesh mobile
number and use OTP `123456`. Then verify these flows:

1. Create a patient profile and add a medicine.
2. Open the medicine, choose the schedule dates and confirmed dose times,
   preview the occurrence count and required quantity, then activate it. Verify
   the dose appears on Today and that pause, resume, edit, and end work.
3. On Today, confirm a due occurrence. With another occurrence, verify a
   10-minute snooze and skip confirmation. Repeating an action must not create
   a duplicate outcome or inventory consumption entry.
4. Open Notifications, enable Android notification permission, and allow
   precise alarms when offered. If precise alarms remain unavailable, verify
   the page reports best-allowed timing and still lists the 14-day plan.
5. Lock the phone and verify the notification hides the medicine name. Open it
   and verify Confirm, Snooze 10 min, and Skip update the same Today occurrence.
6. Scan a prescription, choose on-device or consented cloud OCR, review the
   draft, and confirm that nothing is saved before the medication form.
7. Create a caregiver invitation for a different phone number. Sign in as that
   number, accept it, verify the plan is read-only, then revoke access as owner.
8. In More, change language/privacy preferences, inspect actual sessions,
   revoke another device, and verify the guarded deletion confirmation.
9. While online, open Today once so the confirmed plan is cached. Stop the API
   or remove the physical-phone tunnel, force-stop CareMate, and reopen it.
   Verify “Showing the saved plan on this phone” appears without signing out.
10. With a due Dose Occurrence and the API unavailable, choose Confirm,
    Snooze, or Skip. Verify “Pending sync” appears and the action buttons are
    hidden. Reopen the app to prove the change survived, restore the API, then
    choose “Sync now” and verify the server state replaces the pending state.
11. Open Insights, record an opening quantity or restock, and set a low-stock
    threshold. Verify the estimated stock changes and a confirmed dose reduces
    it once. Switch between 7 and 30 days and confirm the app-based indicator
    explains its self-reported numerator, denominator, outcomes, and exclusions.

The debug APK is written to
`apps/mobile/build/app/outputs/flutter-apk/app-debug.apk`.

## OCR/AI provider configuration

The default development OCR provider is deterministic and production-disabled.
For the recommended Bangladesh pilot configuration, set these only on the API
server:

```dotenv
PRESCRIPTION_OCR_PROVIDER=google-document-ai
GOOGLE_DOCUMENT_AI_PROJECT_ID=your-project
GOOGLE_DOCUMENT_AI_LOCATION=asia-south1
GOOGLE_DOCUMENT_AI_PROCESSOR_ID=your-processor
PRESCRIPTION_AI_EXTRACTOR=openai
OPENAI_API_KEY=your-rotated-server-key
OPENAI_PRESCRIPTION_MODEL=gpt-5.6-sol
```

See [the OCR model evaluation](docs/OCR_MODEL_EVALUATION.md) before enabling
real prescription uploads.

The current login delivery Adapter is intentionally marked as development-only
and uses the configured demo code. Production login SMS, bdapps carrier billing,
and bKash payments remain gated by provider approval and certification as
described in the specification.

Device installation metadata is registered now. A real FCM token is not
collected until Firebase project credentials and platform configuration are
provided; local Android alarms remain the medication reminder authority.
