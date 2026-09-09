---
name: adesso-networking
description: >
  Use this skill when writing Swift code that performs HTTP networking on iOS or macOS
  using the adesso Networking library. Activates whenever a task involves creating network
  requests, configuring a NetworkClient, sending HTTP calls, handling responses or errors,
  or working with request/response interceptors in a Swift Package that depends on
  ams/intern/ios/foundation-libs/networking.
---

# adesso Networking Library

A Swift networking library built on top of `URLSession` providing compile-time safe URL
construction, declarative endpoint configuration, and a composable interceptor system.

**Package:** `ams/intern/ios/foundation-libs/networking`
**Platforms:** iOS 16+, macOS 13+
**Swift:** 6.0+

---

## Core concepts

| Concept | Type | Purpose |
|---|---|---|
| Base URL | `NetworkEnvironment` | Holds the validated base URL and default headers for all requests |
| Request | `NetworkRequest` + trait protocols | Declares a single endpoint as a value type |
| Manager | `NetworkClientImpl` (actor) | Sends requests through `URLSession`, validates status codes, runs interceptors |
| Interceptors | `NetworkRequest/Response/ErrorInterceptor` | Composable hooks for mutation, logging, retry, auth |
| Concurrency | `@NetworkActor` | All network ops run on network actor (Swift 6 safe) |

---

## Step 1 — Create the environment and manager

```swift
import Networking

let environment = NetworkEnvironment(
    base: #URLBase("https://api.example.com/v1"),   // compile-time validated
    defaultHeaders: ["X-API-Key": "secret"]
)

// Simple initialization (uses default configuration)
let networkClient = NetworkClientImpl(environment: environment)

// Advanced: Full configuration with custom encoders, interceptors, session
let networkClient = NetworkClientImpl(
    configuration: NetworkClientConfiguration(
        environment: environment,
        httpBodyEncoder: customEncoder,      // default: JSONEncoder()
        httpBodyDecoder: customDecoder,      // default: JSONDecoder()
        requestInterceptor: requestInt,      // default: no-op
        responseInterceptor: responseInt,    // default: no-op
        errorInterceptor: errorInt,          // default: no-op
        sessionConfiguration: urlSessionConfig  // default: ephemeral, 20s timeout
    )
)

// Modern: Array literal syntax for chaining interceptors (Swift 6+)
let networkClient = NetworkClientImpl(
    configuration: NetworkClientConfiguration(
        environment: environment,
        requestInterceptor: [authInt, loggingInt],
        responseInterceptor: [metricsInt],
        errorInterceptor: [retryInt]
    )
)
```

**Multiple backends:** Create one `NetworkClientImpl` per backend and use [Tagged Clients](Tagged_Clients.md) for compile-time-safe dependency injection.

---

## Step 2 — Declare endpoints

Every endpoint is a `struct` conforming to `NetworkRequest` plus the relevant trait protocols.
Only declare the traits the endpoint actually needs — they are fully composable.

### Static path

```swift
struct GetUsersRequest: NetworkRequestWithResponse {
    typealias ResponseBody = [User]
    let method: HTTPMethod = .get
    var path: URLPath { #URLPath("users") }   // compile-time validated
}
```

### Dynamic path segments

```swift
@URLPathTemplate("users/{id}/posts/{postId}")
struct GetPostRequest: NetworkRequestWithResponse {
    typealias ResponseBody = Post
    let method: HTTPMethod = .get
    // Macro generates: let id: PathParameterStringConvertible
    //                  let postId: PathParameterStringConvertible
    //                  var path: URLPath
}
// Parameters accept any PathParameterStringConvertible — String, UUID, Int, or custom types:
let byString = GetPostRequest(id: "42", postId: "7")
let byUUID   = GetPostRequest(id: UUID(), postId: UUID())
let byInt    = GetPostRequest(id: 1, postId: 7)
```

### Query parameters

```swift
struct SearchUsersRequest: NetworkRequestWithQuery, NetworkRequestWithResponse {
    typealias ResponseBody = [User]
    let method: HTTPMethod = .get
    var path: URLPath { #URLPath("users/search") }
    let query: ["name": "Ada", "page": 1]  // any Encodable type
}
```

### Request body

```swift
struct CreateUserRequest: NetworkRequestWithBody {
    struct RequestBody: Encodable { let name: String; let email: String }
    let method: HTTPMethod = .post
    var path: URLPath { #URLPath("users") }
    let body: RequestBody
}
```

### Optional response body

```swift
struct GetDraftRequest: NetworkRequestWithResponse {
    typealias ResponseBody = Draft?  // Optional for potentially empty responses
    let method: HTTPMethod = .get
    var path: URLPath { #URLPath("drafts/latest") }
}
// Use when server may return 204 No Content or empty body
```

---

## Step 3 — Send requests

```swift
// No response body
try await NetworkClient.send(request: CreateUserRequest(body: .init(name: "Ada", email: "ada@example.com")))

// With response body — return type inferred from ResponseBody
let users: [User] = try await NetworkClient.send(request: GetUsersRequest())

// Optional response body
let draft: Draft? = try await NetworkClient.send(request: GetDraftRequest())

// Dynamic path — String, UUID, Int, or any PathParameterStringConvertible
let post: Post = try await NetworkClient.send(request: GetPostRequest(id: UUID(), postId: 7))
```

---

## Common patterns

**Empty response handling:**  
Use `typealias ResponseBody = SomeType?` when server may return 204 No Content.

**Multiple backends:**  
```swift
let apiClient = NetworkClientImpl(environment: apiEnv)
let authClient = NetworkClientImpl(environment: authEnv)
```

**Auth token injection:**  
See Request Interceptor example in Step 5.

**Multiple interceptors:**  
Use array literal syntax: `requestInterceptor: [auth, logging, metrics]`

**Which traits do I need?**  
- Query params → `NetworkRequestWithQuery`
- Send body → `NetworkRequestWithBody`
- Return body → `NetworkRequestWithResponse`
- Modify headers → `NetworkRequestWithRequestInterceptor`

---

## Step 4 — Handle errors

Every `send` overload uses **typed throws**, each with its own error type scoped to what that
overload can actually throw — `send<R: NetworkRequestWithResponse>` throws `NetworkSendResponseError`,
a plain `send(some NetworkRequest)` throws the smaller `NetworkSendError`, etc. (full mapping in
[Sending_Requests.md](Sending_Requests.md#error-handling)):
- ✅ No type casting required
- ✅ Compiler verifies exhaustive error handling
- ✅ Autocomplete shows only relevant errors — a `send` call that never decodes a response can't be handled for a decoding error

```swift
do {
    let user = try await networkClient.send(request: GetUserRequest(id: "99999")) // NetworkRequestWithResponse
} catch let error {  // error is NetworkSendResponseError (no type casting needed!)
    switch error {
    case .transport(.errorStatusCode(let code, let response)):
        // HTTP status outside allowedStatusCodes
        print("HTTP \(code) error")
    case .responseHasNoData:
        // Non-optional response returned empty body
    case .transport(.noNetworkConnection):
        // No active network path
    case .transport(.secureConnectionNotPossible):
        // TLS failure
    default:
        // Other errors (decoding, interceptor throws, etc.)
        print("Error: \(error)")
    }
}
```

**Full error table (`NetworkTransportError` — reachable from every `send` overload via `.transport(_:)`):**

| Error | Cause |
|---|---|
| `.errorStatusCode(code:response:)` | Status outside `allowedStatusCodes` |
| `.noNetworkConnection` | No active network path |
| `.secureConnectionNotPossible` | TLS failure |
| `.unknownURLError(URLError)` | Network-level errors not mapped to specific case |
| `.interceptorError(any Error & Equatable)` | A custom interceptor's escape hatch for domain errors |

**Additional cases, only on the error types that can actually produce them:**

| Error | On type(s) | Cause |
|---|---|---|
| `.cannotEncodeRequestBody(String)` | all | Request encoding failed |
| `.cannotEncodeQuery(String)` | all | Query encoding failed |
| `.responseHasNoData` | `NetworkSendResponseError` only | Empty body when non-optional response expected |
| `.cannotDecodeResponseBody(String)` | `NetworkSendResponseError`, `NetworkSendOptionalResponseError` | Response decoding failed |
| `.headerFieldsMissing` | `NetworkSendHeaderResponseError` only | Required header absent (header response requests) |

---

## Step 5 — Interceptors

Interceptors are `final class` — they often hold dependencies and are allocated once at app
startup, then passed around by reference rather than copied.

### Request interceptor — runs before URLSession

A typical real-world use is injecting an auth token from a session module:

```swift
final class AddAuthInterceptor: NetworkRequestInterceptor {
    private let sessionManager: SessionManager

    init(sessionManager: SessionManager) {
        self.sessionManager = sessionManager
    }

    func intercept(request: inout HTTPRequest) async throws(NetworkTransportError) {
        guard let token = sessionManager.token else {
            throw .interceptorError(AuthError.notAuthenticated)
        }
        request.urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }
}

let config = NetworkClientConfiguration(
    environment: environment,
    requestInterceptor: AddAuthInterceptor(sessionManager: sessionManager)
)
```

### Response interceptor — runs after URLSession, before decoding

```swift
final class BusinessErrorInterceptor: NetworkResponseInterceptor {
    func intercept(response: inout HTTPResponse) async throws(NetworkTransportError) -> NetworkResponseInterceptorResult {
        if response.urlResponse.value(forHTTPHeaderField: "X-Business-Error") == "true" {
            throw .interceptorError(MyError.backendBusinessError)
        }
        return .defaultHandling   // or .retryRequest
    }
}
```

### Per-request interceptors

```swift
struct AuthRequest: NetworkRequest, NetworkRequestWithRequestInterceptor {
    let method: HTTPMethod = .get
    var path: URLPath { #URLPath("secure/resource") }
    let requestInterceptor: NetworkRequestInterceptor = AddAuthInterceptor()
}
```

**Execution order:** Per-request → global → URLSession. Response interceptors run after status code validation. Error interceptors run if any step throws.

---

## Protocol trait reference

| Protocol | When to add |
|---|---|
| `NetworkRequestWithQuery` | Endpoint takes URL query parameters |
| `NetworkRequestWithBody` | Endpoint sends an `Encodable` body |
| `NetworkRequestWithResponse` | Endpoint returns a decodable body |
| `NetworkRequestWithResponse` with optional `ResponseBody` | Response body may be empty (use `typealias ResponseBody = SomeType?`) |
| `NetworkRequestWithHeaderResponse` | Only response headers are needed |
| `NetworkRequestWithTimeout` | Per-request timeout override |
| `NetworkRequestWithRequestInterceptor` | Per-request request mutation |
| `NetworkRequestWithResponseInterceptor` | Per-request response handling |
| `NetworkRequestWithErrorInterceptor` | Per-request error handling |

---

## URL macros

`#URLBase`, `#URLPath`, and `@URLPathTemplate` validate URLs at compile-time (no `?`, `#`, unencoded spaces, or string interpolation). For runtime strings, use `unsafeValue:` initializer.

---

## Adding the Swift Package dependency

In `Package.swift`:

```swift
.package(url: "https://gitlab.adesso-group.com/ams/intern/ios/foundation-libs/networking.git", from: "2.0.0"),
```

Target dependency:

```swift
.product(name: "Networking", package: "Networking")
```

---

## Testing

**Unit tests:** Use `NetworkClientSpy` (inject via `NetworkClient` protocol).  
**Integration tests:** Use `Mocker` with custom `URLSession` (set `config.protocolClasses = [MockingURLProtocol.self]`).
