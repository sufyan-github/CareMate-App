# CareMate research evidence

**Research cut-off:** 16 August 2026  
**Scope:** evidence for the first milestone: problem definition, Bangladesh market and consumer acceptance, bdapps/Robi and bKash feasibility, and first-party competitor review.  
**Evidence rule:** official statistics, provider-owned documentation, first-party product material, and original research only. Vendor claims are identified as such; absence of first-party evidence is not treated as proof that a feature does not exist.

## Executive decision

There is enough evidence to justify a narrowly scoped CareMate MVP, but not enough to justify broad claims about the total addressable market, SMS reliability, universal smartphone access, or willingness to pay for a subscription.

The defensible first product is:

1. Bengali-first, Android-first medication scheduling with alarms that work offline.
2. Explicit **user verification** of every prescription-derived instruction before activation.
3. Simple dose states: Scheduled, Snoozed, Confirmed, Skipped, and Missed. Confirmation means a user action, never proof that medicine was swallowed.
4. Optional caregiver pairing and missed-dose escalation, with consent, configurable delay, and a quiet-hours policy.
5. Inventory countdown and refill warning.
6. SMS/voice as a fallback or escalation channel, not the only interaction path.
7. Provider abstractions for bdapps and bKash, with production integrations gated on merchant/operator approval and sandbox/contract validation.

Why this shape: Bangladesh studies show real medication-adherence problems and high interest in mobile/SMS health support, but also show uneven phone ownership and SMS literacy. Competitors already cover generic reminders, adherence logs, refill alerts, caregiver sharing, and in some cases label scanning. CareMate's credible differentiation is therefore the **combination** of Bangladesh localization, safety-gated prescription capture, offline reminders, inventory, and family escalation—not the claim that it invented pill reminders.

## 1. Problem and Bangladesh context

### 1.1 Medication adherence is a documented problem

A 2021 cross-sectional study of 2,070 people with type 2 diabetes attending five health facilities in Chattogram Division found **46.3% low medication adherence** (95% CI 41.4%–55.8%). Because adherence was self-reported and the sample came from selected facilities, this is evidence of a material problem in that population, not a national prevalence estimate. [Original study, Global Health Action](https://doi.org/10.1080/16549716.2021.1872895)

A qualitative study of 12 patients at a specialist diabetes hospital in Dhaka identified forgetfulness, medication cost, concern about side effects, and limited medication knowledge as barriers. The small purposive urban sample is useful for problem discovery, not prevalence estimation. [Original study, BMC Research Notes, 21 March 2017](https://doi.org/10.1186/s13104-017-2454-7)

Product implication: reminders can address forgetfulness and tracking, but CareMate cannot solve affordability, medicine supply, side effects, or clinical misunderstanding by notification alone. Refill warnings, clear doctor-instruction display, and a route back to a clinician/pharmacist are more defensible than adherence gamification by itself.

### 1.2 Older adults and family care are central, but the care system is not app-ready by default

The Bangladesh Bureau of Statistics preliminary 2022 census age table implies **9.28% of the population—about 15.36 million people—was aged 60+**. This is a preliminary, unadjusted census result, not a 2026 population estimate. UNFPA's current Bangladesh summary rounds the share to 9.3%. [BBS, *Population & Housing Census 2022: Preliminary Report*](https://nsds.bbs.gov.bd/storage/files/1/Publications/BBS_Preliminary_Census_2022.pdf), [UNFPA Bangladesh, “Population trends”](https://bangladesh.unfpa.org/en/topics/population-trends)

WHO's Bangladesh long-term-care profile describes policy commitments and limited age-specific services, and notes the need for a coordinated long-term-care action plan. A 2025 WHO overview also states that developing countries commonly depend on household and community members for much long-term care. These sources support a family-caregiver workflow, but do not quantify how many Bangladeshi families would adopt CareMate. [WHO, *Long-term Care for Older People: Bangladesh*](https://iris.who.int/bitstream/handle/10665/331448/9789290227359-eng.pdf), [WHO, “Long-Term Care in Ageing Populations,” 10 February 2025](https://wkc.who.int/resources/publications/m/item/long-term-care-in-ageing-populations)

WHO's 2025 Bangladesh healthy-ageing monitoring sheet reports no nationally representative public individual-level data on older people's health/needs, no reported national in-person or online caregiver programme, and no reported 2023 data for the share receiving long-term care or the formal long-term-care workforce. “Not reported” is an evidence gap, not proof that no private or NGO service exists. [WHO, *Bangladesh: Facts and Figures—Healthy Ageing 2025*](https://cdn.who.int/media/docs/default-source/searo/ageing-and-health/fact-sheets-2024/bangladesh---facts-and-figures---healthy-ageing.pdf?sfvrsn=a8984000_2)

Product implication: make caregiver participation optional and consent-based. The patient should retain visibility and revocation controls; caregiver status must not silently transfer medical decision-making authority.

### 1.3 Mobile reach is large, but subscriptions are not people and connectivity is not guaranteed

BTRC reported **185.84 million mobile subscriptions** in February 2026, including **57.30 million Robi subscriptions**. It also reported **113.50 million active mobile-internet subscriptions** and **64.44% mobile-internet penetration** for that month. BTRC defines an internet subscriber as a subscription that accessed the internet at least once in the preceding 90 days. These are SIM/subscription measures, not unique people, smartphone owners, or daily active internet users. [BTRC mobile subscribers](https://btrc.gov.bd/site/page/0ae188ae-146e-465c-8ed8-d76b7947b5dd/), [BTRC internet subscribers](https://btrc.gov.bd/site/page/347df7fe-409f-451e-a415-65b109a207f5/), [BTRC teledensity](https://btrc.gov.bd/site/page/9dbd49e8-e5dd-4e4b-b047-1d42ec922e47/Teledensity)

BTRC's handset-production page says smartphones were **45.89% of locally produced handsets in February 2026**. This is a production mix, not the installed handset base, so it cannot be used as a smartphone-ownership statistic. [BTRC mobile handset information](https://btrc.gov.bd/site/page/cf3588dd-31c9-45b2-b9d5-10f9f2990526/)

ITU's 2024 harmonized indicators estimate **64.4% personal mobile-phone ownership** and **53.4% internet use**. Ownership was 70.0% for men versus 58.8% for women; internet use was 75.8% in urban areas versus 43.6% in rural areas. LTE/WiMAX population coverage was 99.6%, illustrating why network coverage must not be equated with personal device ownership or meaningful use. These are national indicators but not elderly-specific. [ITU DataHub, Bangladesh Digital Development Dashboard](https://datahub.itu.int/data/?e=BGD)

Product implication: local notifications and local schedule data must function without an active network session. SMS cannot be assumed to be reliable or readable merely because mobile subscriptions are numerous.

### 1.4 Digital-health access is unequal

A mixed-method study in Mirzapur surveyed 854 households in 2013–2014 and later conducted 20 focus groups. It found **90.3% household ownership of an electronic device, mostly a mobile phone**, but only **55.2% personal ownership among respondents**; **7.2% of personal-device owners** had used a device for health information or services. The data are old and semiurban, so they describe access mechanisms and inequality, not today's national adoption rate. The qualitative findings pointed to unfamiliarity, discomfort, skills, and awareness barriers, and documented the role of family/peer intermediaries. [Original study, JMIR mHealth and uHealth, 2020](https://mhealth.jmir.org/2020/7/e16473/)

A population survey in rural Chakaria (4,915 respondents, data from 2012–2013) found 81% household mobile-phone ownership, 45% respondent ownership, 31% awareness that phones could be used for health care, and only 2% mobile use among people who had sought care in the prior two weeks. Nearly 70% nevertheless preferred calling a doctor for at least one of lower cost, time savings, or instant advice. These figures are historical and locally specific. [Original study, PLOS ONE, 6 November 2014](https://doi.org/10.1371/journal.pone.0111413)

Product implication: support caregiver-assisted onboarding, Bengali copy, large targets, low reading burden, teach-back confirmation, and voice prompts where feasible. Do not require the patient to own a personal smartphone for the caregiver workflow.

## 2. Consumer acceptance and intervention evidence

### 2.1 Willingness to receive is stronger than proven willingness to subscribe

A Dhaka hospital study of 515 patients with type 2 diabetes found that all but two were interested in receiving diabetes-related SMS; **52.0% expressed positive willingness to pay**, **16.3% zero willingness**, and **31.6% did not provide an amount**. The reported median willingness to pay was **BDT 20/month (IQR 45)**. All participants owned a phone, only about half could read/retrieve SMS, and 36.1% could send SMS. The sample was urban, condition-specific, and already connected to specialist care; the stated-price method did not test an actual purchase. [Original study, *Journal of Public Health*, published online 16 February 2015](https://doi.org/10.1093/pubmed/fdv009)

A 2021 rural study of 307 adults with hypertension in Narail found **61.6% owned a mobile phone**, **67.4% were willing to receive health-information SMS**, and **50.5% were willing to pay**; median stated willingness to pay was **BDT 10 (IQR 28)**. Less than half of phone owners could read SMS. Phone ownership was 73.3% among men versus 50.0% among women, and 82.6% at ages 30–39 versus 53.5% at ages 60–75. This is a single rural area and a hypertension sample, not a national demand estimate. [Original study, BMC Public Health, 30 December 2021](https://doi.org/10.1186/s12889-021-12418-9)

Decision: these studies justify testing SMS/voice and a low-price offer. They do **not** justify selecting a final CareMate price. Conduct fresh Bengali concept testing and a real-money pricing experiment across age, gender, rural/urban location, caregiver role, Robi/non-Robi operator, and smartphone/feature-phone access.

### 2.2 Reminder interventions can help, but results are outcome- and population-specific

In a Dhaka randomized trial, 236 adults with type 2 diabetes were allocated to standard care or standard care plus 90 daily SMS over six months. Among the 200 with endline HbA1c, the between-group HbA1c change was **−0.66 percentage points** (95% CI −0.97 to −0.35; p<0.0001). Self-reported medication-adherence scores improved in both groups with **no significant difference between groups**. Eligibility required access to SMS, and the setting was a specialist urban hospital, limiting generalization. [Original trial, *Diabetes Care*, 1 August 2015](https://doi.org/10.2337/dc15-0505)

A separate Dhaka randomized study used interactive voice calls every ten days plus a 24/7 call centre. It enrolled 320 and retained 273 at endline. Self-reported medication adherence was above 90% in both groups at baseline and endline, with no significant medication-adherence change; diet, physical activity, tobacco/betel-nut behaviour, and glycaemic outcomes improved on several measures. The sample came from one tertiary hospital and was about 75% female, and adherence was self-reported. [Original trial, BMC Health Services Research, 8 June 2020](https://doi.org/10.1186/s12913-020-05387-z)

A much larger 2024 randomized A/B test in Bangladesh's hypertension primary-care network studied 20,072 regular and 12,708 overdue patients. Visit attendance among regular patients was 78.2% after a three-message cascade, 76.6% after one SMS, and 74.8% without a reminder. Among overdue patients, one SMS produced 26.5% attendance versus 20.7% without SMS (adjusted prevalence ratio 1.23, 95% CI 1.15–1.33). This supports SMS for re-engagement, not medication taking or blood-pressure control; valid numbers were required, ownership was not recorded, and some older/rural patients supplied a relative's number. [Original trial, *Journal of Human Hypertension*, November 2024](https://doi.org/10.1038/s41371-024-00942-1)

Counterevidence matters: a rural Bangladesh trial of 420 adults compared in-person education/booklets with the same package plus 21 generalized weekly SMS. Both groups improved, but SMS added no significant behaviour-change effect. The authors raised lack of tailoring, prompt feedback, phone credit, and hard-to-understand brevity as possible issues. This was one purposively enrolled community and not SMS versus usual care. [Original trial, JMIR, December 2020](https://doi.org/10.2196/19137)

Two Bangladesh surveys of adults aged 60+ further support social design rather than a solitary patient app. A 2017 Dhaka survey (274 completed questionnaires) found performance expectancy, effort expectancy, social influence, technology anxiety, and resistance to change significantly associated with intention. A 2022 survey of 493 existing mHealth users recruited through 24 hospitals found social influence, price value, habit, and service quality among significant predictors. Both measured self-reported intention/use in selected hospital-connected samples and cannot estimate national demand. [International Journal of Medical Informatics, May 2017](https://doi.org/10.1016/j.ijmedinf.2017.02.002), [BMC Medical Informatics and Decision Making, July 2022](https://doi.org/10.1186/s12911-022-01917-3)

A 2025 purposive survey of 392 female family caregivers in Dhaka associated caregiving-related internet-service use with social networks, perceived usefulness, reliability, accessibility, affordability, family support, education, and internet literacy. Its machine-learning feature importance is predictive rather than causal; the urban, female-only, partly online sample likely overselects digitally connected caregivers, and the outcome was broad internet-service use rather than medication management. [Original study, *Health Science Reports*, 2025](https://doi.org/10.1002/hsr2.70665)

Decision: position reminders as support, not a guaranteed adherence intervention. The MVP should measure delivery, acknowledgement, snooze, confirmed/skipped/missed state, caregiver escalation, and retention. Health-outcome claims require a prospective evaluation.

## 3. bdapps / Robi evidence

### 3.1 What is officially documented now

The current bdapps API reference labels itself **BDApps API Documentation 1.0** and shows HTTP JSON operations hosted at `https://developer.bdapps.com`. It uses an `applicationId` plus an application `password` in request bodies. These credentials must remain server-side. [Official bdapps API reference](https://dev.bdapps.com/API_Documentation/bdapps_tap_api.html)

| Capability | Official operation | Method / essential behaviour | Confidence and caveat |
|---|---|---|---|
| Send SMS | `/sms/send` | POST; message, destinations, application credentials; `deliveryStatusRequest` 0/1; response includes request/message IDs and per-destination status | Documented. Message length limit is not quantified; docs only say over-limit messages are split. |
| Delivery report | application callback matching documented `/sms/report` schema | bdapps/TAP POSTs destination, timestamp, request ID, and one of DELIVERED, EXPIRED, DELETED, UNDELIVERABLE, ACCEPTED, UNKNOWN, REJECTED; message ID/request ID correlation is required | Documented payload, but callback authentication/signature and retry schedule are not published. |
| Receive SMS | `/sms/receive` callback schema | POST from platform to application with source, message, request ID, encoding | Documented schema. Provisioned callback setup must be validated. |
| Request OTP | `/otp/request` | POST; application credentials and subscriber ID; response includes `referenceNo` | Documented specifically as OTP for subscription activation—not verified as a general-purpose CareMate login OTP. |
| Verify OTP | `/otp/verify` | POST; reference number and OTP; success response includes subscription status | Documented. A successful verification activates the bdapps subscription flow. |
| Subscribe / unsubscribe | `/subscription/send` | POST; `action=1` subscribe, `action=0` unsubscribe | Documented. Consent/approval behaviour must be tested in the assigned product. |
| Subscription status | `/subscription/getStatus` | POST; returns REGISTERED/UNREGISTERED status | Documented. Treat as provider state, reconciled into internal state. |
| Subscriber-base size | `/subscription/query-base` | POST | Documented; not needed for patient-level authorization. |
| Subscription notification callback | documented `/subscription/notify` schema | bdapps POSTs status and frequency (daily/weekly/monthly/yearly) | Documented payload; authenticity and retry rules are not published. |
| Query mobile balance | `/caas/get/balance` | POST; `MobileAccount`, BDT | Documented. Access/product approval required. |
| Direct debit / carrier billing | `/caas/direct/debit` | POST; external transaction ID, subscriber, amount, BDT; response contains internal/reference IDs | Documented as CaaS. Consent, eligible subscribers, price points, reversals, retries, reconciliation, and commercial terms need written confirmation. |

The bdapps product page describes SMS, USSD, CaaS, Subscription, and OTP APIs. The provisioning guide requires developers to create a Pro application and configure the resources and callback URLs. The developer guideline says apps are reviewed and may not be published if requirements fail. [bdapps Pro](https://dev.bdapps.com/bdapps-pro.php), [provisioning guide](https://dev.bdapps.com/provisioning.php), [developer guide](https://dev.bdapps.com/developer-guide.php)

The current charging-SDK page says the option is disabled by default and must be enabled by bdapps support; API key/secret appear only after support confirmation. This makes approval a hard dependency, not an implementation detail. [bdapps Charging SDK consent guide](https://dev.bdapps.com/consent.php)

The official pricing page shows Robi end-user charging bands for bdapps Pro: **BDT 1–2 per SMS**, **BDT 1–2 per USSD menu**, and **BDT 1–50 for CaaS**, plus applicable taxes and a stated developer revenue-share range of 50%–90% after reconciliation. This page describes chargeable bdapps services, not a procurement rate card for sending transactional caregiver alerts; do not use it as the SMS cost forecast until bdapps confirms the CareMate product model. [bdapps pricing](https://dev.bdapps.com/pricing.php)

### 3.2 Unknowns that block production design

The public materials reviewed do not provide a reliable, current answer for:

- rate limits, throughput, burst limits, queueing, or per-app quotas;
- end-to-end SMS delivery-time or delivery-success SLA;
- destination/operator coverage for each API and whether non-Robi recipients are supported;
- a comprehensive error-code catalogue beyond success examples such as `S1000`;
- callback signing, source IP ranges, mTLS, replay prevention, or retry/backoff schedules;
- sandbox endpoint/credentials equivalent to production (the site offers SDK simulators, but that is not proof of a hosted sandbox);
- OTP validity, attempt limits, resend limits, lockout, fraud controls, and whether OTP may be used outside subscription activation;
- subscription charging amount/frequency rules for the approved CareMate product;
- CaaS refund/reversal/query/dispute APIs and idempotency guarantees;
- data-retention, privacy, health-content, and marketing-approval requirements for patient/caregiver messages;
- current commercial contract, taxes, settlement timeline, and revenue share for CareMate.

**Status: API-approval-required.** Before coding the production adapter, obtain an approved Pro application, assigned credentials, product-specific API pack/OpenAPI file, test numbers, callback security requirements, error catalogue, SLA, commercial schedule, and written confirmation of operator coverage and health-message use.

### 3.3 Safe integration stance

- Flutter calls the CareMate backend only; the backend calls bdapps.
- Store credentials in a secrets manager and redact them from logs.
- Persist provider request/message/external transaction IDs and make commands idempotent.
- Treat HTTP 200 as transport success only; inspect provider status fields.
- Deduplicate callbacks, timestamp events, and keep an audit trail.
- Retry only documented transient failures; never blindly retry a debit.
- In the MVP use a mock adapter until the approval checklist is complete.

## 4. bKash evidence

### 4.1 Merchant and environment requirements

bKash's current developer overview says production use requires merchant onboarding, KYC documents, an agreement, completed sandbox testing, and production credentials issued by bKash. The public sandbox is self-contained and uses mocked APIs; its endpoint convention is `https://<service-name>.sandbox.bka.sh`, while production is `https://<service-name>.pay.bka.sh`. TLS 1.2 or higher is required. [bKash Developer, “Product Overview,” current documentation](https://developer.bka.sh/docs/product-overview)

The bKash merchant form asks whether the applicant has an NID, valid trade licence, and bank account. The online-business form also asks for a website/Facebook/mobile-app URL. Submitting the form starts verification; it does not guarantee gateway approval. [bKash Merchant](https://www.bkash.com/en/business/merchant), [bKash Online Business](https://www.bkash.com/en/business/online-business)

The official business page currently lists payment gateway, tokenized checkout, subscription payments, instant refunds, direct charges, B2C payout, and APIs for online business. Availability for CareMate remains subject to onboarding and contract. [bKash Business](https://www.bkash.com/en/business)

### 4.2 Officially documented payment operations

The currently exposed Checkout API reference uses versioned paths labelled `v1.2.0-beta`, despite being the current public reference. Do not freeze that version until bKash assigns the merchant product and credentials.

| Capability | Current sandbox reference | Essential documented fields | Caveat |
|---|---|---|---|
| Grant token | `POST https://checkout.sandbox.bka.sh/v1.2.0-beta/checkout/token/grant` | body: app key/secret; headers: username/password | All four are secrets. Official sample backend says they are shared during PGW onboarding. |
| Create checkout payment | `POST .../checkout/payment/create` | amount, BDT currency, intent sale/authorization, unique merchant invoice; `X-APP-Key` plus bearer authorization | Payment is not complete after creation. |
| Execute payment | `POST .../checkout/payment/execute/{paymentID}` | payment ID; authorized headers | Backend must persist and validate result. |
| Query payment | `GET .../checkout/payment/query/{paymentID}` | payment ID; authorized headers | Use to reconcile uncertain outcomes; never trust the mobile redirect alone. |
| Void authorization | `POST .../checkout/payment/void/{paymentID}` | payment ID | Applies to authorization flow; availability/product terms need confirmation. |
| Refund | `POST .../checkout/payment/refund` | payment ID, transaction ID; optional/defined amount, SKU, reason | Official reference confirms operation; eligibility, partial-refund rules, windows, and settlement need contract confirmation. |
| Tokenized create | `POST https://tokenized.sandbox.bka.sh/v1.2.0-beta/tokenized/checkout/create` | mode, payer reference, required callback URL; optional agreement ID/payment fields depending on mode | Supports agreement-based/tokenized flows. Callback authentication is not documented on the exposed page. |
| Tokenized status | `POST .../tokenized/checkout/payment/status` | payment status operation | Exact product flow must follow assigned docs. |

Primary references: [Grant Token](https://developer.bka.sh/reference/gettokenusingpost), [Create Payment](https://developer.bka.sh/reference/createpaymentusingpost), [Execute Payment](https://developer.bka.sh/reference/executepaymentusingpost), [Query Payment](https://developer.bka.sh/reference/querypaymentusingget), [Refund](https://developer.bka.sh/reference/post_checkout-payment-refund), [Tokenized Create](https://developer.bka.sh/reference/post_tokenized-checkout-create), [Tokenized Payment Status](https://developer.bka.sh/reference/paymentstatususingpost), [official merchant backend sample](https://github.com/bKash-developer/pgw-merchant-backend-php).

bKash says Checkout and Tokenized Checkout are available, as are Auth and Capture and subscriptions. Tokenized Checkout binds a bKash account to the merchant's customer ID after authorization, then later payments can require only the PIN when a valid agreement exists. [bKash product overview](https://developer.bka.sh/docs/product-overview), [bKash tokenized-checkout terms](https://www.bkash.com/en/page/tokenized_checkout)

### 4.3 Security and unknowns

**Verified:** bKash uses merchant-issued secrets and access tokens; the payment experience is hosted/secured by bKash; production credentials follow onboarding; query and refund operations exist; tokenized creation requires a callback URL.

**Unknown/unverified from public pages:** callback signature or webhook secret, source IPs, mTLS, replay rules, callback retry schedule, token TTL/rotation semantics, rate limits, payment expiration, idempotency key support, exact error taxonomy, refund window/partial-refund rules, subscription billing eligibility, pricing/MDR, settlement, chargeback/dispute process, and health-service merchant acceptance.

Architecture consequence (an inference from the documented flow): the backend should create/execute/query payments and own the payment state machine. A callback/redirect is only a signal; before granting premium access, query or otherwise verify the transaction server-to-server and match amount, currency, merchant invoice, payment ID, transaction ID, and expected user/order. Do not put app key, app secret, username, password, or bearer tokens in Flutter. Never use a personal bKash account as the payment integration.

**Status: merchant-approval-required.** Production implementation should wait for assigned API version, credentials, signed commercial agreement, callback-security specification, test cases, and go-live certification.

## 5. Competitor evidence

Legend: **Yes** = supported by current first-party material; **Limited** = partial, older, enterprise-only, or unclear; **No evidence** = no current first-party support found; it does not prove absence.

| Product | Capture / OCR | Scheduling and dose state | Caregiver / missed-dose | Inventory / refill | Voice / AI | Commercial model and material caveat |
|---|---|---|---|---|---|---|
| Medisafe | No current label-OCR evidence; Apple Health Records import is different | Complex schedules, PRN, customizable timing | **Yes:** Medfriend; official 2024 case study says alert 30 minutes after a dose remains unmarked | Refill reminders; full pill-count workflow unclear | Custom sounds/Medtones; AI personalization of reminder timing, not generative medical advice | Free + Premium. Store shows $4.99 monthly/$39.99 annual among legacy IAPs; region/offer may differ. |
| MyTherapy | **Limited:** older first-party pages describe package barcode lookup, not prescription OCR | Medication, appointment, symptom, and measurement reminders; taken/skipped log | **Limited:** older team/family encouragement; no current caregiver missed-dose escalation verified | Supply tracking and refill/new-prescription reminders | No current AI or spoken medication reminder verified | Site says always free, while current US App Store lists IAPs; pricing position is inconsistent. |
| CareClinic | **Unverified:** “photos/no typing” marketing does not clearly document OCR | Rich schedules, tapers/cycles, groups, critical alerts, smart snooze | **Yes:** care-team roles and missed-medication alerts | Doses-left and refill reminders | Siri/Google Assistant shortcuts; vendor calls some trends “AI-powered” without technical detail | Free + monthly/annual/lifetime Premium; current store IAPs do not map cleanly to plan prices. |
| Dosecast consumer | No OCR/barcode evidence; US drug database/photo attachment in Pro | Broad fixed/interval/PRN scheduling; official FAQ says tapers are not supported | **Limited:** multi-person/device sync; enterprise CareNexus caregiver monitoring must not be attributed to consumer app | Pro quantity/refill/no-refills-left alerts | Offline audio/visual reminders; enterprise AI claims are not consumer features | Free indefinitely + subscription Pro/CloudSync; current consumer price not surfaced. |
| DoseAlert (Moose Media) | **Yes:** on-device English pharmacy-label OCR with mandatory review; handwriting/non-English unsupported | Fixed/interval/weekday/cycle/taper/PRN schedules; escalating reminders | **Yes:** QR pairing and configurable caregiver missed-dose alerts | Automatic pill count and low-stock alerts | Accessibility support; no spoken assistant or medical-advice AI | Seven-day trial then CAD 9.99 one-time. Very early-stage (store showed 10+ downloads); site/store publisher names differ. |
| RXClock | No capture flow documented | Vendor claims custom schedules, Take/Snooze/Skip | Vendor claims secure-code caregiver sync and missed-dose alerts | Vendor claims days-supply and refill tracking | Vendor claims AI interaction checking; no spoken feature | Vendor claims free/Pro $4.99/month/Family $9.99/month, but site copy conflicts. No identifiable publisher, dated terms/privacy, or official app-store listing found; treat all as unverified vendor claims. |

### First-party sources and qualifications

- **Medisafe:** [Google Play, updated 9 June 2026](https://play.google.com/store/apps/details?id=com.medisafe.android.client), [Apple App Store](https://apps.apple.com/us/app/medisafe-medication-management/id573916946), [Medfriend case study, February 2024](https://www.medisafe.com/wp-content/uploads/2024/02/Medisafe_Feb-24-Medfriend_CaseStudy.pdf), [privacy policy, updated 1 December 2025](https://medisafe.com/privacy-policy), [product page](https://medisafe.com/download-the-app). Exact Premium price and free-tier Medfriend limits are not consistently stated.
- **MyTherapy:** [current product page](https://www.mytherapyapp.com/), [Apple App Store](https://apps.apple.com/us/app/pill-reminder-mytherapy/id662170995), [older first-party barcode/family description](https://www.mytherapyapp.com/managing-rheumatoid-arthritis-with-an-app). Barcode and family/team claims may vary by market/version.
- **CareClinic:** [medication tracker](https://start.careclinic.io/knowledgebase/medication-tracker/), [reminders](https://start.careclinic.io/knowledgebase/my-reminders/), [care team](https://start.careclinic.io/knowledgebase/care-team/), [caregiver limit, updated 30 July 2026](https://start.careclinic.io/knowledgebase/care-team/am-getting-limit-error-trying/368/), [Premium differences, updated 29 July 2026](https://start.careclinic.io/knowledgebase/premium-subscriptions/there-any-feature-differences-between/228/), [voice commands, updated 30 July 2026](https://start.careclinic.io/knowledgebase/integrations/types-voice-commands-i-use/17), [Apple App Store](https://apps.apple.com/us/app/tracker-reminder-careclinic/id1455648231).
- **Dosecast:** [features](https://dosecast.com/features/), [FAQ](https://dosecast.com/faq/), [patient solution](https://dosecast.com/patients/), [CareNexus provider solution](https://dosecast.com/health-providers/), [Apple App Store](https://apps.apple.com/us/app/dosecast-my-pill-reminder-app/id365191644). Consumer and enterprise claims must remain separated.
- **DoseAlert:** [official product/pricing](https://dosealert.app/), [prescription-scanning help](https://dosealert.app/help/prescription-scanning), [Google Play, updated 13 April 2026](https://play.google.com/store/apps/details?id=com.moosemedia.doseguard).
- **RXClock:** [vendor site](https://rxclock.app/). No corroborating first-party legal/company/store presence was found.

### Competitive opportunity

CareMate should not claim novelty for reminders, snooze, adherence histories, reports, refill alerts, caregiver sharing, or label scanning. All appear in first-party competitor material.

The opportunity to test is a coherent Bangladesh-first workflow:

- Bengali and low-literacy onboarding;
- photo capture of local prescriptions with OCR clearly separated from user-confirmed instructions;
- offline alarms plus optional SMS/voice escalation;
- patient-controlled family roles;
- local medicine vocabulary and packaging support;
- inventory derived from confirmed schedule and dispensed quantity;
- bdapps carrier integration and bKash/Robi commercial options after approval;
- transparent dose-state language that does not claim ingestion;
- accessibility for older adults.

## 6. Evidence-backed MVP requirements

1. **Prescription safety:** OCR output remains a draft. The user must confirm medicine, strength, form, dose, timing, duration, and instructions before scheduling. Low-confidence or contradictory fields must be highlighted, never silently completed.
2. **Offline first:** active schedules and alarms remain on-device; network loss must not suppress a reminder.
3. **Caregiver consent:** invitations require explicit patient acceptance; permissions are role-based; all access and changes are logged; revocation is immediate.
4. **Escalation semantics:** a caregiver alert means “no confirmation received by the configured deadline,” not “medicine not swallowed.”
5. **Multichannel access:** large Bengali UI, optional audio read-out, caregiver setup, and SMS fallback. SMS must not carry unnecessary diagnosis or medication detail on shared phones.
6. **Commercial caution:** free core pilot first; test actual paid conversion. Do not infer price from decade-old stated willingness-to-pay studies.
7. **Provider abstraction:** `SmsProvider`, `OtpProvider`, `CarrierBillingProvider`, and `PaymentProvider` adapters with mock implementations and idempotent backend commands.
8. **Outcome honesty:** report reminder delivery and user-confirmed dose states. Do not market improved clinical outcomes without CareMate-specific prospective evidence.

## 7. Research gaps and validation plan

### Must answer before a real pilot

- Can representative Bengali-speaking patients and caregivers correctly set up a prescription and understand Confirmed versus Missed?
- What prescription formats, handwriting patterns, abbreviations, medicine names, and packaging are common in the intended pilot clinics/pharmacies?
- What are OCR field-level accuracy and unsafe-error rates on a consented local dataset?
- What share of target households has a suitable Android phone, who controls it, and when is it online?
- Do older adults prefer alarm, recorded Bengali voice, IVR, caregiver call, or SMS—and what privacy risks arise on shared phones?
- What escalation delay avoids both unsafe silence and caregiver fatigue?
- What real paid conversion occurs at candidate price points after a free trial?
- What are bdapps' assigned APIs, operator coverage, SLA, rate limits, approval rules, and commercial terms?
- What bKash product/version and callback security are assigned after onboarding?

### Recommended research sequence

1. 15–20 contextual interviews split among patients, caregivers, pharmacists, and prescribers in at least one urban and one non-urban site.
2. Usability testing with older adults and low-literacy users; use comprehension tasks, not opinion scores alone.
3. Build a de-identified/consented prescription benchmark and conduct blinded field-level OCR evaluation.
4. Concierge pilot of 30–50 patient-caregiver pairs using offline reminders and a mock/manual escalation backend.
5. Provider sandbox/approval spike with test numbers only.
6. Real-money pricing test after core workflow retention is established.

## 8. Statistical source register

Every statistic used above is registered here with context and limitations.

| Source title | Publisher / date | URL | Statistic used | Context and limitation |
|---|---|---|---|---|
| *Factors associated with low adherence to medication among patients with type 2 diabetes at different healthcare facilities in southern Bangladesh* | Global Health Action; 2021 | https://doi.org/10.1080/16549716.2021.1872895 | 46.3% low adherence (95% CI 41.4%–55.8%); n=2,070 | Cross-sectional, self-reported adherence, five facilities in Chattogram Division; not national prevalence. |
| *Patients’ perspective of disease and medication adherence for type 2 diabetes in an urban area in Bangladesh* | BMC Research Notes; 21 Mar 2017 | https://doi.org/10.1186/s13104-017-2454-7 | 12 interviews | Purposive sample at one specialist Dhaka hospital; qualitative themes, no prevalence estimate. |
| *Population & Housing Census 2022: Preliminary Report* | Bangladesh Bureau of Statistics; 2022 | https://nsds.bbs.gov.bd/storage/files/1/Publications/BBS_Preliminary_Census_2022.pdf | Age table sums to 9.28% / about 15.36m aged 60+ | National preliminary/unadjusted census; not a 2026 estimate; later total population was post-enumeration-adjusted. |
| “Mobile subscribers” | BTRC; page updated 1 Apr 2026 | https://btrc.gov.bd/site/page/0ae188ae-146e-465c-8ed8-d76b7947b5dd/ | 185.84m total, 57.30m Robi, Feb 2026 | Active subscriptions/SIMs, not unique individuals. |
| “Internet subscribers” / “Teledensity and penetration” | BTRC; pages updated 1 Apr 2026 | https://btrc.gov.bd/site/page/347df7fe-409f-451e-a415-65b109a207f5/ | 113.50m mobile internet; 64.44% mobile-internet penetration, Feb 2026 | Subscription active at least once in preceding 90 days; not people, smartphones, quality, or daily use. |
| “Mobile phone handset information” | BTRC; current page accessed 16 Aug 2026 | https://btrc.gov.bd/site/page/cf3588dd-31c9-45b2-b9d5-10f9f2990526/ | 45.89% of locally produced handsets were smartphones, Feb 2026 | Production mix only; excludes installed base/import context and cannot estimate ownership. |
| Bangladesh Digital Development Dashboard | ITU DataHub; 2024 indicators | https://datahub.itu.int/data/?e=BGD | 64.4% phone ownership; 53.4% internet use; ownership 70.0% men/58.8% women; internet 75.8% urban/43.6% rural; LTE/WiMAX coverage 99.6% | Harmonized national indicators, not elderly-specific; coverage/subscriptions do not establish ownership, literacy, quality, or meaningful use. |
| *Digital Health and Inequalities in Access to Health Services in Bangladesh* | JMIR mHealth and uHealth; 2020 | https://mhealth.jmir.org/2020/7/e16473/ | n=854 households + 20 FGDs; 90.3% household device ownership; 55.2% personal ownership; 7.2% of owners used digital health | Survey 2013–14 in semiurban Mirzapur; FGD 2017; historical and not nationally representative. |
| *Prospects of mHealth Services in Bangladesh: Recent Evidence from Chakaria* | PLOS ONE; 6 Nov 2014 | https://doi.org/10.1371/journal.pone.0111413 | n=4,915; 81% household phone ownership, 45% respondent ownership, 31% awareness, 2% use among recent care-seekers, nearly 70% preference for phone contact for at least one stated reason | Rural Chakaria, data 2012–13; historical/local, not current national adoption. |
| *Mobile phone use and willingness to pay for SMS for diabetes in Bangladesh* | Journal of Public Health / Oxford University Press; published online 16 Feb 2015 (vol. 2016) | https://doi.org/10.1093/pubmed/fdv009 | n=515; 513 interested; 52.0% positive WTP, 16.3% zero, 31.6% no amount; median BDT 20/month (IQR 45); ~half read/retrieve SMS; 36.1% send | Urban specialist-clinic diabetes sample, all phone owners; hypothetical stated WTP, not purchase behaviour; old price level. |
| *Understanding the sociodemographic factors associated with intention to receive SMS messages for health information in a rural area of Bangladesh* | BMC Public Health; 30 Dec 2021 | https://doi.org/10.1186/s12889-021-12418-9 | n=307; 61.6% phone ownership, 67.4% willing to receive, 50.5% willing to pay, median BDT 10 (IQR 28); ownership 73.3% men/50.0% women and 82.6% ages 30–39/53.5% ages 60–75 | Adults with hypertension in one rural union; stated intention/WTP; not national or general consumer sample. |
| *Effects of Mobile Phone SMS to Improve Glycemic Control Among Patients With Type 2 Diabetes in Bangladesh* | Diabetes Care / American Diabetes Association; 1 Aug 2015 | https://doi.org/10.2337/dc15-0505 | n=236 randomized, 200 analyzed for HbA1c; between-group change −0.66 percentage points (95% CI −0.97 to −0.35; p<0.0001); no significant between-group adherence-score difference | Urban specialist hospital; required SMS access; oral-medication patients diagnosed within 5 years; 36 missing endline HbA1c; not evidence of universal reminder effectiveness. |
| *The influence of mobile phone-based health reminders on patient adherence...* | BMC Health Services Research; 8 Jun 2020 | https://doi.org/10.1186/s12913-020-05387-z | n=320 baseline/273 endline; medication adherence >90% both groups and no significant change; around 75% female | One Dhaka tertiary hospital; voice calls every 10 days + call centre; self-report and attrition limit inference. |
| *Text messaging to improve retention in hypertension care in Bangladesh* | Journal of Human Hypertension; Nov 2024 | https://doi.org/10.1038/s41371-024-00942-1 | 20,072 regular + 12,708 overdue; regular attendance 78.2% cascade/76.6% single/74.8% control; overdue 26.5% SMS/20.7% control; aPR 1.23 (1.15–1.33) | Clinic attendance, not medication use or BP control; valid number required; ownership/receipt/literacy/cost-effectiveness not measured. |
| *Awareness Development and Usage of Mobile Health Technology Among Individuals With Hypertension...* | JMIR; Dec 2020 | https://doi.org/10.2196/19137 | n=420 randomized, 412 completed; no significant additional behaviour-change effect from 21 weekly SMS | Single purposively enrolled rural community; both groups received intensive in-person intervention; limited schooling and phone-access eligibility. |
| *Understanding factors influencing the adoption of mHealth by the elderly* | International Journal of Medical Informatics; May 2017 | https://doi.org/10.1016/j.ijmedinf.2017.02.002 | 300 questionnaires, 274 completed, age 60+ | Dhaka selected sample; intentions, not actual adoption or adherence; generic mHealth and old data. |
| *Factors influencing the elderly’s adoption of mHealth* | BMC Medical Informatics and Decision Making; Jul 2022 | https://doi.org/10.1186/s12911-022-01917-3 | n=493 existing users recruited across 24 hospitals; 94% response | Convenience sample already using mHealth; self-report/SEM; excludes many digitally disconnected older adults; no medication outcome. |
| *Social Determinants Influencing Internet-Based Service Adoption Among Female Family Caregivers in Bangladesh* | Health Science Reports; 2025 | https://doi.org/10.1002/hsr2.70665 | n=392 female family caregivers | Purposive Dhaka sample, partly online; broad self-reported internet-service use, not a medication app; feature importance is predictive, not causal. |
| “Mobile subscribers” | BTRC; page updated 1 Apr 2026 | https://btrc.gov.bd/site/page/0ae188ae-146e-465c-8ed8-d76b7947b5dd/ | 57.30m Robi subscriptions, Feb 2026 | Subscription count only; does not prove bdapps API eligibility or recipient coverage. |
| “bdapps Pricing” | bdapps; page copyright 2021, accessed 16 Aug 2026 | https://dev.bdapps.com/pricing.php | Pro SMS BDT 1–2; USSD BDT 1–2/menu; CaaS BDT 1–50; stated revenue share 50%–90% | Public end-user/service charging bands plus tax; not a transactional-SMS vendor quote or CareMate contract. |
| *The Medisafe App And Its Medfriend Feature* | Medisafe; Feb 2024 | https://www.medisafe.com/wp-content/uploads/2024/02/Medisafe_Feb-24-Medfriend_CaseStudy.pdf | Medfriend alert 30 minutes after dose remains unmarked | Vendor case study and product behaviour, not independent effectiveness evidence. |
| “Medisafe Medication Management” | Apple App Store / MediSafe Inc.; accessed 16 Aug 2026 | https://apps.apple.com/us/app/medisafe-medication-management/id573916946 | Store displayed USD 4.99 monthly and USD 39.99 annual among multiple IAP entries | US storefront and legacy/offer entries; exact current checkout price is region- and offer-dependent. |
| DoseAlert product page / Google Play | Moose Media / Moose FM; Play updated 13 Apr 2026, accessed 16 Aug 2026 | https://dosealert.app/ | CAD 9.99 one-time after 7-day trial; Google Play displayed 10+ downloads | Vendor/store data; price is CAD and may change; download bracket indicates very early stage, not active-user count. |
| RXClock vendor page | Publisher/date not identified; accessed 16 Aug 2026 | https://rxclock.app/ | Claimed Pro USD 4.99/month; Family USD 9.99/month | Uncorroborated vendor claim; site has internal plan-feature conflicts and no verified store/legal identity. |

## 9. Non-statistical source register

- bdapps: [API reference](https://dev.bdapps.com/API_Documentation/bdapps_tap_api.html), [Pro API overview](https://dev.bdapps.com/bdapps-pro.php), [provisioning](https://dev.bdapps.com/provisioning.php), [Charging SDK enablement](https://dev.bdapps.com/consent.php), [developer review guidance](https://dev.bdapps.com/developer-guide.php), [downloads/simulator](https://dev.bdapps.com/bdapps-pro-downloads.php).
- bKash: [product overview](https://developer.bka.sh/docs/product-overview), [business products](https://www.bkash.com/en/business), [merchant sign-up](https://www.bkash.com/en/business/merchant), [online-business sign-up](https://www.bkash.com/en/business/online-business), [Checkout terms](https://www.bkash.com/en/page/terms-of-use-checkout), [Tokenized terms](https://www.bkash.com/en/page/tokenized_checkout), [official sample backend](https://github.com/bKash-developer/pgw-merchant-backend-php), and the operation pages linked in section 4.
- Bangladesh ageing/care: [WHO Bangladesh long-term-care profile](https://iris.who.int/bitstream/handle/10665/331448/9789290227359-eng.pdf), [WHO long-term-care overview](https://wkc.who.int/resources/publications/m/item/long-term-care-in-ageing-populations), [BBS Population & Housing Census 2022 publications](https://bbs.portal.gov.bd/pages/static-pages/6922e0ff933eb65569e297dc).
- Competitors: first-party links are grouped under section 5 so product claims remain visibly separate from independent research.

## 10. Claims CareMate must not make from this evidence

- “CareMate is the first medication reminder/caregiver app.”
- “Bangladesh has 185.84 million mobile users.” The source counts subscriptions.
- “45.89% of Bangladeshis own smartphones.” The source is locally produced handset mix.
- “SMS is reliable nationwide” or “bdapps reaches every operator.” No suitable official SLA/coverage evidence was found.
- “bdapps OTP can be used for any app login.” Public documentation ties it to subscription activation.
- “A user took/swallowed a dose.” The product only observes confirmation or lack of confirmation.
- “OCR understood the prescription.” OCR produces an unverified draft.
- “Reminders improve adherence/health outcomes for everyone.” Trials show mixed, population-specific outcomes.
- “Consumers will pay BDT 10 or BDT 20 per month today.” Those are historical hypothetical WTP results in selected clinical samples.
- “bKash payment is available by using a personal wallet.” Production PGW requires merchant onboarding and credentials.
- “RXClock is HIPAA/SOC 2 compliant” or that its offline server-push claim is established. Those are unverified site claims.
