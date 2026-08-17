# CareMate Release Hardening

## Deploy checklist: competition build

**Date:** 18 August 2026 | **Deployer:** CareMate engineering

### Pre-deploy

- [ ] Draft PR is reviewed and approved; CI is green at the release commit.
- [ ] Flutter analysis, full tests, Android debug/release build, API typecheck, API tests, integration tests, and API build pass.
- [ ] No critical or high-severity known defect affects sign-in, medicine review, reminders, offline dose actions, or caregiver consent.
- [ ] Database migrations are tested against an empty database and a copy of the previous schema.
- [ ] `caremate-secrets.env` is supplied outside Git and contains unique production secrets of at least 32 characters.
- [ ] `PRESCRIPTION_CLOUD_OCR_ENABLED` and `PRESCRIPTION_AI_ENABLED` match the approved provider state.
- [ ] `/api/v1/health` and `/api/v1/health/readiness` return success without secret values.
- [ ] The competition application ID and signing key are confirmed; the existing differently signed app is not overwritten.
- [ ] Rollback owner and last known-good APK/API commit are recorded.

### Deploy

- [ ] Apply migrations before accepting traffic; stop if migration verification fails.
- [ ] Deploy the API and verify health, readiness, sign-in, profile load, and manual medicine entry.
- [ ] Enable cloud OCR only after a consent-path smoke test; enable AI structuring separately.
- [ ] Install the signed competition APK on the target phone and confirm notification permission and exact-alarm readiness.
- [ ] Run the five-minute English journey, Bangla switch, offline dose action, resync, and caregiver permission recap.
- [ ] Observe privacy-safe operational events for 15 minutes.

### Post-deploy

- [ ] Confirm API 5xx rate, OCR fallback rate, request duration, and mobile crash/ANR evidence are nominal.
- [ ] Confirm diagnostics contain no phone number, token, prescription text/image, medicine name, user ID, headers, URL parameters, or request body.
- [ ] Save the release SHA, APK checksum, device model/OS, test summary, and two consecutive rehearsal results.
- [ ] Publish release notes and notify the demonstration team.

## Rollback triggers

Rollback or disable the affected provider when any of these occurs:

- Sign-in, manual medicine entry, reminder creation, or offline sync fails in the release smoke test.
- API 5xx responses exceed 1% for five minutes or health/readiness fails twice consecutively.
- API p95 latency exceeds 1.5 seconds for non-provider requests for ten minutes.
- Prescription provider p95 exceeds 20 seconds, provider failure exceeds 10%, or an unsupported medicine candidate bypasses review.
- Any secret, token, phone number, prescription content, or stable user identifier appears in diagnostics.
- The app attempts a data-destructive overwrite of the differently signed physical-device package.

## Provider controls

| Control                          | Safe state | Effect                                                                   |
| -------------------------------- | ---------- | ------------------------------------------------------------------------ |
| `PRESCRIPTION_CLOUD_OCR_ENABLED` | `false`    | Prevents managed OCR calls; on-device/manual fallback remains available  |
| `PRESCRIPTION_AI_ENABLED`        | `false`    | Prevents OpenAI structuring; primary OCR/manual review remains available |
| `PRESCRIPTION_OCR_PROVIDER`      | `disabled` | Requires an explicit approved provider choice                            |
| `PRESCRIPTION_AI_EXTRACTOR`      | `disabled` | Requires an explicit OpenAI selection                                    |

Provider controls are server-side. The OpenAI API key never enters the mobile app, and OpenAI request storage remains disabled in code.

## Privacy-safe diagnostics

Every API response receives an `x-request-id`. A valid caller-supplied ID may be echoed for end-to-end correlation; unsafe values are replaced. Operational events contain only request ID, HTTP method, controller/handler names, outcome, status, and rounded duration. They deliberately exclude URL, parameters, query, headers, payload, user ID, prescription content, and exception messages.

## Error taxonomy

| Class                | Examples                                | User behavior                    | Operator behavior                               |
| -------------------- | --------------------------------------- | -------------------------------- | ----------------------------------------------- |
| Authentication       | `ACCESS_TOKEN_INVALID`, session revoked | Sign in again                    | Check provider/config only if widespread        |
| Validation           | malformed phone, invalid schedule       | Correct highlighted fields       | No alert unless rate spikes                     |
| Conflict             | stale version, duplicate dose action    | Refresh latest safe state        | Inspect sync conflicts, not user content        |
| Provider unavailable | `OCR_PROVIDER_UNAVAILABLE`              | Continue on-device or manually   | Check readiness and feature flags               |
| Provider failed      | `OCR_EXTRACTION_FAILED`                 | Retry once or use fallback       | Disable provider if threshold is exceeded       |
| Network/offline      | mobile network unavailable              | Use cached plan; sync later      | Verify API health before escalation             |
| Internal             | uncaught 5xx                            | Retry later; preserve local work | Roll back on threshold; correlate by request ID |

## Performance budgets

- App cold start to usable signed-out screen: under 2.5 seconds on the competition phone.
- Cached Today screen after session restore: under 1.5 seconds.
- Non-provider API p95: under 1.5 seconds.
- Prescription provider p95: under 20 seconds with progress copy and manual fallback always available.
- Touch response: visible feedback within 100 milliseconds.
- Release APK: investigate any compressed-size increase above 10% from the recorded baseline.

These are release gates to measure during Segment 5; they are not unverified production claims.
