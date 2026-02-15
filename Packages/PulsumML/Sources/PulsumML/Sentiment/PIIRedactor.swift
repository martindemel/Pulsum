import Foundation
import NaturalLanguage

public enum PIIRedactor {
    public static func redact(_ transcript: String) -> String {
        guard !transcript.isEmpty else { return transcript }
        var output = transcript
        let patterns = [
            #"[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}"#, // Email
            #"\+?\d[\d\s\-]{7,}\d"#, // Phone numbers
            #"\b\d{3}[-\s]?\d{2}[-\s]?\d{4}\b"#, // SSN (###-##-####)
            #"\b(?:4\d{3}|5[1-5]\d{2}|3[47]\d{2}|6(?:011|5\d{2}))[- ]?\d{4}[- ]?\d{4}[- ]?\d{4}\b"#, // Credit card
            #"\b\d{1,5}\s+\w+\s+(?:St(?:reet)?|Ave(?:nue)?|Blvd|Dr(?:ive)?|Ln|Rd|Ct|Pl|Way)\b"#, // Street address
            #"\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b"# // IP address
        ]
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
                let range = NSRange(location: 0, length: output.utf16.count)
                output = regex.stringByReplacingMatches(in: output, options: [], range: range, withTemplate: "[redacted]")
            }
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
