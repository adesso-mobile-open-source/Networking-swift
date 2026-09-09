# Codable support for HTTP bodies

This guide covers standard request and response body handling using `Codable`.

**💡 For advanced scenarios** like decoding multiple response types per status code or custom error bodies, see [Advanced Response Handling](Advanced_Response_Handling.md).

## Request body

Add `NetworkRequestWithBody` to send a typed, `Encodable` body with your request:

```swift
public protocol NetworkRequestWithBody: NetworkRequest {
    associatedtype RequestBody: Encodable
    var body: RequestBody { get }
    var httpBodyEncoder: DataEncoding? { get }   // nil → use encoder from NetworkClientConfiguration default
    var contentType: ContentType { get }          // default: application/json
}
```

### Example

```swift
struct CreateUserRequest: NetworkRequestWithBody {
    struct RequestBody: Encodable {
        let name: String
        let email: String
    }

    let method: HTTPMethod = .post
    var path: URLPath { #URLPath("users") }
    let body: RequestBody
}

try await networkClient.send(
    request: CreateUserRequest(body: .init(name: "Ada", email: "ada@example.com"))
)
```

### Custom content type

```swift
struct SubmitFormRequest: NetworkRequestWithBody {
    struct RequestBody: Encodable { let field: String }
    let method: HTTPMethod = .post
    var path: URLPath { #URLPath("forms/submit") }
    let body: RequestBody
    let contentType: ContentType = "application/x-www-form-urlencoded"
}
```

---

## Response body

Add `NetworkRequestWithResponse` to decode a typed response:

```swift
public protocol NetworkRequestWithResponse: NetworkRequest {
    associatedtype ResponseBody: Decodable, Sendable
    var httpBodyDecoder: DataDecoding? { get }   // nil → use decoder from NetworkClientConfiguration default
}
```

### Example

Returns `NetworkResponse<User>`:

```swift
struct GetUserRequest: NetworkRequestWithResponse {
    typealias ResponseBody = User
    let method: HTTPMethod = .get
    var path: URLPath { #URLPath("users/42") }
}

let response = try await networkClient.send(request: GetUserRequest())
let user = response.body  // User

// Or use dynamic member lookup:
print("User ID: \(response.id)")  // equivalent to response.body.id
```

### Optional response body

Use `NetworkRequestWithResponse` with an optional `ResponseBody` when the server may return an empty body:

```swift
struct GetDraftRequest: NetworkRequestWithResponse {
    struct Body: Decodable {
        let id: String
        let title: String
        let content: String
    }
    typealias ResponseBody = Body?  // Mark as optional for potentially empty responses
    
    let method: HTTPMethod = .get
    var path: URLPath { #URLPath("drafts/latest") }
}

let response = try await networkClient.send(request: GetDraftRequest())
let draft = response.body  // Body? (nil if server returned empty)
```

**Why this approach?**

By using `typealias ResponseBody = SomeType?`, you tell the library to:
- Treat empty response bodies as valid (returning `nil` instead of throwing)
- Automatically handle 204 No Content responses
- Support conditional responses where the body may or may not be present

---

## Customising coders

### Global (per `NetworkClientImpl`)

Pass a custom encoder or decoder in `NetworkClientConfiguration`:

```swift
let encoder = JSONEncoder()
encoder.keyEncodingStrategy = .convertToSnakeCase

let decoder = JSONDecoder()
decoder.keyDecodingStrategy = .convertFromSnakeCase

let config = NetworkClientConfiguration(
    environment: environment,
    httpBodyEncoder: encoder,
    httpBodyDecoder: decoder
)
let networkClient = NetworkClientImpl(configuration: config)
```

### Per-request

Override `httpBodyEncoder` or `httpBodyDecoder` on the request type. This takes precedence over the global configuration for that request only:

```swift
struct CreateUserRequest: NetworkRequestWithBody, NetworkRequestWithResponse {
    struct RequestBody: Encodable { let name: String }
    typealias ResponseBody = User

    let method: HTTPMethod = .post
    var path: URLPath { #URLPath("users") }
    let body: RequestBody

    var httpBodyEncoder: DataEncoding? {
        let e = JSONEncoder()
        e.keyEncodingStrategy = .convertToSnakeCase
        return e
    }

    var httpBodyDecoder: DataDecoding? {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }
}
```

For non-JSON formats, see [Custom Coders](Custom_Coders.md).

---

## See Also

- [Custom Coders](Custom_Coders.md) — XML, Protocol Buffers, custom JSON configurations
- [Sending Requests](Sending_Requests.md) — How to execute requests and handle responses
- [Advanced Response Handling](Advanced_Response_Handling.md) — Manual decoding for complex scenarios
- [Declarative Endpoint Config](Declarative_Endpoint_Config.md) — Available protocol traits
