# Phase 4 verification — inventory and app-based insights

Verified on 17 August 2026.

## Delivered behavior

- Every medication owns one quantity-unit-bound Inventory Position.
- Opening, restock, and correction Stock Adjustments are immutable and
  idempotent.
- The first valid self-reported dose confirmation writes one consumption
  adjustment in the same database transaction as the dose transition and
  confirmation. Retrying the command cannot consume stock again.
- Low-stock thresholds use optimistic version checks. Forecasts remain clearly
  estimated and are derived from the current confirmed schedule horizon.
- The API exposes a self-reported/app-based indicator for a bounded local-date
  period. It separately reports on-time confirmations, late confirmations,
  skips, misses, unresolved occurrences, and future/cancelled exclusions.
- The Android Insights tab provides 7-day and 30-day summaries, the explicit
  numerator and denominator, non-clinical explanatory copy, inventory cards,
  opening/restock/correction entry, and low-stock threshold editing.

## Automated checks

- NestJS build and Prisma Client generation completed successfully.
- API integration suite: 44 tests passed, including unit compatibility,
  idempotent adjustment replay, optimistic threshold conflicts, exactly-once
  confirmation consumption, reporting eligibility, empty periods, and invalid
  date-window rejection.
- Flutter static analysis: no issues.
- Flutter behavioral suite: 47 non-golden tests passed, including authenticated
  inventory/report parsing, the app-based indicator UI, opening-stock entry,
  existing medication schedules, dose actions, offline sync, caregiver access,
  authentication, and account settings.
- Android debug APK built successfully with Flutter 3.44.8 / Dart 3.12.2.

APK SHA-256:

`60d4d868cb4c831af734e32b54fd246e7a41cfe3657578e31625df44c36423c7`

APK size: 197,656,093 bytes.

## Verification caveat

The worktree already contained an uncommitted `pubspec.lock` update from the
repository's documented Flutter 3.41.9 baseline to Flutter 3.44. The two
reviewed pixel-golden tests differ under Flutter 3.44 (0.24% for sign-in and
0.79% for Today). Their source images were not overwritten because doing so
would mix an unrelated SDK/baseline migration into Phase 4. All non-golden
behavioral tests pass under the current SDK.

The existing uncommitted lockfile and other user-owned worktree changes were
not staged or included in any Phase 4 commit.
