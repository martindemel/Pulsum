Got it—I understand. You want an automated “test-updater” so when you land future gates (3, 4, 5, …) the repo detects code changes, generates/updates the right tests, runs them, and proposes the patch without you hand-editing every test file.

Below is a practical blueprint that teams actually use, with safe human-in-the-loop controls. It combines:
	•	Gatekeeper checks that force tests to exist (Danger + coverage),
	•	Impact detection to find what changed,
	•	An AI test agent that drafts/update tests and opens a small follow-up PR,
	•	Snapshot/UI contracts so UI changes update snapshots instead of you doing it by hand.

I also include ready-to-drop workflow YAML, a Dangerfile rule, and tiny scripts. (You can paste these and tune paths.)

⸻

The approach (pick the “level” you want)

Level	What happens on every PR	Risk	Best for
0. Enforce	CI fails when code changes without corresponding test diffs or coverage drop	none	Baseline guard
1. Suggest	A bot drafts tests in a sibling branch/PR (you review)	low	Your Gate 3/4/5 cadence
2. Autofix	Bot pushes tests into the same PR if checks pass	medium	Mature repos with strong contracts

We’ll start with Level 1 (draft a small “tests-only” PR), and keep Level 0 enforcement always on.

⸻

Tools we’ll use (industry-standard)
	•	Danger Swift to auto-comment on PRs (e.g., “code changed but no tests”) and enforce norms. It runs inside CI and leaves review notes you define in a Dangerfile.  ￼
	•	Xcode coverage (xccov) to measure coverage from the .xcresult and fail if it drops below a threshold (or if no tests ran).  ￼
	•	Selective test runs using xcodebuild -only-testing/-skip-testing to target impacted suites when iteration needs speed.  ￼
	•	SnapshotTesting for Swift/SwiftUI so UI diffs become “approve snapshots” instead of manual test rewrites. (Inline snapshots keep changes in-file.)  ￼
	•	An AI test agent in CI. You can:
	•	build your own with OpenAI Responses API and a tiny script (recommended), or
	•	try emerging GitHub/Copilot agents that can open PRs with changes, or Google’s Gemini CLI GitHub Action (both are evolving).  ￼

Why an agent + Danger? The agent proposes tests; Danger + coverage guarantee that tests exist and stay meaningful.

⸻

How it works in your repo (Pulsum)

1) Impact detection (what changed?)

Add a script that lists Swift sources touched in the PR, maps them to the right test target(s), and outputs a JSON the agent consumes.

scripts/ci/changed-swift.sh

#!/usr/bin/env bash
set -euo pipefail
base="${1:-origin/main}"
git fetch origin >/dev/null 2>&1 || true
git diff --name-only "$base"...HEAD \
  | grep -E '\.(swift|metal)$' \
  | jq -R -s 'split("\n") | map(select(length>0))' \
  > /tmp/pulsum_changed.json
echo "[changed] wrote /tmp/pulsum_changed.json"

A small mapper (hard-code paths now; refine later) converts source paths → test paths (e.g., Packages/PulsumData/Sources/... → Packages/PulsumData/Tests/...).

scripts/ci/map-to-tests.py

#!/usr/bin/env python3
import json, os, sys, pathlib
mapping = [
  ("Packages/PulsumData/Sources/PulsumData", "Packages/PulsumData/Tests/PulsumDataTests"),
  ("Packages/PulsumServices/Sources/PulsumServices", "Packages/PulsumServices/Tests/PulsumServicesTests"),
  ("Packages/PulsumML/Sources/PulsumML", "Packages/PulsumML/Tests/PulsumMLTests"),
  ("Packages/PulsumAgents/Sources/PulsumAgents", "Packages/PulsumAgents/Tests/PulsumAgentsTests"),
  ("Packages/PulsumUI/Sources/PulsumUI", "PulsumUITests"),
]
srcs = json.load(open("/tmp/pulsum_changed.json"))
targets = set()
for s in srcs:
  for src_root, test_root in mapping:
    if s.startswith(src_root):
      targets.add(test_root)
out = {"changed": srcs, "test_targets": sorted(targets)}
json.dump(out, open("/tmp/pulsum_impact.json","w"), indent=2)
print("[impact] wrote /tmp/pulsum_impact.json")

2) AI test agent (Level 1: suggests tests in a separate PR)

What it does
	•	Reads /tmp/pulsum_impact.json, pulls the changed files’ contents.
	•	For each impacted test target, creates or updates *Tests.swift files:
	•	generates XCTest cases for new/changed public APIs,
	•	for SwiftUI/Views, emits SnapshotTesting cases (image or inline text snapshots),
	•	for services, emits contract tests (success/failure paths),
	•	Opens a bot branch bot/tests-${{ github.sha }} and a draft PR titled “AI tests for #”.

You can implement this with OpenAI Responses API; below is a thin wrapper (language-agnostic). Keep it suggest-only (human review required). For inspiration, see reference repos automating unit tests generation via Actions + ChatGPT.  ￼

3) Danger rules: refuse code without tests/coverage

Dangerfile.swift (excerpt)

import Danger

let danger = Danger()
let allFiles = danger.git.modifiedFiles + danger.git.createdFiles
let changedSwift = allFiles.filter { $0.hasSuffix(".swift") && !$0.contains("Tests") }

let testChanges = allFiles.filter { $0.contains("Tests") || $0.contains("UITests") }
if !changedSwift.isEmpty && testChanges.isEmpty {
  fail("Production Swift files changed but no tests were updated. Please add/approve tests (see AI draft PR if available).")
}

// Optional: enforce minimum coverage delta using an xccov summary emitted by CI
if let covDrop = danger.utils.readFile("Build/coverage_delta.txt").trimmingCharacters(in: .whitespacesAndNewlines), covDrop.hasPrefix("-") {
  warn("Coverage dropped (\(covDrop)). Consider additional tests.")
}

Danger is designed exactly for this “codify team rules in PRs” use-case.  ￼

4) Coverage gate (using xccov)

After tests, parse coverage from .xcresult via xccov and fail if it regresses past a threshold or if suite count is zero. (Plenty of guides/scripts show how to surface JSON for CI.)  ￼

⸻

The workflow (GitHub Actions)

.github/workflows/ai-test-agent.yml

name: AI Test Agent
on:
  pull_request:
    types: [opened, synchronize, reopened]
jobs:
  propose-tests:
    runs-on: macos-14
    permissions:
      contents: write
      pull-requests: write
    steps:
      - uses: actions/checkout@v4
        with: { fetch-depth: 0 }
      - name: Detect changed Swift
        run: |
          chmod +x scripts/ci/changed-swift.sh
          scripts/ci/changed-swift.sh origin/main
          python3 scripts/ci/map-to-tests.py
          cat /tmp/pulsum_impact.json
      - name: Generate tests with AI (suggest-only)
        env:
          OPENAI_API_KEY: ${{ secrets.OPENAI_API_KEY }}
          IMPACT_JSON: /tmp/pulsum_impact.json
        run: |
          python3 scripts/ai/generate_tests.py  # your agent script
      - name: Open draft PR with tests (stacked)
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: |
          git checkout -b bot/tests-${{ github.sha }} || git checkout bot/tests-${{ github.sha }}
          git add -A && git commit -m "bot: propose tests for ${{ github.sha }}" || true
          git push -u origin bot/tests-${{ github.sha }} || true
          gh pr create --base ${{ github.head_ref }} --head bot/tests-${{ github.sha }} \
            --title "AI tests for #${{ github.event.pull_request.number }}" \
            --body "Automated test suggestions based on changed files."

.github/workflows/ci.yml (call your existing sweep + Danger)

name: Pulsum CI
on: [pull_request]
jobs:
  build-and-test:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4
        with: { fetch-depth: 0 }
      - name: Build & run Gate-0/1 sweeps
        run: scripts/ci/integrity.sh
      - name: Danger
        uses: danger/swift@master
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

If you prefer a hosted agent, GitHub just announced a Copilot agent that can clone, edit, and open PRs for a task; Google’s Gemini CLI Action does similar. Both can be adapted to “write tests for this PR.” They’re new, but worth piloting behind our Danger/coverage guardrails.  ￼

⸻

The local option (manual or daily)

If you want a local agent that runs every morning or on commit:
	•	Pre-commit hook for the “suggest skeletons” mode:

cat > .git/hooks/pre-commit <<'H'
#!/usr/bin/env bash
scripts/ci/changed-swift.sh origin/main
python3 scripts/ci/map-to-tests.py
python3 scripts/ai/generate_tests.py --local
H
chmod +x .git/hooks/pre-commit


	•	Or a LaunchAgent on macOS that runs scripts/ci/integrity.sh and scripts/ai/generate_tests.py at 9am and opens a stacked PR if tests are missing. (Safer to let CI run the generation so everything is reviewable in GH.)

⸻

What the generator actually writes
	•	Service/Model code → XCTest target: create/update XYZTests.swift with table-driven unit tests (happy/edge/error), using your Gate contracts (e.g., “backup exclusion must fail closed”).
	•	SwiftUI/View code → SnapshotTesting target: write assertSnapshot(matching:view, as:.image) or .dump text snapshots (inline snapshots reduce file churn).  ￼
	•	Routing/Orchestrators → small integration tests with -only-testing selections to keep runtime fast.  ￼

The agent should never push directly to the feature branch. It opens a separate draft PR with only test files; you accept, squash, or discard.

⸻

Why this will scale across Gates
	•	You don’t need to touch tests by hand for every gate—most changes will trigger the agent → draft PR → you review & approve.
	•	Danger + coverage ensure the worst case still fails early (“code changed, no tests”).
	•	SnapshotTesting handles UI churn with a one-click baseline update instead of hand-coding each assertion.  ￼
	•	Selective runs keep the loop fast while Gate 2/3 grow your surface (-only-testing/-skip-testing).  ￼

⸻

What to do now (action list)
	1.	Add the three helper files (changed-swift.sh, map-to-tests.py, Dangerfile.swift) and turn on Danger.  ￼
	2.	Decide AI runner: your own OpenAI script (recommended) vs. Copilot/Gemini beta.  ￼
	3.	Drop the Actions YAML above.
	4.	Add SnapshotTesting to UI tests and convert 1–2 surfaces to snapshots to prove the “approve baseline” loop.  ￼
	5.	Land this as part of Gate 1 so every later gate auto-gets tests.

If you want, I’ll generate a starter scripts/ai/generate_tests.py that reads the diff, calls an LLM to write XCTest stubs with assertions and SnapshotTesting where applicable, and then opens the draft PR via gh.