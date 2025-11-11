# Pulsum — Gate-by-Gate GitHub Playbook (for “OpenAI Codex 5 High”)

A single, detailed, **copy‑pasteable** guide for how you (and your AI assistants) should branch, commit, PR, merge, tag, and verify **each Gate** (Gate 1, Gate 2, …) using the **same best practices** we finalized for **Gate 0**—with corrections for pitfalls we hit.

---

## 0) Principles this document enforces

* **One Gate = One PR** from a **dedicated branch**; use **Squash & Merge**.
* **Security/Privacy first**: run secret scans and privacy‑manifest checks before opening PR and again before merging.
* **Attach logs** (build/test/scan outputs) to the PR for traceability.
* **Never close a PR without merging** if it has the Gate work—closing loses the nice merge metadata.
* **Tag only after merge** and ensure the tag points at **`main` HEAD**.
* **Human-only tasks** are explicitly called out.

---

## 1) Naming & conventions (uniform across all Gates)

* **Branch name**: `gate<NUM>-<short-topic>`
  Example: `gate1-testing-harness`
* **Commit prefix**: `gate<NUM>:`
  Example: `gate1: enable package tests in shared scheme`
* **PR title**: `gate<NUM>: <clear goal>`
  Example: `gate1: test harness & shared scheme`
* **Tag after merge**: `gate<NUM>-done-YYYY-MM-DD`
  Example: `gate1-done-2025-11-12`

---

## 2) Environment variables for quick reuse

Set these at the start of a Gate:

```bash
export GATE_NUM=1
export TOPIC="testing-harness"
export BRANCH="gate${GATE_NUM}-${TOPIC}"
export TAG="gate${GATE_NUM}-done-$(date +%F)"
```

---

## 3) Start the Gate (create branch, sync main)

```bash
git fetch origin
git checkout main
git pull
git switch -c "$BRANCH"
```

*Do the work for this Gate now.*
Human-required examples for Gate 1 (illustrative):

* Add package test bundles to the **Pulsum** scheme in Xcode (UI step).
* Author missing **UITests** or unit tests (human + AI pairing).
* Verify on a simulator that **permissions** and **flows** behave as expected.

---

## 4) Stage, commit, push

```bash
git status -sb
git add -A
git commit -m "gate${GATE_NUM}: <concise summary of this batch>"
git push -u origin "$BRANCH"
```

If you will push several times during review, keep the prefix:

```bash
git commit -m "gate${GATE_NUM}: address review — fix <item>"
git push
```

---

## 5) Pre‑PR local integrity sweep (repeat before merge too)

```bash
scripts/ci/integrity.sh
```

This runs:

* Git sync check
* Secret scan (repo, and bundle if built)
* Privacy manifests validation
* Release build (signing disabled)
* Gate‑focused tests (Services/Data/ML)
  If any step fails, fix and re‑run until **all green**.

---

## 6) Open the PR (web UI)

Open the URL printed by `git push` or visit the repo’s **Compare & Pull Request** page.
Use the following PR body template:

<details>
<summary><strong>PR body template (copy all)</strong></summary>

```markdown
Gate ${GATE_NUM} — <Short Title>

## Summary
<What this Gate delivers and why it matters. One or two paragraphs max.>

## Verification Matrix
Check | Status | Notes
---|---|---
Integrity sweep (`scripts/ci/integrity.sh`) | ✅ | All checks green
Release build (sim) | ✅ | Attach log path
Secret scans (repo + .app) | ✅ | Attach log paths
Privacy manifests | ✅ | `scripts/ci/check-privacy-manifests.sh`
Focused tests | ✅ | List packages and filters used

## Artifacts (paths on your machine)
<paste these from your last run>
/tmp/pulsum_xcbuild.log  
/tmp/pulsum_services_tests.log  
/tmp/pulsum_data_tests.log  
/tmp/pulsum_ml_tests.log

## Highlights (bullets)
- <Key change 1>
- <Key change 2>
- <Breaking/behavioral changes—call out explicitly>

## Follow-ups
- <Short list of next steps you’ll track in Gate ${GATE_NUM+1} or issues>

```

</details>

Attach the log files referenced above (drag & drop onto PR).

---

## 7) Code review loop (with Codex/CodeRabbit + humans)

* **Respond** to automated review comments (e.g., platform guards, API changes).
* **Implement fix** on the same branch and push:

```bash
git add -A
git commit -m "gate${GATE_NUM}: address review — <short phrase>"
git push
```

* **Human-required**: If the review points to UI/Xcode‑only work (scheme edits, entitlements, signing), do these in Xcode and re-run `scripts/ci/integrity.sh`.

**Pitfall we hit in Gate 0** and the fix:

* Closing the PR without merge produced “closed with unmerged commits.”
  **Correct behavior**: Keep the branch open, push fixes, and **Squash & Merge** once green.
  If you *accidentally* close it, re-open or create a new PR from the same branch.

---

## 8) Merge correctly (Squash & Merge), then clean up

**On GitHub PR page**: choose **Squash & Merge** → confirm.
Then:

```bash
git checkout main
git pull
git branch -d "$BRANCH"
git push origin --delete "$BRANCH"
```

---

## 9) Tag the Gate completion (and ensure it points at `main` HEAD)

```bash
git tag -a "$TAG" -m "Gate ${GATE_NUM} complete"
git push origin --tags
```

**Verify tag points at HEAD (important)**

```bash
git fetch origin
git rev-parse --short HEAD
git rev-parse --short "$TAG"
```

If the tag does not match HEAD (a Gate 0 pitfall), **retag**:

```bash
git tag -d "$TAG"
git push origin :refs/tags/"$TAG"
git tag -a "$TAG" -m "Gate ${GATE_NUM} complete"
git push origin --tags
```

---

## 10) Final integrity sweep on `main` (post‑merge)

```bash
scripts/ci/integrity.sh
```

Expect:

* `local HEAD matches origin/main`
* `tag <TAG> points at HEAD`
* All scans/builds/tests pass

---

## 11) Human‑only tasks (cannot be fully automated)

* **Xcode scheme edits** (adding/removing test bundles, UI test targets).
* **Manual on‑device checks** (permissions UX, microphone behavior, health data paths).
* **App Privacy report via `xcrun privacyreport`** where CLI support requires specific Xcode versions/CLTs.
* **Policy/copy reviews** (consent language, safety escalation copy).
* **Credential rotation** in external systems if a leak is suspected.

When you perform these, note them in the PR body under **Verification Matrix** and **Highlights**.

---

## 12) Quick recoveries (copy‑paste)

**PR closed without merging (oops)**

```bash
# If branch still exists remotely, just reopen PR from GitHub UI.
# If branch was deleted locally:
git checkout -b "$BRANCH" $(git merge-base origin/main HEAD)
git push -u origin "$BRANCH"
# Open a fresh PR, paste the same PR body, and proceed to review/merge.
```

**You deleted the tag or it points to the wrong commit**

```bash
git tag -d "$TAG"
git push origin :refs/tags/"$TAG"
git tag -a "$TAG" -m "Gate ${GATE_NUM} complete"
git push origin --tags
```

**Build warnings: multiple PrivacyInfo.xcprivacy copied**

```bash
scripts/ci/check-privacy-manifests.sh
grep -n 'PrivacyInfo\.xcprivacy in Resources' Pulsum.xcodeproj/project.pbxproj
# Ensure exactly one app target resource entry. Remove duplicates in Xcode or edit project file carefully.
```

**Secret scan fails**

* Remove offending file/line, rotate credentials externally if needed.
* Re-run:

```bash
scripts/ci/scan-secrets.sh
```

---

## 13) Gate‑specific insert (example for Gate 1)

Use this **as-is** and change the descriptions to your Gate 1 scope.

```bash
export GATE_NUM=1
export TOPIC="testing-harness"
export BRANCH="gate${GATE_NUM}-${TOPIC}"
export TAG="gate${GATE_NUM}-done-$(date +%F)"

git fetch origin
git checkout main
git pull
git switch -c "$BRANCH"

# Do Gate 1 work here (tests, scheme updates, minimal UITests)

git add -A
git commit -m "gate${GATE_NUM}: add package tests to shared scheme and basic UITests"
git push -u origin "$BRANCH"

scripts/ci/integrity.sh
```

Then open PR, paste the template body, attach logs, address reviews, **Squash & Merge**, clean branches, tag, and run a final `scripts/ci/integrity.sh`.

---

## 14) What Codex/AI should and should not do

**Codex/AI SHOULD:**

* Propose branch names, commit messages (with `gate<NUM>:` prefix).
* Run integrity scripts and paste results into the PR.
* Apply deterministic code changes surfaced by reviews (e.g., platform guards).
* Prepare PR body and follow the template.

**Codex/AI SHOULD NOT:**

* Enter credentials or write secrets into files or environment.
* Perform UI‑only Xcode edits that require human decisions (e.g., code signing).
* Approve/merge its own PRs without human consent when the scope is high‑risk.

---

## 15) Gate 0 corrections (what we fixed in the process)

* **Don’t close PRs without merge** when they contain a Gate—use **Squash & Merge**.
* **Ensure tags point to `main` HEAD**; if not, delete and re‑tag.
* **Haptic helper**: avoid UIKit type references at call sites on macOS; we corrected by introducing a platform‑agnostic wrapper.

These rules are now baked into this playbook.

---

### Done

This markdown is designed to be **printed** and **followed step‑by‑step** for every Gate. For a one‑page abridged version, ask for the “Gate Playbook one‑pager.”
