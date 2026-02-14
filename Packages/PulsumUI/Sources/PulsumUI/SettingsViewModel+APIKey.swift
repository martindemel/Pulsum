import Foundation
import PulsumAgents
import PulsumServices
import PulsumTypes

// MARK: - GPT API Key Management

extension SettingsViewModel {
    @MainActor
    func saveAPIKey(_ key: String) async {
        guard let orchestrator else {
            gptAPIStatus = "Agent unavailable"
            isGPTAPIWorking = false
            return
        }
        let trimmedKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty else {
            gptAPIStatus = "Missing API key"
            isGPTAPIWorking = false
            return
        }
        gptAPIStatus = "Saving..."
        do {
            try orchestrator.setLLMAPIKey(trimmedKey)
            gptAPIKeyDraft = trimmedKey
            isGPTAPIWorking = false
            gptAPIStatus = "API key saved"
        } catch {
            isGPTAPIWorking = false
            gptAPIStatus = "Missing or invalid API key"
        }
    }

    @MainActor
    func testCurrentAPIKey() async {
        if AppRuntimeConfig.isUITesting {
            let trimmed = gptAPIKeyDraft.trimmingCharacters(in: .whitespacesAndNewlines)
            isTestingAPIKey = false
            if trimmed.isEmpty {
                isGPTAPIWorking = false
                gptAPIStatus = "Missing API key"
            } else {
                let ok = AppRuntimeConfig.useStubLLM
                isGPTAPIWorking = ok
                gptAPIStatus = ok ? "OpenAI reachable" : "OpenAI ping failed"
            }
            return
        }
        guard let orchestrator else {
            gptAPIStatus = "Agent unavailable"
            isGPTAPIWorking = false
            return
        }
        isTestingAPIKey = true
        defer { isTestingAPIKey = false }
        gptAPIStatus = "Testing..."
        isGPTAPIWorking = false
        do {
            let ok = try await orchestrator.testLLMAPIConnection()
            isGPTAPIWorking = ok
            gptAPIStatus = ok ? "OpenAI reachable" : "OpenAI ping failed"
        } catch {
            isGPTAPIWorking = false
            gptAPIStatus = "Missing or invalid API key"
        }
    }
}
