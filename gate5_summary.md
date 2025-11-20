# Gate 5 — Vector Index Safety & Data I/O Integrity

## Problem (BUG‑0012 / 0017 / 0013 / 0022 / 0036)
- Vector index shards used double‑checked locking with unsynchronized dictionary reads, so concurrent search/upsert/remove could race shard initialization and corrupt on‑disk data (S0).
- `FileHandle.close()` failures in shard writes were swallowed with `try?`, leading to silent descriptor leaks and undetected I/O corruption (S1).
- `LibraryImporter` performed `Data(contentsOf:)` + JSON decoding inside `context.perform`, blocking Core Data’s serial queue and freezing UI work whenever podcasts were imported (S2).
- Podcast datasets were duplicated under multiple paths, and nothing prevented stale `project.pbxproj.backup` files from re‑entering the repo (S2/S3 hygiene risks).
- CI harnesses hardcoded unavailable simulators and didn’t enforce strict concurrency builds/tests, so Gate suites could pass locally while missing the concurrency regressions Gate 5 is meant to catch.

## Solution
- Converted `VectorIndex` + `VectorIndexManager` into actor‑safe boundaries (`Packages/PulsumData/Sources/PulsumData/VectorIndex.swift`, `VectorIndexManager.swift`), guarding shard caches with a single critical section and marking `VectorIndexProviding` as `Sendable` so CoachAgent and other actors await it explicitly.
- Rebuilt the shard file‑handle utility to wrap all writes in `withHandle {}` that always closes exactly once; any `close()` failure now surfaces as `VectorIndexError.ioFailure` and gets logged with the shard name. (`Packages/PulsumData/Sources/PulsumData/VectorIndex.swift:96-210`)
- Refactored `LibraryImporter.ingestIfNeeded()` so file reads/decoding happen **off the main actor** before `context.perform`; the Core Data block now only upserts managed objects and returns DTO payloads. Vector index upserts run *after* the Core Data work and **only then** persist `LibraryIngest.checksum`, so transient indexing failures retry safely. (`Packages/PulsumData/Sources/PulsumData/LibraryImporter.swift:40-210`)
- Moved the canonical `Pulsum.xcdatamodeld` into `Packages/PulsumData/Sources/PulsumData/Resources/` and load it from `Bundle.pulsumDataResources`, so SwiftPM tests and the app share the same `.momd` without extra copies. (`Packages/PulsumData/Sources/PulsumData/DataStack.swift:70-187`; `Packages/PulsumData/Package.swift:17-36`)
- Deduped podcast datasets to a single `podcastrecommendations 2.json`, updated `sha256.txt`, and expanded `scripts/ci/integrity.sh` to fail if multiple hashes or any `*.pbxproj.backup` files appear. (`scripts/ci/integrity.sh:1-230`; `sha256.txt`)
- Upgraded `scripts/ci/test-harness.sh` to auto-discover Gate suites per package, run strict‑concurrency builds/tests, pick a real iOS 26.x simulator (prefers 26.0.1, gracefully falls back), and run Gate‑5 UITests after building the app. (`scripts/ci/test-harness.sh:1-220`)

## Key Files & Anchors
- `Packages/PulsumData/Sources/PulsumData/VectorIndex.swift` — actorized index, shard lock, structured file‑handle closing, search/upsert/remove helpers.
- `Packages/PulsumData/Sources/PulsumData/VectorIndexManager.swift` — public actor façade (`VectorIndexProviding & Sendable`) used by CoachAgent.
- `Packages/PulsumData/Sources/PulsumData/LibraryImporter.swift` — non‑blocking import flow and DTO handoff.
- `Packages/PulsumData/Sources/PulsumData/DataStack.swift` — shared Core Data stack loading `Pulsum.momd` from the package bundle.
- `scripts/ci/integrity.sh`, `scripts/ci/test-harness.sh` — dataset/pbxproj guards, strict concurrency builds, simulator selection, Gate suite orchestration.
- Documentation updates: `architecture.md`, `bugs.md`, `instructions.md`, and `todolist.md` now reflect Gate 5 status, data integrity changes, and canonical model/dataset locations.

## Tests & Harness
- **PulsumData:** `Gate5_VectorIndexConcurrencyTests` stress concurrent upsert/search/remove across multiple shards; `Gate5_VectorIndexFileHandleTests` inject failing handles to ensure `close()` errors propagate; `Gate5_VectorIndexManagerActorTests` verify actor usage from background contexts; `Gate5_LibraryImporterPerfTests` time concurrent reads during imports; `Gate5_LibraryImporterAtomicityTests` ensure checksum persistence is atomic with successful indexing and retries remain idempotent. (`Packages/PulsumData/Tests/PulsumDataTests/…`)
- **Integrity:** `scripts/ci/integrity.sh` now enforces clean working trees (unless `CI_ALLOW_DIRTY=1`), dataset hash uniqueness, absence of `*.pbxproj.backup`, Gate‑0 suites, and a release build on a real simulator destination.
- **Harness:** `scripts/ci/test-harness.sh` builds the Pulsum app first, picks an available iOS 26.x simulator, and runs Gate suites (including Gate5_* filters) plus PulsumUITests under strict concurrency flags.

## Simulating Scenarios
- Run strict concurrency builds per package:  
  ```bash
  for pkg in Packages/PulsumData Packages/PulsumAgents Packages/PulsumServices Packages/PulsumML; do
    swift build --package-path "$pkg" -Xswiftc -strict-concurrency=complete
  done
  ```
- Execute Gate‑5 targeted tests:  
  ```bash
  swift test --package-path Packages/PulsumData -Xswiftc -strict-concurrency=complete \
    --filter "(Gate5_VectorIndexManagerActorTests|Gate5_VectorIndexFileHandleTests|Gate5_VectorIndexConcurrencyTests|Gate5_LibraryImporterPerfTests)"
  ```
- Run the integrity sweep (dataset/pbxproj guard + release build + Gate0 suites):  
  ```bash
  CI_ALLOW_DIRTY=1 bash scripts/ci/integrity.sh
  ```
- Full harness (strict concurrency + simulator pick + UI Gate suites):  
  ```bash
  bash scripts/ci/test-harness.sh
  ```

## Follow-ups / Watch Items
- **TSan availability:** local macOS runners may lack `libclang_rt.tsan_osx_dynamic.dylib`; ensure at least one CI job runs `swift test -Xswiftc -sanitize=thread --filter Gate5_` on a toolchain that ships the runtime.
- **Simulator inventory:** keep `PULSUM_SIM_OS` aligned with whatever iOS 26.x runtimes GitHub / local runners actually have installed so harness logs remain meaningful.
- **Dataset monitoring:** `scripts/ci/integrity.sh` should remain in required status to block any reintroduction of duplicate podcast JSON or `*.pbxproj.backup` files.
