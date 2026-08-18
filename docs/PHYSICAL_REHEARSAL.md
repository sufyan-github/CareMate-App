# Physical Device Rehearsal Evidence

**Date:** 18 August 2026
**Target:** Motorola edge 60 fusion, Android 16
**Competition package:** `com.caremate.competition`

## Build identity

- Branch: `agent/competition-ready-caremate`
- Release base: Segment 5 working tree based on `40d6eae`; final commit is recorded in Git history and CI
- API: `http://127.0.0.1:3000/api/v1` through `adb reverse tcp:3000 tcp:3000`
- Existing package `com.caremate.app` is preserved because it uses a different signing key.
- APK SHA-256: `5334707632D962446FB1E0A6058B04A1ACCB182CCFA69BBFF4DC953EBCFD2C3A`
- APK size: 197,683,021 bytes (188.53 MiB debug build)
- Cold launch: 2,289 ms (`adb shell am start -W`)

## Rehearsal results

| Run | Install/launch | Health/readiness | Sign-in | Review/manual fallback | Offline action/resync | Caregiver recap | Bangla/larger text | Result |
| --- | -------------- | ---------------- | ------- | ---------------------- | --------------------- | --------------- | ------------------ | ------ |
| 1   | Pass           | Pass             | Pass    | Contract tests         | Online confirmation   | Widget tests    | Widget tests       | Pass   |
| 2   | Pass           | Pass             | Pass    | Contract tests         | Pass                  | Widget tests    | Widget tests       | Pass   |

Run 1 used synthetic phone `01700123457` and loaded the seeded Napa plan with a confirmed dose. Run 2 used `01700123458`, removed only the ADB API tunnel, confirmed a due dose, displayed `Pending sync`, restored the tunnel, and reached `Confirmed by you` with `Everything is already synced`.

The physical run intentionally used the development OCR provider because no OpenAI key was present. The OpenAI evidence-bound extraction and manual-review fallback are covered by automated API and Flutter tests; production provider evaluation remains a pilot gate.

## Evidence to capture

- `adb shell pm path com.caremate.competition`
- App foreground screenshot with no personal notifications visible.
- Health and readiness response status only; never capture environment values or secrets.
- APK SHA-256 and file size.
- Start-to-first-frame timing from `adb shell am start -W`.
- Any blocked permission, provider, or network condition and the demonstrated fallback.

## Acceptance

Both runs must pass without reinstalling or deleting `com.caremate.app`, exposing real personal data, editing the database by hand, or changing source code between runs.
