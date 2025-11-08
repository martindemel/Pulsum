# Pulsum Bug Remediation Plan

## Guiding Principles
- Tackle production blockers and compliance exposure first, then restore the end-to-end wellbeing loop, and finally address UX polish and resiliency gaps.
- When a bug represents a broken contract or security/privacy exposure, fix it in the earliest feasible phase and add automated tests or monitors to prevent regression.
- After each phase, run the full SwiftPM test suite plus targeted manual checks (voice journal, HealthKit ingestion, GPT consent) before moving forward.

## Phase 0 — Containment & Build Readiness (Day 0–1)
1. **Secrets & Compliance:** Rotate the leaked OpenAI key and remove it from source control; add PrivacyInfo manifests for every target and ensure backup exclusion errors surface instead of being ignored (BUG-20251026-0001, BUG-20251026-0002, BUG-20251026-0018, BUG-20251026-0033).【F:bugs.md†L7-L25】【F:bugs.md†L73-L160】
2. **Platform Entitlements & Permissions:** Add the missing speech entitlement, wire microphone permission prompts, and verify Info.plist usage strings are honored (BUG-20251026-0003, BUG-20251026-0026).【F:bugs.md†L9-L34】【F:bugs.md†L105-L155】
3. **Build & Runtime Stability:** Restore compilation by importing UIKit for haptics, resolve the Foundation Models stub crash, and guard the vector index double-checked locking (BUG-20251026-0012, BUG-20251026-0019, BUG-20251026-0035).【F:bugs.md†L19-L43】【F:bugs.md†L403-L418】【F:bugs.md†L620-L652】
4. **Release Hygiene:** Delete the stale project.pbxproj backup, consolidate duplicated podcast datasets, and ensure backup exclusion/test artifacts are removed from builds (BUG-20251026-0013, BUG-20251026-0036).【F:bugs.md†L20-L43】【F:bugs.md†L420-L434】

## Phase 1 — Restore Core Capture & Data Flow (Day 1–3)
1. **Voice Journaling Loop:** Rewire begin/finish flows to prevent duplicate sessions, request microphone access before recording, ensure cleanup on errors, and trigger wellbeing recompute plus transcript persistence (BUG-20251026-0005, BUG-20251026-0006, BUG-20251026-0015, BUG-20251026-0016, BUG-20251026-0034).【F:bugs.md†L12-L43】【F:bugs.md†L200-L360】
2. **Speech Stack:** Replace the modern speech backend stub, stop logging PHI, and fix the GPT retrieval payload along with fallback routing so the coach is grounded (BUG-20251026-0004, BUG-20251026-0007, BUG-20251026-0008, BUG-20251026-0033).【F:bugs.md†L11-L41】【F:bugs.md†L200-L360】
3. **HealthKit Ingestion:** Add authorization checks before queries, restart DataAgent when permissions change, refresh the wellbeing card after sync, and fix the Settings status indicator to cover all required types (BUG-20251026-0024, BUG-20251026-0037, BUG-20251026-0040, BUG-20251026-0043).【F:bugs.md†L29-L50】【F:bugs.md†L438-L575】
4. **Data Integrity:** Surface FileHandle close failures, move blocking I/O off the Core Data queue, and re-enable backup exclusion validation (BUG-20251026-0017, BUG-20251026-0022).【F:bugs.md†L24-L29】【F:bugs.md†L340-L399】

## Phase 2 — Wellbeing & ML Correctness (Day 3–5)
1. **Estimator Accuracy:** Correct the wellbeing target math, persist estimator weights across launches, and incorporate journal sentiment into labels and features (BUG-20251026-0028, BUG-20251026-0038, BUG-20251026-0039).【F:bugs.md†L35-L46】【F:bugs.md†L680-L756】
2. **Personalization Feedback:** Wire RecRanker updates, ensure embeddings never silently return zero vectors, and re-enable AFM contextual embeddings once the crash guard is in place (BUG-20251026-0020, BUG-20251026-0021, BUG-20251026-0027).【F:bugs.md†L27-L35】【F:bugs.md†L600-L704】
3. **LLM Reliability:** Fix the ping validation case mismatch, propagate retrieval context into GPT payloads, and expose runtime GPT key entry/testing in the UI (BUG-20251026-0004, BUG-20251026-0023, BUG-20251026-0041).【F:bugs.md†L11-L49】【F:bugs.md†L600-L704】

## Phase 3 — Experience & Accessibility (Day 5–7)
1. **UI Responsiveness:** Keep transcripts visible post-analysis, dismiss the chat keyboard on tab switches, and address waveform buffer churn (BUG-20251026-0009, BUG-20251026-0042, BUG-20251026-0032).【F:bugs.md†L16-L49】【F:bugs.md†L438-L704】
2. **Design System Compliance:** Update design tokens for Dynamic Type, add localization resources, and restore the Spline hero experience (BUG-20251026-0010, BUG-20251026-0011, BUG-20251026-0030, BUG-20251026-0031).【F:bugs.md†L17-L38】【F:bugs.md†L438-L652】
3. **Settings & Consent UX:** Provide a functioning Apple Intelligence deep link, surface accurate HealthKit status, and ensure consent banners reflect new GPT key wiring (BUG-20251026-0010, BUG-20251026-0041, BUG-20251026-0043).【F:bugs.md†L17-L50】【F:bugs.md†L438-L575】

## Phase 4 — Testing, Tooling & Regression Safety (Day 7+)
1. **Test Harness:** Add SwiftPM packages to the shared Xcode scheme and flesh out the empty test scaffolds with critical path coverage (BUG-20251026-0014, BUG-20251026-0025).【F:bugs.md†L21-L33】【F:bugs.md†L580-L640】
2. **Bootstrap Reliability:** Replace orphaned startup tasks with structured concurrency and add integration tests covering retries and HealthKit re-authorization flows (BUG-20251026-0029, BUG-20251026-0040).【F:bugs.md†L36-L47】【F:bugs.md†L520-L575】
3. **Release Checklist:** Document verification steps (secrets rotation, privacy manifests, HealthKit + GPT regression suites) and integrate them into CI to prevent recurrence of the highest-severity issues (addresses Phase 0–3 fixes collectively).

## Cross-Cutting Verification
- After each phase, run `swift test`, targeted UI smoke tests (voice journaling, HealthKit sync, chat, Settings), and lint/formatters. Capture logs to confirm no PHI output and that wellbeing recomputation occurs after subjective inputs.
- Prior to release, perform a full dry run: fresh install, deny/allow HealthKit mid-session, rotate GPT key via new UI, record a journal, and verify wellbeing score reacts appropriately.
