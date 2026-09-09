# Advanced Response Handling

This guide covers scenarios where the standard `NetworkRequestWithResponse` protocol doesn't fit your needs, requiring manual response decoding or custom error handling.

---

## When you need manual decoding

The library's standard Codable integration assumes:
1. A single response type for success cases
2. HTTP status codes clearly separate success from failure
3. The response decoder can handle the body format

**You need manual decoding when:**
- Different success status codes return different response types (e.g., `200 OK` returns `User`, `201 Created` returns `UserCreatedResponse`, `202 Accepted` returns `AcceptedResponse`)
- Error responses have structured bodies you want to decode
- The response format varies based on headers or other metadata
- You need access to raw response data alongside the decoded body

---

## Design philosophy: Type safety for the common case

The library **intentionally does not** support multiple response types per request through generic type parameters or complex configurations. This would sacrifice compile-time type safety for the 99% of requests that have a single, well-defined response type.

Instead, for advanced scenarios, you manually decode responses using the raw data available in `NetworkResponse` and `NetworkTransportError`. This keeps the common case simple while still supporting edge cases.

---

## Access points for raw data

### 1. Success responses: `NetworkResponse.rawBody`

Every successful response provides access to the raw body data:

```swift
public struct NetworkResponse<T> {
    public let body: T                  // The decoded body
    public let httpResponse: HTTPResponse
    public var rawBody: Data            // The raw response data
    public var statusCode: Int          // HTTP status code
    public var headerFields: [AnyHashable: Any]  // Response headers
}
```

### 2. Error responses: `NetworkTransportError.errorStatusCode`

When a non-OK status code is received, the error contains the full HTTP response. This case lives
on `NetworkTransportError`, embedded via a `.transport(_:)` case in whichever `send`-overload-specific
error type applies (`NetworkSendError`, `NetworkSendResponseError`, etc. — see
[Sending Requests](Sending_Requests.md#error-handling)):

```swift
public enum NetworkTransportError {
    case errorStatusCode(code: Int, response: HTTPResponse)
    // ... other cases
}
```

The `HTTPResponse` contains:
- `data: Data` — The raw response body
- `urlResponse: HTTPURLResponse` — The full HTTP response with headers and status
- `request: HTTPRequest` — The original request that was sent

---

## Common scenarios

### Scenario 1: Decode custom error bodies

When your backend returns structured error responses (e.g., validation errors, business logic failures), decode them from the caught error:

```swift
struct APIErrorResponse: Decodable {
    let code: String
    let message: String
    let fields: [String: String]?
}

struct CreateUserRequest: NetworkRequestWithBody {
    struct RequestBody: Encodable {
        let email: String
        let password: String
    }
    
    let method: HTTPMethod = .post
    var path: URLPath { #URLPath("users") }
    let body: RequestBody
}

// Usage — CreateUserRequest conforms to NetworkRequestWithBody only, so send(...)
// throws NetworkSendError.
do {
    try await client.send(request: CreateUserRequest(body: requestBody))
} catch let NetworkSendError.transport(.errorStatusCode(code, response)) {
    // Decode the error response body.
    if let apiError = try? JSONDecoder().decode(APIErrorResponse.self, from: response.data) {
        print("API Error: \(apiError.message)")
        if let fieldErrors = apiError.fields {
            print("Field errors: \(fieldErrors)")
        }
    } else {
        print("HTTP \(code) error with no structured body")
    }
} catch {
    print("Other error: \(error)")
}
```

#### Reusable helper for error decoding

Define the helper once on `NetworkTransportError` — since every `send`-overload-specific error type
embeds it via `.transport(_:)`, the helper works for all of them:

```swift
extension NetworkTransportError {
    /// Attempts to decode the error response body as the specified type.
    func decodeErrorBody<T: Decodable>(
        as type: T.Type,
        using decoder: DataDecoding = JSONDecoder()
    ) -> T? {
        guard case let .errorStatusCode(_, response) = self else {
            return nil
        }
        return try? decoder.decode(type, from: response.data)
    }
}

// Usage
do {
    try await client.send(request: request)
} catch let NetworkSendError.transport(transportError) {
    if let apiError = transportError.decodeErrorBody(as: APIErrorResponse.self) {
        print("Validation failed: \(apiError.message)")
    }
}
```

---

### Scenario 2: Different response types per status code (success cases)

When different success status codes return different response shapes, **don't use `NetworkRequestWithResponse`**. Instead, use `NetworkRequest` (or `NetworkRequestWithBody`) and manually decode based on the status code:

```swift
struct CreateResourceRequest: NetworkRequestWithBody {
    struct RequestBody: Encodable {
        let name: String
    }
    
    let method: HTTPMethod = .post
    var path: URLPath { #URLPath("resources") }
    let body: RequestBody
    
    // Accept both 200 and 201
    var allowedStatusCodes: Range<Int> { 200..<202 }
}

// Response types
struct Resource: Decodable {
    let id: String
    let name: String
}

struct CreatedResponse: Decodable {
    let id: String
    let location: String
}

// Usage
let response = try await client.send(request: CreateResourceRequest(body: .init(name: "New Resource")))

switch response.statusCode {
case 200:
    let resource = try JSONDecoder().decode(Resource.self, from: response.rawBody)
    print("Resource updated: \(resource.id)")
    
case 201:
    let created = try JSONDecoder().decode(CreatedResponse.self, from: response.rawBody)
    print("Resource created at: \(created.location)")
    
default:
    // Should never happen due to allowedStatusCodes, but handle gracefully
    throw NetworkSendError.transport(.unknownError("Unexpected status code: \(response.statusCode)"))
}
```

---

### Scenario 3: Response format varies by header

When the response body format depends on metadata (e.g., `Content-Type` header):

```swift
struct GetDataRequest: NetworkRequest {
    let method: HTTPMethod = .get
    var path: URLPath { #URLPath("data/export") }
}

let response = try await client.send(request: GetDataRequest())

if let contentType = response.headerFields["Content-Type"] as? String {
    switch contentType {
    case let ct where ct.contains("application/json"):
        let jsonData = try JSONDecoder().decode(ExportData.self, from: response.rawBody)
        print("JSON export: \(jsonData)")
        
    case let ct where ct.contains("text/csv"):
        let csvString = String(data: response.rawBody, encoding: .utf8)
        print("CSV export: \(csvString ?? "Invalid UTF-8")")
        
    default:
        print("Unknown content type: \(contentType)")
    }
}
```

---

### Scenario 4: Optional response with status-specific handling

Handle cases where `204 No Content` vs `200 OK` have different meanings:

```swift
struct DeleteUserRequest: NetworkRequest {
    let userId: String
    
    let method: HTTPMethod = .delete
    var path: URLPath { #URLPath("users/\(userId)") }
    
    // Accept both 200 and 204
    var allowedStatusCodes: Range<Int> { 200..<205 }
}

struct DeletionResult: Decodable {
    let deletedAt: Date
    let affectedResources: [String]
}

let response = try await client.send(request: DeleteUserRequest(userId: "42"))

switch response.statusCode {
case 200:
    // Server returned details about the deletion
    let result = try JSONDecoder().decode(DeletionResult.self, from: response.rawBody)
    print("Deleted at \(result.deletedAt), affected: \(result.affectedResources)")
    
case 204:
    // No content — deletion succeeded with no additional info
    print("User deleted successfully")
    
default:
    throw NetworkSendError.transport(.unknownError("Unexpected status code: \(response.statusCode)"))
}
```

---

## Best practices

### ✅ Do:
- Use `NetworkRequestWithResponse` for standard, single-type responses (99% of cases)
- Use manual decoding for edge cases where response types vary
- Create reusable helper extensions for common patterns (e.g., `decodeErrorBody`)
- Document why manual decoding is needed in comments
- Keep manual decoding logic close to the request definition

### ❌ Don't:
- Manually decode responses when `NetworkRequestWithResponse` would work
- Ignore error cases — always handle both success and error paths
- Assume the raw data is valid — wrap decoding in `try` or `try?`
- Forget to set `allowedStatusCodes` when accepting multiple success codes

---

## Complete example: Async job creation

A realistic example combining multiple techniques:

```swift
// Request
struct CreateExportJobRequest: NetworkRequest {
    struct RequestBody: Encodable {
        let format: String
        let filters: [String: String]
    }
    
    let method: HTTPMethod = .post
    var path: URLPath { #URLPath("exports/jobs") }
    let body: RequestBody
    
    // Accept both 200 (synchronous) and 202 (async)
    var allowedStatusCodes: Range<Int> { 200..<203 }
}

// Response types
struct ExportData: Decodable {
    let records: [Record]
}

struct AsyncJobResponse: Decodable {
    let jobId: String
    let statusUrl: String
    let estimatedTime: Int
}

struct ExportError: Decodable {
    let error: String
    let invalidFilters: [String]?
}

// Usage
do {
    let response = try await client.send(
        request: CreateExportJobRequest(
            body: .init(format: "csv", filters: ["status": "active"])
        )
    )
    
    switch response.statusCode {
    case 200:
        // Synchronous response — data ready immediately
        let exportData = try JSONDecoder().decode(ExportData.self, from: response.rawBody)
        print("Export complete: \(exportData.records.count) records")
        
    case 202:
        // Asynchronous response — poll the job
        let job = try JSONDecoder().decode(AsyncJobResponse.self, from: response.rawBody)
        print("Job \(job.jobId) created, check \(job.statusUrl) in ~\(job.estimatedTime)s")
        
    default:
        throw NetworkSendError.transport(.unknownError("Unexpected status: \(response.statusCode)"))
    }
    
} catch let NetworkSendError.transport(.errorStatusCode(code, response)) {
    // Decode structured error response
    if let exportError = try? JSONDecoder().decode(ExportError.self, from: response.data) {
        print("Export failed: \(exportError.error)")
        if let invalidFilters = exportError.invalidFilters {
            print("Invalid filters: \(invalidFilters)")
        }
    } else {
        print("Export failed with HTTP \(code)")
    }
    
} catch {
    print("Network error: \(error)")
}
```

---

## Related

- [Codable Body](Codable_Body.md) — Standard request/response body handling
- [Response Validation](Response_Validation.md) — Customizing allowed status codes
- [Custom Coders](Custom_Coders.md) — Using non-JSON encoders/decoders
- [Interception](Interception.md) — Response interceptors for global error handling
