# CareMate Accessibility Audit

- Date: 2026-08-17
- Scope: Flutter sign-in and Today journey
- Target: WCAG 2.1 AA with Android touch-target guidance

## Outcome

The competition-critical sign-in and Today journey now has a reusable accessibility baseline. Automated analysis passes, actionable controls use 48 logical-pixel minimum targets, status changes have screen-reader descriptions, and dose actions reflow at 200% text scaling.

This is a focused implementation audit, not a claim of full-product WCAG conformance. TalkBack testing and contrast measurement on final release assets remain required before public launch.

## Findings addressed

| Area                  | Previous risk                                                             | Change                                                               | Verification                    |
| --------------------- | ------------------------------------------------------------------------- | -------------------------------------------------------------------- | ------------------------------- |
| Touch targets         | Compact secondary actions could be difficult for older adults             | Theme-wide padded controls and 48-pixel minimum sizes                | Widget size assertions          |
| Large text            | Confirm, snooze, and skip shared one horizontal row                       | Primary action is full width; secondary actions wrap                 | 200% text widget test           |
| Dynamic status        | Network and authentication failures were visually styled but inconsistent | Shared status card with live-region option and plain recovery action | Semantics widget test           |
| Screen-reader actions | A grouped status label could hide its recovery control                    | Descriptive container semantics preserve the separate button node    | Semantics tap-action assertion  |
| Empty state           | Medication empty state used a one-off layout                              | Shared empty-state component with permission-aware action            | Flutter analysis and flow tests |
| Brand mark            | Decorative heart had no accessible context                                | Sign-in mark is identified as the CareMate image                     | Source review                   |
| Color dependence      | Status relied heavily on container color                                  | Every status includes an icon, title, and message                    | Source review                   |

## Remaining manual checks

Before a store or production release:

1. Navigate the full patient and caregiver paths with TalkBack enabled.
2. Verify logical focus order after dialogs, camera return, and failed network calls.
3. Measure light and dark theme contrast for text, icons, focus states, and disabled controls.
4. Test Android font size and display size at their largest settings on the target Motorola device.
5. Verify Bengali strings with a native reader after localization is implemented.
6. Confirm that prescription images and captured documents never receive misleading image descriptions.

## Acceptance bar

A competition build passes this segment when Flutter analysis is clean, non-golden tests pass, the 200% text test has no overflow, status actions remain accessible, and the physical-device smoke test can be performed with no data-destructive reinstall.
