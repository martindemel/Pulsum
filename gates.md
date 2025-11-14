Got it — I read **every line** of your `bugs.md` (43 bugs) and the companion `architecture.md` spec and used them as the source of truth for the plan below. Nothing in this plan is guessed; where the documents themselves raise unknowns (e.g., the iOS Settings deep link for Apple Intelligence), I call that out so we can decide before coding.  

---

## Gate Progress Tracker

| Gate | Focus | Status | Notes |
| --- | --- | --- | --- |
| 0 | Security & build blockers | ✅ Complete (2025‑11‑09) | LLM key rotation, privacy manifests, speech auth, AFM stub hardening shipped with Gate-0 tests. |
| 1 | Deterministic test harness & seams | ✅ Complete (2025‑11‑09) | Shared scheme + UITest seams + Gate0_/Gate1_ package suites enabled locally & in CI. |
| 2 | Voice journal E2E | ✅ Complete (2025‑11‑11) | Closed BUG‑0005/0007/0009/0015/0016/0032/0034 with mic preflight hardening, session guardrails, waveform perf, and wellbeing refresh. |
| 3 | HealthKit ingestion & UI freshness | ⏳ Not started | Blocks: BUG‑0024/0037/0040/0043. |
| 4 | RAG/LLM wiring & consent UX | ⏳ Not started | Blocks: BUG‑0004/0010/0011/0023/0041. |
| 5 | Vector index & data I/O integrity | ⏳ Not started | Blocks: BUG‑0012/0013/0017/0022/0036. |
| 6 | ML correctness & personalization | ⏳ Not started | Blocks: BUG‑0020/0021/0027/0028/0038/0039. |
| 7 | UI polish & spec gaps | ⏳ Not started | Blocks: BUG‑0009/0010/0011/0030/0031/0042. |
| 8 | Release compliance & final audit | ⏳ Not started | Re-run `scripts/ci/integrity.sh`, privacy report, and release smoke once Gates 0‑7 are green. |

### Recently Completed Gates
- **Gate 0 (Security & Build Blockers)** — Closed BUG‑0001/0002/0003/0006/0018/0019/0026/0033/0035 with hardened secret handling, privacy manifests, speech auth, backup exclusion, and typed AFM stubs. Verified via `scripts/ci/scan-secrets.sh`, `scripts/ci/check-privacy-manifests.sh`, Gate0_* package tests.
- **Gate 1 (Deterministic Test Harness & Seams)** — Closed BUG‑0014/0025 by wiring package tests into the shared scheme, adding UITest seams/env vars, and enforcing Gate0_|Gate1_ filters in CI (see `.github/workflows/test-harness.yml` and `Gate1_SpeechFakeBackendTests.swift`).

---

## Executive approach (why this order)

We’ll fix in **risk‑ordered “gates”** so the app is always shippable after each gate:

1. **Security & build blockers** → credential leak, PHI risks, crashy stubs, compile errors
2. **Test harness on** → make package tests run and add missing UI tests so each subsequent fix can be verified automatically
3. **Voice journal E2E** → permissions, lifecycle, transcript UI, performance
4. **HealthKit ingestion & UI freshness** → auth checks, restart on re‑grant, auto refresh surfaces
5. **RAG/LLM wiring & consent UX** → retrieval context, ping tests, key entry, settings deep link
6. **Vector index safety & data I/O** → thread safety, file handles, importer blocking
7. **ML correctness & personalization** → weight signs, persistence, sentiment signal, ranker learning, embeddings
8. **UI polish & spec gaps** → Spline hero, Dynamic Type, localization
9. **Release compliance** → Privacy manifests, backup exclusion verification, final audit

This mirrors the constraints and UX promises in your architecture (privacy first, AFM/GPT‑5 routing with Two‑Wall guardrails, Liquid Glass UI, real‑time feedback) and the “Critical Blockers” list in `bugs.md`.  

---

## Gate 0 — **Emergency security + hard build blockers**  
*Status: ✅ Completed 2025‑11‑09 (see tracker above for verification details).*

**G0.1 — Rotate & unship the OpenAI key (BUG‑0001, S0)**
**Fix**: Immediately rotate the exposed key, purge it from repo history, remove Info.plist exposure, and make `LLMGateway` read only Keychain/env (fall back to in‑memory during tests). Add a runtime key input in Settings (see BUG‑0041).
**Automated**: Add a test that scans the built app bundle for `sk-` pattern to fail CI if a key ever ships again; add LLMGateway precedence tests.
**Manual**: After building a Release IPA, `strings` the app and confirm no credential appears; verify GPT calls succeed only after entering a key in Settings.  

**G0.2 — PHI never leaks to iCloud & logs (BUG‑0018 S0, BUG‑0033 S1)**
**Fix**: Replace `try? setResourceValues` with `do/catch` + os_log error and **fail fast** on first‑run if backup exclusion can’t be set. Wrap all transcript logging in `#if DEBUG` (or remove).
**Automated**: Unit test DataStack to assert `NSURLIsExcludedFromBackupKey == true`. Unit test Release logging with a preprocessor flag so transcript text never appears.
**Manual**: On device with iCloud backup on, record a journal, then inspect xattrs for `com.apple.metadata:com_apple_backup_excludeItem`. Verify no transcripts in Console logs. 

**G0.3 — Foundation Models stub crash (BUG‑0019, S0)**
**Fix**: Make the AFM stub **generic and typed** (`respond<T: Decodable>(…, generating: T.Type) async throws -> T`) and always throw a typed `.unavailable`, ensuring real providers catch and fall back cleanly.
**Automated**: Simulate AFM unavailable on iOS 26 and assert providers fall back without crash for Sentiment/Safety. 

**G0.4 — Compile error in PulseView (BUG‑0035, S1)**
**Fix**: `#if canImport(UIKit) import UIKit #endif` and guard haptics behind availability.
**Automated**: Build both device and simulator variants in CI to catch missing imports. 

**G0.5 — Speech entitlement & permissions (BUG‑0003 S1, BUG‑0026 S1)**
**Fix**: Add `com.apple.developer.speech` entitlement; preflight with `AVAudioSession.requestRecordPermission` **before** starting audio engine.
**Automated**: Mock `AVAudioSession` & `SFSpeechRecognizer` authorizations; assert first‑run prompts occur.
**Manual**: Clean install → attempt first journal → see both permission prompts and successful capture.
**Signing note (2025‑11‑12)**: Apple’s Developer portal still lacks a Speech toggle for `ai.pulsum.Pulsum`, so the entitlement is temporarily removed from `Pulsum.entitlements` while keeping SFSpeechRecognizer + mic preflight logic intact. Re‑enable the entitlement once the capability becomes available. 

**G0.6 — Privacy manifests required (BUG‑0002, S1)**
**Fix**: Create `PrivacyInfo.xcprivacy` for app **and each package** with the Required‑Reason API codes listed in the spec (C617.1, E174.1, CA92.1).
**Automated**: Xcode Privacy Report check in CI; script verifies presence of five manifests.  

---

## Gate 1 — **Test harness ON**  
*Status: ✅ Completed 2025‑11‑09; remaining items listed below stayed for regression awareness.*

**G1.1 — Add package test bundles to scheme (BUG‑0014, S1)**
**Fix**: Update `Pulsum.xcscheme` Testables to include `PulsumAgentsTests`, `PulsumServicesTests`, `PulsumDataTests`, `PulsumMLTests`.
**Automated**: CI runs `xcodebuild test` and `swift test` and compares counts to catch accidental exclusions. 

**G1.2 — Replace empty app/UI tests with real flows (BUG‑0025, S1)**
**Fix**: Add UITests for: first‑run permissions; journal begin/stream/finish; consent toggle; coach chat send; Settings key entry & ping.
**Automated**: Snapshot at different content sizes (see BUG‑0030 later) and a smoke “journal → recommendations refreshed” flow. 

---

## Gate 2 — **Voice journaling, end‑to‑end**

**Status (2025‑11‑11):** ✅ Mic preflight now chains speech + microphone requests, voice journaling rejects duplicates and always finalizes SafetyAgent, transcripts/toasts persist until cleared, wellbeing recomputes via `DataAgent.reprocessDay`, and the waveform renderer uses the new `LiveWaveformLevels` ring buffer. Shared types/notifications now live in `PulsumTypes`, so Services/Agents/UI all link the same `SpeechSegment` + `.pulsum*` notifications and Gate harness runs clean across packages + UI. Coverage: `Gate0_SpeechServiceAuthorizationTests`, `Gate2_ModernSpeechBackendTests`, `Gate2_JournalSessionTests`, `Gate2_OrchestratorLLMKeyAPITests`, `LiveWaveformBufferTests`, `Gate2_TypesWiringTests`, and the updated `JournalFlowUITests`.

**G2.1 — Mic permission preflight (BUG‑0006, S1)**
**Fix**: In `SpeechService.requestAuthorization()`, chain `SFSpeechRecognizer.requestAuthorization` + `AVAudioSession.requestRecordPermission`.
**Tests**: Unit test permission denial → surface a clear user message and no engine start. 

**G2.2 — Reprocess wellbeing after journal (BUG‑0005, S1)**
**Fix**: After `finishVoiceJournalRecording`, call `DataAgent.reprocessDay(date:)` and notify UI (see Gate 4 freshness bus).
**Tests**: Assert `ScoreBreakdown` changes when sentiment differs; CoachView picks new cards. 

**G2.3 — Prevent duplicate sessions (BUG‑0016, S1) & always tear down (BUG‑0034, S1)**
**Fix**: Guard `beginVoiceJournal` when `activeSession != nil` (either return early or stop prior). Wrap stream consumption in `do/catch` with `defer { stopAndCleanup() }` that **always** runs SafetyAgent on the final text.
**Tests**: Spawn concurrent begins → only one active; inject a streaming error → mic indicator turns off; result still persisted; safety ran. 

**G2.4 — Transcript visibility (BUG‑0009, S2)**
**Fix**: Show transcript if non‑empty **even after** analysis; add “Saved to Journal” toast; hide only on explicit Clear.
**Tests**: UI snapshot before/after analysis; transcript persists. 

**G2.5 — Waveform performance (BUG‑0032, S2)**
**Fix**: Replace per‑frame buffer copies with a fixed‑size ring buffer and draw by index range; move heavy math off main thread.
**Tests**: Performance test ensures allocations & dropped frames below thresholds during a 30s session. 

**G2.6 — Modern speech backend (BUG‑0007, S2)**
**Fix (interim)**: Keep legacy fallback but expose an internal feature flag & availability hook so we can drop in the iOS 26 APIs when public.
**Tests**: Verify selection path; latency benchmark stored for later comparison. *(Open question in bugs.md remains: confirm API availability.)* 

---

## Gate 3 — **HealthKit ingestion & UI freshness**

**G3.1 — Auth checks before queries (BUG‑0024, S1)**
**Fix**: Check `authorizationStatus(for:)` for each required type before creating queries; if denied, post a structured reason to UI.
**Tests**: Revoke one type (e.g., sleep) → observers don’t execute and UI shows which type is missing. 

**G3.2 — Restart ingestion after re‑grant (BUG‑0040, S1)**
**Fix**: After a Settings/Onboarding “Request Health Access”, call back into `AgentOrchestrator` to re‑`start()` the `DataAgent` (idempotent).
**Tests**: Deny at first run → grant via app → new samples arrive without relaunch. 

**G3.3 — Auto‑refresh wellbeing & coach (BUG‑0037, S1; also BUG‑0015, S1)**
**Fix**: Expose `AsyncStream<FeatureVectorSnapshot>` or Notification from `DataAgent` and have `CoachViewModel`/main card subscribe and refresh on new snapshots and after slider submit.
**Tests**: Programmatically emit a snapshot → UI updates on main tab; sliders submit triggers refresh immediately. 

**G3.4 — HealthKit status accuracy (BUG‑0043, S2)**
**Fix**: Report status across **all** required types (HRV, HR, RHR, sleep, RR, steps); show partial states.
**Tests**: Deny one → UI shows “5/6 granted” with specific missing types. 

---

## Gate 4 — **RAG/LLM wiring & consent UX**

**G4.1 — Retrieval context in GPT requests (BUG‑0004, S1)**
**Fix**: Add `candidateMoments[]` (id, title, short/detail, evidenceBadge) to the Responses API payload per your `CoachPhrasingSchema`; keep PHI out as required by the spec.
**Automated**: Extend `LLMGatewaySchemaTests` to assert the outgoing JSON contains the selected candidates; measure improved grounding coverage in acceptance tests.  

**G4.2 — PING mismatch (BUG‑0023, S2)**
**Fix**: Make both sides lower‑case `"ping"`.
**Tests**: “Test API Key” in Settings goes green with a valid key. 

**G4.3 — Allow runtime key entry (BUG‑0041, S1) & remove Info.plist path**
**Fix**: Add `SecureField("OpenAI API Key", text: $gptAPIKeyDraft)` + **Save & Test** button that writes to Keychain and triggers `checkGPTAPIKey()`.
**Tests**: Round‑trip save; key used on next boot; no Info.plist access path remains. 

**G4.4 — Apple Intelligence deep link (BUG‑0010, S2)**
**Fix**: Replace macOS‑only `x-apple.systempreferences:` with `UIApplication.openSettingsURLString` + clear copy telling users where to enable Apple Intelligence; keep the “status” display.
**Tests**: Button opens app settings on iOS; copy updated. *(Open question from bugs.md acknowledged: no documented iOS 26 URI in the repo.)* 

---

## Gate 5 — **Vector index & data I/O integrity**

**G5.1 — Thread‑safe shard cache (BUG‑0012, S0)**
**Fix**: Make **all** access to `shards` go through a barrier queue (or wrap the whole `VectorIndex` in an `actor`). Remove the double‑checked read outside the lock.
**Automated**: TSan stress tests that concurrently call search/upsert without data races or crashes. 

**G5.2 — FileHandle close safety (BUG‑0017, S1)**
**Fix**: Replace `try? handle.close()` with `do/catch` and bubble errors; ensure `defer` closes even on throws.
**Automated**: Inject close failures; assert proper error propagation and no fd leaks. 

**G5.3 — LibraryImporter blocking I/O (BUG‑0022, S2)**
**Fix**: Read JSON **outside** `context.perform`, then pass decoded structs into the perform block.
**Automated**: Time budget test shows import no longer blocks Core Data queue. 

**G5.4 — Dataset duplication (BUG‑0013, S2) & stray pbxproj backup (BUG‑0036, S3)**
**Fix**: Keep a single canonical JSON file; remove duplicates and the checked‑in project backup; add a pre‑commit lint to block future `.backup` files.
**Automated**: Repo hygiene test scans for duplicate hashes and backup project files. 

---

## Gate 6 — **ML correctness & personalization**

**G6.1 — Fix inverted weights & label math (BUG‑0028, S1)**
**Fix**: Align coefficient signs and target computation so **higher HRV/steps lift** the score and **higher sleep debt lowers** it. Update docs so code & spec agree (architecture currently lists seed weights that conflict with intended semantics).
**Automated**: Unit tests asserting contribution signs; synthetic feature vectors demonstrate expected directionality.  

**G6.2 — Persist StateEstimator across launches (BUG‑0038, S1)**
**Fix**: Add `EstimatorState` persistence (Core Data entity or small JSON under `Application Support/` with file protection). Load on startup; periodically checkpoint after updates.
**Automated**: Restart simulation shows weights survive and influence next session. 

**G6.3 — Include sentiment in the target & weights (BUG‑0039, S1)**
**Fix**: Add the sentiment feature to `computeTarget` and seed a modest positive/negative weight; update `ScoreBreakdown` mapping.
**Automated**: Journals with opposite sentiment shift the contribution band accordingly. 

**G6.4 — RecRanker learns from feedback (BUG‑0027, S1)**
**Fix**: On recommendation complete/skip, call `ranker.update(...)` with bounded LR; persist ranker state if needed.
**Automated**: Simulated accept/reject series changes pairwise weights; top‑3 ordering adapts. 

**G6.5 — Embeddings: re‑enable contextual AFM & forbid zero vectors (BUG‑0020, S1; BUG‑0021, S1)**
**Fix**: Re‑enable `NLContextualEmbedding` per the design (or keep Core ML fallback if APIs remain unsafe), and **never** return a zero vector—throw and degrade to keyword retrieval if both providers fail.
**Automated**: Dimension invariants (384d) and failure‑path tests; topic gate/safety accuracy regression tests. *(Open question in bugs.md: reason contextual path was disabled—confirm before flipping.)*  

---

## Gate 7 — **UI polish & spec gaps**

**G7.1 — Spline hero on Main (BUG‑0011, S2)**
**Fix**: Add `SplineRuntime` view to Main per spec (cloud URL + local fallback), styled as Liquid Glass, and keep the segmented control/AI button behavior.
**Manual**: Verify online and airplane‑mode fallbacks.  

**G7.2 — Dynamic Type (BUG‑0030, S1)**
**Fix**: Replace fixed sizes in `PulsumDesignSystem` with semantic text styles (`.title`, `.headline`, etc.) or `.scaledFont`.
**Automated**: Snapshot tests across content sizes ensure no clipping. 

**G7.3 — Localization (BUG‑0031, S1)**
**Fix**: Extract user strings to `Localizable.strings` and use `String(localized:)`.
**Manual**: Run app in Spanish and verify major surfaces. 

**G7.4 — Keyboard dismissal on tab change (BUG‑0042, S2)**
**Fix**: Clear `@FocusState` on `onDisappear` and on tab selection change.
**Automated**: UITest switches tabs while typing; keyboard disappears. 

---

## Gate 8 — **Release compliance**

**G8.1 — Privacy manifests (re‑verify), consent banner, cloud routing**
**Fix**: Ensure manifests in app + all packages; confirm consent copy and minimized GPT‑5 context per spec; verify **no PHI** enters cloud requests.
**Automated**: Schema tests assert cloud payload contains only `{userToneHints, topSignal, topMomentId?, z‑score summary}`. 

---

## Cross‑gate traceability (bug → gate)

* **S0**: 0001 (G0), 0012 (G5), 0018 (G0), 0019 (G0)
* **S1** (high): 0002(G0), 0003(G0), 0004(G4), 0005(G2), 0006(G2), 0008(G4/G3—routing uses snapshot keys), 0014(G1), 0015(G3), 0016(G2), 0017(G5), 0024(G3), 0025(G1), 0026(G0), 0027(G6), 0028(G6), 0029(G5 or G0.5, choose with start refactor), 0030(G7), 0031(G7), 0033(G0), 0034(G2), 0037(G3), 0038(G6), 0039(G6), 0040(G3), 0041(G4)
* **S2/S3**: Remaining per gates above (0007, 0009, 0010, 0011, 0013, 0022, 0023, 0032, 0036, 0042, 0043). 

---

## Per‑bug mini playbook (fix + tests)

Below are concise instructions you can apply **one bug at a time**. Where two bugs are tightly coupled, I grouped them:

* **0001 – OpenAI key leaked (S0)**: Rotate key, remove Info.plist usage; Settings key entry (0041); Keychain only.
  *Unit*: LLMGateway resolves key precedence; *Static*: grep built app for `sk-`; *Manual*: ping OK only after entering key. 

* **0002 – Privacy manifests missing (S1)**: Add `PrivacyInfo.xcprivacy` to app & all packages with required reason codes in spec; validate with Xcode Privacy Report. 

* **0003/0026 – Speech entitlement & mic prompt (S1)**: Add entitlement, preflight mic permission; denial yields actionable UI.
  *UI test*: first‑run shows two prompts; second run starts instantly. 

* **0004 – Retrieval context dropped (S1)**: Include `candidateMoments` in Responses payload (id, title, short/detail, evidenceBadge); update `LLMGatewaySchemaTests`.
  *Manual*: Inspect JSON via stub; GPT replies mention specific source titles. 

* **0005 – Reprocess after journal (S1)**: Invoke `DataAgent.reprocessDay`; post update event.
  *Unit*: Score changes after journal with different sentiment; *UI*: Main card refreshes without navigation. 

* **0006 – Mic permission first (S1)**: See 0003/0026. 

* **0007 – Modern speech stub (S2)**: Keep legacy path; add feature flag and TODO; document.
  *Perf*: record baseline latency for later. 

* **0008 – Fallback routing bad keys (S1)**: Change router to use existing `z_*`/`subj_*` keys; add assertion if key missing.
  *Unit*: With a synthetic snapshot, fallback picks the correct top signal. 

* **0009 – Transcript hides (S2)**: Render transcript if non‑empty after analysis; add “Saved” toast.
  *UI snapshot*: still visible 3s post analysis. 

* **0010 – Apple Intelligence link (S2)**: Use `UIApplication.openSettingsURLString` + copy; remove macOS URI.
  *UI test*: tapping opens Settings on iOS. 

* **0011 – Spline hero missing (S2)**: Add Spline view per spec snippet; verify cloud URL + local fallback asset.
  *Manual*: online/offline behavior. 

* **0012 – Shard cache DCL (S0)**: Guard all shard reads/writes under barrier or convert to `actor`; remove outer read.
  *TSan*: 1k concurrent searches produce no races. 

* **0013 – Dataset duplicates (S2)**: Keep single canonical JSON; remove others and stop bundling extra.
  *Static*: check there’s exactly one file with that hash. 

* **0014 – Package tests not in scheme (S1)**: Add them; CI must run both SPM and Xcode.
  *Meta*: test list count compared to `swift test`. 

* **0015/0037 – No refresh after check‑in/HK sync (S1)**: Publish snapshot events; `CoachViewModel` subscribes; `PulseViewModel` triggers refresh on submit.
  *UI test*: check‑in immediately updates cards; background HK sync updates main card. 

* **0016/0034 – Journal session lifecycle (S1)**: No duplicates and always stop/safety on errors; see G2.3.
  *Unit*: For error injection path, mic indicator off and safety invoked. 

* **0017 – FileHandle close (S1)**: Don’t swallow close errors; surface/log; ensure handles closed in `defer`.
  *FD test*: open fd count stable after repeated upserts/removes. 

* **0018 – Backup exclusion (S0)**: Don’t ignore failures; block with error banner if we cannot exclude PHI.
  *Manual*: Verify xattrs on all storage dirs. 

* **0019 – AFM stub type (S0)**: Typed generic stub + guaranteed fallback; see G0.3. 

* **0020 – Contextual embeddings disabled (S1)**: Re‑enable NL contextual embeddings if safe; otherwise keep Core ML fallback and track as tech debt with explicit flag.
  *Unit*: dimension = 384; similarity sanity checks. *(Open question in bugs.md: why it was disabled)*. 

* **0021 – Zero‑vector fallback (S1)**: Throw error instead; callers must handle “no embedding available” by keyword fallback.
  *Unit*: Failure path covered; vector index never stores `[0,…,0]`. 

* **0022 – Blocking file I/O (S2)**: Move `Data(contentsOf:)` out of `context.perform`; decode then persist.
  *Perf test*: Core Data queue isn’t blocked during import. 

* **0023 – PING case mismatch (S2)**: “ping” everywhere; green check in Settings. 

* **0024 – HK auth checks (S1)**: Verify status before execute; report denied types.
  *Manual*: Revoke one permission → user‑facing reminder. 

* **0025 – Empty app/UI tests (S1)**: Replace with real acceptance tests (see G1.2). 

* **0027 – RecRanker not learning (S1)**: Call `update` on accept/skip completion; cap LR; optional persistence.
  *Unit*: A/B ordering changes with feedback history. 

* **0028 – Weight signs (S1)**: Fix coefficients & target signs; update doc comments.
  *Unit*: Contribution signs correct. 

* **0029 – Orphan startup Tasks (S1)**: Make `start()` idempotent by storing a single `startupTask` and awaiting/cancelling as needed; set state based on actual outcome.
  *Unit*: Rapid retries don’t double‑start orchestrator; startup state transitions correct. 

* **0030 – Dynamic Type (S1)**: Use semantic styles/scaled fonts; fix any clipped layouts.
  *Snapshot*: XL → no truncation. 

* **0031 – Localization (S1)**: Extract to `Localizable.strings`; adopt `String(localized:)`.
  *Manual*: Switch device language to ES; key surfaces translated. 

* **0032 – Waveform perf**: handled in G2.5. 

* **0033 – Transcript logs (S1)**: handled in G0.2. 

* **0034 – Legacy teardown**: handled in G2.3. 

* **0035 – UIKit import**: handled in G0.4. 

* **0036 – pbxproj backup**: handled in G5.4. 

* **0037 – Main card freshness**: handled in G3.3. 

* **0038 – Estimator persistence**: handled in G6.2. 

* **0039 – Sentiment feature**: handled in G6.3. 

* **0040 – HK restart**: handled in G3.2. 

* **0041 – GPT‑5 key UI**: handled in G4.3. 

* **0042 – Keyboard focus**: handled in G7.4. 

* **0043 – HK status UI**: handled in G3.4. 

---

## Verification scaffolding we’ll put in place once (then reuse for each bug)

* **CI gates**: (a) bundle scan for leaked keys; (b) Xcode Privacy Report must pass; (c) run package tests from scheme. 
* **Observability**: replace `print` with `Logger` and DEBUG‑only logs; add os_signposts around journal start/finish and HealthKit ingest to make UI refresh lags measurable. 
* **Freshness bus**: a single `AsyncStream`/Notification from `AgentOrchestrator` for “snapshot updated” so **journal**, **sliders**, and **HealthKit** all refresh the UI without bespoke glue, per your spec’s “real‑time feedback” promise. 

---

## Known unknowns (from your docs) we’ll resolve as we go

* **Apple Intelligence Settings deep link** on iOS 26: not documented in the repo; we’ll use the app’s Settings URL and copy guidance unless you have an official URI. 
* **Modern Speech APIs** availability: `SpeechAnalyzer/SpeechTranscriber` are treated as pending; keep legacy path flagged until confirmed. 
* **Contextual embeddings disabled**: re‑enable only after we understand the “unsafe runtime code” note; otherwise stick with Core ML fallback and explicit degraded mode. 

---

## Alignment with architecture

This plan enforces your **non‑negotiables** (PHI on‑device, consent‑gated GPT‑5 phrasing, AFM/ML fallbacks), implements the **Liquid Glass + Spline** main visual, and restores **Two‑Wall guardrails** with grounded retrieval payloads — all explicitly specified in `architecture.md`. It also implements the privacy manifest requirements and App Store compliance you flagged as mandatory. 

---

### If anything above seems off

I didn’t skip any lines in `bugs.md` or `architecture.md`. Where those documents themselves were ambiguous (notably BUG‑0010, BUG‑0007, BUG‑0020), I marked them as open questions and proposed conservative, compliant defaults instead of guessing. If you want me to assume a specific iOS deep link or to hard‑enable a speech/embedding API, tell me and I’ll incorporate it — otherwise I’ll proceed with the safer options outlined here.  

---

**Next step** (suggested): start Gate 0 with a short PR stack — (1) rotate key & remove Info.plist path, (2) fix transcript logging & backup exclusion, (3) AFM stub typing, (4) PulseView UIKit import, (5) speech entitlement + mic preflight — and land a **green CI** with the bundle scan and Privacy Report checks enabled. Then we’ll march gate‑by‑gate with the tests listed above so each fix is verified in isolation.  
