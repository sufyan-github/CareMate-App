# CareMate competition-readiness roadmap

**Status:** Competition build completed; pilot gates remain
**Date:** 18 August 2026
**Owner:** CareMate product and engineering  
**Assumption:** No named competition rubric was supplied. This roadmap optimizes for the criteria most physical product competitions judge: problem clarity, differentiation, usability, technical credibility, safety, impact, and a reliable live demonstration.

## Competition position

CareMate should not compete as another pill-alarm application. Its credible story is a Bangladesh-first, offline-capable medication-support system that turns a reviewed prescription draft into reliable local reminders, self-reported dose outcomes, inventory insight, and consent-based family care.

The winning release is a polished and provable pilot MVP. It is not the release with the largest feature count.

## Success criteria

The competition build succeeds when judges can complete this five-minute story on a physical Android phone without developer intervention:

1. Sign in with a Bangladesh phone number using clearly labelled demo OTP delivery.
2. Create or select a Patient Profile and capture a prescription or enter a medicine manually.
3. Review an explicitly unverified OCR draft and activate a deterministic schedule.
4. Confirm, snooze, or skip a Dose Occurrence, including an offline action that later syncs.
5. Show private reminders, inventory/run-out insight, and consent-based caregiver access.

Release evidence must include passing automated checks, a reproducible physical-device script, privacy-safe demo data, screenshots, architecture and safety explanations, and a rehearsed offline recovery path.

## Status overview

| Theme                          | Status             | Current evidence                                                             | Competition gap                                                                           |
| ------------------------------ | ------------------ | ---------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------- |
| Core medication lifecycle      | Done               | Medication, schedules, reminders, dose commands                              | Needs a tighter guided demo journey                                                       |
| Offline reliability            | Done               | Encrypted local cache, mutation outbox, background retry                     | Needs a one-tap rehearsal and visible sync proof                                          |
| Prescription capture           | In progress        | ML Kit preview, cloud consent, provider abstraction, OpenAI structuring      | Needs real provider secrets/evaluation and stronger review UX                             |
| Family care                    | Done               | Invitations, permissions, read-only shared plans, revocation                 | Needs judge-ready seeded two-person story                                                 |
| Inventory and insight          | Done               | Immutable ledger, thresholds, run-out forecast, adherence indicator          | Needs clearer visual hierarchy and explanation                                            |
| Localization and accessibility | Competition ready  | Live Bangla critical path, larger-text preference, semantics, 48 dp controls | Native-language and older-adult review remain required before a pilot                     |
| Release operations             | Competition ready  | CI, provider controls, readiness, competition package ID, and two rehearsals | Production signing, provider credentials, and store distribution remain pilot gates       |
| Commercial integrations        | Blocked externally | Provider-neutral specification                                               | bKash, bdapps and production SMS require approval; exclude from competition critical path |

## Now: committed competition build

### Segment 0 — Evidence-bound prescription name extraction

**Status:** Completed
**Outcome:** OpenAI can recover a visibly supported medicine name when primary OCR misses it, while unsupported OCR claims fail closed.  
**Evidence:** Versioned prompt, structured evidence source, warnings, and regression tests.

### Segment 1 — Product direction and judging contract

**Status:** Completed

**Outcome:** Fix scope, architecture, design priorities, demo success criteria, dependencies, and non-goals before UI expansion.  
**Dependencies:** Existing specification and physical-device evidence.

### Segment 2 — Premium mobile experience and accessibility

**Status:** Completed

**Outcome:** A consistent design system, stronger onboarding, clearer Today hierarchy, humane empty/error/offline states, minimum 48 dp touch targets, text scaling resilience, and screen-reader semantics.  
**Dependencies:** Segment 1 design audit.  
**Exit gate:** Flutter analysis and behavioral tests pass; key screens are visually reviewed at light/dark and large text.

### Segment 3 — Bangladesh-first demo journey

**Status:** Completed

**Outcome:** Bangla/English parity for the critical path, elderly-friendly display preference, clearer OCR confidence/evidence review, and a deterministic caregiver demonstration.  
**Dependencies:** Copy inventory and design tokens from Segment 2.  
**Exit gate:** The five-minute judge journey works in English and Bangla without network-only assumptions.

### Segment 4 — Trust, reliability, and release hardening

**Status:** Completed

**Outcome:** Privacy-safe diagnostics, provider readiness/kill switches, explicit development-mode labelling, performance checks, robust error taxonomy, and operational documentation.  
**Dependencies:** Stable user journey from Segment 3.  
**Exit gate:** No sensitive values enter logs; provider failure and offline recovery are demonstrated.

### Segment 5 — Verification and competition package

**Status:** Completed
**Outcome:** CI gates, release checklist, demo seed/reset workflow, physical-device rehearsal, screenshots, architecture one-pager, judge script, and backup video plan.  
**Dependencies:** All earlier segments.  
**Exit gate:** A clean checkout can build and verify; the physical demo passes twice consecutively.

## Next: pilot preparation after the competition build

| Initiative                        | Priority | Dependency                                                  | Reason                                                                   |
| --------------------------------- | -------- | ----------------------------------------------------------- | ------------------------------------------------------------------------ |
| Bangladesh prescription benchmark | Must     | Consented, de-identified dataset and qualified adjudication | Required before accuracy claims or production OCR selection              |
| Firebase push delivery            | Should   | Firebase credentials and privacy review                     | Local alarms remain authoritative; push adds caregiver reach             |
| Pilot operations console          | Should   | Audit policy and role model                                 | Supports consent, provider events and support without unsafe data access |
| Crash/ANR integration             | Should   | Approved telemetry processor and consent policy             | Needed for a controlled pilot, not required to prove the local demo      |
| Closed pilot with 30–50 pairs     | Must     | Ethics/privacy/legal review and support runbook             | Measures correction burden, reminder reliability and caregiver value     |

## Later: directional opportunities

- Pharmacy refill coordination after partnership and regulatory review.
- Approved bKash or carrier subscription flows after sandbox certification.
- Elderly voice interaction only after safety and usability validation.
- Medicine reference candidates backed by an approved Bangladesh source; never silent correction.
- Clinician or facility integrations only with a separately reviewed consent and governance model.

## Explicitly out of scope for the competition critical path

- Diagnosis, prescribing, interaction advice, or proof that medicine was swallowed.
- Production charging, recurring billing, or unapproved SMS delivery.
- A public AI chatbot handling clinical questions.
- Automatic schedule activation from OCR or AI output.
- A backend rewrite, microservice split, or new state-management framework.
- Features that cannot be demonstrated reliably on the physical phone.

## Risks and dependencies

| Risk                                       | Status             | Mitigation                                                                                                       |
| ------------------------------------------ | ------------------ | ---------------------------------------------------------------------------------------------------------------- |
| OpenAI and managed OCR secrets are absent  | Blocked            | Keep manual/on-device fallback; enable only through server-side secrets and kill switches                        |
| Installed APK has a different signing key  | Resolved           | Competition package `com.caremate.competition` installs independently and preserves `com.caremate.app`           |
| Production OTP/SMS is not approved         | Blocked externally | Clearly label deterministic development OTP; never imply a real delivery integration                             |
| Bangla medical copy could be mistranslated | At risk            | Translate the interface, not medical meaning; review critical copy with a qualified native reviewer before pilot |
| Scope exceeds one-agent capacity           | Active             | Commit to Now outcomes, defer vendor- and research-gated work, and require an exit gate per segment              |
| Existing worktree contains unrelated edits | Active             | Stage only segment-owned paths and push one validated commit per segment                                         |

## Prioritization rule

Use this order for every proposed addition:

1. Prevent harm or misleading claims.
2. Prevent live-demo failure.
3. Reduce user effort in the five-minute journey.
4. Strengthen Bangladesh-specific differentiation.
5. Improve visual polish and judge comprehension.
6. Defer anything dependent on unapproved providers, new research, or speculative scale.
