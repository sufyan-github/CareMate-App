# CareMate Competition One-Pager

## The problem

Medication support breaks down between a handwritten prescription, a busy household, unreliable connectivity, and the moment a person must decide what to do. Generic reminder apps expect clean manual data and rarely make family access, offline behavior, or AI uncertainty visible.

## The CareMate answer

CareMate is a Bangladesh-first medication-support system. It turns a prescription image into an explicitly unverified review draft, helps the patient activate deterministic local reminders, records self-reported dose outcomes offline, forecasts medicine run-out, and shares only patient-approved information with a caregiver.

## Why it is different

- **Review-first AI:** OpenAI focuses on visibly supported medicine names, exposes evidence and confidence, never activates a schedule, and fails closed when evidence is missing.
- **Offline authority:** Android reminders and dose actions work from an encrypted local plan; queued changes sync later with version-aware conflict handling.
- **Consent-based family care:** The patient selects each caregiver permission, reviews the exact grant, and can revoke it.
- **Bangladesh-first UX:** Bangladesh phone validation, Asia/Dhaka scheduling, live English/বাংলা critical paths, larger text, and Bangla/handwriting OCR consent.
- **Operational trust:** Provider kill switches, manual fallback, secret-free readiness, privacy-safe correlation, encrypted tokens/phone values, and explicit demo-only delivery.

## Architecture

```text
Flutter Android app
  ├─ secure session + encrypted Drift cache
  ├─ local reminders + offline dose outbox
  └─ review-first prescription and caregiver UX
                │ HTTPS / versioned JSON
NestJS modular API
  ├─ authentication and encrypted identifiers
  ├─ patient medication + deterministic schedule engine
  ├─ dose lifecycle, sync, inventory, reporting, care access
  └─ provider adapters + kill switches + safe diagnostics
                │
SQLite/libSQL data model       Google OCR / OpenAI (optional)
```

The competition build remains a modular monolith: one deployable API, one mobile client, and clear module boundaries. This minimizes live-demo failure while preserving paths to managed database, approved SMS, push delivery, and controlled pilots.

## Safety boundary

CareMate does not diagnose, prescribe, check interactions, or prove medicine ingestion. OCR and AI output is an editable draft. Adherence is an app-based indicator of self-reported outcomes. Manual medicine entry always remains available.

## Evidence

- Mobile analysis, behavioral tests, accessibility/large-text tests, and golden tests.
- API typecheck, unit/integration suites, build, feature-flag, readiness, and diagnostic-privacy tests.
- Reproducible CI artifact and physical-device runner using `com.caremate.competition` so existing app data is not overwritten.
- Five-minute judge script, deterministic demo seeding, rollback triggers, and rehearsal log.

## Next proof after competition

A consented, de-identified Bangladesh prescription benchmark and a 30–50 patient/caregiver closed pilot, both subject to qualified clinical, privacy, legal, and native-language review.
