# How to Run a Full Pulsum Audit — Step by Step (V2)

This is your cheat sheet. Follow these steps in order whenever you want to scan the app for issues, whether after completing a phase from the master plan, before an App Store submission, or after any major code change.

Project root means: the repository root containing `Pulsum.xcodeproj` and `Packages/`.
Generated outputs (`master_report.md`, `guidelines_report.md`, `master_plan_FINAL.md`, `diagnostics_data.md`, `privacy_report.pdf`) must live in this root.

---

## Quick Version (if you're in a hurry)

1. Export diagnostics from the app on your iPhone → save as `diagnostics_data.md`
2. Open a new AI chat → paste `guidelines_checkV2.md` → wait for `guidelines_report.md`
3. Open a NEW AI chat → paste `scan_promptV2.md` → wait for `master_report.md` + `master_plan_FINAL.md`
4. Review `master_plan_FINAL.md` → start fixing

> **Why guidelines FIRST?** The technical scan reads `guidelines_report.md` when building the master plan. This way the plan includes both technical fixes AND compliance items (disclaimers, 988 Lifeline, AI labels, etc.). If you run the scan first, the plan would be missing all App Store compliance work.

---

## Full Version

### Step 1: Prepare the App (5 minutes)

Before running the scan, get fresh runtime data from a real device:

1. **Build and install** the app on your iPhone (or simulator with HealthKit enabled)
2. **Run through the main flows:**
   - Launch the app (let it complete startup + HealthKit bootstrap)
   - Grant HealthKit permissions if prompted
   - Record a voice journal (at least 10 seconds)
   - View the wellbeing score
   - Open the Coach tab and send a chat message
   - Open Settings and verify everything loads
   - Type something crisis-related in chat (e.g., "I feel hopeless") to trigger safety detection
3. **Export diagnostics:**
   - Go to Settings → Diagnostics section
   - Tap "Export diagnostics"
   - Share/save the exported file
4. **Save as `diagnostics_data.md`** in the project root (`$PROJECT_ROOT/diagnostics_data.md`).
5. **Optional (recommended before submission):** Generate Xcode privacy report and save as `$PROJECT_ROOT/privacy_report.pdf`
   - Archive app in Xcode
   - Organizer → Privacy Report
   - Export PDF to project root

> If you skip this step, the scan still works — it just won't have runtime evidence. The reports will note "static analysis only."

---

### Step 2: Run the Guidelines Check FIRST

The guidelines check runs first so its output is available when the technical scan builds the master plan.

1. **Open a new AI chat** (Cursor, Codex, or any agent with file access)
2. **Paste or reference:**
   ```
   guidelines_checkV2.md
   ```
   If your agent requires `@` file mentions, use `@guidelines_checkV2.md` or copy-paste the file contents directly.
3. **Wait.** This reads the source files relevant to compliance and produces `guidelines_report.md`. Takes ~10-15 minutes.
4. **When done, you'll have:**
   - `guidelines_report.md` — App Store compliance status with PASS/FAIL/AT RISK per guideline

> **Why first?** The technical scan (Step 3) reads `guidelines_report.md` when generating the master plan. Guidelines first = the plan includes both technical fixes AND compliance items.

---

### Step 3: Run the Technical Scan SECOND

This produces 2 reports: `master_report.md` and `master_plan_FINAL.md`.

1. **Open a NEW AI chat** (not the same one as Step 2 — fresh context for the full technical analysis)
2. **Paste or reference the scan prompt:**
   ```
   scan_promptV2.md
   ```
   If your agent requires `@` file mentions, use `@scan_promptV2.md` or copy-paste the file contents directly.
3. **Wait.** The scan reads every source file, analyzes 25+ dimensions, reads the `guidelines_report.md` from Step 2, and writes 2 reports. This takes 15-30 minutes.
4. **When done, you'll have:**
   - `master_report.md` — all technical/architecture/production findings
   - `master_plan_FINAL.md` — comprehensive phased remediation plan (includes both technical fixes AND guidelines compliance items)

> **Tip:** If the AI stops early, tell it: "Continue. You need to produce both master_report.md and master_plan_FINAL.md."

---

### Step 4: Review the Reports

Read the reports in this order:

1. **`master_plan_FINAL.md`** — Start here. This is your action list. Check:
   - How many items per phase?
   - Which items are already done (`[x]`) from previous work?
   - What's the overall progress percentage?

2. **`master_report.md`** — Read the Executive Summary and "If You Only Fix 5 Things" section. Then scan the Summary Table for new CRIT/HIGH findings. Deep-dive into specific findings only when you're working on them.

3. **`guidelines_report.md`** — Check the Overall Compliance Assessment (PASS/AT RISK/FAIL). Look at the Submission Readiness Checklist — unchecked items are blockers or risks.

---

### Step 5: Fix Issues (follow the master plan)

1. Open `master_plan_FINAL.md`
2. Work through items in phase order (Phase 0 → 1 → 2 → 3)
3. Do NOT skip phases — each builds on the previous
4. After completing each item, mark it: `[x] *(2026-02-15)*`
5. After completing each phase, run `swiftformat .` and verify the build passes
6. **After Phase 0:** Do the manual smoke test (it's in the plan's warnings)

---

### Step 6: Re-scan After Fixes (repeat as needed)

After completing a phase or making significant changes:

1. Repeat Steps 1-4
2. The new scan will:
   - **Compare against previous reports** (if they still exist in the project root)
   - Show a **delta summary**: findings fixed, new findings, regressions
   - Verify that items marked `[x]` in the old plan are actually fixed
   - Generate updated reports and a new plan

---

## File Map — What Lives Where

| File | What It Is | Who Creates It | When to Read |
|---|---|---|---|
| `scan_promptV2.md` | Full audit prompt v2 (you paste this to run a scan) | You (one-time setup, already done) | When running a scan |
| `guidelines_checkV2.md` | Apple guidelines checklist prompt v2 | You (one-time setup, already done) | When running compliance-only check |
| `master_report.md` | Technical findings report | AI generates during scan | After each scan |
| `guidelines_report.md` | App Store compliance report | AI generates during scan | After each scan / before submission |
| `master_plan_FINAL.md` | Remediation plan with checkboxes | AI generates during scan | Daily — this is your work tracker |
| `master_plan_1_1_FUTURE.md` | v1.1+ roadmap (backend, StoreKit, widgets, etc.) | You (already created) | When planning post-v1.0 work |
| `diagnostics_data.md` | Runtime logs from real device | You export from app | Before each scan (optional) |
| `privacy_report.pdf` | Xcode-generated privacy aggregation report | You export from Organizer | Before compliance scan (optional, high value) |
| `scan_instructionsV2.md` | This file — the cheat sheet | You (already created) | When you forget what to do |

---

## When to Run a Scan

| Situation | What to Run |
|---|---|
| **After completing a phase** from master_plan_FINAL.md | Guidelines check (`guidelines_checkV2.md`) FIRST, then technical scan (`scan_promptV2.md`) |
| **Before App Store submission** | Guidelines check FIRST, then technical scan (both mandatory) |
| **After a large PR or merge** | Technical scan |
| **Quick compliance check** before TestFlight | Guidelines only (`guidelines_checkV2.md`) |
| **After adding a new feature** | Technical scan |
| **Monthly maintenance check** | Guidelines check FIRST, then technical scan |
| **Something broke and you don't know why** | Export diagnostics → technical scan |
| **Just checking if Apple would approve** | Guidelines only (`guidelines_checkV2.md`) |

---

## Troubleshooting

**The AI stopped before writing all reports:**
→ For the technical scan: "Continue. You need to produce both master_report.md and master_plan_FINAL.md."
→ For the guidelines check: "Continue. You need to produce guidelines_report.md."

**The scan missed files I recently added:**
→ The scan discovers files dynamically via glob. If new files are in standard locations (`Packages/*/Sources/**/*.swift`), they'll be found. If they're in a non-standard location, check that the glob patterns in Phase 0 of `scan_promptV2.md` cover them.

**The reports are too long to read:**
→ Start with `master_plan_FINAL.md` — it's the actionable summary. Read `master_report.md` only for specific finding details when you're working on an item.

**Diagnostics export is empty or very short:**
→ Make sure diagnostics are enabled in the app: Settings → Diagnostics → Enabled = ON. Run through all flows (journal, score, chat, settings) before exporting. The diagnostics system only logs events that actually occur.

**I don’t have `privacy_report.pdf`:**
→ It is optional. Run the scans without it.
→ For stronger compliance evidence, export it from Xcode Organizer and place it at `$PROJECT_ROOT/privacy_report.pdf`.

**The AI says it can't find `guidelines_checkV2.md`:**
→ Reference it explicitly as `guidelines_checkV2.md` (or `@guidelines_checkV2.md`).
→ If lookup still fails, copy-paste the file contents directly into chat.

**Previous reports are overwritten:**
→ Each scan overwrites its output files. If you want to keep old reports for comparison, copy them before running:
```bash
cp master_report.md master_report_PREV.md
cp guidelines_report.md guidelines_report_PREV.md
cp master_plan_FINAL.md master_plan_FINAL_PREV.md
```
The scans will auto-compare against previous reports if they exist in the project root (the scan prompts include comparison logic).

---

## Quick Reference: File Locations

```
$PROJECT_ROOT/
├── scan_promptV2.md          ← Full scan prompt v2 (paste to run)
├── scan_instructionsV2.md    ← This cheat sheet (v2)
├── guidelines_checkV2.md     ← Compliance-only prompt v2
├── master_report.md          ← Technical findings (AI generates)
├── guidelines_report.md      ← Compliance report (AI generates)
├── master_plan_FINAL.md      ← Action plan with checkboxes (AI generates)
├── master_plan_1_1_FUTURE.md ← v1.1+ roadmap
├── diagnostics_data.md       ← Runtime diagnostics (you export from app)
├── privacy_report.pdf        ← Optional Xcode privacy report evidence
└── AGENTS.md                 ← Project conventions for AI agents
```
