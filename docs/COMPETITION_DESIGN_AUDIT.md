# Competition design audit

**Artifact reviewed:** Current Android sign-in capture, Today golden, application shell, theme, and critical flow source  
**Stage:** Refinement toward a physical competition build  
**Primary users:** People managing their own medicines, older adults, and trusted caregivers in Bangladesh

## Overall impression

CareMate already feels calmer and more trustworthy than a typical prototype: the teal palette, large actions, plain safety copy, and bottom navigation give it a credible Material foundation. The biggest opportunity is to turn a collection of capable screens into one unmistakable guided story. Connection failures, generic empty states, incomplete Bangla support, and dense secondary information currently compete with the primary medication action.

## First impression

- The heart mark and “Your medicines, right on time” headline correctly establish care and timeliness.
- The sign-in screen uses generous spacing and a strong primary action, but the first captured experience is dominated by a red connection failure. A judge will read that as product instability before seeing the value.
- The brand mark is generic and the product does not yet explain its Bangladesh/offline/family differentiation above the fold.
- The Today screen is functionally rich, but its summary, readiness, quick actions, next dose, sync state and education compete for attention.

## Usability findings

| Finding                                                                        | Severity | Recommendation                                                                                                                                    |
| ------------------------------------------------------------------------------ | -------- | ------------------------------------------------------------------------------------------------------------------------------------------------- |
| Network failure appears as a terminal red block during sign-in                 | Critical | Explain whether the API, internet, or phone tunnel is unavailable; provide a retry action and an explicitly labelled demo/offline path where safe |
| The competition story requires several independently discovered screens        | Critical | Add progressive guidance and a single “next best action” on empty/first-run states                                                                |
| OCR confidence and evidence source are not visible next to the suggested name  | Critical | Show “Read from image”, confidence wording and evidence text before continuing                                                                    |
| Development OTP can look like production SMS                                   | Critical | Label demo delivery and show the configured demo code only in non-production builds                                                               |
| Language preference does not provide critical-path Bangla parity               | Critical | Localize navigation, onboarding, Today, dose actions, OCR review and safety copy first                                                            |
| Terms and Privacy appear as prose rather than clearly interactive destinations | Moderate | Use explicit buttons/links with accessible labels                                                                                                 |
| Dense insight and readiness copy increases scan time                           | Moderate | Use progressive disclosure; lead with status and action, move explanation behind “How this works”                                                 |
| The same strong teal is used across branding, success and primary actions      | Moderate | Separate semantic success from brand/primary colors                                                                                               |
| Caregiver value is hidden until later navigation                               | Moderate | Introduce it as an optional benefit after the first medicine is active                                                                            |
| Error and offline states use technical concepts inconsistently                 | Moderate | Standardize plain-language state cards with title, consequence, action and last-updated time                                                      |

## Visual hierarchy

- **Correct primary focus:** next Dose Occurrence and its available action.
- **Secondary focus:** today’s progress and sync/reminder readiness.
- **Tertiary focus:** education, inventory and caregiver prompts.
- Use one filled action per section. Secondary actions should be outlined or text actions.
- Prefer concise status chips and short supporting copy over multiple paragraphs on the Today screen.
- Keep the bottom navigation labels visible. Five destinations are acceptable for the current breadth, but notifications should remain a contextual top-level action rather than a sixth destination.

## Consistency findings

| Element         | Issue                                                                    | Recommendation                                                                               |
| --------------- | ------------------------------------------------------------------------ | -------------------------------------------------------------------------------------------- |
| State messaging | Error, offline, pending sync and readiness use different visual patterns | Introduce one reusable status banner/card component with severity semantics                  |
| Empty states    | Some pages lead with explanation, others with actions                    | Standardize icon, title, one-sentence consequence, primary action, optional secondary action |
| Page headers    | Brand/app bar and page titles vary by flow                               | Define shell, task-page and modal header patterns                                            |
| Spacing         | Screens mix ad hoc values from 8 to 32                                   | Define spacing tokens and use a small scale consistently                                     |
| Corner radii    | Cards and action surfaces vary                                           | Define small, medium and large radii in the theme extension                                  |
| Copy            | “Patient”, “profile”, “plan”, and “dose” can feel domain-heavy           | Use canonical terms but add plain-language labels for first-time users                       |

## Accessibility

- Keep every action at least 48 by 48 logical pixels and avoid icon-only actions without tooltips/semantic labels.
- Verify 200% text scaling without clipped dose names, times, bottom navigation labels or dialogs.
- Do not rely on teal, red or amber alone; pair color with icon, title and text.
- Announce pending sync, offline cache and successful dose actions through live regions where appropriate.
- Use traversal order so the next dose, time, medicine and primary action are read together.
- Provide a high-legibility preference with larger type, simpler cards, reduced secondary copy and no reduced touch targets.
- Bangla fonts must render at readable line height; test conjuncts, Bengali numerals and mixed Bangla/Latin medicine names on the physical phone.

## What works well

- Material 3 gives the app familiar controls and platform-consistent behavior.
- The palette is calm and health-appropriate without imitating a clinical record system.
- Safety boundaries are already stated in prescription and adherence copy.
- The Today screen prioritizes real actions over decorative analytics.
- Offline and sync state are surfaced rather than hidden.
- Navigation maps well to the product’s core mental model: Today, Medicines, Care, Insights and More.

## Priority recommendations

1. **Make the next safe action unmistakable.** Every first-run, empty, error and offline state should lead to one recoverable action.
2. **Turn AI output into visible evidence, not magic.** Put evidence source, confidence language and manual correction directly in prescription review.
3. **Complete the Bangladesh critical path.** English-only polish is not enough for the product’s claimed differentiation.
4. **Create a legibility mode.** Older users need fewer competing elements, larger type and larger action surfaces.
5. **Build a deterministic judge journey.** Seeded synthetic data, clear demo labelling and a reset path should eliminate setup delays without contaminating production behavior.
