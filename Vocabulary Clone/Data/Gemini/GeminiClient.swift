import Foundation

/// Minimal client for Gemini's `generateContent` REST endpoint — just the
/// pieces this app needs (a system instruction, a user prompt, and a JSON
/// schema for structured output), decoded into whatever `Response` type the
/// caller expects. Shared by every Gemini-backed generator in the app so the
/// request/response plumbing and error handling live in one place.
struct GeminiClient {
    enum ClientError: Error {
        case badHTTPStatus(Int, body: String)
        case emptyResponse
    }

    private let apiKey: String
    private let model: String
    private let urlSession: URLSession

    init(apiKey: String, model: String = "gemini-2.5-flash", urlSession: URLSession = .shared) {
        self.apiKey = apiKey
        self.model = model
        self.urlSession = urlSession
    }

    func generate<Response: Decodable>(
        systemInstruction: String,
        prompt: String,
        responseSchema: GeminiSchema,
        as responseType: Response.Type
    ) async throws -> Response {
        var components = URLComponents(string: "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent")!
        components.queryItems = [URLQueryItem(name: "key", value: apiKey)]

        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(RequestBody(
            systemInstruction: .init(parts: [.init(text: systemInstruction)]),
            contents: [.init(parts: [.init(text: prompt)])],
            generationConfig: .init(responseMimeType: "application/json", responseSchema: responseSchema)
        ))

        let (data, urlResponse) = try await urlSession.data(for: request)
        guard let httpResponse = urlResponse as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            let status = (urlResponse as? HTTPURLResponse)?.statusCode ?? -1
            throw ClientError.badHTTPStatus(status, body: String(data: data, encoding: .utf8) ?? "")
        }

        let envelope = try JSONDecoder().decode(ResponseEnvelope.self, from: data)
        guard let text = envelope.candidates.first?.content.parts.first?.text,
              let textData = text.data(using: .utf8)
        else {
            throw ClientError.emptyResponse
        }
        return try JSONDecoder().decode(Response.self, from: textData)
    }

    private struct RequestBody: Encodable {
        struct Content: Encodable {
            struct Part: Encodable { let text: String }
            let parts: [Part]
        }
        struct GenerationConfig: Encodable {
            let responseMimeType: String
            let responseSchema: GeminiSchema
        }
        let systemInstruction: Content
        let contents: [Content]
        let generationConfig: GenerationConfig
    }

    private struct ResponseEnvelope: Decodable {
        struct Candidate: Decodable {
            struct Content: Decodable {
                struct Part: Decodable { let text: String }
                let parts: [Part]
            }
            let content: Content
        }
        let candidates: [Candidate]
    }
}

/// A hand-rolled subset of Gemini's structured-output schema format (itself
/// a subset of OpenAPI's schema object): object/array/string/integer types,
/// nested properties, array element types, and string enums. A `final class`
/// rather than a `struct` because `items`/`properties` need to reference
/// `GeminiSchema` itself, which a value type can't do without indirection.
final class GeminiSchema: Encodable {
    let type: String
    let properties: [String: GeminiSchema]?
    let items: GeminiSchema?
    let required: [String]?
    let enumValues: [String]?

    init(
        type: String,
        properties: [String: GeminiSchema]? = nil,
        items: GeminiSchema? = nil,
        required: [String]? = nil,
        enumValues: [String]? = nil
    ) {
        self.type = type
        self.properties = properties
        self.items = items
        self.required = required
        self.enumValues = enumValues
    }

    enum CodingKeys: String, CodingKey {
        case type, properties, items, required
        case enumValues = "enum"
    }
}
