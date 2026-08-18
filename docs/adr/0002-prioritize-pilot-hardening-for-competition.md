# ADR-0002: Prioritize pilot hardening for the competition build

**Status:** Accepted  
**Date:** 17 August 2026  
**Deciders:** CareMate product and engineering

## Context

CareMate already implements the core medication, reminder, offline-sync, caregiver, prescription-draft, inventory, and reporting domains. The next request is to make it a standard, physical competition-winning application.

The main constraints are safety-sensitive health data, a physical Android demonstration, one active implementation stream, unapproved production providers, an existing modular monolith and Flutter client, and a mixed local worktree. The competition rubric is unspecified, so the design must be defensible across problem, innovation, usability, implementation, impact, and presentation criteria.

## Decision

Keep the existing Flutter client, NestJS modular monolith, Turso/libSQL persistence, local-first reminder authority, and provider interfaces. Invest the competition build in a narrow, polished, observable, accessible and reproducible pilot journey.

Add competition capabilities only when they strengthen the core journey or its evidence. Demo behavior must be explicitly labelled, deterministic, isolated from real accounts/providers, and incapable of sending messages or charging money. Provider-dependent features retain manual fallbacks and kill switches.

Implementation is divided into independently validated segments. Each segment stages only its own paths, produces one focused commit, and is pushed to the competition-readiness branch.

## Options considered

### Option A: Add maximum feature breadth

| Dimension           | Assessment |
| ------------------- | ---------- |
| Complexity          | High       |
| Demo reliability    | Low        |
| Safety risk         | High       |
| Judge comprehension | Low        |
| Time to evidence    | Poor       |

**Pros:** More features to list.  
**Cons:** Fragmented story, incomplete integrations, more failure modes, and weak proof of quality.

### Option B: Harden and polish the existing differentiated journey

| Dimension           | Assessment |
| ------------------- | ---------- |
| Complexity          | Medium     |
| Demo reliability    | High       |
| Safety risk         | Controlled |
| Judge comprehension | High       |
| Time to evidence    | Strong     |

**Pros:** Builds on tested domains, improves trust and usability, and yields a coherent physical demonstration.  
**Cons:** Commercial and speculative features remain visibly deferred.

### Option C: Rewrite into microservices or a new client architecture

| Dimension           | Assessment           |
| ------------------- | -------------------- |
| Complexity          | Very high            |
| Demo reliability    | Low during migration |
| Safety risk         | High regression risk |
| Judge comprehension | Medium               |
| Time to evidence    | Very poor            |

**Pros:** Could support future organizational scale.  
**Cons:** Solves no current user problem, duplicates stable infrastructure, and consumes the competition window.

## Trade-off analysis

Option B wins because the product already contains differentiated capabilities but lacks the release polish and evidence needed for a credible live demonstration. A safe health-support product is more impressive when its boundaries, offline behavior, consent model and recovery are visible than when it contains many provider stubs.

## Consequences

- Existing domain and persistence contracts remain stable.
- UI and operational quality receive priority over new commercial features.
- Demo mode, if added, must be an explicit environment with synthetic data and no external effects.
- Bangla localization is limited to interface copy until qualified review supports medical terminology.
- OCR and AI remain unverified draft generators with mandatory human confirmation.
- Production claims remain gated by benchmark, privacy, legal, provider and pilot evidence.
- A future service split remains possible behind the existing module/provider interfaces.

## Action items

1. Complete the competition roadmap and design audit.
2. Consolidate mobile design tokens and accessibility behavior.
3. Build the bilingual, elderly-friendly, judge-ready critical path.
4. Add privacy-safe diagnostics and provider readiness controls.
5. Add CI, reproducible demo/reset tooling, release evidence and physical-device rehearsal.
