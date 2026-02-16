import Foundation
import NaturalLanguage

public enum PIIRedactor {
    // Regex patterns compiled once at load time
    private static let emailRegex = try? NSRegularExpression(
        pattern: #"[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}"#,
        options: [.caseInsensitive]
    )
    private static let phoneRegex = try? NSRegularExpression(
        pattern: #"\+?\d[\d\s\-]{7,}\d"#,
        options: [.caseInsensitive]
    )
    private static let ssnRegex = try? NSRegularExpression(
        pattern: #"\b\d{3}[-\s]?\d{2}[-\s]?\d{4}\b"#,
        options: [.caseInsensitive]
    )
    private static let creditCardRegex = try? NSRegularExpression(
        pattern: #"\b(?:4\d{3}|5[1-5]\d{2}|3[47]\d{2}|6(?:011|5\d{2}))[- ]?\d{4}[- ]?\d{4}[- ]?\d{4}\b"#,
        options: [.caseInsensitive]
    )
    private static let streetAddressRegex = try? NSRegularExpression(
        pattern: #"\b\d{1,5}\s+\w+\s+(?:St(?:reet)?|Ave(?:nue)?|Blvd|Dr(?:ive)?|Ln|Rd|Ct|Pl|Way)\b"#,
        options: [.caseInsensitive]
    )
    private static let ipAddressRegex = try? NSRegularExpression(
        pattern: #"\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b"#,
        options: [.caseInsensitive]
    )
    private static let dateOfBirthRegex = try? NSRegularExpression(
        pattern: #"\b\d{1,2}[/\-]\d{1,2}[/\-]\d{2,4}\b"#,
        options: [.caseInsensitive]
    )
    private static let parenthesizedPhoneRegex = try? NSRegularExpression(
        pattern: #"\(\d{3}\)\s*\d{3}[-.]?\d{4}"#,
        options: [.caseInsensitive]
    )

    private static let cachedPatterns: [NSRegularExpression] = [emailRegex, phoneRegex, ssnRegex, creditCardRegex, streetAddressRegex, ipAddressRegex, dateOfBirthRegex, parenthesizedPhoneRegex]
        .compactMap { $0 }

    public static func redact(_ transcript: String) -> String {
        guard !transcript.isEmpty else { return transcript }
        var output = transcript
        for regex in cachedPatterns {
            let range = NSRange(location: 0, length: output.utf16.count)
            output = regex.stringByReplacingMatches(in: output, options: [], range: range, withTemplate: "[redacted]")
        }
        if #available(iOS 17, macOS 13, *) {
            let tagger = NLTagger(tagSchemes: [.nameType])
            tagger.string = output
            var replacements: [Range<String.Index>] = []
            tagger.enumerateTags(in: output.startIndex ..< output.endIndex,
                                 unit: .word,
                                 scheme: .nameType,
                                 options: [.omitWhitespace, .omitPunctuation]) { tag, range in
                if let tag, tag == .personalName {
                    replacements.append(range)
                }
                return true
            }
            for range in replacements.reversed() {
                output.replaceSubrange(range, with: "[redacted]")
            }
        }
        return output
    }
}
