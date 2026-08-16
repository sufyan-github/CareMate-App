# CareMate prescription OCR model evaluation

**Research cut-off:** 17 August 2026

**Scope:** Bangladesh prescriptions containing Bangla and English, printed and handwritten text
**Evidence rule:** primary sources only—official repositories, model cards, papers, and provider documentation. Vendor benchmark claims are identified as such and are not treated as CareMate accuracy evidence.

## Executive decision

Do **not** use `JonSnow1807/Medical-Prescription-OCR` as CareMate's production OCR model. Its own repository and model card say it is English-first, trained on 1,000 synthetic prescriptions, not validated for clinical use, and should not process real prescriptions. The reported 71% character accuracy and 84% word accuracy are self-reported on 100 held-out synthetic samples, not on Bangladeshi prescriptions. [Repository and stated limitations](https://github.com/JonSnow1807/Medical-Prescription-OCR), [model card](https://huggingface.co/chinmays18/medical-prescription-ocr), [dataset](https://huggingface.co/datasets/chinmays18/medical-prescription-dataset)

There is no defensible single “best model” before testing on consented, locally representative prescriptions. The recommended launch architecture is:

1. **On-device capture and quality gate:** crop, perspective correction, blur/glare checks, and a manual-entry fallback. Retain the current ML Kit Latin recognizer only as a fast English-print preview; it cannot cover Bangla.
2. **Primary production OCR candidate:** Google Document AI Enterprise OCR behind the CareMate backend. Google describes it as document-specialized OCR for printed and handwritten text in more than 200 languages; its processor matrix lists Bangla/Bengali (`bn`, `Beng`), and the product includes layout, deskewing, rotation correction, language/handwriting hints, and document-quality scoring. The OCR processor is available in `asia-south1`. This is the strongest currently documented fit for mixed Bangla/English prescriptions, but it still requires a Bangladesh benchmark. [processor and language matrix](https://docs.cloud.google.com/document-ai/docs/processors-list), [Enterprise Document OCR](https://docs.cloud.google.com/document-ai/docs/enterprise-document-ocr)
3. **Self-hosted comparison/fallback candidate:** benchmark PaddleOCR-VL-1.6 and 1.5 on the same dataset. The official project describes a 0.9B document model, Apache-2.0 model licensing, and Bengali among the 111 languages added to the 1.5 family. However, the official material does not validate Bangla handwriting or prescriptions, so it is not safe to select from headline benchmarks alone. [PaddleOCR repository](https://github.com/PaddlePaddle/PaddleOCR), [PaddleOCR-VL-1.6 model card](https://huggingface.co/PaddlePaddle/PaddleOCR-VL-1.6), [deployment warning](https://www.paddleocr.ai/latest/en/version3.x/pipeline_usage/PaddleOCR-VL.html)
4. **Structured extraction, not source-of-truth OCR:** use a current OpenAI vision-capable Responses model, called only by the CareMate backend, to convert the image plus OCR evidence into a strict prescription JSON draft. OpenAI officially supports image inputs and JSON-schema Structured Outputs. It does not publish Bangladesh-prescription accuracy, so the model must output `null` for unreadable fields and cite source spans/boxes; it must never invent or silently “correct” medicine instructions. [image inputs](https://platform.openai.com/docs/quickstart/make-your-first-api-request), [Structured Outputs](https://platform.openai.com/docs/api-reference/responses)
5. **Bangladesh medicine normalization:** rank candidates against the official DGDA allopathic product database. Normalization may suggest a registered brand/generic/strength, but must preserve raw OCR text and never overwrite it invisibly. [DGDA product database](https://info.dgda.gov.bd/allopathic-medicines)
6. **Mandatory human confirmation:** every medicine, strength, unit, dose, route, frequency, timing, and duration remains an unverified draft until the user confirms it. No OCR or AI result may create an active reminder automatically.

This is a safety decision, not a claim that Google or OpenAI is clinically validated. The production provider should be selected only after the benchmark and privacy gates in this document pass.

## Current CareMate implementation

CareMate currently instantiates ML Kit with `TextRecognitionScript.latin`. That is appropriate only for English/Latin printed preview. Google's current on-device Text Recognition v2 packages support Latin, Chinese, Devanagari, Japanese, and Korean scripts; Bengali is absent. Bundled models can work immediately and offline, while unbundled models require a first download. ML Kit states that inputs and results are processed fully on-device and are not sent to Google servers. [Android implementation options](https://developers.google.com/ml-kit/vision/text-recognition/v2/android), [supported scripts and languages](https://developers.google.com/ml-kit/vision/text-recognition/v2/languages), [ML Kit data processing terms](https://developers.google.com/ml-kit/terms)

Decision: keep the existing recognizer as a clearly labelled **English printed preview/fallback**, not as the Bangladesh prescription engine.

## Candidate comparison

| Candidate | Bangla + English | Handwriting | Deployment/privacy | License/commercial posture | CareMate decision |
|---|---|---|---|---|---|
| Current Google ML Kit Text Recognition v2 | English/Latin yes; Bengali script not supported | No documented prescription/Bengali handwriting support | On-device; bundled option can work offline; Google says inputs/results stay on device | Proprietary mobile SDK under Google terms | Keep only for capture preview and English printed fallback |
| Tesseract 5 + `ben`/`eng` data | Bengali and English trained data exist | Official docs describe printed-text extraction, not handwriting | Fully local; can compile for Android/iPhone | Engine and official trained data are Apache-2.0 | Useful low-resource printed fallback; not primary handwriting OCR |
| EasyOCR | Official code has a Bengali model for `bn`, Assamese, Manipuri and English | Repository lists handwriting support as “coming next” | Self-hosted Python/PyTorch; image need not leave CareMate infrastructure | Apache-2.0 | Benchmark for printed mixed-script text; reject as handwriting solution |
| PaddleOCR PP-OCRv6 | Excellent size tiers, but official v6 list is Chinese/English/Japanese plus Latin-script languages; no Bengali | Improved general OCR, but no Bengali support in v6 | Self-hosted, edge/mobile/server tiers | Apache-2.0 | Do not select v6 for Bangla despite it being the newest general OCR line |
| PaddleOCR-VL-1.5/1.6 | 1.5 release explicitly adds Bengali within 111 languages; 1.6 is the current 0.9B document parser | No official Bangladesh-prescription handwriting validation | Self-hosted VLM; official docs recommend a dedicated VLM service for production | Official 1.6 model card and project are Apache-2.0 | Best open/self-hosted candidate to benchmark, not a proven winner |
| Google Document AI Enterprise OCR | Bangla/Bengali appears in the 200+ language OCR processor list; mixed document text supported | Enterprise OCR includes handwriting and language/handwriting hints | Cloud API; `asia-south1` available. Google says synchronous input is processed in memory and not persisted; regional processing, IAM, VPC-SC and CMEK are available | Managed commercial service; no model redistribution | Best documented launch candidate, subject to benchmark and contract/privacy review |
| Google Cloud Vision | Printed Bengali is supported and regularly evaluated; mixed languages supported | Bengali-script handwriting is experimental; Latin handwriting supported | Cloud API. Synchronous images are processed in memory and not persisted to disk according to Google; request metadata is temporarily logged | Managed commercial service; no model redistribution | Lighter managed benchmark/fallback, weaker documented handwriting posture than Document AI |
| Azure Vision Read | Printed Bengali supported; mixed language lines supported | Current GA handwriting list does not include Bengali | Cloud API or on-prem Read container | Managed commercial service/container terms | Strong printed candidate, weak fit for Bangla handwriting |
| OpenAI vision-capable Responses model | Can accept images and extract text, but no official Bangla-prescription OCR benchmark | No official prescription handwriting accuracy claim | Cloud API; route through CareMate backend only | Proprietary service/API terms | Use for schema extraction and cross-checking, never sole OCR evidence |
| `JonSnow1807/Medical-Prescription-OCR` | Model card says primarily English | Claims handwritten English prescription support | About 0.2B parameters/~800 MB; self-hosted | MIT model/repo; dataset page reviewed does not present a clear reusable-data license | Research comparison only; do not ship |

### Primary-source details

#### Tesseract

Tesseract 5 is an Apache-2.0 OCR engine whose documentation describes an LSTM line recognizer and printed-text extraction. The official `tessdata_best` repository contains both `ben.traineddata` and `eng.traineddata`, also under Apache-2.0, and the project says it can be compiled for Android and iPhone. This makes it attractive for offline printed documents, but the project does not claim general handwriting recognition. [engine and license](https://github.com/tesseract-ocr/tesseract), [Bengali trained data](https://github.com/tesseract-ocr/tessdata_best), [mobile compilation statement](https://github.com/tesseract-ocr/tessdoc)

#### EasyOCR

EasyOCR's current configuration includes a `bengali_g1` recognizer and allows `bn`/`as`/`en` together. Its repository is Apache-2.0, but the official README still lists handwritten-text support as future work. It is therefore a reasonable printed-script baseline, not a doctor's-handwriting solution. [language configuration](https://github.com/JaidedAI/EasyOCR/blob/master/easyocr/config.py), [recognizer selection](https://github.com/JaidedAI/EasyOCR/blob/master/easyocr/easyocr.py), [README and limitation](https://github.com/JaidedAI/EasyOCR)

#### PaddleOCR

Do not assume that “newest” means “best for Bangla.” PP-OCRv6 is the current universal OCR family with tiny, small, and medium tiers, but its official 50-language list is Chinese, English, Japanese, and Latin-script languages—not Bengali. [PP-OCRv6 documentation](https://www.paddleocr.ai/latest/en/version3.x/algorithm/PP-OCRv6/PP-OCRv6.html)

PaddleOCR-VL is a different document-parsing family. The official repository says PaddleOCR-VL-1.5 expanded to 111 languages including Bengali; the current 1.6 card describes a 0.9B-parameter model and Apache-2.0 license. Its public document benchmarks cover document parsing, tables, formulas, layouts, and physical distortion, not Bangladeshi prescriptions. The local Python examples are for validation, and the official deployment guide recommends a dedicated inference service for production. [project release notes](https://github.com/PaddlePaddle/PaddleOCR), [1.6 technical page](https://github.com/PaddlePaddle/PaddleOCR/blob/main/docs/version3.x/algorithm/PaddleOCR-VL/PaddleOCR-VL-1.6.en.md), [production deployment warning](https://www.paddleocr.ai/latest/en/version3.x/pipeline_usage/PaddleOCR-VL.html)

#### Google Document AI and Cloud Vision

Document AI Enterprise OCR is Google's document-specialized option. The official processor list says the GA OCR processor extracts printed and handwritten text in more than 200 languages and lists both Bangla and Bengali (`bn`, `Beng`). Enterprise OCR returns document layout, can deskew images, supports rotation correction and language/handwriting hints, and provides image-quality scores for blur, noise, darkness, faintness, small text, cutoff, and glare. The OCR processor is available in `asia-south1`. [processor list, languages and regions](https://docs.cloud.google.com/document-ai/docs/processors-list), [Enterprise Document OCR capabilities](https://docs.cloud.google.com/document-ai/docs/enterprise-document-ocr)

Google says synchronous Document AI input is processed in memory and not persisted, batch input normally deletes immediately with a one-day failsafe TTL, and customer content is not used to train its models. It supports regional processing and controls including IAM, VPC Service Controls and customer-managed encryption keys. [Document AI security/data usage](https://docs.cloud.google.com/document-ai/docs/security)

Cloud Vision remains a lighter benchmark/fallback. It explicitly documents regularly evaluated printed Bengali and experimental Bengali-script handwriting. `DOCUMENT_TEXT_DETECTION` supports automatic language detection across the full supported set; hints such as `bn` and `en` should be tested because Google warns that a wrong hint can hurt results. [language levels and handwriting scripts](https://docs.cloud.google.com/vision/docs/languages), [handwriting language hints](https://docs.cloud.google.com/vision/docs/handwriting)

Google states that synchronous Vision images are processed in memory and not persisted to disk, that submitted content is not used to train Cloud Vision, and that request metadata may be logged temporarily. Async operations briefly store input with a failsafe TTL of a few hours. EU and US OCR endpoints are available, but the default global endpoint does not guarantee a particular location. [Vision data usage](https://docs.cloud.google.com/vision/docs/data-usage), [OCR locations](https://docs.cloud.google.com/vision/docs/ocr)

#### Azure Vision

Azure Read supports printed Bengali and mixed languages, including mixed text on one line. Its current GA handwriting table lists English, Japanese, Simplified Chinese, Korean, French, Portuguese, German, Spanish, and Italian—but not Bengali. Azure also documents an on-premises Read container. This makes it a credible print benchmark or private deployment option, not the leading Bangla-handwriting candidate. [language support](https://learn.microsoft.com/en-us/azure/ai-services/computer-vision/language-support), [OCR deployment options](https://learn.microsoft.com/en-us/azure/ai-services/computer-vision/overview-ocr)

#### OpenAI

The Responses API can accept image inputs and Structured Outputs can constrain output to a JSON Schema. These features fit a prescription parser that returns an evidence-linked draft. They do not prove OCR correctness or clinical validity. OpenAI's vision guide warns that non-Latin text may perform suboptimally, small or rotated text can be misread, and image descriptions can be incorrect. Pin a model snapshot after evaluation because OpenAI notes that prompting behavior can change between snapshots and recommends evals for consistency. [image input and limitations](https://developers.openai.com/api/docs/guides/images-vision), [Structured Outputs API](https://platform.openai.com/docs/api-reference/responses), [model-version guidance](https://platform.openai.com/docs/api-reference/authentication)

OpenAI says API inputs/outputs are not used for training by default. Default abuse-monitoring logs can retain customer content for up to 30 days. The Responses API also has 30-day application-state retention by default; `store: false` does not by itself remove abuse-monitoring retention. Eligible organizations can request Modified Abuse Monitoring or Zero Data Retention, subject to endpoint and image-input limitations. [current API data controls](https://developers.openai.com/api/docs/guides/your-data), [enterprise privacy](https://openai.com/enterprise-privacy/)

The API key must never be embedded in Flutter, committed, logged, or returned to the app. OpenAI explicitly requires routing mobile requests through the application's own backend and recommends environment variables or a key-management service. [official key-safety guidance](https://help.openai.com/en/articles/5112595-best-practices-for-api-key-safety)

## Evaluation of the supplied JonSnow model

Positive attributes:

- MIT-licensed repository/model and simple self-hosted Transformers/Gradio path.
- Document-level Donut architecture produces structured text rather than only character boxes.
- Explicitly discloses limitations and warns against clinical use.

Blocking issues for CareMate:

- The model card says it is primarily English; there is no Bangla training or evaluation.
- All 1,000 images are synthetic, split 800/100/100. The visible dataset rows contain a small synthetic vocabulary and generated combinations, not real Bangladesh brands, abbreviations, physician styles, or layouts.
- Its own 84% word and 71% character accuracy imply error levels unacceptable for silent medication scheduling even if those figures transferred—which has not been shown.
- The repository explicitly says research use only, not clinically validated, and not to process real prescriptions.
- The dataset page reviewed does not show an explicit dataset license badge, so reuse of the training data needs separate confirmation even though the model/repository says MIT.
- The model is about 0.2B parameters and the repository describes an ~800 MB download, which is unsuitable for the intended lightweight Android path.
- A BART zero-shot prescription classifier only predicts document type; it does not make extracted medication instructions safe or correct.

Decision: include it only as an offline research baseline in the benchmark. Do not copy it into the mobile app, deploy its public demo for patient documents, or use its output to create schedules.

## Recommended production flow

```text
Flutter camera/gallery
  -> on-device crop, blur/glare/perspective checks
  -> encrypted upload to CareMate backend
  -> OCR provider abstraction
       A: Google Document AI Enterprise OCR
       B: self-hosted PaddleOCR-VL benchmark/fallback
       C: Google Cloud Vision lightweight fallback
       D: manual transcription fallback
  -> preserve raw text + boxes + provider confidence + model version
  -> OpenAI structured extractor (backend only)
       image/crops + OCR evidence -> strict JSON, nullable fields, evidence references
  -> deterministic validators
       units, strength, frequency, duration, contradictions, missing evidence
  -> DGDA candidate ranking (suggestions, never invisible correction)
  -> side-by-side user review of every field
  -> explicit user confirmation
  -> medication draft/save
  -> separate confirmation before schedule/reminders become active
```

### Provider interface

Keep providers replaceable and return evidence rather than just a string:

```ts
type OcrLine = {
  text: string;
  script: "Bengali" | "Latin" | "unknown";
  confidence: number | null;
  polygon: Array<{ x: number; y: number }>;
};

type PrescriptionDraftField = {
  value: string | null;
  confidence: "high" | "medium" | "low" | "unknown";
  evidenceLineIds: string[];
  warnings: string[];
};
```

Every provider response should record provider, exact model/version, request ID, latency, and an internal prompt/schema version. Never record raw images, patient names, phone numbers, or full OCR text in application logs.

### AI extraction rules

- Return `null` when unreadable; never guess a missing strength, frequency, duration, or route.
- Preserve raw text and show the original crop next to each extracted value.
- Require an evidence line/box for every non-null clinical field.
- Treat DGDA matches as candidates with similarity scores, not corrections.
- If OCR and AI disagree, mark the field low-confidence and require manual re-entry.
- Never infer a schedule from a drug's usual usage. Only transcribe the document and explicit user corrections.
- Do not provide diagnosis, interaction advice, or dose recommendations in the capture pipeline.
- Never activate reminders, caregiver alerts, refill calculations, or subscription actions from an unconfirmed draft.

## Bangladesh benchmark required before provider selection

Create a consented, de-identified evaluation set reviewed under an approved privacy process. Do not upload patient prescriptions to public demos or public datasets.

### Sampling

- Bangla-only, English-only, and mixed-script prescriptions.
- Printed, handwritten, and mixed printed/handwritten documents.
- Government/private facilities, urban/rural settings, multiple regions, and different prescription pads.
- Many prescribers and handwriting styles; split train/validation/test by prescriber and facility to reduce leakage.
- Common capture failures: low light, glare, blur, skew, folds, stamps, multiple pages, and low-cost phone cameras.
- Local brand/generic names, strengths, units, Bengali numerals, abbreviations, and timing conventions.

### Ground truth

- Two independent transcriptions plus pharmacist/qualified-clinical adjudication for disagreements.
- Store line polygons and exact raw transcription separately from normalized medicine entities.
- Mark genuinely illegible source text as illegible; do not force annotators to guess.
- Keep a locked test set that is never used for prompt or model tuning.

### Metrics

- Character error rate and word error rate by script and by printed/handwritten subset.
- Exact-match precision/recall for medicine name, strength, unit, form, dose, route, frequency, timing, and duration.
- Critical substitution rate, omission rate, and hallucinated-field rate.
- DGDA top-1/top-3 candidate recall without allowing normalization to hide OCR errors.
- Percentage of drafts requiring manual correction, review completion time, latency, failure rate, and cost per page.
- Fairness slices by script mix, capture quality, facility type, and device tier.

Compare at minimum: current ML Kit, Tesseract `ben+eng`, EasyOCR `bn+en`, JonSnow research baseline, PaddleOCR-VL-1.5/1.6, Google Document AI Enterprise OCR, Google Cloud Vision, Azure Read, OpenAI direct image extraction, and OCR-evidence-plus-OpenAI extraction.

### Non-negotiable release gates

- Zero paths that turn OCR/AI output into an active medication schedule without explicit human confirmation.
- Every saved clinical field retains its raw source/evidence and audit trail.
- Unreadable/contradictory fields fail closed and support manual entry.
- Provider/model/prompt changes must pass the locked regression set before rollout.
- Security review, threat model, retention/deletion verification, and applicable Bangladesh legal/regulatory review are complete.
- Product copy calls the result an **unverified draft**, never a verified prescription or medical advice.

## Privacy and operational requirements

- Ask for explicit consent before any cloud OCR/AI upload; explain the provider path in Bengali and English.
- Offer manual entry and an on-device English-print fallback when the user declines cloud processing or is offline.
- Strip EXIF metadata and unrelated image borders when practical; do not perform unsafe redaction that removes prescription context.
- Encrypt in transit and at rest; use short-lived object URLs and least-privilege service identities.
- Delete temporary images after processing and expose user deletion controls. Make the retention period a documented configuration with automated enforcement.
- Store OpenAI and OCR credentials only in backend secret management. Use separate development/production projects, least-privilege keys, spend/rate limits, and rotation.
- Rate-limit uploads, validate MIME type and decoded image dimensions, malware-scan where appropriate, and cap file/page size.
- Never send patient prescription images to public Hugging Face Spaces, Gradio demos, or third-party test pages.
- Keep provider request IDs and redacted operational metadata for troubleshooting, not document contents.

## Phased implementation recommendation

### Phase 1 — safe functional capture

- Finish camera/gallery/manual-entry flows.
- Keep ML Kit Latin preview with honest English-print labelling.
- Store OCR output only as an editable draft.
- Add tests proving scan cancellation, failure, empty text, and low-confidence paths never create a medicine.

### Phase 2 — provider benchmark

- Implement backend `PrescriptionOcrProvider` adapters for Google Document AI, Google Cloud Vision, self-hosted PaddleOCR-VL, and OpenAI structured extraction.
- Build the consented Bangladesh test set and evaluation harness.
- Select provider/model snapshots from measured field-level accuracy, safety, latency, privacy, and cost—not generic OCR leaderboard scores.

### Phase 3 — controlled production pilot

- Pilot with a small consenting group and pharmacist review.
- Monitor corrections and critical disagreements without logging patient document content.
- Use feature flags and a kill switch; fall back to manual entry on provider or policy failure.

### Phase 4 — local specialization

- If the benchmark shows material gaps, train/fine-tune only on lawfully collected, consented, de-identified Bangladesh data.
- Document dataset provenance, license/consent, model card, per-slice performance, known failure modes, and rollback criteria.
- Re-evaluate every model or prompt update against the locked set.

## Final recommendation

For the next CareMate phase, implement the abstraction and safety workflow first. Benchmark **Google Document AI Enterprise OCR as the leading managed OCR candidate**, **PaddleOCR-VL-1.5/1.6 as the leading self-hosted candidate**, and **OpenAI as an evidence-bound structured parser/cross-checker**. Keep Cloud Vision, ML Kit, Tesseract and EasyOCR as lower-complexity, privacy-preserving, or low-cost fallbacks where their documented script limits permit. Reject the supplied JonSnow model for production, while retaining it as a clearly labelled research baseline.

The product guarantee must be procedural: OCR creates an unverified draft, users verify every instruction, and no model is allowed to prescribe or activate treatment.
