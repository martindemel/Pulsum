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
    func testPartialHealthAccessStatusVisibleInSettings() throws {
        launchPulsum(additionalEnvironment: [
            "PULSUM_HEALTHKIT_STATUS_OVERRIDE": partialHealthAccessOverride
        ])
        try openSettingsSheetOrSkip()

        let summary = app.staticTexts["HealthAccessSummaryLabel"]
        XCTAssertTrue(summary.waitForExistence(timeout: 5))
        XCTAssertTrue(summary.label.contains("5/6"), "Summary should reflect partial access.")

        let missing = app.staticTexts["HealthAccessMissingLabel"]
        XCTAssertTrue(missing.exists)
        XCTAssertTrue(missing.label.contains("Sleep"))

        dismissSettingsSheet()
    }

    func testRequestHealthAccessButtonGrantsAllTypes() throws {
        launchPulsum(additionalEnvironment: [
            "PULSUM_HEALTHKIT_STATUS_OVERRIDE": partialHealthAccessOverride,
            "PULSUM_HEALTHKIT_REQUEST_BEHAVIOR": "grantAll"
        ])
        try openSettingsSheetOrSkip()

        let button = app.buttons["HealthAccessRequestButton"]
        XCTAssertTrue(button.exists)
        button.tap()

        let successToast = app.staticTexts["Health data connected"]
        let toastAppeared = successToast.waitForExistence(timeout: 5)
        XCTAssertTrue(toastAppeared, "Success toast should appear after access is granted.")

        let summary = app.staticTexts["HealthAccessSummaryLabel"]
        XCTAssertTrue(summary.waitForExistence(timeout: 5))
        XCTAssertTrue(summary.label.contains("6/6"), "Summary label after grant: \(summary.label)")

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

    func testNoToastOnInitialFullyGranted() throws {
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

        try openSettingsSheetOrSkip()

        let successToast = app.staticTexts["Health data connected"]
        XCTAssertFalse(successToast.exists, "Toast must not appear on initial fully granted state.")

        dismissSettingsSheet()
    }
}
