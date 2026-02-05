import XCTest

private let partialHealthAccessOverride = [
    "HKQuantityTypeIdentifierHeartRateVariabilitySDNN=authorized",
    "HKQuantityTypeIdentifierHeartRate=authorized",
    "HKQuantityTypeIdentifierRestingHeartRate=authorized",
    "HKQuantityTypeIdentifierRespiratoryRate=authorized",
    "HKQuantityTypeIdentifierStepCount=authorized",
    "HKCategoryTypeIdentifierSleepAnalysis=denied"
].joined(separator: ",")

final class Gate3_HealthAccessUITests: PulsumUITestCase {
    func testPartialHealthAccessStatusVisibleInSettings() {
        launchPulsum(additionalEnvironment: [
            "PULSUM_HEALTHKIT_STATUS_OVERRIDE": partialHealthAccessOverride
        ])
        guard openSettingsSheetOrSkip() else { return }

        let summary = app.staticTexts["HealthAccessSummaryLabel"]
        XCTAssertTrue(summary.waitForExistence(timeout: 5))
        XCTAssertTrue(summary.label.contains("5/6"), "Summary should reflect partial access.")

        let missing = app.staticTexts["HealthAccessMissingLabel"]
        XCTAssertTrue(missing.exists)
        XCTAssertTrue(missing.label.contains("Sleep"))

        dismissSettingsSheet()
    }

    func testRequestHealthAccessButtonGrantsAllTypes() {
        launchPulsum(additionalEnvironment: [
            "PULSUM_HEALTHKIT_STATUS_OVERRIDE": partialHealthAccessOverride,
            "PULSUM_HEALTHKIT_REQUEST_BEHAVIOR": "grantAll"
        ])
        guard openSettingsSheetOrSkip() else { return }

        let button = app.buttons["HealthAccessRequestButton"]
        XCTAssertTrue(button.exists)
        button.tap()

        let successToast = app.staticTexts["Health data connected"]
        let toastAppeared = successToast.waitForExistence(timeout: 5)

        let summary = app.staticTexts["HealthAccessSummaryLabel"]
        XCTAssertTrue(summary.waitForExistence(timeout: 5))
        XCTAssertTrue(summary.label.contains("6/6"), "Summary label after grant: \(summary.label)")
        if !toastAppeared {
            let summaryAttachment = XCTAttachment(string: "Toast missing; summary after request: \(summary.label)")
            summaryAttachment.name = "HealthAccessToastFallback"
            summaryAttachment.lifetime = .keepAlways
            add(summaryAttachment)
        }

        if ProcessInfo.processInfo.environment["UITEST_CAPTURE_TREE"] == "1" {
            let summaryAttachment = XCTAttachment(string: "Summary after request: \(summary.label)")
            summaryAttachment.name = "HealthAccessSummaryDebug"
            summaryAttachment.lifetime = .keepAlways
            add(summaryAttachment)

            let treeAttachment = XCTAttachment(string: app.debugDescription)
            treeAttachment.name = "AppDebugTree"
            treeAttachment.lifetime = .keepAlways
            add(treeAttachment)
        }

        dismissSettingsSheet()
    }

    func testNoToastOnInitialFullyGranted() {
        let allGranted = [
            "HKQuantityTypeIdentifierHeartRateVariabilitySDNN=authorized",
            "HKQuantityTypeIdentifierHeartRate=authorized",
            "HKQuantityTypeIdentifierRestingHeartRate=authorized",
            "HKQuantityTypeIdentifierRespiratoryRate=authorized",
            "HKQuantityTypeIdentifierStepCount=authorized",
            "HKCategoryTypeIdentifierSleepAnalysis=authorized"
        ].joined(separator: ",")

        launchPulsum(additionalEnvironment: [
            "PULSUM_HEALTHKIT_STATUS_OVERRIDE": allGranted
        ])

        guard openSettingsSheetOrSkip() else { return }

        let successToast = app.staticTexts["Health data connected"]
        XCTAssertFalse(successToast.exists, "Toast must not appear on initial fully granted state.")

        dismissSettingsSheet()
    }
}
