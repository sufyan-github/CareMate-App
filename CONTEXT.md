# CARELINK domain context

CARELINK is a medication-support platform. It helps a person remember a planned dose, record what they report doing, and optionally keep a trusted caregiver informed. It does not diagnose, prescribe, replace a clinician, or prove that medicine was swallowed.

## Canonical language

### User

An authenticated account identified by a verified phone number. A User can own one Patient Profile and can also act as a Caregiver.

_Avoid_: Account holder when discussing the domain actor; Patient as a synonym for every User.

### Patient Profile

The person whose medication plan, Dose Occurrences, inventory, and adherence indicators are managed. A Patient Profile may be self-managed or managed with consent by one or more Caregivers.

_Avoid_: Dependent, ward, beneficiary.

### Caregiver

A User who has accepted a Care Relationship and can see or manage only the capabilities granted by that relationship.

_Avoid_: Admin, owner, guardian unless a separate legal status is actually verified.

### Care Relationship

The consent-backed, revocable link between a Caregiver and a Patient Profile. It contains explicit permissions and escalation preferences.

_Avoid_: Friend link, family link, sharing record.

### Prescription Image

An uploaded image supplied as input to extraction. It is supporting material, not a verified prescription record by itself.

_Avoid_: Prescription when only the image or OCR output is meant.

### OCR Draft

Unverified text and structured fields extracted from a Prescription Image. Every medical field remains editable and requires User confirmation.

_Avoid_: Parsed prescription, confirmed medicine list, AI prescription.

### Verified Medication Plan

The User-confirmed collection of Medications, Dose Instructions, and Medication Schedules created from an OCR Draft or manual entry. “Verified” means verified by the User, not clinically verified.

_Avoid_: Doctor-approved plan, clinical prescription.

### Medication

A User-confirmed medicine record with display name, form, strength, and optional instructions. It does not imply that the item exists in a national medicine database.

_Avoid_: Drug master record when referring to User-entered data.

### Dose Instruction

The human-readable rule for how a Medication is intended to be used, including quantity, route, meal relation, and start/end bounds when known.

_Avoid_: Schedule when the instruction has not yet been converted into occurrences.

### Medication Schedule

A deterministic recurrence rule, timezone, and active period from which Dose Occurrences are generated.

_Avoid_: Reminder; alarm.

### Dose Occurrence

One planned medication event at a specific local date and time. It is the authoritative unit for reminders, confirmation, inventory decrement, and escalation.

_Avoid_: Alarm, notification, dose log.

### Dose Status

The lifecycle state of a Dose Occurrence: `SCHEDULED`, `REMINDER_SENT`, `SNOOZED`, `CONFIRMED`, `SKIPPED`, `MISSED`, or `CANCELLED`.

_Avoid_: `TAKEN` as a claim of ingestion. The UI may ask the User to confirm, but CARELINK stores a self-reported confirmation.

### Dose Confirmation

The User action reporting that a Dose Occurrence was handled. It records actor, time, device, and timing classification. It is not proof of ingestion.

_Avoid_: Administration proof, compliance proof.

### Escalation Policy

The consented rule that decides whether and when a missed Dose Occurrence creates an Alert for a Caregiver and which delivery channels may be used.

_Avoid_: Emergency protocol unless it is a separately reviewed emergency workflow.

### Alert

A time-stamped in-app, push, or SMS message generated from an Escalation Policy. It communicates app-observed state, not a diagnosis or verified emergency.

_Avoid_: Medical warning, emergency diagnosis.

### Inventory Position

The calculated quantity of a Medication remaining after confirmed Dose Occurrences and explicit Stock Adjustments.

_Avoid_: Pharmacy inventory; exact stock unless every adjustment is known.

### Stock Adjustment

An auditable addition, correction, or consumption change applied to an Inventory Position.

_Avoid_: Silent quantity edit.

### App-based Adherence Indicator

A clearly labeled calculation from eligible Dose Occurrences and their self-reported outcomes. It is not a clinical adherence measure.

_Avoid_: Adherence score without the “app-based” qualifier; medical compliance rating.

### Subscription Plan

A versioned commercial offer that maps to Entitlements, price, billing period, and supported payment channels.

_Avoid_: Entitlement as a synonym for plan.

### Subscription

The User’s time-bounded commercial relationship with one Subscription Plan and one billing channel. Provider state never grants features directly.

_Avoid_: Payment; entitlement.

### Entitlement

An internal, time-bounded permission to use a premium capability. Entitlements are derived from reconciled Subscription state or an administrative grant.

_Avoid_: Feature flag, provider success response.

### Payment Attempt

One provider transaction lifecycle for purchasing or renewing a Subscription. It is immutable apart from controlled state transitions and provider references.

_Avoid_: Subscription transaction.

### Provider Event

An authenticated callback or delivery report received from an external provider and stored before idempotent processing.

_Avoid_: Webhook as the domain meaning; webhook is only one transport.

### Sync Mutation

A uniquely identified offline-originated command waiting to be accepted or rejected by the server.

_Avoid_: Data row sync; last-write-wins update.

### Demo Mode

A visibly labeled, isolated environment using seeded data and fake provider Adapters. Demo Mode never sends real messages or charges money.

_Avoid_: Sandbox when the product behavior, rather than a provider environment, is meant.

