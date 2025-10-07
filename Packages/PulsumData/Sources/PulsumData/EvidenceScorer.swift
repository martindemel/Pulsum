import Foundation

public enum EvidenceBadge: String {
    case strong = "Strong"
    case medium = "Medium"
    case weak = "Weak"
}

struct EvidenceScorer {
    private static let strongDomains: [String] = [
        "pubmed",
        "nih.gov",
        ".gov",
        ".edu",
        "who.int",
        "cochrane.org"
    ]

    private static let mediumDomains: [String] = [
        "nature.com",
        "sciencedirect.com",
        "mayoclinic.org",
        "harvard.edu"
    ]

    static func badge(for urlString: String?) -> EvidenceBadge {
        guard let urlString, let url = URL(string: urlString), let host = url.host?.lowercased() else {
            return .weak
        }

        if strongDomains.contains(where: { host == $0 || host.hasSuffix($0) }) {
            return .strong
        }

        if mediumDomains.contains(where: { host == $0 || host.hasSuffix($0) }) {
            return .medium
        }

        return .weak
    }
}
