**Title & Metadata**
- Pulsum — App Status & Stage
- Date: 2025-11-02
- Repo root: /Users/martin.demel/Desktop/PULSUM/Pulsum

**Executive Summary**
- Pulsum frames an AI-guided wellness coach for iOS 26+ — "Pulsum is an iOS 26+ wellbeing coach that boots an `AgentOrchestrator`" — architecture.md
- Mandate is full production readiness without placeholders — "Build a production, App‑Store‑ready version of Pulsum—no placeholders, no mock UIs, no fake backends." — instructions.md
- Privacy commitment keeps PHI local only — "PHI stays on‑device (NSFileProtectionComplete) + Keychain for secrets." — instructions.md
- Agent guardrails ensure safe cloud escalation — "The orchestrator enforces a three-wall guardrail—safety classification, on-topic gating, and retrieval coverage" — architecture.md
- DataAgent fuses health streams with journaling — "Health metrics and journals flow through a `DataAgent` actor that merges HealthKit streams" — architecture.md
- Voice journaling stores only transcripts for analysis — "Audio is never stored; transcripts stored locally only." — instructions.md
- Critical security blockers remain unresolved — "BUG-20251026-0001 — Live OpenAI key embedded in repo." — bugs.md
- Compliance milestone still outstanding — "Milestone 5 - Safety, Consent, Privacy Compliance (Planned)" — todolist.md

**Current Stage & Why**
Stage: Alpha — feature set is substantial, but severe blockers suggest internal hardening.
- "BUG-20251026-0001 — Live OpenAI key embedded in repo." — bugs.md
- "BUG-20251026-0002 — Privacy manifests missing for all targets." — bugs.md
- "Milestone 5 - Safety, Consent, Privacy Compliance (Planned)" — todolist.md

**App Overview (from docs)**
- **Intent & Scope:** Wellness coaching orchestrated through agents and rich surfaces — "Pulsum is an iOS 26+ wellbeing coach that boots an `AgentOrchestrator`" — architecture.md; "Create SwiftUI feature surfaces: MainView (SplineRuntime scene + segmented control + header)" — todolist.md; "CoachView (cards + chat)" — todolist.md; "PulseView (slide-to-record + sliders + countdown)" — todolist.md
- **Success Criteria / Metrics:** Unknown — not documented in architecture.md or instructions.md.

**Architecture (documented)**
- Package stack separates UI, agents, services, data, and ML — "Domain orchestrators, data ingestion, coaching logic, safety, and sentiment agents." — architecture.md; "Platform services: HealthKit wrapper, LLM gateway, speech capture, keychain, and diagnostics notifications." — architecture.md; "Core Data stack, vector index implementation, and library importer" — architecture.md; "On-device ML utilities for embeddings, sentiment, topic gating, safety heuristics, and state estimation." — architecture.md
- Single manager pattern fronts the agent system — "AgentOrchestrator (manager pattern; single user‑facing agent, other agents as tools)" — instructions.md
- DataAgent handles biometric aggregation — "DataAgent (HealthKit ingest, stats, features)" — instructions.md
- Sentiment pipeline enforces on-device privacy controls — "SentimentAgent (STT→transcript; AFM sentiment + on‑device embedding; PII redaction)" — instructions.md
- Coaching logic combines retrieval, ranking, and guardrails — "CoachAgent (RAG/CAG over library; pairwise ranker; on‑topic chat)" — instructions.md

**Current State (from `todolist.md` & `bugs.md`)**
- **Done:** Foundations and UI milestones landed — "All test suites pass with zero Swift 6 concurrency warnings" — todolist.md; "Ensure graceful fallbacks when Foundation Models unavailable on older devices or when Apple Intelligence disabled" — todolist.md; "Create SwiftUI feature surfaces: MainView (SplineRuntime scene + segmented control + header)" — todolist.md
- **In-Progress:** Unknown — no active workstream documented in todolist.md.
- **Planned:** Compliance and release prep queued — "Implement consent UX/state persistence (`UserPrefs`, `ConsentState`)" — todolist.md; "Produce Privacy Manifest + Info.plist declarations" — todolist.md; "Expand automated tests: unit coverage for agents/services/ML math, UI snapshot tests" — todolist.md
- **Major bugs/themes:** Security exposure — "BUG-20251026-0001 — Live OpenAI key embedded in repo." — bugs.md; Compliance blocker — "BUG-20251026-0002 — Privacy manifests missing for all targets." — bugs.md; Voice journaling permissions gap — "BUG-20251026-0003 — Speech entitlement absent; authorization denied." — bugs.md; Data freshness regression — "BUG-20251026-0005 — Journals don't trigger wellbeing reprocessing." — bugs.md

**Risks, Assumptions, Dependencies**
- Embedded credential threatens security posture — "BUG-20251026-0001 — Live OpenAI key embedded in repo." — bugs.md
- Backup exclusions failing risk PHI exposure — "BUG-20251026-0018 — Backup exclusion failures ignored." — bugs.md
- Concurrency race in vector index could corrupt retrieval — "BUG-20251026-0012 — Vector index shard cache races initialization." — bugs.md
- Cloud asset dependency for hero visual — "Load a Spline scene from the cloud; local fallback allowed." — instructions.md
- GPT-5 consent gating essential for phrasing — "Primary phrasing model = GPT‑5 (cloud) only with explicit in‑app consent" — instructions.md

**Open Questions / Unknowns**
1. Primary user personas beyond "wellbeing coach" — Unknown.
2. Success metrics or KPIs for launch — Unknown.
3. agents.md reference requested externally — not found.
4. Remediation timeline for S0/S1 bugs — Unknown.

**Confidence**
Confidence: Medium — Documentation is recent but may lag live implementation — "Generated on: 2025-10-26T01:14:51Z UTC" — architecture.md

**Evidence Index**
- architecture.md — Architecture digest detailing guardrails, packages, and data flow.
- instructions.md — Product specification covering scope, privacy, and agent expectations.
- todolist.md — Milestone tracker outlining completed and planned work.
- bugs.md — Current defect log with severity and impact notes.
