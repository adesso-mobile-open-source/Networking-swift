# Sending requests

## Setup

Create a `NetworkEnvironment` with the `#URLBase` macro and instantiate `NetworkClientImpl`:

```swift
let environment = NetworkEnvironment(
    base: #URLBase("https://api.example.com/v1"),
    defaultHeaders: ["X-API-Key": "secret"]
)

let networkClient = NetworkClientImpl(environment: environment)
```

For dependency injection, hold a reference to the `NetworkClient` protocol:

```swift
final class UserRepository {
    private let networkClient: NetworkClient

    init(networkClient: NetworkClient) {
        self.networkClient = networkClient
    }
}
```

> **Multiple backends / behaviours:** If your app talks to more than one backend, or needs different configurations (e.g. one manager that attaches session tokens, another for unauthenticated public APIs), create a separate `NetworkClientImpl` instance for each and register them in your dependency injection container under different types or names. Each instance keeps its own `NetworkEnvironment`, interceptors, and coder configuration.

---

## Sending a request without a response body

Returns `NetworkResponse<EmptyBody>`:

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

let response = try await networkClient.send(
    request: CreateUserRequest(body: .init(name: "Ada", email: "ada@example.com"))
)
// response.statusCode, response.headerFields, etc. are available
```

**What is `EmptyBody`?**

`EmptyBody` is a sentinel type used when a request doesn't expect a response body. It has no properties or methods. You typically ignore `response.body` and only access metadata like `response.statusCode` or `response.headerFields`.

```swift
let response = try await networkClient.send(request: CreateUserRequest(...))
// response.body is EmptyBody (you can ignore it)
print("Created with status: \(response.statusCode)")  // ✅ Access metadata
```

---

## Sending a request with a response body

Returns `NetworkResponse<ResponseBody>` where `ResponseBody` is the decoded type:

```swift
struct GetUsersRequest: NetworkRequestWithResponse {
    typealias ResponseBody = [User]
    let method: HTTPMethod = .get
    var path: URLPath { #URLPath("users") }
}

let response = try await networkClient.send(request: GetUsersRequest())
let users = response.body  // [User]

// Or use dynamic member lookup to access properties of the body directly:
let firstUser = response.first  // equivalent to response.body.first
let userCount = response.count  // equivalent to response.body.count
```

---

## Sending a request with an optional response body

When the server may return an empty body, use `NetworkRequestWithResponse` with an optional `ResponseBody`. Returns `NetworkResponse<ResponseBody?>`:

```swift
struct GetDraftRequest: NetworkRequestWithResponse {
    struct Body: Decodable {
        let id: String
        let title: String
        let content: String
    }
    typealias ResponseBody = Body?  // Optional for empty responses
    
    let method: HTTPMethod = .get
    var path: URLPath { #URLPath("drafts/latest") }
}

let response = try await networkClient.send(request: GetDraftRequest())
let draft = response.body  // Body? — nil when server returns empty

// Access response metadata even when body is nil
print("Status: \(response.statusCode)")
if let draft = draft {
    print("Draft: \(draft.title)")
} else {
    print("No draft available")
}
```

**When to use optional responses:**

- Server returns `204 No Content` for some requests
- Endpoint conditionally returns data (e.g., "latest draft" may not exist)
- DELETE operations that optionally return the deleted resource
- GET operations that may return empty results (where `null` is semantically different from an empty array)

---

## Sending a request with both request and response body

Returns `NetworkResponse<ResponseBody>`:

```swift
@URLPathTemplate("users/{id}")
struct UpdateUserRequest: NetworkRequestWithBody, NetworkRequestWithResponse {
    struct RequestBody: Encodable { let name: String }
    typealias ResponseBody = User
    let method: HTTPMethod = .put
    let body: RequestBody
}

let response = try await networkClient.send(
    request: UpdateUserRequest(id: "42", body: .init(name: "Ada"))
)
let updated = response.body  // User
```

---

## Retrieving response headers

```swift
struct TokenRequest: NetworkRequestWithHeaderResponse {
    let method: HTTPMethod = .post
    var path: URLPath { #URLPath("auth/token") }
    var requiredHeaders: [String] { ["X-Session-Token"] }
}

let headers = try await networkClient.send(request: TokenRequest())
let token = headers["X-Session-Token"]
```

`NetworkSendHeaderResponseError.headerFieldsMissing` is thrown if any listed header is absent.

---

## Error handling

Every `send` overload uses **typed throws** (Swift 6), but — unlike a single library-wide error
enum — each overload declares the *smallest* error type that matches what it can actually throw.
This means the compiler stops you from writing a `case` for an error that overload could never
produce (e.g. a decoding error for a `send` call that never decodes a response body).

| `send` overload | Throws |
|---|---|
| `send(some NetworkRequest)` / `send(some NetworkRequestWithBody)` | `NetworkSendError` |
| `send<R: NetworkRequestWithResponse>(...)` (± `NetworkRequestWithBody`) | `NetworkSendResponseError` |
| optional-`ResponseBody` overloads (± `NetworkRequestWithBody`) | `NetworkSendOptionalResponseError` |
| `send(some NetworkRequestWithHeaderResponse)` | `NetworkSendHeaderResponseError` |

All four embed connectivity, TLS, status-code, and interceptor-pipeline failures via a shared
`.transport(NetworkTransportError)` case — the only error type interceptors themselves can throw
(see [Interception](Interception.md)):

```swift
do {
    let response = try await client.send(request: request)  // NetworkRequestWithResponse
    print("Success: \(response.body)")
} catch let .transport(.noNetworkConnection) {
    print("No internet connection")
} catch let .transport(.errorStatusCode(code, response)) {
    print("HTTP \(code) error")
    // Decode error body if needed
    if let apiError = try? JSONDecoder().decode(APIError.self, from: response.data) {
        print("API error: \(apiError.message)")
    }
} catch let .transport(.secureConnectionNotPossible) {
    print("TLS/SSL error")
} catch let .cannotDecodeResponseBody(message) {
    print("Decoding failed: \(message)")
} catch let .responseHasNoData {
    print("Expected a body but the response was empty")
}
```

### `NetworkTransportError` cases (reachable from every `send` overload)

| Error | Cause |
|---|---|
| `.errorStatusCode(code: Int, response: HTTPResponse)` | HTTP status code outside `NetworkRequest.allowedStatusCodes` (default: 200–299) |
| `.noNetworkConnection` | No active network path (requires opting into `AssertNetworkConnectionInterceptor`) |
| `.secureConnectionNotPossible` | TLS / certificate failure |
| `.responseIsNoHTTPURLResponse` | URLSession returned a non-HTTP response |
| `.unknownURLError(URLError)` | Network-level error not mapped to a specific case |
| `.unknownError(String)` | Any other untyped SDK error |
| `.interceptorError(any Error & Equatable)` | A custom interceptor's escape hatch for domain errors |

### Additional cases per error type

| Error | On type(s) | Cause |
|---|---|---|
| `.cannotEncodeQuery(String)` | all four | Query parameter encoding failed (only if the request also conforms to `NetworkRequestWithQuery`) |
| `.cannotEncodeRequestBody(String)` | all four | Request body encoding failed (only if the request also conforms to `NetworkRequestWithBody`) |
| `.responseHasNoData` | `NetworkSendResponseError` only | Response body was empty but a non-optional body was expected |
| `.cannotDecodeResponseBody(String)` | `NetworkSendResponseError`, `NetworkSendOptionalResponseError` | Response body decoding failed |
| `.headerFieldsMissing` | `NetworkSendHeaderResponseError` only | A required response header was absent |

See [Advanced Response Handling](Advanced_Response_Handling.md) for examples of decoding error response bodies.

---

## See Also

- [Declarative Endpoint Config](Declarative_Endpoint_Config.md) — How to define request types
- [Codable Body](Codable_Body.md) — Request/response body handling
- [Response Validation](Response_Validation.md) — Customizing allowed status codes
- [Advanced Response Handling](Advanced_Response_Handling.md) — Decoding error bodies, multi-type responses
- [Interception](Interception.md) — Request/response/error interceptors
- [Tagged Clients](Tagged_Clients.md) — Type-safe dependency injection with multiple clients
