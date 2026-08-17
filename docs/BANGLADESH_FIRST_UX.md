# Bangladesh-First Competition Journey

## Outcome

The competition-critical mobile journey now responds immediately when a user selects English or বাংলা. The preference is synchronized with the CareMate account, cached securely on the phone, and retained on the signed-out screen. A separate larger-text setting raises the app scale to at least 125% without overriding a larger Android system setting.

## Critical-path coverage

| Journey area         | English and Bangla behavior                                                                                          |
| -------------------- | -------------------------------------------------------------------------------------------------------------------- |
| Sign-in              | Headline, instructions, fields, validation, actions, demo OTP disclosure, and legal notice                           |
| App navigation       | Today, Medicines, Care, Insights, More, and Notifications labels                                                     |
| Today                | Page purpose, dose actions, empty state, quick actions, and medicine entry points                                    |
| Prescription capture | Safety disclosure, capture actions, consent dialog, review instructions, candidate evidence, and continuation action |
| Caregiver invitation | Demo-delivery disclosure, permissions, validation, review dialog, and consent boundary                               |
| Settings             | Language, navigation rows, sign-out action, and larger-text preference                                               |

Screens outside this five-minute competition path continue to use reviewed English where translated copy is not yet available. This is explicit fallback behavior, not a claim of complete production localization.

## Prescription review contract

Each structured medicine candidate shows:

- The extracted display name.
- A high, medium, or low OCR-confidence band with the numeric model estimate.
- The visible evidence text supporting the candidate.
- A selectable control that copies the candidate into an editable medicine-name field.

The interface states that confidence is a model estimate, not medical verification. The user must choose a name visible on the prescription and then review the separate medicine form. No schedule is activated automatically.

## Caregiver demo contract

The demo makes consent observable:

1. The patient enters a Bangladesh mobile number.
2. The patient chooses individual read permissions.
3. A confirmation dialog repeats the invited number, every permission, and the acceptance boundary.
4. The demo states that no SMS is sent; the invitation appears when the invited number signs in.
5. The care circle shows pending or accepted state, all granted permissions, and revocation.

## Translation safety

The Bangla copy translates interface actions and safety boundaries; it does not translate or infer medicine names, prescriptions, diagnoses, or clinical advice. Before a pilot or public launch, a qualified native Bangla reviewer must validate every string in context, including truncation, tone, and comprehension with older adults.

## Verification

- Flutter analysis must pass.
- English behavioral tests must remain green.
- The settings flow must prove live Bangla switching, larger text, and Bangla persistence after sign-out.
- OCR confidence boundaries must have unit coverage.
- The caregiver flow must prove that no invitation is created before the permission recap is confirmed.
