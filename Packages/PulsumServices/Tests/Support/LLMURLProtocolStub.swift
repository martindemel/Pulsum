import Foundation

final class LLMURLProtocolStub: URLProtocol {
    nonisolated(unsafe) static var handler: ((URLRequest) -> (Int, Data))?
    nonisolated(unsafe) static var respondWithSchemaError: Bool = false
    nonisolated(unsafe) static var invocationCount: Int = 0

    private static let endpointSuffix = "/v1/responses"
    private static let defaultSuccess = Data("{\"id\":\"resp_stub\",\"object\":\"response\",\"model\":\"gpt-5\",\"output\":[{\"type\":\"message\",\"role\":\"assistant\",\"content\":[{\"type\":\"output_text\",\"text\":\"{\\\"coachReply\\\":\\\"We can anchor with one calm breath and a soft light stretch.\\\",\\\"isOnTopic\\\":true,\\\"groundingScore\\\":0.82,\\\"intentTopic\\\":\\\"sleep\\\",\\\"refusalReason\\\":\\\"\\\",\\\"nextAction\\\":\\\"Dim lights 30 minutes before bed\\\"}\"}]}]}".utf8)
    private static let pingResponse = Data("{\"output\":[]}".utf8)
    private static let schemaErrorResponse = Data("{\"error\":{\"message\":\"Invalid schema: Missing text.format.name\"}}".utf8)

    override class func canInit(with request: URLRequest) -> Bool {
        guard let url = request.url else { return false }
        return url.absoluteString.contains(endpointSuffix)
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        LLMURLProtocolStub.invocationCount += 1

        let (status, data): (Int, Data)
        if let handler = LLMURLProtocolStub.handler {
            (status, data) = handler(request)
        } else if Self.isPing(request: request) {
            (status, data) = (200, Self.pingResponse)
        } else if LLMURLProtocolStub.respondWithSchemaError {
            (status, data) = (400, Self.schemaErrorResponse)
        } else {
            (status, data) = (200, Self.defaultSuccess)
        }

        let response = HTTPURLResponse(url: request.url!,
                                       statusCode: status,
                                       httpVersion: nil,
                                       headerFields: ["Content-Type": "application/json"])!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}

    private static func isPing(request: URLRequest) -> Bool {
        guard let body = bodyJSON(from: request),
              let input = body["input"] as? [[String: Any]],
              let user = input.last,
              let content = user["content"] as? String else {
            return false
        }
        return content == "ping"
    }

    private static func bodyJSON(from request: URLRequest) -> [String: Any]? {
        guard let data = bodyData(from: request) else { return nil }
        return (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
    }

    private static func bodyData(from request: URLRequest) -> Data? {
        if let data = request.httpBody { return data }
        guard let stream = request.httpBodyStream else { return nil }
        stream.open()
        defer { stream.close() }
        var data = Data()
        let bufferSize = 1024
        var buffer = [UInt8](repeating: 0, count: bufferSize)
        while stream.hasBytesAvailable {
            let read = stream.read(&buffer, maxLength: bufferSize)
            if read > 0 {
                data.append(buffer, count: read)
            } else {
                break
            }
        }
        return data
    }
}
