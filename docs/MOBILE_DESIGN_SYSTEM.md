# CareMate Mobile Design System

## Purpose

CareMate's interface must feel calm and trustworthy while remaining usable for older adults, caregivers, and people under medication-related stress. The system favors clear hierarchy, generous targets, plain language, and visible recovery paths over decorative density.

## Foundations

The source of truth is `apps/mobile/lib/app/design/caremate_tokens.dart`.

### Spacing

Use the 4-point spacing scale through `CareMateSpacing`:

- `xxs`: 4
- `xs`: 8
- `sm`: 12
- `md`: 16
- `lg`: 20
- `xl`: 24
- `xxl`: 32

Do not introduce one-off spacing values unless a platform constraint requires one.

### Shape

Use `CareMateRadii` for consistent shape language:

- Small: 12 for compact controls
- Medium: 16 for fields and icon containers
- Large: 20 for cards and prominent surfaces
- Pill: 999 for badges only

### Layout and touch

- Interactive controls must have a minimum 48-by-48 logical-pixel target.
- Content pages use `CareMateLayout.pagePadding`.
- Focused forms use `CareMateLayout.maxContentWidth` to remain readable on tablets.
- Controls with multiple labels must wrap vertically rather than shrink text.

## Components

### Status card

Use `CareMateStatusCard` for information, success, warning, error, and offline states. Every card requires a short title and an actionable message. If recovery is possible, provide one explicit action. Use `liveRegion` only for state that changes after user interaction.

### Empty state

Use `CareMateEmptyState` when a collection has no content. Explain why the space is empty and provide the single best next action when the current user has permission to act.

### Buttons

- Filled: the one primary action in a section.
- Outlined: a safe secondary action.
- Text: cancellation, navigation, or lower-priority action.
- Use verb-led labels such as “Add medicine” and “Sync now”.

## Content principles

- Never imply that CareMate has diagnosed, prescribed, or verified a medicine.
- Describe AI extraction as a draft that the user must review.
- Explain offline state without blaming the user or device.
- State what happened, what is safe, and what the user can do next.
- Reserve technical terms and debug credentials for development builds.

## Review checklist

Before merging a new screen:

- Uses design tokens instead of new one-off constants.
- Has loading, empty, error, offline, and success behavior where applicable.
- Remains usable at 200% text scaling on a 360 logical-pixel-wide device.
- All controls expose meaningful labels and at least 48-by-48 targets.
- Color is not the only status indicator.
- Primary action remains clear when the keyboard is visible.
