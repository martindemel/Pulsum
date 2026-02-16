// This file exists solely to disambiguate `FeatureVectorSnapshot` which is
// defined in both PulsumAgents and PulsumTypes. By importing only PulsumAgents
// here (not PulsumTypes), the typealias resolves unambiguously.
@testable import PulsumAgents

typealias AgentSnapshot = FeatureVectorSnapshot
