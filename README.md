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

Run the API checks with `pnpm --filter @caremate/api test:integration`. Run the
mobile checks from `apps/mobile` with `flutter analyze && flutter test`.

The current login delivery Adapter is intentionally marked as development-only
and uses the configured demo code. Production login SMS, bdapps carrier billing,
and bKash payments remain gated by provider approval and certification as
described in the specification.
