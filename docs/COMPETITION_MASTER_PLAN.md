# CareMate Competition Master Plan — Execution Tracker

**Owner:** Abu Sufyan  
**Runway:** 14 days to demonstration  
**Updated:** 18 August 2026  
**Baseline:** [Implemented app features](IMPLEMENTED_APP_FEATURES.md)

## Objective

Turn CareMate's already strong engineering implementation into a memorable, evidence-backed competition entry. New work is limited to the Tier 0 and Tier 1 items below. Anything else remains out of scope until after the competition.

Every addition must either appear in the five-minute demonstration or answer a question judges are very likely to ask.

## Frozen product boundary

CareMate converts manually entered or extracted prescription information into a user-reviewed medication plan, schedules local reminders, records self-reported dose outcomes offline, estimates stock, and shares explicitly approved information with a caregiver.

CareMate does not diagnose, prescribe, check medicine interactions, or prove ingestion. Prescription extraction always produces an editable, unverified draft.

## Competition gaps

| Gap                                                      | Severity | Planned response |
| -------------------------------------------------------- | -------- | ---------------- |
| Caregiver missed-dose alert is not visible end to end    | Critical | T0-2             |
| Text-first UX excludes some older and low-literacy users | Critical | T0-1             |
| No primary user-interview evidence                       | Critical | T0-5             |
| Bangladesh differentiation needs a visible proof point   | Critical | T0-1 and T0-3    |
| No measured OCR accuracy result                          | High     | T0-6             |
| No doctor-visit report                                   | High     | T0-4             |
| Demo still depends on laptop/API connectivity            | Medium   | T0-7             |

## Tier 0 backlog

| ID   | Deliverable                                        | Current status                                    | Exit gate                                                        |
| ---- | -------------------------------------------------- | ------------------------------------------------- | ---------------------------------------------------------------- |
| T0-1 | Simple Mode, Bangla voice, and pictogram dose card | **Core implemented; physical audio gate remains** | Airplane-mode Bangla speech and fallback verified on phone       |
| T0-2 | Live caregiver missed-dose loop                    | **Core implemented; two-device gate remains**     | Miss → alert → acknowledge → late-confirm resolve on two devices |
| T0-3 | Bangladesh medicine knowledge pack                 | Not started                                       | Versioned offline dataset and ranked autocomplete                |
| T0-4 | Doctor-visit PDF/share report                      | Not started                                       | Bilingual offline PDF generated and shared                       |
| T0-5 | User evidence pack                                 | Externally coordinated                            | At least 12 consented interviews synthesized honestly            |
| T0-6 | OCR self-evaluation                                | Dataset required                                  | Published method and per-segment result table                    |
| T0-7 | Airplane-mode demo hardening                       | Partially covered by existing offline cache       | Full stage script passes without network repair                  |

## T0-1 implementation record

Implemented:

- `simpleMode` and `voicePromptsEnabled` account preferences with a tracked Prisma migration.
- Matching encrypted local preferences for immediate offline restoration.
- Simple Mode available in two taps: **More → Simple Mode**.
- Account and phone persistence, with safe rollback messaging when server save fails.
- Normal five-tab navigation replaced by one dose per screen while the mode is enabled.
- Always-visible back/exit control.
- 144 dp medication-form pictogram with a deterministic color band and text label.
- Time-of-day pictogram and explicit time text.
- Meal-relation pictogram and explicit meal text.
- 76 dp confirm and later actions.
- Skip protected behind a long press on Later plus a confirmation dialog.
- Explicit self-reported-action explanation.
- Bangla announcement template with Bangla digits and dose/meal translation.
- Device TTS locale order: `bn-BD`, then `bn-IN`.
- Clear fallback message when a Bangla device voice is unavailable.
- No medicine name or announcement text is written to logs.
- Drift schema migration preserving meal relation for offline pictograms.
- Tests at 200% text scaling, preference restoration, API persistence, announcement generation, actions, and exit behavior.

Still required before T0-1 is marked fully complete:

- Validate `bn-BD` or `bn-IN` speech with the phone in airplane mode.
- Add and verify consented, locally produced bundled Bangla fallback clips if the competition phone lacks an offline Bangla voice.
- Validate speech after opening a notification while respecting the lock-screen privacy rule.
- Conduct the blurred-text/non-reader pictogram comprehension check.
- Record a qualified native Bangla copy review.
- Replace the Material form-symbol set with the planned 18 custom SVGs if comprehension testing shows the standard symbols are insufficient.

## T0-2 implementation record

Implemented:

- Tracked `CaregiverAlert` and immutable `CaregiverAlertEvent` database migration.
- Idempotent fan-out keyed by Dose Occurrence and accepted caregiver invitation.
- Profile-level missed-dose grace window, defaulting to 45 minutes and adjustable to 15, 30, 45, or 60 minutes.
- Recipient filtering by active acceptance and `canReceiveMissedDoseAlerts`; revocation blocks access and future fan-out immediately.
- Medicine-name redaction unless `canViewMedicationPlan` is granted.
- Quiet-hour queuing from 22:00 to 07:00 in the Patient Profile timezone.
- Authenticated list, acknowledge, and audit endpoints.
- Automatic alert resolution after a late self-reported confirmation, including minutes-late text.
- Immutable generated, delivered-in-app, acknowledged, and resolved events.
- Caregiver alert centre with 30-second foreground polling, manual refresh, acknowledge, and `tel:` call action.
- Private Android local notification whose lock-screen body omits the medicine name.
- Existing 15-minute WorkManager cycle also polls for newly delivered caregiver alerts in the background; the stage timing guarantee comes from the foreground 30-second channel.
- Competition-only in-app simulate button and `scripts/force-missed-dose.ps1` command.
- API integration coverage for full resolution, privacy redaction, and revocation; mobile coverage for transport, private presentation, notification dispatch, acknowledgement, and demo trigger.

Still required before T0-2 is marked fully complete:

- Run miss → alert → acknowledge → late-confirm → resolved on two physical devices twice consecutively.
- Record the measured alert latency and confirm it is at most 60 seconds while the caregiver Care screen is foregrounded.
- Verify `adb reverse` for both devices and the private lock-screen notification on the selected competition phones.
- Exercise a quiet-hour queued alert and a mid-rehearsal revocation on physical hardware.

## Evidence work that cannot be fabricated

The team must supply real, consented inputs for these items:

- Interview participants and schedules.
- Verbatim anonymized quotes.
- Survey responses.
- Synthetic/de-identified OCR evaluation images and ground truth.
- Named Bangla reviewer.
- Competition rubric and deadline if available.

Do not invent users, quotes, accuracy percentages, market numbers, validation, partnerships, or clinical claims.

## Five-minute demonstration sequence

1. Show the problem and the Bangladesh-specific inclusion gap.
2. Enter Simple Mode, enable airplane mode, hear the Bangla prompt, and report the dose.
3. Show the offline action surviving restart and synchronizing once.
4. Force a synthetic miss and show the second-device caregiver alert.
5. Show inventory, the transparent app-based indicator, and the safety boundary.
6. Close with measured evidence, pilot request, and the exact external gates.

## Freeze rule

Code freezes three days before the event. The final three days are reserved for physical-device rehearsal, evidence, pitch delivery, Q&A drills, backup video, device charging, and duplicate offline backups.

## Current verified competition artifact

- Path: `apps/mobile/build/app/outputs/flutter-apk/app-debug.apk`
- Build flags: `COMPETITION_DEMO=true`, `API_BASE_URL=http://127.0.0.1:3000/api/v1`
- Size: 222,208,109 bytes
- SHA-256: `8A489037D09C4621A705DACD85E4D03A2A7EEBE3DDC3C6FDCE0D065FCBF6232C`
- Automated verification: 59 API tests, 62 Flutter tests, clean TypeScript/Flutter analysis, Prisma generation, Nest build, and Android competition APK build.
- Operational verification: the real competition seed and `force-missed-dose.ps1 -Minutes 46` completed against a compiled API with an isolated in-memory database; the occurrence reached `MISSED` and no synthetic data was retained.
- Physical verification status: pending the T0-1 audio/comprehension gates and T0-2 two-device rehearsal listed above.

## Master acceptance checklist

### Product

- [ ] T0-1 passes all physical audio and comprehension gates.
- [ ] T0-2 passes the two-device caregiver loop twice consecutively.
- [ ] T0-3 offline medicine suggestions are versioned and tested.
- [ ] T0-4 bilingual report generates offline.
- [ ] T0-7 entire demonstration passes in the failure configuration.

### Evidence

- [ ] At least 12 interviews are synthesized with consent and no identifiers.
- [ ] Two cut features are documented with evidence.
- [ ] OCR evaluation method, sample counts, and results are published.
- [ ] Architecture and ER diagrams are exported.
- [ ] Test counts and physical build identity are current.
- [ ] Privacy controls are summarized in one page.

### Presentation

- [ ] Eight slides or fewer.
- [ ] Live product segment is no longer than 150 seconds.
- [ ] Claims clearly distinguish implemented, simulated, gated, and planned work.
- [ ] Ninety-second offline backup video exists on two devices and removable storage.
- [ ] Two phones, two cables, a power bank, and screen mirroring are tested.
- [ ] Two timed rehearsals pass after code freeze.
