import Testing
@testable import PulsumML

struct PIIRedactorTests {
    @Test("Email addresses are redacted")
    func test_emailRedaction() {
        let input = "Contact me at john.doe@example.com for details"
        let result = PIIRedactor.redact(input)
        #expect(!result.contains("john.doe@example.com"))
        #expect(result.contains("[redacted]"))
    }

    @Test("Phone numbers without parens are redacted")
    func test_phoneRedaction_noParen() {
        let input = "Call me at 555-123-4567 today"
        let result = PIIRedactor.redact(input)
        #expect(!result.contains("555-123-4567"))
        #expect(result.contains("[redacted]"))
    }

    @Test("Phone numbers with area code parens are redacted")
    func test_phoneRedaction_withParens() {
        let input = "My number is (555) 123-4567 please call"
        let result = PIIRedactor.redact(input)
        #expect(!result.contains("(555) 123-4567"))
        #expect(result.contains("[redacted]"))
    }

    @Test("SSN patterns are redacted")
    func test_ssnRedaction() {
        let input = "My SSN is 123-45-6789 and that is private"
        let result = PIIRedactor.redact(input)
        #expect(!result.contains("123-45-6789"))
        #expect(result.contains("[redacted]"))
    }

    @Test("Multiple PII types in one string are all redacted")
    func test_mixedPII() {
        let input = "Email me at test@example.com, call 555-867-5309, SSN 999-88-7777"
        let result = PIIRedactor.redact(input)
        #expect(!result.contains("test@example.com"))
        #expect(!result.contains("555-867-5309"))
        #expect(!result.contains("999-88-7777"))
    }

    @Test("Clean text without PII is preserved")
    func test_cleanTextPreserved() {
        let input = "I went for a walk and felt great today"
        let result = PIIRedactor.redact(input)
        #expect(result.contains("I went for a walk and felt great today"))
    }

    @Test("Empty input returns empty string")
    func test_emptyInput() {
        let result = PIIRedactor.redact("")
        #expect(result.isEmpty)
    }
}
