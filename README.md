# Networking

A thin, compile-time-safe HTTP networking layer built on `URLSession` and Swift macros.

```swift
// 1. Declare an environment (validated at compile time)
let environment = NetworkEnvironment(
    base: #URLBase("https://api.example.com/v1"),
    defaultHeaders: [.authorization: "Bearer \(token)"]
)

// 2. Describe an endpoint
@URLPathTemplate("users/{id}/posts")
struct GetPostsRequest: NetworkRequestWithResponse {
    typealias ResponseBody = [Post]
    let method: HTTPMethod = .get
}

// 3. Send it
let response = try await networkClient.send(request: GetPostsRequest(id: "42"))
let posts = response.body  // [Post]

// Dynamic member lookup lets you access body properties directly:
let firstPost = response.first      // equivalent to response.body.first
let postCount = response.count      // equivalent to response.body.count
```

## Why this library?

This library takes a **declarative, composable, and compile-time-safe** approach to networking, built around Swift concurrency from the ground up. It aligns closely with Swift's core pillar of compile-time safety, catching errors before your code runs.

### Declarative endpoint definitions

Define your API endpoints as value types that declare their requirements through composable protocol traits:

```swift
struct GetUserRequest: NetworkRequestWithResponse {
    typealias ResponseBody = User
    let method: HTTPMethod = .get
    var path: URLPath { #URLPath("users/42") }
}
```

No manual URL construction, no stringly-typed paths, no runtime configuration. The compiler verifies everything.

### Compile-time safety throughout

The library enforces correctness at every layer:

| What | How | Benefit |
|------|-----|---------|
| **URL construction** | `#URLBase`, `#URLPath`, `@URLPathTemplate` macros | Malformed URLs cannot compile |
| **Request configuration** | Composable protocol traits | The compiler tells you what configuration is required for each trait. |
| **Response types** | Generic `send<R>` overloads | Type system ensures correct request/response handling |
| **Error handling** | Typed throws with overload-specific error types (`NetworkSendError`, `NetworkSendResponseError`, etc.) | Exhaustive error handling verified by compiler — only errors that overload can actually throw |
| **Dependency injection** | `NetworkClientTagged<Tag>` phantom types | Wrong client injection = compile error |

### Composable protocol traits

Build complex requests by composing simple protocol traits:

```swift
struct SearchRequest: NetworkRequestWithQuery,      // + query params
                      NetworkRequestWithBody,        // + request body  
                      NetworkRequestWithResponse {   // + response body
    struct Query: Encodable { let term: String }
    struct RequestBody: Encodable { let filters: [String] }
    typealias ResponseBody = [Result]
    
    let method: HTTPMethod = .post
    var path: URLPath { #URLPath("search") }
    let query: Query
    let body: RequestBody
}
```

Each trait adds exactly one capability. Compose only what you need.

### Built on Swift concurrency

Every `send` method is `async` and uses typed throws. The library is `Sendable`-aware throughout, with `@NetworkActor` ensuring thread-safe client operations. No callbacks, no completion handlers, no `Result` types—just structured concurrency.

### Type-driven request routing

The compiler selects the correct `send` implementation based on your request's type:

```swift
// No response body → send() returns NetworkResponse<EmptyBody>
try await client.send(request: CreateUserRequest(...))

// Response body → send() returns NetworkResponse<User>
try await client.send(request: GetUserRequest())

// Optional response → send() returns NetworkResponse<User?>
try await client.send(request: GetDraftRequest())  // ResponseBody = Draft?
```

Zero runtime dispatch. The type system does the work.

## Features

- [Compile-time URL safety](Documentation/Compile_Time_Safety.md) — `#URLBase`, `#URLPath`, `@URLPathTemplate`
- [Declarative endpoint configuration](Documentation/Declarative_Endpoint_Config.md)
- [Sending requests with async/await](Documentation/Sending_Requests.md)
- [Encodable query parameters](Documentation/Encodable_Query.md)
- [Codable request/response bodies](Documentation/Codable_Body.md)
- [Custom en-/decoders](Documentation/Custom_Coders.md)
- [HTTP response validation](Documentation/Response_Validation.md)
- [Request/Response/Error interception](Documentation/Interception.md)
- [Tagged clients for type-safe dependency injection](Documentation/Tagged_Clients.md)
- [Advanced response handling](Documentation/Advanced_Response_Handling.md) — Manual decoding, error bodies, multi-type responses

## Quick start

### 1. Create a `NetworkEnvironment`

```swift
let environment = NetworkEnvironment(
    base: #URLBase("https://api.example.com/v1")
)
```

Pass `defaultHeaders` for headers that apply to every request (e.g. API keys):

```swift
let environment = NetworkEnvironment(
    base: #URLBase("https://api.example.com/v1"),
    defaultHeaders: ["X-API-Key": "secret"]
)
```

### 2. Create a `NetworkClient`

```swift
let networkClient = NetworkClientImpl(
    configuration: NetworkClientConfiguration(environment: environment)
)
```

**With interceptors using array literal syntax:**

```swift
let networkClient = NetworkClientImpl(
    configuration: NetworkClientConfiguration(
        environment: environment,
        requestInterceptor: [loggingInterceptor, authInterceptor],
        responseInterceptor: [cacheInterceptor, metricsInterceptor],
        errorInterceptor: [retryInterceptor, analyticsInterceptor]
    )
)
```

**Multiple clients with type-safe tagging:**

If you have multiple client instances (e.g., public vs authenticated, or different backend services), use tagged clients for compile-time safety:

```swift
enum PublicAPI {}
enum AuthenticatedAPI {}

let publicClient = NetworkClientImpl(configuration: publicConfig)
    .tag(with: PublicAPI.self)

let authenticatedClient = NetworkClientImpl(configuration: authenticatedConfig)
    .tag(with: AuthenticatedAPI.self)

// Type-safe dependency injection
class LoginService {
    init(client: NetworkClientTagged<PublicAPI>) { ... }  // Only accepts public client
}
```

See [Tagged Clients](Documentation/Tagged_Clients.md) for details.

### 3. Define your endpoints

**Static path:**
```swift
struct GetUsersRequest: NetworkRequestWithResponse {
    typealias ResponseBody = [User]
    let method: HTTPMethod = .get
    var path: URLPath { #URLPath("users") }
}
```

**Dynamic path (macro-generated parameters):**
```swift
@URLPathTemplate("users/{id}")
struct GetUserRequest: NetworkRequestWithResponse {
    typealias ResponseBody = User
    let method: HTTPMethod = .get
}
// Parameters accept any PathParameterStringConvertible — String, UUID, Int, or your own types:
let byString = GetUserRequest(id: "42")
let byUUID   = GetUserRequest(id: UUID())
let byInt    = GetUserRequest(id: 42)
```

**Custom parameter types:**

Path parameters can be any type conforming to `PathParameterStringConvertible`:

```swift
extension UserID: PathParameterStringConvertible {
    var stringRepresentation: String { rawValue }
}

let request = GetUserRequest(id: myUserID)  // Works!
```

Built-in conformances: `String`, `UUID`, `Int`, `Int32`, `Int64`

**With query parameters:**
```swift
struct SearchUsersRequest: NetworkRequestWithQuery, NetworkRequestWithResponse {
    struct Query: Encodable { let name: String; let page: Int }
    typealias ResponseBody = [User]
    let method: HTTPMethod = .get
    var path: URLPath { #URLPath("users/search") }
    let query: Query
}
```

**With request body:**
```swift
struct CreateUserRequest: NetworkRequestWithBody {
    struct RequestBody: Encodable { let name: String; let email: String }
    let method: HTTPMethod = .post
    var path: URLPath { #URLPath("users") }
    let body: RequestBody
}
```

### 4. Send requests

All `send` methods return `NetworkResponse<T>` and use typed throws with an error type scoped to
what that specific overload can actually throw (e.g. `NetworkSendError`, `NetworkSendResponseError`):

```swift
// No response body — returns NetworkResponse<EmptyBody>
let response = try await networkClient.send(
    request: CreateUserRequest(body: .init(name: "Ada", email: "ada@example.com"))
)

// With response body — returns NetworkResponse<[User]>
let response = try await networkClient.send(request: GetUsersRequest())
let users = response.body  // Extract the decoded body

// With optional response body — returns NetworkResponse<User?>
let response = try await networkClient.send(request: GetUserRequest(id: "42"))
let user = response.body  // User? type
```

**Access response metadata:**

```swift
response.body         // The decoded body
response.statusCode   // HTTP status code (e.g., 200)
response.headerFields // Response headers
response.rawBody      // Raw Data for manual decoding
```

**Dynamic member lookup (`@dynamicMemberLookup`):**

Access body properties directly without `.body`:

```swift
// These are equivalent:
let firstUser = response.first
let firstUser = response.body.first

let count = response.count
let count = response.body.count

// Works with methods too:
let filtered = response.filter { $0.isActive }
let filtered = response.body.filter { $0.isActive }
```

If there's a name conflict (e.g., `body` has a `statusCode` property), `NetworkResponse` properties take precedence. Use explicit `response.body.propertyName` to disambiguate.

**Typed throws (Swift 6), scoped per overload:**

Each `send` overload declares the smallest error type that matches its own call tree, so you never
need a `default:` catch-all for cases that overload could never actually produce:

| `send` overload | Throws | Cases |
|---|---|---|
| `send(some NetworkRequest)` / `send(some NetworkRequestWithBody)` | `NetworkSendError` | transport + query/body encoding |
| `send<R: NetworkRequestWithResponse>` (± body) | `NetworkSendResponseError` | + `responseHasNoData`, `cannotDecodeResponseBody` |
| optional-`ResponseBody` overloads (± body) | `NetworkSendOptionalResponseError` | + `cannotDecodeResponseBody` only (empty body → `nil`, never thrown) |
| `send(some NetworkRequestWithHeaderResponse)` | `NetworkSendHeaderResponseError` | + `headerFieldsMissing` |

All four embed shared connectivity/TLS/status-code/interceptor failures via a `.transport(NetworkTransportError)` case:

```swift
do {
    let response = try await client.send(request: request) // NetworkRequestWithResponse
} catch let .transport(.errorStatusCode(code, response)) {
    print("HTTP \(code) error")
    // Decode error body from response.data if needed
} catch .transport(.noNetworkConnection) {
    print("No internet connection")
} catch let .cannotDecodeResponseBody(message) {
    print("Decoding failed: \(message)")
} catch let .responseHasNoData {
    print("Expected a body but got none")
}
```

**Why typed throws, split per overload?**
- ✅ No type casting required (`as NetworkSendResponseError` is unnecessary)
- ✅ Compiler verifies exhaustive error handling
- ✅ Autocomplete shows only relevant errors
- ✅ A `send(request: some NetworkRequest)` call can't be handled for a `headerFieldsMissing` or `cannotDecodeResponseBody` case it could never throw

---

For full documentation see the [Documentation](Documentation/Features.md) folder.
