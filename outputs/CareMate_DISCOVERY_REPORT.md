# CareMate Discovery Report

**Research cut-off:** 16 August 2026  
**Scope:** problem definition, Bangladesh market context, consumer/service acceptance, competition, bdapps/Robi feasibility, bKash feasibility, and validation plan  
**Product:** CareMate — *Medicine. Memory. Family.*

## Executive decision

**Decision: conditional GO for a focused discovery pilot and medication-care MVP; NO-GO for a full product build, paid launch, or claims of market acceptance until field validation is complete.**

The evidence supports four conclusions:

1. The underlying problem is credible. Medication routines are difficult to manage, Bangladesh has a large NCD burden, and family support is an important part of care.
2. The delivery channels are plausible. Mobile and mobile-internet subscriptions are widespread, but subscriptions are not the same as unique people or smartphone ownership; an offline-first design and SMS fallback remain necessary.
3. Older Bangladeshi users may accept mHealth when it is useful, simple, socially supported, and low-anxiety. Acceptance is conditional, not automatic.
4. CareMate's individual features are not novel. The opportunity is the Bangladesh-specific combination of verified prescription capture, deterministic scheduling, stock tracking, family escalation, Bangla accessibility, offline reminders, and telecom fallback.

The correct first customer is **an adult family caregiver who owns an Android smartphone and manages medicines for an older parent**, while the patient experience is a simplified Bangla companion. This is more promising than asking an elderly patient to buy, configure, and operate the full service alone.

## 1. Problem specification

### 1.1 Problem statement

People managing repeated medicines must translate a prescription into a daily routine, remember each scheduled dose, distinguish taken from pending doses, keep enough medicine in stock, and communicate exceptions to family members. These tasks are fragmented across paper prescriptions, memory, phone calls, alarms, and physical medicine packs.

For families living apart, the caregiver often lacks timely, trustworthy information. A missed app confirmation does **not** prove that medicine was not swallowed; it means only that a scheduled dose remains unconfirmed and may need attention.

### 1.2 Primary job to be done

> When I manage medicines for myself or a family member, help me turn the doctor's written instructions into a verified routine, remind the right person at the right time, and tell the caregiver only when follow-up may be needed.

### 1.3 Actors and distinct needs

| Actor | Core need | Current workaround | Main adoption barrier |
|---|---|---|---|
| Older patient | Know what to take now with minimal effort | Paper, memory, family call, generic alarm | Small text, complex setup, technology anxiety, language |
| Adult family caregiver | Know when a loved one may need attention | Repeated calls/messages and manual tracking | Alert fatigue, false alarms, trust, privacy |
| Self-managing chronic patient | Reliable reminders, history, and refill visibility | Alarm/calendar/notes | Setup burden and weak long-term engagement |
| Parent managing a child | Coordinate routine safely | Paper notes and family messaging | Consent, safety, multiple schedules |
| CareMate operator | Deliver a dependable service at sustainable cost | N/A | SMS economics, support load, regulatory and API approvals |

### 1.4 The core failure sequence

```text
Prescription is hard to interpret or re-enter
  -> schedule is missing or wrong
  -> reminder is absent, unclear, or ignored
  -> dose remains unconfirmed
  -> family learns late or calls unnecessarily
  -> stock can run out without warning
```

CareMate should interrupt this sequence without making a medical decision:

```text
Prescription image
  -> OCR draft
  -> explicit human verification
  -> deterministic schedule
  -> offline reminder
  -> Taken / Snoozed / Skipped / Unconfirmed
  -> inventory update
  -> configurable caregiver escalation
```

### 1.5 Safety boundary

CareMate is a medication organization and family-care coordination service. It must not diagnose, prescribe, change dosage, infer physical ingestion, or treat OCR output as a medical instruction. Every OCR result is an editable draft until the user confirms it against the prescription.

## 2. Bangladesh market evidence

### 2.1 Demand context

WHO reported in September 2025 that noncommunicable diseases account for **71% of deaths in Bangladesh**, with more than half of those deaths premature. This establishes a large chronic-care context, but it does not measure medication non-adherence or CareMate demand. ([WHO Bangladesh, 7 September 2025](https://www.who.int/bangladesh/news/detail/07-09-2025-a-nation-unites-35-ministries-in-landmark-move-to-fight-against-noncommunicable-diseases))

A 2021 cross-sectional study of 2,070 people with type 2 diabetes attending five facilities in Chattogram Division found **46.3% low medication adherence** (95% CI 41.4%–55.8%). The measure was self-reported and the facilities were selected, so this is evidence of a substantial problem in that population—not a national prevalence estimate. ([Global Health Action, 2021](https://doi.org/10.1080/16549716.2021.1872895))

WHO's 2025 Bangladesh healthy-ageing factsheet reports that, for 2023, Bangladesh had no programme available for caregivers of older persons and reported limited or very limited resources across major healthy-ageing priorities. This supports a caregiver-support gap at a system level, but not willingness to pay for a private app. ([WHO, *Facts and Figures — Healthy Ageing: Bangladesh*, 2025](https://cdn.who.int/media/docs/default-source/searo/ageing-and-health/fact-sheets-2024/bangladesh---facts-and-figures---healthy-ageing.pdf?sfvrsn=a8984000_2))

### 2.2 Reach and channel context

BTRC reported **185.84 million mobile subscriptions** in February 2026, of which **57.30 million** were Robi subscriptions. These are subscriptions/SIMs, not unique individuals. ([BTRC mobile subscribers](https://btrc.gov.bd/site/page/0ae188ae-146e-465c-8ed8-d76b7947b5dd/))

BTRC reported **128.27 million internet subscriptions** in February 2026, including **113.50 million mobile-internet subscriptions**. BTRC defines an internet subscriber as a subscription that accessed the internet at least once in the preceding 90 days. This is not proof of reliable daily connectivity. ([BTRC internet subscribers](https://btrc.gov.bd/site/page/347df7fe-409f-451e-a415-65b109a207f5/))

BTRC's handset-production data show that smartphones represented **45.89% of locally produced handsets in February 2026**. This is a flow measure for domestic production, not the installed handset base, but it warns against designing a smartphone-only family communication model. ([BTRC handset information](https://btrc.gov.bd/site/page/cf3588dd-31c9-45b2-b9d5-10f9f2990526/Mobile-phone-handset-info-%28locally-produced%29-))

ITU's harmonized 2024 indicators estimate 64.4% personal mobile-phone ownership and 53.4% internet use. The reported gaps are material: phone ownership was 70.0% for men versus 58.8% for women, and internet use was 75.8% in urban areas versus 43.6% in rural areas. These are national but not elderly-specific indicators. ([ITU DataHub, Bangladesh](https://datahub.itu.int/data/?e=BGD))

**Product implication:** Android-first is reasonable, but the medication reminder must work offline and caregiver escalation needs a channel that does not assume both parties have active data at the same moment.

### 2.3 Market size: what can and cannot be claimed

A defensible monetary TAM/SAM/SOM cannot be calculated from the reviewed evidence. Mobile subscriptions, NCD burden, and the number of older people are not equivalent to people who manage repeated medicines, have an addressable caregiver relationship, will adopt CareMate, or will pay.

Use a bottom-up model after discovery:

```text
TAM users = people actively managing repeated medicines with a recurring coordination problem
SAM pairs = TAM users with an eligible patient-caregiver workflow, supported Android device, consent, and service reach
Annual SAM revenue = validated paying pairs x observed annual revenue per paying pair
Initial SOM = pairs the pilot/acquisition/support operation can realistically onboard and retain
```

For the first year, define the obtainable market operationally: caregiver-led pairs reachable through two or three partner clinics/pharmacies or employer/community groups in one urban area, followed by a rural-access test. Do not derive the customer count by multiplying BTRC subscriptions by an assumed disease or conversion rate.

### 2.4 Prescription and medicine context

The Bangladesh Medical & Dental Council's prescription outline includes doctor identity and registration, patient details, clinical sections, an open `Rx` area, advice, signature, and date. The source defines a structure but does not require a machine-readable layout. ([BMDC, *Outline of a Prescription*, Appendix V](https://www.bmdc.org.bd/docs/12-Appendix.pdf))

The Directorate General of Drug Administration publishes a searchable registered-products catalogue with brand, strength, and dosage-form records. The catalogue can be investigated as a future reference-data source, but licensing, API access, data quality, update frequency, and safe matching must be agreed before use. ([DGDA registered products](https://info.dgda.gov.bd/))

Claims about the percentage of handwritten prescriptions, typical handwriting quality, common abbreviations, and packaging conventions could not be verified from a sufficiently current national primary source. These must be measured with a consented local prescription sample before selecting or training OCR.

## 3. Will consumers accept the service?

### 3.1 Evidence-based answer

**Potentially yes, but acceptance has not been demonstrated for CareMate.** Existing evidence supports a testable hypothesis, not a launch claim.

A Bangladesh study of nearly 300 people aged 60+ found that performance expectancy, effort expectancy, social influence, technology anxiety, and resistance to change significantly affected intention to adopt mHealth. The study was conducted in Dhaka and examined mHealth generally, so it should guide design rather than be treated as national proof of demand. ([Hoque & Sorwar, 2017, DOI 10.1016/j.ijmedinf.2017.02.002](https://doi.org/10.1016/j.ijmedinf.2017.02.002))

Two Bangladesh studies provide a price signal, with major caveats. Among 515 phone-owning patients with type 2 diabetes at a Dhaka hospital, 52.0% stated positive willingness to pay for diabetes SMS and the reported median was BDT 20/month; only about half could read/retrieve SMS. Among 307 adults with hypertension in rural Narail, 67.4% were willing to receive health SMS and 50.5% were willing to pay, with a median stated amount of BDT 10; fewer than half of phone owners could read SMS. These were condition-specific stated-preference studies—not completed purchases—and cannot set CareMate pricing. ([Journal of Public Health, 2015](https://doi.org/10.1093/pubmed/fdv009), [BMC Public Health, 2021](https://doi.org/10.1186/s12889-021-12418-9))

A one-year randomized intervention in Dhaka used personalized interactive voice calls and a call centre for people with type 2 diabetes. Self-reported medication adherence was already above 90% in both groups at baseline and endline, so the intervention did not establish a clear medication-adherence improvement; it did improve some diet, exercise, and glucose-control outcomes. This is important counter-evidence against assuming reminders alone solve adherence. ([Yasmin et al., 2020](https://pmc.ncbi.nlm.nih.gov/articles/PMC7282058/))

A 2024 randomized A/B test in Bangladesh's hypertension primary-care network found one SMS increased follow-up attendance among overdue patients to 26.5% versus 20.7% without SMS; among regular patients, a three-message cascade produced 78.2% attendance versus 74.8% without a reminder. This supports SMS for re-engagement, not proof of medication taking or clinical benefit. ([Journal of Human Hypertension, 2024](https://doi.org/10.1038/s41371-024-00942-1))

A systematic review and meta-analysis of nine randomized trials found app users were more likely to adhere, but urged caution because six studies relied on self-report, follow-up was short, and interventions and populations varied. ([Armitage et al., 2020, BMJ Open](https://bmjopen.bmj.com/content/10/1/e032045))

A large randomized trial of low-cost reminder devices involving 53,480 participants found no statistically significant adherence improvement. The result reinforces that passive reminders without motivation, workflow fit, or social support may be insufficient. ([Choudhry et al., 2017, JAMA Internal Medicine](https://pmc.ncbi.nlm.nih.gov/articles/PMC5470369/))

### 3.2 Acceptance hypothesis by user

| Segment | Acceptance outlook | Why they may adopt | Why they may reject |
|---|---|---|---|
| Adult caregiver for an older parent | **Highest initial potential** | Peace of mind, fewer check-in calls, missed-dose signal, stock visibility | False alerts, surveillance concerns, setup burden, recurring price |
| Older patient with caregiver help | **Conditional** | Bangla voice, one-screen experience, useful reminders | Anxiety, low digital confidence, feeling controlled, unreliable alarms |
| Independent chronic patient | **Moderate** | Reminder/history/refill bundle | Strong global alternatives, habit decay, manual entry |
| Parent/child | **Future validation** | Routine coordination | Child safety and consent; core medicine workflow not yet proven |
| AI companion user | **Do not prioritize yet** | Conversation/accessibility | Trust, cost, safety, distraction from core value |

### 3.3 Conditions for acceptance

CareMate is more likely to be accepted if it:

- lets a caregiver perform setup while preserving patient consent and control;
- uses Bangla by default for the elderly experience, with voice that does not depend on an AI API;
- makes the current action obvious with large targets and minimal navigation;
- works without internet for reminders and queues confirmations for later sync;
- sends caregiver alerts only after a configurable grace period;
- explains that “unconfirmed” is not “not swallowed”;
- allows family members to tune or disable SMS to control cost and fatigue;
- shows the prescription image beside extracted fields during verification;
- gives a free core reminder experience before asking for payment.

### 3.4 Acceptance risks

The most serious risks are not lack of features. They are:

1. **Setup risk:** prescription-to-schedule entry is too slow or too error-prone.
2. **Trust risk:** users interpret OCR output or app status as medical truth.
3. **Alarm risk:** Android battery and exact-alarm policies prevent expected reminder behavior on some devices.
4. **Relationship risk:** patients perceive caregiver monitoring as surveillance.
5. **False-escalation risk:** a patient takes medicine but does not confirm, causing unnecessary family alerts.
6. **Price risk:** users value the service but will not pay enough to cover SMS/support costs.
7. **Language risk:** literal translation fails to match how patients describe medicine routines.

## 4. Competitive analysis

### 4.1 What is already standard

Reminders, taken/skipped logs, adherence history, refill alerts, flexible schedules, family profiles, caregiver alerts, and prescription or label scanning already exist in various products. CareMate must not claim invention of these categories.

| Product | Verified first-party capabilities | Commercial signal | Gap relevant to CareMate |
|---|---|---|---|
| Medisafe | Complex reminders, refill alerts, tracking, interaction warnings, and Medfriend caregiver alerts; no current first-party prescription-label OCR found | Free/Premium model; current exact checkout price varies or is unclear | No verified Bangladesh/bdapps positioning |
| MyTherapy | Reminders, taken/skipped history, supply/refill tracking, health diary, reports, and family/team references; barcode lookup appears in older pages, not prescription OCR | Main site says free, while the current App Store exposes optional purchases | No verified Bangla, bdapps, or Bangladesh prescription workflow |
| CareClinic | Medication and symptom tracking, appointments, caregiver coordination, missed-medication alerts, and medication photos; automatic OCR extraction is unverified | Free core plus Premium; exact current plan mapping is unclear | Broad health platform may be more complex than an elderly-first flow |
| Dosecast | Offline reminders, backup reminders, flexible schedules, multiple dose forms, adherence, quantity and refill alerts, and multi-person support; consumer caregiver escalation is unverified | Free and Pro editions; enterprise provider platform advertises from US$3/patient/month | Strong feature overlap; no verified Bangladesh telecom/localization layer |
| DoseAlert | On-device label OCR, escalating alarms, caregiver pairing, adherence, inventory, and local-first privacy | Seven-day trial; CAD 9.99 one-time | Very close but early-stage competitor; CareMate needs Bangladesh-specific execution, not a generic feature claim |
| RXClock | Site claims PWA reminders, caregiver sync, reports, refill tracking, and AI interaction checking | Site lists Free, Pro US$4.99/month, and Family US$9.99/month | Publisher, store distribution, security badges, uptime, and some plan claims were not independently verifiable |

Sources: [Medisafe Medfriend case study](https://www.medisafe.com/wp-content/uploads/2024/02/Medisafe_Feb-24-Medfriend_CaseStudy.pdf), [MyTherapy](https://www.mytherapyapp.com/), [CareClinic caregiver app](https://careclinic.io/caregiver-app/), [Dosecast features](https://dosecast.com/features/), [DoseAlert](https://dosealert.app/), [RXClock](https://rxclock.app/).

### 4.2 Defensible differentiation hypothesis

CareMate's opportunity is a localized service system:

```text
User-verified prescription intelligence
  + deterministic medication scheduling
  + offline Bangla-first elderly experience
  + caregiver exception workflow
  + inventory/runout visibility
  + Robi/bdapps fallback communication
  + Bangladesh payment options
```

This is a **differentiation hypothesis**, not yet a moat. Defensibility would come from validated local workflow data, reliable execution across common Android devices, trusted caregiver consent, partnerships, and a high-quality Bangladesh prescription test corpus—not from adding a generic LLM.

## 5. bdapps/Robi service feasibility

### 5.1 Confirmed from official documentation

bdapps offers HTTP APIs for SMS, USSD, CaaS/direct debit, subscription, and an OTP flow associated with enabling subscription. The official `sms/send` operation is `POST`, accepts application credentials server-side, supports delivery-report requests, and returns request/message identifiers. Delivery reports contain statuses including `DELIVERED`, `EXPIRED`, `UNDELIVERABLE`, `ACCEPTED`, `UNKNOWN`, and `REJECTED`. ([bdapps API documentation](https://dev.bdapps.com/API_Documentation/bdapps_tap_api.html))

The subscription API supports subscribe/unsubscribe and status queries. The OTP documentation explicitly describes OTP verification as activating a bdapps subscription; it should not be assumed to be a general-purpose identity OTP for every CareMate user without written confirmation. ([bdapps API documentation](https://dev.bdapps.com/API_Documentation/bdapps_tap_api.html))

bdapps publishes a simulator/developer kit for local testing and requires provisioning an application. Enabling the Subscription Charging SDK requires a request to bdapps support, after which API credentials are exposed in the developer console. ([bdapps downloads](https://dev.bdapps.com/bdapps-pro-downloads.php), [charging SDK consent steps](https://dev.bdapps.com/consent.php))

### 5.2 Critical commercial ambiguity

The official pricing page describes bdapps as a subscriber-charged/revenue-share platform, including stated SMS charges of Tk 1–2 for bdapps Pro and subscription/alert models. This may not match CareMate's intended model of the business paying for a transactional missed-dose SMS to any caregiver. ([bdapps pricing](https://dev.bdapps.com/pricing.php))

**Before implementation, obtain written answers from bdapps/Robi:**

1. Can CareMate send transactional caregiver alerts where CareMate, not the recipient, bears the cost?
2. Which Robi/Airtel/other-network recipients are supported?
3. Are caregiver alerts permitted without subscribing the recipient to a charged content service?
4. What consent wording, opt-out, sender ID, template approval, and healthcare-content rules apply?
5. What are current per-message costs, Unicode/Bangla segmentation rules, throughput limits, retry rules, and delivery-report SLA?
6. What sandbox/provisioning and production approval steps apply to NADB/demo and production?
7. Can the OTP API be used for CareMate authentication independently of paid subscription?

Until those answers are documented, build `SmsProvider` with `MockSmsProvider` and an isolated `BdappsSmsProvider`; do not make bdapps a hard dependency of the medication reminder.

## 6. bKash feasibility

bKash's official business page states that online-business integrations can include a payment gateway, tokenized checkout, subscription payments, instant refunds, direct charges, payouts, and APIs. Merchant onboarding is required; a personal wallet is not an acceptable production integration. ([bKash Business](https://www.bkash.com/en/business))

The official bKash sandbox portal lists Checkout, Tokenized Checkout v2, dynamic charging, webhook notification, query, execute, search, refund, and query-refund demonstrations. It describes webhooks as notifications of successful transactions. ([bKash Demo Merchant Portal](https://merchantdemo.sandbox.bka.sh/))

**Architecture decision:** keep credentials and transaction verification in the backend. Model payment as `created -> pending_user_action -> succeeded | failed | cancelled | expired`, verify status server-to-server, and process callbacks idempotently. Use a `PaymentProvider` abstraction with a mock provider for demos.

**Before production:** complete merchant onboarding and obtain the current merchant-specific API pack, credentials, commercial terms, callback-signature requirements, refund permissions, subscription-payment eligibility, and production approval. Public pages confirm product availability but do not establish CareMate's eligibility or exact contract.

## 7. Recommended MVP and exclusions

### 7.1 MVP promise

> Help a family convert a prescription into a verified medicine routine, remind the patient offline, and surface only the exceptions that may require caregiver attention.

### 7.2 MVP scope

1. Phone authentication using a provider-neutral OTP interface.
2. Patient and caregiver profiles with explicit invitation, consent, and permissions.
3. Prescription photo upload and OCR draft.
4. Mandatory field-by-field user verification before activation.
5. Deterministic schedule and required-quantity calculation.
6. Local Android alarms/notifications with Bangla and English text-to-speech.
7. Taken, Snoozed, Skipped, and Missed state handling with valid transitions only.
8. Local inventory decrement only after a confirmed dose, plus low-stock estimate.
9. Caregiver push alert after configurable grace periods.
10. SMS provider abstraction and clearly marked mock flow until bdapps commercial/API validation.
11. Basic, transparent app-based adherence indicator.
12. Offline action queue and idempotent sync.

### 7.3 Explicitly defer

AI companion, child entertainment, sleep coaching, marketplace, diagnosis, drug-interaction recommendations, doctor/pharmacy portals, payment, carrier subscription, and advanced forecasting. CareBuddy may appear only as a clearly marked future concept in a competition pitch, not as an MVP dependency.

## 8. Consumer validation plan

### Phase A — Problem interviews

Recruit a deliberately varied discovery sample, not a statistically representative sample:

- 12 adult caregivers managing medicine for a parent;
- 12 patients aged 60+ with at least one repeated medicine;
- 6 self-managing adults with complex schedules;
- 5 pharmacists or pharmacy staff;
- 5 physicians familiar with outpatient prescribing;
- 3 accessibility/geriatric-care practitioners.

Do not show the solution in the first half of each interview. Ask for the last real medication-management episode, artifacts used, errors, calls, refill problems, and emotional cost.

Key questions:

1. “Tell me about the last time the medicine routine changed.”
2. “How did you convert the prescription into times and quantities?”
3. “What happens when nobody is sure whether a dose was taken?”
4. “How often do you call or message about medicine, and what triggers it?”
5. “Show me how you know when stock will finish.”
6. “Who should see medication information, and what should stay private?”
7. “What would make an alert annoying or frightening?”
8. “Who would set this up, who would use it daily, and who would pay?”

### Phase B — Prescription/OCR feasibility

With explicit consent and de-identification, collect at least 200 prescription images spanning public/private facilities, printed/handwritten content, lighting conditions, Bangla/English mixtures, and common dosage forms. A clinician or pharmacist should create the reference transcription.

Measure per field, not only whole-page OCR:

- medicine name exact-match and normalized-match accuracy;
- strength, form, dose, frequency, duration, and meal-relation accuracy;
- proportion of fields correctly flagged as uncertain;
- time to review and correct;
- dangerous-error count;
- rejection/rescan rate.

**Safety gate:** no automatic schedule activation at any accuracy. The pilot should not proceed if users routinely confirm incorrect high-risk fields or cannot distinguish OCR from the prescription source.

### Phase C — Usability test

Test a clickable prototype with 8–10 older patients and 8–10 caregivers, iterating between rounds. Tasks:

1. review an OCR draft;
2. correct one wrong dose field;
3. confirm a schedule;
4. respond to a reminder;
5. snooze once;
6. understand an “unconfirmed” caregiver alert;
7. add stock;
8. revoke caregiver access.

Record completion without help, critical errors, time, comprehension, font scaling, touch misses, and whether users can explain what the app does **not** know.

### Phase D — Concierge pilot

Run a 4–6 week pilot with 30–50 patient-caregiver pairs. Use manual review behind the scenes for OCR and mock or tightly controlled SMS. This tests behavior and service operations before scaling automation.

### 8.1 Go/no-go gates

These are proposed product thresholds, not medical standards:

| Gate | GO threshold | Stop/rework signal |
|---|---|---|
| Problem frequency | At least 60% of target caregivers describe a recurring reminder, uncertainty, or stock problem without prompting | Problem is rare or adequately solved by alarms/messages |
| Value | At least 50% of caregiver participants ask to continue or recommend the pilot | Positive comments but no continued use intent |
| Setup | At least 80% complete verified setup with no critical error after one guided introduction | Repeated dose/frequency confirmation errors |
| Elderly reminder UX | At least 85% independently perform Taken and Snooze in usability testing | Confusion between Taken, Skip, and Snooze |
| Alert quality | Fewer than 20% of escalations are rated unnecessary after tuning | Alert fatigue or relationship conflict |
| Reliability | At least 99% of locally scheduled test reminders fire within the defined device-specific tolerance in the supported-device matrix | Vendor battery behavior makes reminders unpredictable |
| Retention | At least 60% of pairs remain active in week 4 | Use collapses after novelty |
| Payment | At least 20% of target caregivers choose a real paid preorder or deposit at the tested price | Hypothetical willingness but no payment behavior |
| Safety | Zero unreviewed OCR schedules and zero known invalid state transitions | Any schedule activated without explicit verification |

### 8.2 Pricing tests

Do not ask only “Would you pay?” Test behavior with three concrete offers:

- Free: one patient, offline reminders, one caregiver, push alerts.
- Family Care: multiple patients, inventory insights, reports, priority support.
- Telecom add-on: important SMS alerts, priced separately or with a fair-use allowance.

Use a refundable deposit or preorder after demonstrating the workflow. SMS should be an explicit costed add-on until bdapps economics are confirmed.

## 9. Measurement model

### North-star pilot metric

**Care routines completed without an avoidable caregiver intervention**, measured only from app events and follow-up—not as proof of physical ingestion.

### Supporting metrics

- prescription review completion rate;
- median time from upload to verified schedule;
- uncertain-field correction rate;
- local reminder delivery rate by device/OS;
- confirmation, snooze, skip, and unconfirmed rates;
- caregiver escalation rate and useful-alert rating;
- stock-warning lead time;
- weekly active patient-caregiver pairs;
- week-4 retention;
- support contacts per active pair;
- SMS delivery and cost per active paid pair;
- privacy/consent revocations and deletion completion.

Do not market the adherence percentage as a clinical outcome. It is an app-based indicator: confirmed scheduled doses divided by eligible scheduled doses, with skipped/cancelled rules stated visibly.

## 10. Risks and mitigations

| Risk | Severity | Mitigation before build/launch |
|---|---:|---|
| OCR creates unsafe instruction | Critical | Draft-only OCR, field confidence, mandatory review, audit trail, reference image |
| Reminder interpreted as medical advice | Critical | Use confirmed schedule only; no diagnosis or dosage changes |
| New Bangladesh data rules misapplied | Critical | Counsel review of the 2025 data ordinances; data map, consent, deletion, localization/transfer assessment |
| bdapps commercial model unsuitable for transactional alerts | High | Obtain written confirmation; keep alternate SMS provider and push-only core |
| False missed-dose alerts damage trust | High | Grace period, patient follow-up, late confirmation, configurable escalation |
| Android OEM kills alarms | High | Supported-device matrix, exact-alarm education, boot/timezone rescheduling, telemetry without health content |
| Bangla UX is translated but unnatural | High | Co-design and usability testing in Bangla; voice prompts tested with older users |
| Caregiver monitoring becomes coercive | High | Explicit invitation, granular permissions, visible access log, easy revoke |
| Business cannot cover SMS/support | High | Free local core, paid exception services, cost caps, real price testing |
| Competition copies features | Medium | Local operations, partnerships, reliability, consent design, and validated data—not feature count |

Bangladesh enacted the National Data Governance Ordinance 2025 and listed a Personal Data Protection Ordinance 2025 in the official ordinance register. Exact obligations for CareMate's health, image, voice, child, cross-border, and caregiver data flows require current Bangladeshi legal review before production. ([Legislative and Parliamentary Affairs Division, 2025 ordinance register](https://legislativediv.gov.bd/pages/static-pages/694032c335ce18e1c0561ff1), [Bangladesh Laws, National Data Governance Ordinance 2025](https://bdlaws.minlaw.gov.bd/act-print-1573.html))

## 11. Evidence register for statistics

| Source | Publication/update date | Statistic used | Context and limitation |
|---|---|---|---|
| WHO Bangladesh NCD announcement | 7 Sep 2025 | NCDs cause 71% of deaths; over half premature | Burden context, not adherence prevalence |
| Global Health Action study | 2021 | 46.3% low adherence among 2,070 selected facility patients with type 2 diabetes | Self-report; selected Chattogram facilities; not national prevalence |
| BTRC mobile subscribers | Feb 2026 data | 185.84m total mobile subscriptions; 57.30m Robi | SIM subscriptions, not unique users |
| BTRC internet subscribers | Feb 2026 data | 128.27m total; 113.50m mobile internet | Active in preceding 90 days; not daily reliability |
| BTRC handset information | Feb 2026 data | 45.89% of locally produced handsets were smartphones | Production mix, not installed base |
| ITU DataHub | 2024 indicators | 64.4% phone ownership; 53.4% internet use; gender and rural/urban gaps | National, not elderly-specific |
| Hoque & Sorwar | May 2017 | Nearly 300 Dhaka participants aged 60+ | General mHealth intention; not national CareMate demand |
| Journal of Public Health SMS willingness study | Online Feb 2015 | 52.0% positive stated WTP; median BDT 20/month among 515 Dhaka diabetes patients | Phone-owning, urban, condition-specific; hypothetical payment |
| BMC Public Health rural SMS study | Dec 2021 | 67.4% willing to receive; 50.5% willing to pay; median BDT 10 among 307 hypertension participants | Single rural area; hypothetical payment; SMS literacy constraint |
| Yasmin et al. | 2020 publication; 2014–15 intervention | 320 randomized at baseline; medication adherence >90% self-reported in both groups | Urban diabetes sample; ceiling/self-report limitations |
| Journal of Human Hypertension A/B trial | Nov 2024 | 26.5% versus 20.7% attendance among overdue patients; 78.2% versus 74.8% among regular patients with cascade versus no reminder | Visit attendance, not medication adherence or clinical outcome |
| Choudhry et al. | 2017 | 53,480 randomized | Low-cost devices, not CareMate; shows reminders alone may fail |

## 12. Unknowns requiring primary field work or partner confirmation

- National prevalence and causes of medication non-adherence by age and condition.
- Frequency and format distribution of handwritten prescriptions.
- OCR performance on representative Bangladeshi prescriptions.
- Installed Android/device mix among target caregivers and patients.
- Bangla voice, terminology, and numeral preferences by age and literacy.
- Real caregiver alert tolerance and escalation timing.
- Willingness to pay and payer identity.
- Transactional bdapps SMS eligibility, recipient networks, pricing, consent, throughput, and SLA.
- General-purpose versus subscription-only bdapps OTP eligibility.
- bKash merchant approval and subscription-payment terms for CareMate.
- Exact legal classification and compliance duties for health, child, voice, and cross-border data.

## 13. Recommended next action

Do **not** start with the complete 50-screen product. Run a six-week discovery milestone:

1. secure a clinical/pharmacy adviser and Bangladesh privacy counsel;
2. complete 35–40 problem interviews;
3. obtain written bdapps and bKash integration answers;
4. test the core Bangla patient and caregiver prototype;
5. build a consented prescription corpus and benchmark OCR providers;
6. price-test the caregiver service with real commitment;
7. publish a pilot protocol and safety case;
8. only then approve the narrow MVP backlog.

The product should move to implementation when the problem, safe workflow, alert usefulness, reminder reliability, partner feasibility, and payment signal pass the gates above. Until then, CareMate is a strong, locally relevant hypothesis—not a validated service.

---

## Source notes

Competitor capabilities and prices are first-party product claims captured at the research cut-off and may change. They are useful for feature comparison but are not independent proof of effectiveness, security, user count, or regulatory compliance. No source in this report proves that CareMate is clinically effective or that consumers will pay for it.
