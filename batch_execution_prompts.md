# Batch Execution Prompts

Open a **fresh Claude Code window** for each batch. Copy-paste the prompt below.
Each prompt is self-contained — no dependency on prior sessions. CLAUDE.md auto-loads.

After each batch completes, verify the commit landed on `main` before starting the next.

---

## Batch 1 — Quick Safety Wins

```
Read `master_fix_plan.md` section "Batch 1 — Quick Safety Wins" (section 6) and the detailed fix descriptions in sections 2 and 3.

BEFORE making any changes: create a safe-point commit of the current working state with message "Safe point: before Batch 1 — quick safety wins".

Then implement these 15 fixes IN ORDER. For each fix, read the target file first, apply the change described in the plan, then move to the next:

1. CRIT-02: FoundationModelsSafetyProvider.swift — change .guardrailViolation and .refusal from .safe to .caution
2. CRIT-03: CoachPhrasingSchema.swift + LLMGateway.swift — unify intentTopic enum values
3. CRIT-05: SafetyLocal.swift + SafetyAgent.swift — add missing crisis keywords
4. CRIT-06: RecRankerStateStore.swift, EstimatorStateStore.swift, BackfillStateStore.swift, SentimentAgent.swift, HealthKitAnchorStore.swift — change FileProtectionType.complete to .completeUnlessOpen
5. CRIT-07: CoachAgent.swift — replace preconditionFailure with thrown error
6. CRIT-09: SafetyLocal.swift — fix crisis classification to not require both embedding AND keyword
7. CRIT-10: LLMGateway.swift — remove force unwrap on URL
8. CRIT-12: glow.swift — fix timer leaks (store refs, invalidate on disappear)
9. HIGH-05: PulseViewModel.swift — fix isAnalyzing getting permanently stuck
10. HIGH-08: HealthKitService.swift — guard force unwraps on quantityType
11. HIGH-12: AgentOrchestrator.swift — replace intentTopic! with ?? "wellbeing"
12. HIGH-13: AFMTextEmbeddingProvider.swift — remove unnecessary AFM availability gate
13. HIGH-14: HealthKitAnchorStore.swift — fix read/write queue asymmetry
14. HIGH-15: AgentOrchestrator.swift — add reprocessDay after submitTranscript
15. HIGH-16: LLMGateway.swift — add NSLock for inMemoryAPIKey

After ALL fixes: run swiftformat, build for simulator, run SPM tests for all 5 packages. Fix any build errors.

Then commit with message "Batch 1: Quick safety wins — 15 CRIT/HIGH fixes" and push to main.
```

---

## Batch 2 — Core Data Fixes

```
Read `master_fix_plan.md` section "Batch 2 — Core Data Fixes" (section 6) and the detailed fix descriptions for CRIT-01, CRIT-04, HIGH-09, HIGH-11 in sections 2 and 3.

BEFORE making any changes: create a safe-point commit with message "Safe point: before Batch 2 — core data fixes".

Implement these 4 fixes. They are interrelated (all touch the data layer), so read all target files first to understand the full picture:

1. CRIT-01: VectorIndex.swift — replace String.hashValue sharding with FNV-1a deterministic hash
2. CRIT-04: DataStack.swift + PulsumManagedObjectModel.swift — replace fatalError with throwing init, define DataStackError enum. Update AppViewModel.swift to handle the error.
3. HIGH-09: VectorIndex.swift — add atomic writes (write to temp file, rename)
4. HIGH-11: VectorIndex.swift — remove NSLock and per-shard DispatchQueues (actor isolation suffices)

After ALL fixes: run swiftformat, build for simulator, run `swift test --package-path Packages/PulsumData`. Fix any build errors.

Then commit with message "Batch 2: Core data layer fixes — deterministic hashing, throwing init, atomic writes" and push to main.
```

---

## Batch 3 — ML Correctness

```
Read `master_fix_plan.md` section "Batch 3 — ML Correctness" (section 6) and the detailed fix descriptions for HIGH-01, HIGH-02, HIGH-03, MED-01 in sections 3 and 4. Also read section 7 "Calculation Corrections" for the exact math fixes.

BEFORE making any changes: create a safe-point commit with message "Safe point: before Batch 3 — ML correctness".

Implement these 4 fixes:

1. HIGH-01: RecRanker.swift — fix Bradley-Terry pairwise gradient (see section 7 for exact math)
2. HIGH-02: SentimentService.swift — add NaturalLanguageSentimentProvider as final fallback, return nil on total failure
3. HIGH-03: EmbeddingTopicGateProvider.swift — return isOnTopic: true with low confidence when embeddings unavailable
4. MED-01: RecRanker.swift + StateEstimator.swift — add proper synchronization (convert to actors or add locks)

After ALL fixes: run swiftformat, build for simulator, run `swift test --package-path Packages/PulsumML`. Fix any build errors.

Then commit with message "Batch 3: ML correctness — Bradley-Terry gradient, sentiment fallback, topic gate degradation" and push to main.
```

---

## Batch 4 — Concurrency Safety

```
Read `master_fix_plan.md` section "Batch 4 — Concurrency Safety" (section 6) and the detailed fix descriptions for HIGH-04, HIGH-10, CRIT-11, CRIT-08 in sections 2 and 3.

BEFORE making any changes: create a safe-point commit with message "Safe point: before Batch 4 — concurrency safety".

This is the largest batch. Implement these fixes:

1. HIGH-04: SpeechService.swift — fix LegacySpeechBackend data race (convert to actor or add serial DispatchQueue)
2. HIGH-10: Fix @unchecked Sendable across these files — convert each to actor or add proper synchronization:
   - EmbeddingService.swift
   - SentimentService.swift
   - LibraryImporter.swift
   - HealthKitService.swift (priority — mutable dictionaries)
   - KeychainService.swift
   - HealthKitAnchorStore.swift
   - EstimatorStateStore.swift
3. CRIT-11: SentimentAgent.swift — replace NSManagedObjectID in JournalResult with UUID or String (PersistentIdentifier for cross-actor refs per project rules)
4. CRIT-08: Add UserDefaults required reason API to ALL PrivacyInfo.xcprivacy files (app + each SPM package that has one)

After ALL fixes: run swiftformat, build for simulator, run SPM tests for all 5 packages. Fix any build errors.

Then commit with message "Batch 4: Concurrency safety — actor conversions, Sendable fixes, privacy manifest" and push to main.
```

---

## Batch 5 — UI & Accessibility

```
Read `master_fix_plan.md` section "Batch 5 — UI & Accessibility" (section 6) and the detailed fix descriptions for HIGH-06, HIGH-07, MED-24 in sections 3 and 4.

BEFORE making any changes: create a safe-point commit with message "Safe point: before Batch 5 — UI and accessibility".

Implement these 3 fixes:

1. HIGH-06: PulsumDesignSystem.swift — replace all fixed-size fonts with Dynamic Type equivalents (.largeTitle, .title, .headline, .body, .caption)
2. HIGH-07: CoachAgent.swift — replace performAndWait with async perform (non-blocking)
3. MED-24: glow.swift — replace UIScreen.main.bounds with GeometryReader

After ALL fixes: run swiftformat, build for simulator, run `swift test --package-path Packages/PulsumUI`. Fix any build errors.

Then commit with message "Batch 5: UI & accessibility — Dynamic Type fonts, async perform, responsive layout" and push to main.
```

---

## Batch 6 — App Store Compliance

```
Read `master_fix_plan.md` section "Batch 6 — App Store Compliance" (section 6) and section 8 "App Store Blockers". Also read detailed fix descriptions for HIGH-17, HIGH-18, MED-16, MED-06 in sections 3 and 4.

BEFORE making any changes: create a safe-point commit with message "Safe point: before Batch 6 — App Store compliance".

Implement these 4 fixes:

1. HIGH-17: OnboardingView.swift + SettingsView.swift — add mandatory health disclaimer ("This app does not provide medical advice. Always consult a healthcare professional."). Onboarding must require acknowledgment.
2. HIGH-18: SettingsViewModel.swift — add "Delete All My Data" that deletes Core Data entities, clears vector index directory, removes Keychain entries, clears UserDefaults, resets to onboarding.
3. MED-16: AppViewModel.swift + PulsumRootView.swift — persist onboarding completion with @AppStorage
4. MED-06: SafetyAgent.swift — make crisis message locale-aware (not just 988 US hotline)

After ALL fixes: run swiftformat, build for simulator, run SPM tests for all 5 packages. Fix any build errors.

Then commit with message "Batch 6: App Store compliance — health disclaimer, data deletion, onboarding persistence, locale-aware crisis" and push to main.
```

---

## Batch 7 — Medium Priority (remaining)

```
Read `master_fix_plan.md` section 4 "Medium Priority Fixes" for the full list. Skip any MED items already done in Batches 1-6 (MED-01, MED-06, MED-16, MED-24).

BEFORE making any changes: create a safe-point commit with message "Safe point: before Batch 7 — medium priority fixes".

Implement the remaining MED items in order: MED-02 through MED-23 (skipping already-done items). For each:
- Read the target file first
- Apply the fix described in the plan
- Build-verify periodically (every 4-5 fixes) to catch errors early

After ALL fixes: run swiftformat, build for simulator, run SPM tests for all 5 packages. Fix any build errors.

Then commit with message "Batch 7: Medium priority fixes" and push to main.
```

---

## Batch 8 — Low Priority

```
Read `master_fix_plan.md` section 5 "Low Priority Fixes" for the full list.

BEFORE making any changes: create a safe-point commit with message "Safe point: before Batch 8 — low priority fixes".

Implement all LOW items (LOW-01 through LOW-20) in order. For each:
- Read the target file first
- Apply the fix described in the plan
- Build-verify periodically (every 5-6 fixes)

After ALL fixes: run swiftformat, build for simulator, run SPM tests for all 5 packages. Fix any build errors.

Then commit with message "Batch 8: Low priority fixes — cleanup, guards, dead code removal" and push to main.
```
