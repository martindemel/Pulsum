# Unused File Identification Report
Generated: 2026-02-02T18:58:18
Repo: /Users/martin.demel/Desktop/PULSUM/Pulsum

Notes:
- Markdown files are listed but do not count as usage evidence.
- PDFs are treated as support-only unless used by build/test.
- Test references are tracked separately as test-only usage.
- Ignored local artifact directories detected (not scanned file-by-file): Build, DerivedData

## Summary
- Total files analyzed: 309 (tracked 305, untracked 4)
- used-build-runtime: 132
- used-test-only: 75
- support-doc-md: 47
- support-doc-pdf: 18
- support-asset: 13
- support-config: 2
- generated-artifact: 18
- local-artifact: 1
- unused-candidate: 3

## Top 10 Largest Non-Build/Test Candidates
| Path | Size | Category | Tracked |
| --- | --- | --- | --- |
| `main.gif` | 20.8 MB | support-asset | yes |
| `export 2.md` | 19.4 MB | generated-artifact | no |
| `Docs/a-practical-guide-to-building-with-gpt-5.pdf` | 11.5 MB | support-doc-pdf | yes |
| `a-practical-guide-to-building-agents.pdf` | 7.0 MB | support-doc-pdf | yes |
| `ios support documents/Landmarks_ Building an app with Liquid Glass _ Apple Developer Documentation.pdf` | 7.0 MB | support-doc-pdf | yes |
| `codex_inventory.json` | 4.8 MB | generated-artifact | yes |
| `ios support documents/Adopting Liquid Glass _ Apple Developer Documentation.pdf` | 4.6 MB | support-doc-pdf | yes |
| `ios support documents/Liquid Glass _ Apple Developer Documentation.pdf` | 4.1 MB | support-doc-pdf | yes |
| `coverage_ledger.json` | 4.1 MB | generated-artifact | yes |
| `ChatGPT for engineers - Resource _ OpenAI Academy.pdf` | 3.8 MB | support-doc-pdf | yes |

## Build-Included But No Explicit Runtime/Test References
| Path | Evidence |
| --- | --- |
| `Packages/PulsumData/Sources/PulsumData/Resources/Pulsum.xcdatamodeld/.xccurrentversion` | swiftpm:resource PulsumData |
| `Packages/PulsumData/Sources/PulsumData/Resources/PulsumCompiled.momd/Pulsum.omo` | swiftpm:resource PulsumData |
| `Packages/PulsumData/Sources/PulsumData/Resources/PulsumCompiled.momd/VersionInfo.plist` | swiftpm:resource PulsumData |
| `podcastrecommendations 2.json` | pbx:resources |
| `streak_low_poly_copy.splineswift` | pbx:resources |

## Detailed Inventory
| Path | Tracked | Size | Modified | Category | Evidence |
| --- | --- | --- | --- | --- | --- |
| `_git_tracked_files.txt` | yes | 14.8 KB | 2026-01-22T14:58:02 | generated-artifact |  |
| `_project_focus_files.txt` | yes | 12.3 KB | 2026-01-20T16:37:02 | generated-artifact |  |
| `_project_tree.txt` | yes | 3.5 MB | 2026-01-20T16:28:53 | generated-artifact |  |
| `baseline 5_2/baseline_5_2.md` | yes | 74.4 KB | 2026-01-22T13:18:42 | generated-artifact |  |
| `baseline 5_2/baseline_appendix_5_2.md` | yes | 47.7 KB | 2026-01-22T13:02:05 | generated-artifact |  |
| `baseline 5_2/baseline_file_inventory_5_2.json` | yes | 110.2 KB | 2026-01-22T12:52:32 | generated-artifact |  |
| `baseline 5_2/baseline_progress_5_2.md` | yes | 19.2 KB | 2026-01-22T13:19:00 | generated-artifact |  |
| `baseline 5_2/baseline_tracked_files_5_2.txt` | yes | 14.8 KB | 2026-01-22T12:51:29 | generated-artifact |  |
| `baseline_progress.md` | yes | 2.7 KB | 2026-01-22T15:55:52 | generated-artifact |  |
| `codex_inventory.json` | yes | 4.8 MB | 2025-10-25T22:10:37 | generated-artifact |  |
| `coverage_ledger.json` | yes | 4.1 MB | 2025-10-25T22:32:26 | generated-artifact |  |
| `export 2.md` | no | 19.4 MB | 2026-01-25T18:19:14 | generated-artifact |  |
| `export_pulsum.md` | no | 1.6 MB | 2026-01-25T20:34:41 | generated-artifact |  |
| `files.zlist` | yes | 1.7 MB | 2025-10-25T22:01:49 | generated-artifact |  |
| `inventory.json` | yes | 42.2 KB | 2025-11-20T19:23:09 | generated-artifact |  |
| `sha256.txt` | yes | 2.7 MB | 2025-11-20T19:23:09 | generated-artifact |  |
| `terminal_1.md` | yes | 517.0 KB | 2025-11-13T23:07:19 | generated-artifact |  |
| `terminal_new.md` | yes | 698.7 KB | 2025-11-13T23:07:19 | generated-artifact |  |
| `Pulsum.xcodeproj/xcuserdata/martin.demel.xcuserdatad/xcschemes/xcschememanagement.plist` | yes | 780.0 B | 2026-01-22T17:46:52 | local-artifact |  |
| `MAINDESIGN.png` | yes | 3.7 MB | 2025-10-06T23:00:11 | support-asset |  |
| `checkin.PNG` | yes | 3.4 MB | 2026-01-24T14:09:07 | support-asset |  |
| `coach.PNG` | yes | 902.0 KB | 2026-01-24T14:09:07 | support-asset |  |
| `iconlogo.png` | yes | 1.0 MB | 2025-11-13T23:07:19 | support-asset |  |
| `iconnew.png` | yes | 980.1 KB | 2025-11-16T20:06:33 | support-asset |  |
| `infinity_blubs_copy.splineswift` | yes | 266.4 KB | 2025-10-06T23:00:11 | support-asset |  |
| `insights.PNG` | yes | 1.2 MB | 2026-01-24T14:09:07 | support-asset |  |
| `ios app mockup.png` | yes | 2.7 MB | 2025-10-06T23:00:11 | support-asset |  |
| `logo.jpg` | yes | 148.8 KB | 2025-10-06T23:00:11 | support-asset |  |
| `logo2.png` | yes | 571.7 KB | 2025-10-06T23:00:11 | support-asset |  |
| `main.gif` | yes | 20.8 MB | 2025-12-06T18:37:35 | support-asset |  |
| `main_screen.PNG` | yes | 1.1 MB | 2026-01-24T14:09:07 | support-asset |  |
| `mainanimation.usdz` | yes | 46.3 KB | 2025-10-06T23:00:11 | support-asset |  |
| `.gitignore` | yes | 792.0 B | 2026-01-24T15:22:05 | support-config |  |
| `Config.xcconfig.template` | yes | 274.0 B | 2025-11-13T23:07:19 | support-config |  |
| `CLAUDE.md` | yes | 14.0 KB | 2026-01-22T17:25:06 | support-doc-md |  |
| `COMPREHENSIVE_BUG_ANALYSIS.md` | yes | 41.0 KB | 2025-11-13T23:07:19 | support-doc-md |  |
| `DIAGNOSIS.md` | yes | 7.1 KB | 2026-01-22T17:25:06 | support-doc-md |  |
| `Docs/architecture copy.md` | yes | 108.9 KB | 2025-11-13T23:07:19 | support-doc-md |  |
| `Docs/architecture_short copy.md` | yes | 27.5 KB | 2025-10-25T19:13:26 | support-doc-md |  |
| `Docs/chat1.md` | yes | 10.0 KB | 2025-10-06T23:00:11 | support-doc-md |  |
| `Docs/chat2.md` | yes | 6.1 KB | 2025-10-06T23:00:11 | support-doc-md |  |
| `Docs/unused-files-report.md` | no | 46.1 KB | 2026-02-02T18:54:36 | support-doc-md |  |
| `GITHUB_WORKFLOW.md` | yes | 17.4 KB | 2025-10-08T21:12:40 | support-doc-md |  |
| `GPT 5.2 Codex prompt guide_12_03_2025.md` | yes | 32.2 KB | 2026-01-19T12:55:59 | support-doc-md |  |
| `GPT 5.2 prompt guide 12_11_2025.md` | yes | 24.0 KB | 2026-01-19T12:54:51 | support-doc-md |  |
| `OLD_gpt5_1_prompt_guide.md` | yes | 35.9 KB | 2025-11-17T20:54:50 | support-doc-md |  |
| `POST_FIX_AUDIT.md` | yes | 58.5 KB | 2026-01-22T17:25:06 | support-doc-md |  |
| `POST_IX_AUDIT.md` | yes | 5.4 KB | 2026-01-22T17:25:06 | support-doc-md |  |
| `Packages/PulsumML/Sources/PulsumML/AFM/README_FoundationModels.md` | yes | 2.2 KB | 2025-10-09T12:37:18 | support-doc-md |  |
| `Packages/PulsumML/Sources/PulsumML/Resources/README_CreateModel.md` | yes | 645.0 B | 2025-10-09T12:37:18 | support-doc-md |  |
| `README.md` | yes | 20.4 KB | 2026-02-01T12:58:41 | support-doc-md |  |
| `agents.md` | yes | 15.2 KB | 2025-12-28T14:11:26 | support-doc-md |  |
| `appdesign.md` | no | 36.3 KB | 2026-01-25T13:16:28 | support-doc-md |  |
| `architecture.md` | yes | 52.3 KB | 2026-01-22T17:25:06 | support-doc-md |  |
| `architecture_short.md` | yes | 5.9 KB | 2025-10-25T19:16:46 | support-doc-md |  |
| `audit_gate_0_and_1.md` | yes | 11.2 KB | 2025-11-13T23:07:19 | support-doc-md |  |
| `baseline.md` | yes | 75.5 KB | 2026-01-22T16:13:59 | support-doc-md |  |
| `bugs.md` | yes | 99.5 KB | 2025-12-27T14:50:31 | support-doc-md |  |
| `bugsplan.md` | yes | 5.9 KB | 2025-11-09T18:57:46 | support-doc-md |  |
| `calculations.md` | yes | 11.0 KB | 2025-11-02T13:06:07 | support-doc-md |  |
| `coderabit.md` | yes | 9.4 KB | 2025-11-07T11:24:01 | support-doc-md |  |
| `core/pulsum/review.md` | yes | 28.2 KB | 2025-11-02T12:45:35 | support-doc-md |  |
| `core/pulsum/status.md` | yes | 6.0 KB | 2025-11-02T12:59:05 | support-doc-md |  |
| `gate2_summary.md` | yes | 6.8 KB | 2025-11-16T20:06:33 | support-doc-md |  |
| `gate3_summary.md` | yes | 3.4 KB | 2025-11-16T20:10:04 | support-doc-md |  |
| `gate4_summary.md` | yes | 5.0 KB | 2025-11-17T21:00:12 | support-doc-md |  |
| `gate5_summary.md` | yes | 6.1 KB | 2025-11-20T19:23:09 | support-doc-md |  |
| `gate6_analysis.md` | yes | 7.2 KB | 2025-12-27T14:52:29 | support-doc-md |  |
| `gate6_summary.md` | yes | 6.9 KB | 2025-11-23T20:36:45 | support-doc-md |  |
| `gates.md` | yes | 32.1 KB | 2025-11-23T20:36:29 | support-doc-md |  |
| `gates_learnings.md` | yes | 5.7 KB | 2025-11-13T23:07:19 | support-doc-md |  |
| `geminibugs.md` | yes | 6.2 KB | 2025-11-20T19:23:09 | support-doc-md |  |
| `github_cheat_sheet.md` | yes | 7.5 KB | 2025-11-13T23:07:19 | support-doc-md |  |
| `github_master_gate.md` | yes | 8.7 KB | 2025-11-13T23:07:19 | support-doc-md |  |
| `instructions.md` | yes | 32.0 KB | 2025-11-23T20:37:07 | support-doc-md |  |
| `liquidglass.md` | yes | 47.2 KB | 2025-10-06T23:00:11 | support-doc-md |  |
| `openai_summary_chat_gate4.md` | yes | 108.2 KB | 2025-11-17T20:54:50 | support-doc-md |  |
| `review_calculation_summary.md` | yes | 248.0 KB | 2025-11-23T13:24:18 | support-doc-md |  |
| `scorecalculation.md` | yes | 8.6 KB | 2026-01-19T21:01:23 | support-doc-md |  |
| `tests_automation.md` | yes | 10.1 KB | 2025-11-13T23:07:19 | support-doc-md |  |
| `todolist.md` | yes | 22.7 KB | 2025-12-29T00:34:08 | support-doc-md |  |
| `ChatGPT for engineers - Resource _ OpenAI Academy.pdf` | yes | 3.8 MB | 2025-11-02T12:22:13 | support-doc-pdf |  |
| `Docs/a-practical-guide-to-building-with-gpt-5.pdf` | yes | 11.5 MB | 2025-11-17T20:54:50 | support-doc-pdf |  |
| `a-practical-guide-to-building-agents.pdf` | yes | 7.0 MB | 2025-10-06T23:00:11 | support-doc-pdf |  |
| `ios support documents/Adding intelligent app features with generative models _ Apple Developer Documentation.pdf` | yes | 99.0 KB | 2025-10-06T23:00:11 | support-doc-pdf |  |
| `ios support documents/Adopting Liquid Glass _ Apple Developer Documentation.pdf` | yes | 4.6 MB | 2025-10-06T23:00:11 | support-doc-pdf |  |
| `ios support documents/Foundation Models _ Apple Developer Documentation.pdf` | yes | 771.5 KB | 2025-10-06T23:00:11 | support-doc-pdf |  |
| `ios support documents/Generating content and performing tasks with Foundation Models _ Apple Developer Documentation.pdf` | yes | 704.2 KB | 2025-10-06T23:00:11 | support-doc-pdf |  |
| `ios support documents/Improving the safety of generative model output _ Apple Developer Documentation.pdf` | yes | 1.1 MB | 2025-10-06T23:00:11 | support-doc-pdf |  |
| `ios support documents/Landmarks_ Applying a background extension effect _ Apple Developer Documentation.pdf` | yes | 2.0 MB | 2025-10-06T23:00:11 | support-doc-pdf |  |
| `ios support documents/Landmarks_ Building an app with Liquid Glass _ Apple Developer Documentation.pdf` | yes | 7.0 MB | 2025-10-06T23:00:11 | support-doc-pdf |  |
| `ios support documents/Landmarks_ Displaying custom activity badges _ Apple Developer Documentation.pdf` | yes | 1.8 MB | 2025-10-06T23:00:11 | support-doc-pdf |  |
| `ios support documents/Landmarks_ Extending horizontal scrolling under a sidebar or inspector _ Apple Developer Documentation.pdf` | yes | 1.6 MB | 2025-10-06T23:00:11 | support-doc-pdf |  |
| `ios support documents/Landmarks_ Refining the system provided Liquid Glass effect in toolbars _ Apple Developer Documentation.pdf` | yes | 1.3 MB | 2025-10-06T23:00:11 | support-doc-pdf |  |
| `ios support documents/Liquid Glass _ Apple Developer Documentation.pdf` | yes | 4.1 MB | 2025-10-06T23:00:11 | support-doc-pdf |  |
| `ios support documents/Support languages and locales with Foundation Models _ Apple Developer Documentation.pdf` | yes | 379.8 KB | 2025-10-06T23:00:11 | support-doc-pdf |  |
| `ios support documents/SystemLanguageModel _ Apple Developer Documentation.pdf` | yes | 343.4 KB | 2025-10-06T23:00:11 | support-doc-pdf |  |
| `ios support documents/aGenerating content and performing tasks with Foundation Models _ Apple Developer Documentation.pdf` | yes | 703.3 KB | 2025-10-06T23:00:11 | support-doc-pdf |  |
| `ios support documents/iOS & iPadOS 26 Release Notes _ Apple Developer Documentation.pdf` | yes | 1.2 MB | 2025-10-06T23:00:11 | support-doc-pdf |  |
| `Pulsum/PulsumApp.swift` | yes | 671.0 B | 2026-01-23T15:37:50 | unused-candidate |  |
| `ios support files/glow.swift` | yes | 4.5 KB | 2025-10-06T23:00:11 | unused-candidate |  |
| `testfile` | yes | 2.0 B | 2025-10-25T21:29:38 | unused-candidate |  |
| `.github/coderabbit.yaml` | yes | 2.8 KB | 2025-10-08T21:10:32 | used-build-runtime | ci:github |
| `.github/workflows/auto-merge.yml` | yes | 3.5 KB | 2025-10-08T21:11:08 | used-build-runtime | ci:github |
| `.github/workflows/auto-pr.yml` | yes | 2.5 KB | 2025-10-08T21:10:48 | used-build-runtime | ci:github |
| `.github/workflows/test-harness.yml` | yes | 484.0 B | 2025-11-20T19:23:09 | used-build-runtime | ci:github |
| `Config.xcconfig` | yes | 260.0 B | 2025-11-08T16:56:13 | used-build-runtime | pbx:baseConfig |
| `Packages/PulsumAgents/Package.swift` | yes | 1.3 KB | 2026-01-22T17:25:06 | used-build-runtime | swiftpm:manifest |
| `Packages/PulsumAgents/Sources/PulsumAgents/AgentOrchestrator.swift` | yes | 45.4 KB | 2026-01-22T23:58:34 | used-build-runtime | swiftpm:target PulsumAgents |
| `Packages/PulsumAgents/Sources/PulsumAgents/BackfillStateStore.swift` | yes | 5.7 KB | 2025-12-29T00:31:05 | used-build-runtime | swiftpm:target PulsumAgents |
| `Packages/PulsumAgents/Sources/PulsumAgents/CheerAgent.swift` | yes | 1.2 KB | 2025-10-09T12:37:18 | used-build-runtime | swiftpm:target PulsumAgents |
| `Packages/PulsumAgents/Sources/PulsumAgents/CoachAgent+Coverage.swift` | yes | 4.0 KB | 2025-12-28T23:24:57 | used-build-runtime | swiftpm:target PulsumAgents |
| `Packages/PulsumAgents/Sources/PulsumAgents/CoachAgent.swift` | yes | 31.4 KB | 2026-01-22T17:25:06 | used-build-runtime | swiftpm:target PulsumAgents |
| `Packages/PulsumAgents/Sources/PulsumAgents/DataAgent.swift` | yes | 171.2 KB | 2026-01-22T17:25:06 | used-build-runtime | swiftpm:target PulsumAgents |
| `Packages/PulsumAgents/Sources/PulsumAgents/EstimatorStateStore.swift` | yes | 3.9 KB | 2025-12-29T00:31:22 | used-build-runtime | swiftpm:target PulsumAgents |
| `Packages/PulsumAgents/Sources/PulsumAgents/HealthAccessStatus.swift` | yes | 1.4 KB | 2025-11-16T20:06:33 | used-build-runtime | swiftpm:target PulsumAgents |
| `Packages/PulsumAgents/Sources/PulsumAgents/PrivacyInfo.xcprivacy` | yes | 559.0 B | 2025-11-09T18:57:47 | used-build-runtime | swiftpm:resource PulsumAgents |
| `Packages/PulsumAgents/Sources/PulsumAgents/PulsumAgents.swift` | yes | 855.0 B | 2025-10-09T12:37:18 | used-build-runtime | swiftpm:target PulsumAgents |
| `Packages/PulsumAgents/Sources/PulsumAgents/RecRankerStateStore.swift` | yes | 3.8 KB | 2025-12-29T00:30:46 | used-build-runtime | swiftpm:target PulsumAgents |
| `Packages/PulsumAgents/Sources/PulsumAgents/SafetyAgent.swift` | yes | 3.3 KB | 2025-12-28T23:24:39 | used-build-runtime | swiftpm:target PulsumAgents |
| `Packages/PulsumAgents/Sources/PulsumAgents/SentimentAgent.swift` | yes | 15.5 KB | 2026-01-25T13:35:55 | used-build-runtime | swiftpm:target PulsumAgents |
| `Packages/PulsumAgents/Sources/PulsumAgents/WellbeingScoreState.swift` | yes | 383.0 B | 2026-01-22T17:25:06 | used-build-runtime | swiftpm:target PulsumAgents |
| `Packages/PulsumAgents/Tests/PulsumAgentsTests/Resources/library_retry_test.json` | yes | 513.0 B | 2026-01-22T17:25:06 | used-build-runtime | swiftpm:resource PulsumAgentsTests; test-ref:Packages/PulsumAgents/Tests/PulsumAgentsTests/LibraryImportRetryTests.swift |
| `Packages/PulsumData/Package.swift` | yes | 1.0 KB | 2025-12-28T23:20:44 | used-build-runtime | swiftpm:manifest |
| `Packages/PulsumData/Sources/PulsumData/Bundle+PulsumDataResources.swift` | yes | 295.0 B | 2025-11-13T23:07:19 | used-build-runtime | swiftpm:target PulsumData |
| `Packages/PulsumData/Sources/PulsumData/DataStack.swift` | yes | 7.0 KB | 2025-12-29T00:31:35 | used-build-runtime | swiftpm:target PulsumData |
| `Packages/PulsumData/Sources/PulsumData/EvidenceScorer.swift` | yes | 957.0 B | 2025-10-06T23:00:11 | used-build-runtime | swiftpm:target PulsumData |
| `Packages/PulsumData/Sources/PulsumData/LibraryImporter.swift` | yes | 16.7 KB | 2026-01-22T18:16:10 | used-build-runtime | swiftpm:target PulsumData |
| `Packages/PulsumData/Sources/PulsumData/Model/ManagedObjects.swift` | yes | 4.9 KB | 2025-10-06T23:00:11 | used-build-runtime | swiftpm:target PulsumData |
| `Packages/PulsumData/Sources/PulsumData/PrivacyInfo.xcprivacy` | yes | 559.0 B | 2025-11-09T18:57:47 | used-build-runtime | swiftpm:resource PulsumData |
| `Packages/PulsumData/Sources/PulsumData/PulsumData.swift` | yes | 1.9 KB | 2025-11-09T18:57:47 | used-build-runtime | swiftpm:target PulsumData |
| `Packages/PulsumData/Sources/PulsumData/PulsumManagedObjectModel.swift` | yes | 4.4 KB | 2025-12-28T15:48:53 | used-build-runtime | swiftpm:target PulsumData |
| `Packages/PulsumData/Sources/PulsumData/Resources/Pulsum.xcdatamodeld/.xccurrentversion` | yes | 259.0 B | 2025-11-20T19:23:09 | used-build-runtime | swiftpm:resource PulsumData |
| `Packages/PulsumData/Sources/PulsumData/Resources/Pulsum.xcdatamodeld/Pulsum.xcdatamodel/contents` | yes | 7.6 KB | 2025-11-20T19:23:09 | used-build-runtime | runtime-ref:Packages/PulsumData/Sources/PulsumData/PulsumManagedObjectModel.swift; swiftpm:resource PulsumData |
| `Packages/PulsumData/Sources/PulsumData/Resources/PulsumCompiled.momd/Pulsum.mom` | yes | 8.8 KB | 2025-12-28T15:47:53 | used-build-runtime | runtime-ref:Packages/PulsumData/Sources/PulsumData/PulsumManagedObjectModel.swift; swiftpm:resource PulsumData |
| `Packages/PulsumData/Sources/PulsumData/Resources/PulsumCompiled.momd/Pulsum.omo` | yes | 21.6 KB | 2025-12-28T15:47:53 | used-build-runtime | swiftpm:resource PulsumData |
| `Packages/PulsumData/Sources/PulsumData/Resources/PulsumCompiled.momd/VersionInfo.plist` | yes | 743.0 B | 2025-12-28T15:47:53 | used-build-runtime | swiftpm:resource PulsumData |
| `Packages/PulsumData/Sources/PulsumData/VectorIndex.swift` | yes | 16.4 KB | 2025-12-28T23:23:25 | used-build-runtime | swiftpm:target PulsumData |
| `Packages/PulsumData/Sources/PulsumData/VectorIndexManager.swift` | yes | 2.0 KB | 2025-12-28T23:27:50 | used-build-runtime | swiftpm:target PulsumData |
| `Packages/PulsumData/Tests/PulsumDataTests/Resources/podcasts_sample.json` | yes | 785.0 B | 2025-10-06T23:00:11 | used-build-runtime | swiftpm:resource PulsumDataTests; test-ref:Packages/PulsumData/Tests/PulsumDataTests/Gate5_LibraryImporterAtomicityTests.swift |
| `Packages/PulsumML/Package.swift` | yes | 1.2 KB | 2025-12-28T22:23:08 | used-build-runtime | swiftpm:manifest |
| `Packages/PulsumML/Sources/PulsumML/AFM/FoundationModelsAvailability.swift` | yes | 1.5 KB | 2025-10-09T12:37:17 | used-build-runtime | swiftpm:target PulsumML |
| `Packages/PulsumML/Sources/PulsumML/AFM/FoundationModelsStub.swift` | yes | 2.0 KB | 2025-11-13T23:07:19 | used-build-runtime | swiftpm:target PulsumML |
| `Packages/PulsumML/Sources/PulsumML/BaselineMath.swift` | yes | 1.4 KB | 2025-10-06T23:00:11 | used-build-runtime | swiftpm:target PulsumML |
| `Packages/PulsumML/Sources/PulsumML/Bundle+PulsumMLResources.swift` | yes | 271.0 B | 2025-11-13T23:07:19 | used-build-runtime | swiftpm:target PulsumML |
| `Packages/PulsumML/Sources/PulsumML/Embedding/AFMTextEmbeddingProvider.swift` | yes | 1.9 KB | 2025-11-21T16:58:05 | used-build-runtime | swiftpm:target PulsumML |
| `Packages/PulsumML/Sources/PulsumML/Embedding/CoreMLEmbeddingFallbackProvider.swift` | yes | 2.2 KB | 2025-11-21T16:58:21 | used-build-runtime | swiftpm:target PulsumML |
| `Packages/PulsumML/Sources/PulsumML/Embedding/EmbeddingError.swift` | yes | 401.0 B | 2025-10-06T23:00:11 | used-build-runtime | swiftpm:target PulsumML |
| `Packages/PulsumML/Sources/PulsumML/Embedding/EmbeddingService.swift` | yes | 15.3 KB | 2025-12-28T22:24:20 | used-build-runtime | swiftpm:target PulsumML |
| `Packages/PulsumML/Sources/PulsumML/Embedding/TextEmbeddingProviding.swift` | yes | 184.0 B | 2025-10-06T23:00:11 | used-build-runtime | swiftpm:target PulsumML |
| `Packages/PulsumML/Sources/PulsumML/Placeholder.swift` | yes | 380.0 B | 2025-11-20T19:41:38 | used-build-runtime | swiftpm:target PulsumML |
| `Packages/PulsumML/Sources/PulsumML/PrivacyInfo.xcprivacy` | yes | 559.0 B | 2025-11-09T18:57:47 | used-build-runtime | swiftpm:resource PulsumML |
| `Packages/PulsumML/Sources/PulsumML/RecRanker.swift` | yes | 5.9 KB | 2025-11-21T22:47:42 | used-build-runtime | swiftpm:target PulsumML |
| `Packages/PulsumML/Sources/PulsumML/Resources/PulsumFallbackEmbedding.mlmodel` | yes | 401.2 KB | 2025-10-06T23:00:11 | used-build-runtime | runtime-ref:Packages/PulsumML/Sources/PulsumML/Embedding/CoreMLEmbeddingFallbackProvider.swift; swiftpm:resource PulsumML |
| `Packages/PulsumML/Sources/PulsumML/Resources/PulsumSentimentCoreML.mlmodel` | yes | 5.4 KB | 2025-10-06T23:00:11 | used-build-runtime | runtime-ref:Packages/PulsumML/Sources/PulsumML/Sentiment/CoreMLSentimentProvider.swift; swiftpm:resource PulsumML |
| `Packages/PulsumML/Sources/PulsumML/Safety/FoundationModelsSafetyProvider.swift` | yes | 3.4 KB | 2025-11-13T23:07:19 | used-build-runtime | swiftpm:target PulsumML |
| `Packages/PulsumML/Sources/PulsumML/SafetyLocal.swift` | yes | 8.5 KB | 2026-01-24T15:43:42 | used-build-runtime | swiftpm:target PulsumML |
| `Packages/PulsumML/Sources/PulsumML/Sentiment/AFMSentimentProvider.swift` | yes | 2.7 KB | 2025-11-20T19:42:22 | used-build-runtime | swiftpm:target PulsumML |
| `Packages/PulsumML/Sources/PulsumML/Sentiment/CoreMLSentimentProvider.swift` | yes | 1.4 KB | 2025-11-13T23:07:19 | used-build-runtime | swiftpm:target PulsumML |
| `Packages/PulsumML/Sources/PulsumML/Sentiment/FoundationModelsSentimentProvider.swift` | yes | 2.4 KB | 2025-11-13T23:07:19 | used-build-runtime | swiftpm:target PulsumML |
| `Packages/PulsumML/Sources/PulsumML/Sentiment/NaturalLanguageSentimentProvider.swift` | yes | 721.0 B | 2025-10-09T12:37:17 | used-build-runtime | swiftpm:target PulsumML |
| `Packages/PulsumML/Sources/PulsumML/Sentiment/PIIRedactor.swift` | yes | 1.5 KB | 2025-10-06T23:00:11 | used-build-runtime | swiftpm:target PulsumML |
| `Packages/PulsumML/Sources/PulsumML/Sentiment/SentimentProviding.swift` | yes | 556.0 B | 2025-10-09T12:37:17 | used-build-runtime | swiftpm:target PulsumML |
| `Packages/PulsumML/Sources/PulsumML/Sentiment/SentimentService.swift` | yes | 1.3 KB | 2025-10-09T12:37:17 | used-build-runtime | swiftpm:target PulsumML |
| `Packages/PulsumML/Sources/PulsumML/StateEstimator.swift` | yes | 3.8 KB | 2025-11-20T19:35:13 | used-build-runtime | swiftpm:target PulsumML |
| `Packages/PulsumML/Sources/PulsumML/TopicGate/EmbeddingTopicGateProvider.swift` | yes | 7.0 KB | 2025-12-27T14:54:16 | used-build-runtime | swiftpm:target PulsumML |
| `Packages/PulsumML/Sources/PulsumML/TopicGate/FoundationModelsTopicGateProvider.swift` | yes | 2.7 KB | 2025-11-13T23:07:19 | used-build-runtime | swiftpm:target PulsumML |
| `Packages/PulsumML/Sources/PulsumML/TopicGate/TopicGateProviding.swift` | yes | 1017.0 B | 2025-10-06T23:00:11 | used-build-runtime | swiftpm:target PulsumML |
| `Packages/PulsumServices/Package.swift` | yes | 1.0 KB | 2025-11-13T23:07:19 | used-build-runtime | swiftpm:manifest |
| `Packages/PulsumServices/Sources/PulsumServices/BuildFlags.swift` | yes | 732.0 B | 2025-11-13T23:07:19 | used-build-runtime | swiftpm:target PulsumServices |
| `Packages/PulsumServices/Sources/PulsumServices/Bundle+PulsumServicesResources.swift` | yes | 311.0 B | 2025-11-13T23:07:19 | used-build-runtime | swiftpm:target PulsumServices |
| `Packages/PulsumServices/Sources/PulsumServices/CoachPhrasingSchema.swift` | yes | 2.3 KB | 2025-10-06T23:00:11 | used-build-runtime | swiftpm:target PulsumServices |
| `Packages/PulsumServices/Sources/PulsumServices/FoundationModelsCoachGenerator.swift` | yes | 4.8 KB | 2025-10-09T12:37:18 | used-build-runtime | swiftpm:target PulsumServices |
| `Packages/PulsumServices/Sources/PulsumServices/HealthKitAnchorStore.swift` | yes | 3.1 KB | 2025-12-29T00:35:59 | used-build-runtime | swiftpm:target PulsumServices |
| `Packages/PulsumServices/Sources/PulsumServices/HealthKitService.swift` | yes | 32.6 KB | 2026-01-24T14:09:07 | used-build-runtime | swiftpm:target PulsumServices |
| `Packages/PulsumServices/Sources/PulsumServices/KeychainService.swift` | yes | 4.6 KB | 2026-01-23T00:03:57 | used-build-runtime | swiftpm:target PulsumServices |
| `Packages/PulsumServices/Sources/PulsumServices/LLMGateway.swift` | yes | 36.3 KB | 2026-01-22T23:58:25 | used-build-runtime | swiftpm:target PulsumServices |
| `Packages/PulsumServices/Sources/PulsumServices/Placeholder.swift` | yes | 543.0 B | 2025-10-06T23:00:11 | used-build-runtime | swiftpm:target PulsumServices |
| `Packages/PulsumServices/Sources/PulsumServices/PrivacyInfo.xcprivacy` | yes | 559.0 B | 2025-11-09T18:57:47 | used-build-runtime | swiftpm:resource PulsumServices |
| `Packages/PulsumServices/Sources/PulsumServices/SpeechService.swift` | yes | 20.3 KB | 2026-01-23T15:41:32 | used-build-runtime | swiftpm:target PulsumServices |
| `Packages/PulsumTypes/Package.swift` | yes | 541.0 B | 2025-12-28T23:33:50 | used-build-runtime | swiftpm:manifest |
| `Packages/PulsumTypes/Sources/PulsumTypes/AppRuntimeConfig.swift` | yes | 2.0 KB | 2026-01-23T15:37:28 | used-build-runtime | swiftpm:target PulsumTypes |
| `Packages/PulsumTypes/Sources/PulsumTypes/DebugLog.swift` | yes | 1.2 KB | 2026-01-22T17:25:06 | used-build-runtime | swiftpm:target PulsumTypes |
| `Packages/PulsumTypes/Sources/PulsumTypes/DiagnosticsLogger.swift` | yes | 19.6 KB | 2026-01-22T17:25:06 | used-build-runtime | swiftpm:target PulsumTypes |
| `Packages/PulsumTypes/Sources/PulsumTypes/DiagnosticsPaths.swift` | yes | 1.2 KB | 2026-01-22T17:25:06 | used-build-runtime | swiftpm:target PulsumTypes |
| `Packages/PulsumTypes/Sources/PulsumTypes/DiagnosticsReport.swift` | yes | 6.0 KB | 2026-01-22T17:25:06 | used-build-runtime | swiftpm:target PulsumTypes |
| `Packages/PulsumTypes/Sources/PulsumTypes/DiagnosticsTypes.swift` | yes | 8.4 KB | 2025-12-29T11:59:15 | used-build-runtime | swiftpm:target PulsumTypes |
| `Packages/PulsumTypes/Sources/PulsumTypes/Notifications.swift` | yes | 393.0 B | 2025-11-13T23:07:19 | used-build-runtime | swiftpm:target PulsumTypes |
| `Packages/PulsumTypes/Sources/PulsumTypes/SpeechTypes.swift` | yes | 360.0 B | 2025-11-13T23:07:19 | used-build-runtime | swiftpm:target PulsumTypes |
| `Packages/PulsumTypes/Sources/PulsumTypes/Timeout.swift` | yes | 3.1 KB | 2026-01-22T17:25:06 | used-build-runtime | swiftpm:target PulsumTypes |
| `Packages/PulsumTypes/Sources/PulsumTypes/WellbeingSnapshotKind.swift` | yes | 105.0 B | 2026-01-22T17:25:06 | used-build-runtime | swiftpm:target PulsumTypes |
| `Packages/PulsumUI/Package.swift` | yes | 982.0 B | 2026-01-22T17:25:06 | used-build-runtime | swiftpm:manifest |
| `Packages/PulsumUI/Sources/PulsumUI/AppViewModel.swift` | yes | 22.0 KB | 2026-01-23T15:41:23 | used-build-runtime | swiftpm:target PulsumUI |
| `Packages/PulsumUI/Sources/PulsumUI/CoachView.swift` | yes | 15.9 KB | 2026-01-23T15:38:08 | used-build-runtime | swiftpm:target PulsumUI |
| `Packages/PulsumUI/Sources/PulsumUI/CoachViewModel.swift` | yes | 18.2 KB | 2026-01-23T21:50:07 | used-build-runtime | swiftpm:target PulsumUI |
| `Packages/PulsumUI/Sources/PulsumUI/ConsentBannerView.swift` | yes | 2.3 KB | 2025-10-19T15:34:34 | used-build-runtime | swiftpm:target PulsumUI |
| `Packages/PulsumUI/Sources/PulsumUI/GlassEffect.swift` | yes | 4.8 KB | 2025-10-06T23:00:11 | used-build-runtime | swiftpm:target PulsumUI |
| `Packages/PulsumUI/Sources/PulsumUI/HealthAccessRequirement.swift` | yes | 2.5 KB | 2025-11-16T20:06:33 | used-build-runtime | swiftpm:target PulsumUI |
| `Packages/PulsumUI/Sources/PulsumUI/LiquidGlassComponents.swift` | yes | 7.0 KB | 2025-10-06T23:00:11 | used-build-runtime | swiftpm:target PulsumUI |
| `Packages/PulsumUI/Sources/PulsumUI/LiveWaveformLevels.swift` | yes | 1.6 KB | 2025-11-13T23:07:19 | used-build-runtime | swiftpm:target PulsumUI |
| `Packages/PulsumUI/Sources/PulsumUI/OnboardingView.swift` | yes | 14.0 KB | 2025-11-16T20:06:33 | used-build-runtime | swiftpm:target PulsumUI |
| `Packages/PulsumUI/Sources/PulsumUI/PrivacyInfo.xcprivacy` | yes | 559.0 B | 2025-11-09T18:57:47 | used-build-runtime | swiftpm:resource PulsumUI |
| `Packages/PulsumUI/Sources/PulsumUI/PulseView.swift` | yes | 16.4 KB | 2025-11-21T12:10:02 | used-build-runtime | swiftpm:target PulsumUI |
| `Packages/PulsumUI/Sources/PulsumUI/PulseViewModel.swift` | yes | 9.0 KB | 2025-12-28T23:29:19 | used-build-runtime | swiftpm:target PulsumUI |
| `Packages/PulsumUI/Sources/PulsumUI/PulsumDesignSystem.swift` | yes | 7.7 KB | 2025-10-19T15:34:34 | used-build-runtime | swiftpm:target PulsumUI |
| `Packages/PulsumUI/Sources/PulsumUI/PulsumRootView.swift` | yes | 14.4 KB | 2026-01-23T15:38:01 | used-build-runtime | swiftpm:target PulsumUI |
| `Packages/PulsumUI/Sources/PulsumUI/SafetyCardView.swift` | yes | 3.0 KB | 2025-10-19T15:34:34 | used-build-runtime | swiftpm:target PulsumUI |
| `Packages/PulsumUI/Sources/PulsumUI/ScoreBreakdownView.swift` | yes | 19.1 KB | 2025-11-21T23:42:23 | used-build-runtime | swiftpm:target PulsumUI |
| `Packages/PulsumUI/Sources/PulsumUI/ScoreBreakdownViewModel.swift` | yes | 2.0 KB | 2025-10-06T23:00:11 | used-build-runtime | swiftpm:target PulsumUI |
| `Packages/PulsumUI/Sources/PulsumUI/SettingsView.swift` | yes | 51.3 KB | 2026-01-23T19:19:00 | used-build-runtime | swiftpm:target PulsumUI |
| `Packages/PulsumUI/Sources/PulsumUI/SettingsViewModel.swift` | yes | 18.0 KB | 2026-01-23T19:19:15 | used-build-runtime | swiftpm:target PulsumUI |
| `Pulsum.xcodeproj/project.pbxproj` | yes | 32.3 KB | 2026-01-25T14:08:42 | used-build-runtime | xcodeproj |
| `Pulsum.xcodeproj/project.xcworkspace/contents.xcworkspacedata` | yes | 135.0 B | 2025-09-28T18:53:36 | used-build-runtime | xcodeproj; xcworkspace |
| `Pulsum.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved` | yes | 389.0 B | 2026-01-25T14:08:32 | used-build-runtime | xcodeproj; xcworkspace |
| `Pulsum.xcodeproj/xcshareddata/xcschemes/Pulsum.xcscheme` | yes | 6.1 KB | 2026-01-25T13:36:54 | used-build-runtime | xcodeproj |
| `Pulsum.xcodeproj/xcshareddata/xcschemes/PulsumUI.xcscheme` | yes | 3.2 KB | 2026-01-25T13:36:54 | used-build-runtime | xcodeproj |
| `Pulsum/Assets.xcassets/AccentColor.colorset/Contents.json` | yes | 123.0 B | 2025-09-28T18:53:35 | used-build-runtime | assets.xcassets |
| `Pulsum/Assets.xcassets/AppIcon.appiconset/Contents.json` | yes | 713.0 B | 2025-11-15T18:15:56 | used-build-runtime | assets.xcassets |
| `Pulsum/Assets.xcassets/AppIcon.appiconset/iconnew 1.png` | yes | 980.1 KB | 2025-11-16T20:06:33 | used-build-runtime | assets.xcassets |
| `Pulsum/Assets.xcassets/AppIcon.appiconset/iconnew 2.png` | yes | 980.1 KB | 2025-11-16T20:06:33 | used-build-runtime | assets.xcassets |
| `Pulsum/Assets.xcassets/AppIcon.appiconset/iconnew.png` | yes | 980.1 KB | 2025-11-16T20:06:33 | used-build-runtime | assets.xcassets |
| `Pulsum/Assets.xcassets/Contents.json` | yes | 63.0 B | 2025-09-30T22:02:05 | used-build-runtime | assets.xcassets |
| `Pulsum/PrivacyInfo.xcprivacy` | yes | 559.0 B | 2025-11-09T18:57:47 | used-build-runtime | pbx:resources |
| `Pulsum/Pulsum.entitlements` | yes | 310.0 B | 2025-11-13T23:07:19 | used-build-runtime | pbx:CODE_SIGN_ENTITLEMENTS |
| `PulsumDiagnostics-Latest.txt` | yes | 42.6 KB | 2025-12-29T21:15:23 | used-build-runtime | runtime-ref:Packages/PulsumTypes/Sources/PulsumTypes/DiagnosticsReport.swift |
| `podcastrecommendations 2.json` | yes | 51.5 KB | 2025-10-06T23:00:11 | used-build-runtime | pbx:resources |
| `scripts/ci/build-release.sh` | yes | 265.0 B | 2025-11-09T18:57:47 | used-build-runtime | ci:scripts |
| `scripts/ci/check-privacy-manifests.sh` | yes | 3.2 KB | 2025-11-09T18:57:47 | used-build-runtime | ci:scripts |
| `scripts/ci/integrity.sh` | yes | 7.9 KB | 2025-11-20T19:23:09 | used-build-runtime | ci:scripts |
| `scripts/ci/scan-placeholders.sh` | yes | 632.0 B | 2025-11-13T23:07:19 | used-build-runtime | ci:scripts |
| `scripts/ci/scan-secrets.sh` | yes | 1.9 KB | 2025-11-09T18:57:47 | used-build-runtime | ci:scripts |
| `scripts/ci/test-harness.sh` | yes | 8.0 KB | 2026-01-22T19:11:23 | used-build-runtime | ci:scripts |
| `scripts/ci/ui-tests.sh` | yes | 1.3 KB | 2026-01-22T19:11:15 | used-build-runtime | ci:scripts |
| `streak_low_poly_copy.splineswift` | yes | 48.3 KB | 2025-10-06T23:00:11 | used-build-runtime | pbx:resources |
| `Packages/PulsumAgents/Tests/PulsumAgentsTests/AgentSystemTests.swift` | yes | 2.8 KB | 2025-11-17T20:54:50 | used-test-only | swiftpm:test-target PulsumAgentsTests; test-source |
| `Packages/PulsumAgents/Tests/PulsumAgentsTests/ChatGuardrailAcceptanceTests.swift` | yes | 10.6 KB | 2025-12-29T00:39:17 | used-test-only | swiftpm:test-target PulsumAgentsTests; test-source |
| `Packages/PulsumAgents/Tests/PulsumAgentsTests/ChatGuardrailTests.swift` | yes | 8.9 KB | 2025-11-17T20:54:50 | used-test-only | swiftpm:test-target PulsumAgentsTests; test-source |
| `Packages/PulsumAgents/Tests/PulsumAgentsTests/CoachAgentKeywordFallbackTests.swift` | yes | 2.3 KB | 2026-01-22T17:25:06 | used-test-only | swiftpm:test-target PulsumAgentsTests; test-source |
| `Packages/PulsumAgents/Tests/PulsumAgentsTests/DebugLogBufferTests.swift` | yes | 901.0 B | 2025-12-27T14:45:10 | used-test-only | swiftpm:test-target PulsumAgentsTests; test-source |
| `Packages/PulsumAgents/Tests/PulsumAgentsTests/Gate2_JournalSessionTests.swift` | yes | 1.3 KB | 2025-11-13T23:07:19 | used-test-only | swiftpm:test-target PulsumAgentsTests; test-source |
| `Packages/PulsumAgents/Tests/PulsumAgentsTests/Gate2_OrchestratorLLMKeyAPITests.swift` | yes | 6.0 KB | 2025-12-28T23:35:23 | used-test-only | swiftpm:test-target PulsumAgentsTests; test-source |
| `Packages/PulsumAgents/Tests/PulsumAgentsTests/Gate2_TypesWiringTests.swift` | yes | 354.0 B | 2025-11-13T23:07:19 | used-test-only | swiftpm:test-target PulsumAgentsTests; test-source |
| `Packages/PulsumAgents/Tests/PulsumAgentsTests/Gate3_FreshnessBusTests.swift` | yes | 2.6 KB | 2025-12-28T14:07:34 | used-test-only | swiftpm:test-target PulsumAgentsTests; test-source |
| `Packages/PulsumAgents/Tests/PulsumAgentsTests/Gate3_HealthAccessStatusTests.swift` | yes | 4.5 KB | 2025-12-28T17:54:10 | used-test-only | swiftpm:test-target PulsumAgentsTests; test-source |
| `Packages/PulsumAgents/Tests/PulsumAgentsTests/Gate3_IngestionIdempotenceTests.swift` | yes | 2.1 KB | 2025-12-28T17:54:19 | used-test-only | swiftpm:test-target PulsumAgentsTests; test-source |
| `Packages/PulsumAgents/Tests/PulsumAgentsTests/Gate4_ConsentRoutingTests.swift` | yes | 3.8 KB | 2026-01-22T18:01:19 | used-test-only | swiftpm:test-target PulsumAgentsTests; test-source |
| `Packages/PulsumAgents/Tests/PulsumAgentsTests/Gate4_LLMKeyTests.swift` | yes | 1.5 KB | 2025-11-17T20:54:50 | used-test-only | swiftpm:test-target PulsumAgentsTests; test-source |
| `Packages/PulsumAgents/Tests/PulsumAgentsTests/Gate4_RoutingTests.swift` | yes | 4.0 KB | 2025-12-27T14:59:09 | used-test-only | swiftpm:test-target PulsumAgentsTests; test-source |
| `Packages/PulsumAgents/Tests/PulsumAgentsTests/Gate6_EmbeddingAvailabilityDegradationTests.swift` | yes | 2.8 KB | 2025-12-28T14:10:42 | used-test-only | swiftpm:test-target PulsumAgentsTests; test-source |
| `Packages/PulsumAgents/Tests/PulsumAgentsTests/Gate6_RecRankerLearningTests.swift` | yes | 2.9 KB | 2025-12-28T14:09:55 | used-test-only | swiftpm:test-target PulsumAgentsTests; test-source |
| `Packages/PulsumAgents/Tests/PulsumAgentsTests/Gate6_RecRankerPersistenceTests.swift` | yes | 3.1 KB | 2025-12-28T14:10:06 | used-test-only | swiftpm:test-target PulsumAgentsTests; test-source |
| `Packages/PulsumAgents/Tests/PulsumAgentsTests/Gate6_SentimentJournalingFallbackTests.swift` | yes | 1.5 KB | 2025-12-28T14:09:44 | used-test-only | swiftpm:test-target PulsumAgentsTests; test-source |
| `Packages/PulsumAgents/Tests/PulsumAgentsTests/Gate6_StateEstimatorPersistenceTests.swift` | yes | 1.8 KB | 2025-12-28T14:10:26 | used-test-only | swiftpm:test-target PulsumAgentsTests; test-source |
| `Packages/PulsumAgents/Tests/PulsumAgentsTests/Gate6_StateEstimatorWeightsAndLabelsTests.swift` | yes | 2.7 KB | 2025-12-28T14:10:18 | used-test-only | swiftpm:test-target PulsumAgentsTests; test-source |
| `Packages/PulsumAgents/Tests/PulsumAgentsTests/Gate6_WellbeingBackfillPhasingTests.swift` | yes | 15.1 KB | 2026-01-24T14:09:07 | used-test-only | swiftpm:test-target PulsumAgentsTests; test-source |
| `Packages/PulsumAgents/Tests/PulsumAgentsTests/Gate6_WellbeingStateMappingTests.swift` | yes | 2.1 KB | 2025-12-28T14:10:34 | used-test-only | swiftpm:test-target PulsumAgentsTests; test-source |
| `Packages/PulsumAgents/Tests/PulsumAgentsTests/Gate7_FirstRunWatchdogTests.swift` | yes | 4.4 KB | 2026-01-22T17:25:06 | used-test-only | swiftpm:test-target PulsumAgentsTests; test-source |
| `Packages/PulsumAgents/Tests/PulsumAgentsTests/HealthKitServiceStub.swift` | yes | 5.5 KB | 2025-12-28T17:50:58 | used-test-only | swiftpm:test-target PulsumAgentsTests; test-source |
| `Packages/PulsumAgents/Tests/PulsumAgentsTests/LibraryImportRetryTests.swift` | yes | 2.2 KB | 2026-01-22T17:25:06 | used-test-only | swiftpm:test-target PulsumAgentsTests; test-source |
| `Packages/PulsumAgents/Tests/PulsumAgentsTests/RecommendationsTimeoutTests.swift` | yes | 5.7 KB | 2026-01-22T17:25:06 | used-test-only | swiftpm:test-target PulsumAgentsTests; test-source |
| `Packages/PulsumAgents/Tests/PulsumAgentsTests/TestCoreDataStack.swift` | yes | 904.0 B | 2025-12-28T15:40:37 | used-test-only | swiftpm:test-target PulsumAgentsTests; test-source |
| `Packages/PulsumAgents/Tests/PulsumAgentsTests/TestHealthKitSampleSeeder.swift` | yes | 5.2 KB | 2026-01-22T17:25:06 | used-test-only | swiftpm:test-target PulsumAgentsTests; test-source |
| `Packages/PulsumData/Tests/PulsumDataTests/DataStackSecurityTests.swift` | yes | 1.1 KB | 2025-11-09T18:57:47 | used-test-only | swiftpm:test-target PulsumDataTests; test-source |
| `Packages/PulsumData/Tests/PulsumDataTests/Gate0_DataStackSecurityTests.swift` | yes | 994.0 B | 2025-11-09T18:57:47 | used-test-only | swiftpm:test-target PulsumDataTests; test-source |
| `Packages/PulsumData/Tests/PulsumDataTests/Gate5_LibraryImporterAtomicityTests.swift` | yes | 11.5 KB | 2026-01-22T18:16:54 | used-test-only | swiftpm:test-target PulsumDataTests; test-source |
| `Packages/PulsumData/Tests/PulsumDataTests/Gate5_LibraryImporterPerfTests.swift` | yes | 1.2 KB | 2025-11-20T19:23:09 | used-test-only | swiftpm:test-target PulsumDataTests; test-source |
| `Packages/PulsumData/Tests/PulsumDataTests/Gate5_VectorIndexConcurrencyTests.swift` | yes | 2.5 KB | 2025-11-20T19:23:09 | used-test-only | swiftpm:test-target PulsumDataTests; test-source |
| `Packages/PulsumData/Tests/PulsumDataTests/Gate5_VectorIndexFileHandleTests.swift` | yes | 2.5 KB | 2025-11-20T19:23:09 | used-test-only | swiftpm:test-target PulsumDataTests; test-source |
| `Packages/PulsumData/Tests/PulsumDataTests/Gate5_VectorIndexManagerActorTests.swift` | yes | 1.9 KB | 2025-11-20T19:23:09 | used-test-only | swiftpm:test-target PulsumDataTests; test-source |
| `Packages/PulsumData/Tests/PulsumDataTests/LibraryImporterTests.swift` | yes | 2.4 KB | 2025-12-06T12:45:07 | used-test-only | swiftpm:test-target PulsumDataTests; test-source |
| `Packages/PulsumData/Tests/PulsumDataTests/PulsumDataBootstrapTests.swift` | yes | 1.1 KB | 2025-10-06T23:00:11 | used-test-only | swiftpm:test-target PulsumDataTests; test-source |
| `Packages/PulsumData/Tests/PulsumDataTests/VectorIndexTests.swift` | yes | 817.0 B | 2025-12-29T00:37:35 | used-test-only | swiftpm:test-target PulsumDataTests; test-source |
| `Packages/PulsumML/Tests/PulsumMLTests/EmbeddingServiceAvailabilityTests.swift` | yes | 2.5 KB | 2025-11-21T22:49:03 | used-test-only | swiftpm:test-target PulsumMLTests; test-source |
| `Packages/PulsumML/Tests/PulsumMLTests/EmbeddingServiceFallbackTests.swift` | yes | 942.0 B | 2025-11-20T19:43:58 | used-test-only | swiftpm:test-target PulsumMLTests; test-source |
| `Packages/PulsumML/Tests/PulsumMLTests/Gate0_EmbeddingServiceFallbackTests.swift` | yes | 1.3 KB | 2025-11-21T16:59:16 | used-test-only | swiftpm:test-target PulsumMLTests; test-source |
| `Packages/PulsumML/Tests/PulsumMLTests/Gate6_EmbeddingProviderContextualTests.swift` | yes | 2.4 KB | 2025-11-21T16:59:06 | used-test-only | swiftpm:test-target PulsumMLTests; test-source |
| `Packages/PulsumML/Tests/PulsumMLTests/PackageEmbedTests.swift` | yes | 5.2 KB | 2025-12-27T14:47:56 | used-test-only | swiftpm:test-target PulsumMLTests; test-source |
| `Packages/PulsumML/Tests/PulsumMLTests/SafetyLocalTests.swift` | yes | 1.0 KB | 2025-10-06T23:00:11 | used-test-only | swiftpm:test-target PulsumMLTests; test-source |
| `Packages/PulsumML/Tests/PulsumMLTests/TopicGateMarginTests.swift` | yes | 1.9 KB | 2025-12-29T00:28:27 | used-test-only | swiftpm:test-target PulsumMLTests; test-source |
| `Packages/PulsumML/Tests/PulsumMLTests/TopicGateTests.swift` | yes | 5.2 KB | 2025-12-29T00:20:11 | used-test-only | swiftpm:test-target PulsumMLTests; test-source |
| `Packages/PulsumServices/Tests/PulsumServicesTests/Gate0_LLMGatewayTests.swift` | yes | 1.8 KB | 2025-11-09T18:57:47 | used-test-only | swiftpm:test-target PulsumServicesTests; test-source |
| `Packages/PulsumServices/Tests/PulsumServicesTests/Gate0_SpeechServiceAuthorizationTests.swift` | yes | 3.7 KB | 2025-11-13T23:07:19 | used-test-only | swiftpm:test-target PulsumServicesTests; test-source |
| `Packages/PulsumServices/Tests/PulsumServicesTests/Gate0_SpeechServiceLoggingTests.swift` | yes | 1.1 KB | 2025-11-09T18:57:47 | used-test-only | swiftpm:test-target PulsumServicesTests; test-source |
| `Packages/PulsumServices/Tests/PulsumServicesTests/Gate1_LLMGatewayUITestSeams.swift` | yes | 946.0 B | 2025-11-13T23:07:19 | used-test-only | swiftpm:test-target PulsumServicesTests; test-source |
| `Packages/PulsumServices/Tests/PulsumServicesTests/Gate1_SpeechFakeBackendTests.swift` | yes | 965.0 B | 2025-11-13T23:07:19 | used-test-only | swiftpm:test-target PulsumServicesTests; test-source |
| `Packages/PulsumServices/Tests/PulsumServicesTests/Gate2_ModernSpeechBackendTests.swift` | yes | 1.3 KB | 2025-11-13T23:07:19 | used-test-only | swiftpm:test-target PulsumServicesTests; test-source |
| `Packages/PulsumServices/Tests/PulsumServicesTests/Gate4_LLMGatewayPingSeams.swift` | yes | 628.0 B | 2025-11-17T20:54:50 | used-test-only | swiftpm:test-target PulsumServicesTests; test-source |
| `Packages/PulsumServices/Tests/PulsumServicesTests/HealthKitAnchorStoreTests.swift` | yes | 1.9 KB | 2025-10-06T23:00:11 | used-test-only | swiftpm:test-target PulsumServicesTests; test-source |
| `Packages/PulsumServices/Tests/PulsumServicesTests/KeychainServiceTests.swift` | yes | 490.0 B | 2025-10-06T23:00:11 | used-test-only | swiftpm:test-target PulsumServicesTests; test-source |
| `Packages/PulsumServices/Tests/PulsumServicesTests/LLMGatewaySchemaTests.swift` | yes | 11.4 KB | 2025-11-17T20:54:50 | used-test-only | swiftpm:test-target PulsumServicesTests; test-source |
| `Packages/PulsumServices/Tests/PulsumServicesTests/LLMGatewayTests.swift` | yes | 11.3 KB | 2025-11-17T20:54:50 | used-test-only | swiftpm:test-target PulsumServicesTests; test-source |
| `Packages/PulsumServices/Tests/PulsumServicesTests/PulsumServicesDependencyTests.swift` | yes | 506.0 B | 2025-10-06T23:00:11 | used-test-only | swiftpm:test-target PulsumServicesTests; test-source |
| `Packages/PulsumServices/Tests/PulsumServicesTests/SpeechServiceTests.swift` | yes | 2.7 KB | 2025-11-09T18:57:47 | used-test-only | swiftpm:test-target PulsumServicesTests; test-source |
| `Packages/PulsumServices/Tests/Support/LLMURLProtocolStub.swift` | yes | 3.5 KB | 2025-11-17T20:54:50 | used-test-only | swiftpm:test-target PulsumServicesTests; test-source |
| `Packages/PulsumTypes/Tests/DiagnosticsLoggerTests.swift` | yes | 9.5 KB | 2026-01-22T17:25:06 | used-test-only | swiftpm:test-target PulsumTypesTests; test-source |
| `Packages/PulsumTypes/Tests/PulsumTypesTests/TimeoutTests.swift` | yes | 1.0 KB | 2026-01-22T17:25:06 | used-test-only | swiftpm:test-target PulsumTypesTests; test-source |
| `Packages/PulsumUI/Tests/PulsumUITests/CoachViewModelTests.swift` | yes | 14.9 KB | 2026-01-22T17:25:06 | used-test-only | swiftpm:test-target PulsumUITests; test-source |
| `Packages/PulsumUI/Tests/PulsumUITests/LiveWaveformBufferTests.swift` | yes | 1.1 KB | 2026-01-22T17:25:06 | used-test-only | swiftpm:test-target PulsumUITests; test-source |
| `Packages/PulsumUI/Tests/PulsumUITests/PulsumRootViewTests.swift` | yes | 200.0 B | 2026-01-22T17:25:06 | used-test-only | swiftpm:test-target PulsumUITests; test-source |
| `Packages/PulsumUI/Tests/PulsumUITests/SettingsViewModelHealthAccessTests.swift` | yes | 5.5 KB | 2026-01-22T17:25:06 | used-test-only | swiftpm:test-target PulsumUITests; test-source |
| `Packages/PulsumUI/Tests/PulsumUITests/TestCoreDataStack.swift` | yes | 829.0 B | 2026-01-22T17:25:06 | used-test-only | swiftpm:test-target PulsumUITests; test-source |
| `PulsumTests/PulsumTests.swift` | yes | 294.0 B | 2025-09-28T18:53:35 | used-test-only | test-source; xcode:test-target |
| `PulsumUITests/FirstRunPermissionsUITests.swift` | yes | 377.0 B | 2025-11-13T23:07:19 | used-test-only | test-source; xcode:test-target |
| `PulsumUITests/Gate3_HealthAccessUITests.swift` | yes | 3.4 KB | 2026-01-22T20:42:30 | used-test-only | test-source; xcode:test-target |
| `PulsumUITests/Gate4_CloudConsentUITests.swift` | yes | 2.6 KB | 2026-01-22T20:49:16 | used-test-only | test-source; xcode:test-target |
| `PulsumUITests/JournalFlowUITests.swift` | yes | 1.6 KB | 2025-11-13T23:07:19 | used-test-only | test-source; xcode:test-target |
| `PulsumUITests/PulsumUITestCase.swift` | yes | 8.3 KB | 2026-01-23T00:41:52 | used-test-only | test-source; xcode:test-target |
| `PulsumUITests/PulsumUITestsLaunchTests.swift` | yes | 814.0 B | 2025-09-28T18:53:35 | used-test-only | test-source; xcode:test-target |
| `PulsumUITests/SettingsAndCoachUITests.swift` | yes | 5.0 KB | 2026-01-24T15:22:37 | used-test-only | test-source; xcode:test-target |

## Spot Checks (Random Unused Candidates)
| Path | Basename | Occurrences (non-generated docs) |
| --- | --- | --- |
| `testfile` | `testfile` | 3 |
| `Pulsum/PulsumApp.swift` | `PulsumApp.swift` | 10 |
| `ios support files/glow.swift` | `glow.swift` | 4 |