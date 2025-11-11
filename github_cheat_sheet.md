# GitHub How-To (Pulsum) — Printable Cheat Sheet

A compact guide to the **what/why/how** of Git & GitHub for your Pulsum repo, with **copy-pasteable commands**. Keep this next to your keyboard.

---

## 1) Core words (what they mean)

* **Repository (repo)**: Your project’s versioned database (local and on GitHub).
* **Working directory**: The files you’re editing right now.
* **Staging area (index)**: The exact snapshot you plan to commit.
* **Commit**: A saved snapshot with a message.
* **Branch**: A line of development (e.g., `main`, `feat/foo`).
* **Remote**: A server copy of the repo (usually `origin` on GitHub).
* **HEAD**: Your current commit checked out locally.
* **PR (Pull Request)**: A proposal to merge one branch into another (review + checks).
* **Squash merge**: Merge a PR as a single tidy commit.
* **Tag**: A named pointer to a specific commit (e.g., a milestone).

---

## 2) Pulsum “golden rules”

* Keep **secrets out of Git**. Use **Keychain/env**; scan with `scripts/ci/scan-secrets.sh`.
* Never commit **build outputs** (`Build/`, `DerivedData/`, `.xcarchive`, `.app`).
* Work on a **feature branch** → open **PR** → **squash merge** → tag if needed.
* Use the repo’s **privacy** and **secret** checks before merging.

---

## 3) Daily workflow (quick start)

**Sync `main`**

```bash
git fetch origin
git checkout main
git pull
```

**Create feature branch**

```bash
git switch -c feat/my-change
```

**Work, then stage & commit**

```bash
git status -sb
git add -A
git commit -m "feat: concise summary of the change"
```

**Push & open PR**

```bash
git push -u origin feat/my-change
```

Open the PR on GitHub, paste the PR body, attach logs, and request review.

**After merge**

```bash
git checkout main
git pull
git branch -d feat/my-change
git push origin --delete feat/my-change
```

**Tag the milestone (optional)**

```bash
git tag -a gate0-done-YYYY-MM-DD -m "Gate 0 complete"
git push origin --tags
```

---

## 4) Staging vs committing (the mental model)

* `git add` moves changes → **Staging area**
* `git commit` moves staged snapshot → **Repository history**
* `git push` sends commits → **GitHub**

**Helpful views**

```bash
git status -sb
git diff
git diff --staged
```

**Stage precisely**

```bash
git add path/to/file.swift
git add -p
```

---

## 5) Integrity & CI commands (Pulsum)

**Full integrity sweep**

```bash
scripts/ci/integrity.sh
```

**Mini-check (fast)**

```bash
git fetch origin
test "$(git rev-parse HEAD)" = "$(git rev-parse origin/main)" && echo SYNC_OK || echo SYNC_MISMATCH
scripts/ci/scan-secrets.sh
scripts/ci/check-privacy-manifests.sh
scripts/ci/build-release.sh -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=26.0' -derivedDataPath Build || \
scripts/ci/build-release.sh -destination 'platform=iOS Simulator,name=iPhone 15,OS=26.0' -derivedDataPath Build
swift test --package-path Packages/PulsumServices --filter Gate0_
swift test --package-path Packages/PulsumData     --filter Gate0_
swift test --package-path Packages/PulsumML       --filter Gate0_
```

**One-off build (signing disabled)**

```bash
scripts/ci/build-release.sh -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=26.0' -derivedDataPath Build
```

---

## 6) Secret & privacy hygiene

**Repo scan**

```bash
scripts/ci/scan-secrets.sh
```

**Bundle scan (after building)**

```bash
scripts/ci/scan-secrets.sh Build/Build/Products/Release-iphonesimulator/Pulsum.app
```

**Privacy manifests**

```bash
scripts/ci/check-privacy-manifests.sh
```

---

## 7) Pull Request flow (end-to-end)

**Create PR**

```bash
git switch -c feat/topic-branch
git add -A
git commit -m "feat: summary"
git push -u origin feat/topic-branch
```

Open PR on GitHub → fill title & description → attach logs → assign reviewers.

**Merge (squash) then clean up**

```bash
git checkout main
git pull
git branch -d feat/topic-branch
git push origin --delete feat/topic-branch
```

**Re-tag milestone**

```bash
git tag -d gate0-done-YYYY-MM-DD
git push origin :refs/tags/gate0-done-YYYY-MM-DD
git tag -a gate0-done-YYYY-MM-DD -m "Gate 0 complete"
git push origin --tags
```

---

## 8) Common fixes (copy-paste)

**Tracked build files showed up**

```bash
git rm -r --cached Build
git rm -r --cached DerivedData 2>/dev/null || true
git rm -r --cached Pulsum.xcodeproj/project.xcworkspace/xcuserdata 2>/dev/null || true
find . -name '.DS_Store' -print0 | xargs -0 git rm -f --cached --ignore-unmatch
git commit -m "chore(git): untrack build products and user-state"
```

**Delete branch before merging PR (whoops)**

```bash
git checkout -b the-branch <commit-sha>
git push -u origin the-branch
# Reopen/restore PR → Squash merge on GitHub
```

**Tag is on the wrong commit**

```bash
git tag -d gate0-done-YYYY-MM-DD
git push origin :refs/tags/gate0-done-YYYY-MM-DD
git tag -a gate0-done-YYYY-MM-DD -m "Milestone complete"
git push origin --tags
```

**Duplicate PrivacyInfo.xcprivacy copy warning**

```bash
grep -n 'PrivacyInfo\.xcprivacy in Resources' Pulsum.xcodeproj/project.pbxproj
# Ensure there is exactly one PBXBuildFile in Resources for the app target
```

---

## 9) Investigate history & diffs

```bash
git log --oneline --decorate --graph -n 15
git show HEAD
git show <commit> --name-status
git blame path/to/file.swift
git diff <base>..<head>
git shortlog -sn
```

---

## 10) Undo safely

**Discard working changes**

```bash
git restore path/to/file.swift
git restore .
```

**Unstage but keep edits**

```bash
git restore --staged path/to/file.swift
```

**Revert a bad commit (create fix commit)**

```bash
git revert <commit-sha>
```

**Amend last commit (small fixups)**

```bash
git add -A
git commit --amend --no-edit
```

**Stash work temporarily**

```bash
git stash push -m "wip"
git stash list
git stash pop
```

---

## 11) Commit & branch naming (simple conventions)

* **Commits**: `feat: …`, `fix: …`, `chore: …`, `ci: …`, `docs: …`, `refactor: …`, `test: …`, `perf: …`, `build: …`, `ui: …`
* **Branches**: `feat/<topic>`, `fix/<ticket-or-bug>`, `ci/<thing>`

Examples

```bash
git commit -m "fix(speech): gate transcript logging under DEBUG"
git commit -m "ci: add full repository integrity sweep script"
```

---

## 12) Zsh & copying commands

* Paste commands **without** leading `#` lines; zsh treats them as commands.
* One command per line avoids parse errors in long pastes.

---

## 13) Project-specific helpers (Pulsum)

**Integrity sweep**

```bash
scripts/ci/integrity.sh
```

**Privacy & secret checks**

```bash
scripts/ci/check-privacy-manifests.sh
scripts/ci/scan-secrets.sh
```

**Build (signing off)**

```bash
scripts/ci/build-release.sh -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=26.0' -derivedDataPath Build
```

**Gate-0 tests**

```bash
swift test --package-path Packages/PulsumServices --filter Gate0_
swift test --package-path Packages/PulsumData     --filter Gate0_
swift test --package-path Packages/PulsumML       --filter Gate0_
```

---

## 14) .gitignore essentials (Pulsum)

Track **templates & manifests**; ignore **secrets & build**:

```
Build/
DerivedData/
*.xcarchive
*.xcresult
*.app
.build/
.swiftpm/
.vscode/
.idea/
.claude/
*.log
*.tmp
Config.xcconfig
.env
.env.*
!Config.xcconfig.template
```

Do **not** ignore:

* `PrivacyInfo.xcprivacy` (app + packages)
* `Package.resolved` (recommended)

---

## 15) When to run the full sweep

* Before pushing a PR that touches **security**, **privacy**, **speech**, or **LLM** paths
* Before **release/TestFlight** builds
* After **Xcode/SDK** upgrades
* When tagging a milestone

---

Print this and keep it handy. If you need a one-page version, say “one-pager” and I’ll condense it.
