# Interception

Networking supports three interception points: request, response, and error. Each can be configured globally (via `NetworkClientConfiguration`) or per-request (via the `NetworkRequestWith*Interceptor` protocols).

---

## When to NOT to use interception

**Different backend configurations should use different `NetworkClient` instances.** Do not try to handle multiple backend configurations or authentication states with a single client and conditional interceptors.

**💡 Tip:** Use [Tagged Clients](Tagged_Clients.md) to enforce at compile time that the correct client is injected into each service or repository.

### Use separate instances for:

#### 1. **Different base URLs**

If your app communicates with multiple backend services (e.g., a main API and a separate analytics service), create a dedicated `NetworkClient` for each:

```swift
// Main API client
let mainAPIClient = NetworkClientImpl(
    configuration: NetworkClientConfiguration(
        environment: NetworkEnvironment(base: URL(string: "https://api.example.com")!)
    )
)

// Analytics API client
let analyticsClient = NetworkClientImpl(
    configuration: NetworkClientConfiguration(
        environment: NetworkEnvironment(base: URL(string: "https://analytics.example.com")!)
    )
)
```

#### 2. **Different authentication requirements**

If your backend has both public (unauthenticated) and authenticated endpoints, use separate clients:

```swift
// Public client (no authentication)
let publicClient = NetworkClientImpl(
    configuration: NetworkClientConfiguration(
        environment: environment
    )
)

// Authenticated client (adds session token to all requests)
let authenticatedClient = NetworkClientImpl(
    configuration: NetworkClientConfiguration(
        environment: environment,
        requestInterceptor: AddSessionTokenRequestInterceptor(sessionProvider: sessionProvider)
    )
)
```

Use `publicClient` for login, registration, and public data retrieval. Use `authenticatedClient` for all authenticated operations. This keeps authentication concerns cleanly separated and prevents accidentally sending tokens to public endpoints.

#### 3. **Different encoding/decoding formats**

If different parts of your backend use different serialization formats:

```swift
// JSON client (default)
let jsonClient = NetworkClientImpl(
    configuration: NetworkClientConfiguration(environment: environment)
)

// XML client
let xmlClient = NetworkClientImpl(
    configuration: NetworkClientConfiguration(
        environment: environment,
        httpBodyEncoder: XMLEncoder(),
        httpBodyDecoder: XMLDecoder()
    )
)
```

### Benefits of multiple instances

- **Clearer separation of concerns**: Each client has a single, well-defined purpose
- **Type safety**: No runtime checks needed to determine which interceptors to apply
- **Easier testing**: Mock only the specific client your test needs
- **Better performance**: Avoid conditional logic in interceptors that runs on every request
- **Simpler debugging**: Request/response logs are naturally grouped by client instance

### Managing multiple instances

Keep your `NetworkClient` instances alive for the app's lifetime and inject them via dependency injection.

See [Tagged Clients](Tagged_Clients.md) for detailed documentation on how to ensure at compile-time that the correct `NetworkClient` instance is injected.

---

## Request interception

Executes immediately before the `URLRequest` is handed to `URLSession`. The interceptor receives a mutable `HTTPRequest`, which already contains the composed URL (including query), method, headers, and body.

```swift
public protocol NetworkRequestInterceptor: Sendable {
    func intercept(request: inout HTTPRequest) async throws(NetworkTransportError)
}
```

### Creating a request interceptor

```swift
struct AddRequestIdInterceptor: NetworkRequestInterceptor {
    func intercept(request: inout HTTPRequest) async throws(NetworkTransportError) {
        request.urlRequest.setValue(request.uuid.uuidString, forHTTPHeaderField: "X-Request-ID")
    }
}
```

A common real-world example is a session token interceptor provided by your authentication/session module:

```swift
struct AddSessionTokenRequestInterceptor: NetworkRequestInterceptor {
    private let sessionProvider: SessionProvider

    func intercept(request: inout HTTPRequest) async throws(NetworkTransportError) {
        guard let token = sessionProvider.currentToken else {
            throw .interceptorError(SessionError.notAuthenticated)
        }
        request.urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }
}
```

The session module owns `SessionProvider` and vends the interceptor; the networking layer stays decoupled from authentication details.

For simple cases use `ClosureRequestInterceptor`:

```swift
let interceptor = ClosureRequestInterceptor { request in
    request.urlRequest.setValue(token, forHTTPHeaderField: "Authorization")
}

// No-op interceptor
let noop = ClosureRequestInterceptor.empty  // Also: .ResponseInterceptor.empty, .ErrorInterceptor.empty
```

### Configuring globally

```swift
let config = NetworkClientConfiguration(
    environment: environment,
    requestInterceptor: AddRequestIdInterceptor()
)
```

### Configuring per-request

```swift
struct AuthenticatedRequest: NetworkRequest, NetworkRequestWithRequestInterceptor {
    let method: HTTPMethod = .get
    var path: URLPath { #URLPath("secure/resource") }
    let requestInterceptor: NetworkRequestInterceptor = AddTokenInterceptor()
}
```

Per-request interceptors run **before** the global interceptor (so the global interceptor sees the already-mutated request last, enabling accurate logging).

---

## Response interception

Executes after the server response arrives, before the body is decoded or returned. The interceptor may mutate the response data or signal a retry.

```swift
public protocol NetworkResponseInterceptor: Sendable {
    func intercept(response: inout HTTPResponse) async throws(NetworkTransportError) -> NetworkResponseInterceptorResult
}
```

Return values:

| Result | Effect |
|---|---|
| `.defaultHandling` | Continue normally |
| `.retryRequest` | Re-execute the entire request, re-evaluating request interceptors |

### Creating a response interceptor

```swift
struct BusinessErrorInterceptor: NetworkResponseInterceptor {
    func intercept(response: inout HTTPResponse) async throws(NetworkTransportError) -> NetworkResponseInterceptorResult {
        if response.urlResponse.value(forHTTPHeaderField: "X-Business-Error") == "true" {
            throw .interceptorError(MyError.backendBusinessError)
        }
        return .defaultHandling
    }
}
```

### Built-in: HTTP status validation

Status code validation is built into `NetworkClient` and driven by `NetworkRequest.allowedStatusCodes` (default `200..<300`). It runs before any response interceptor. See [Response Validation](Response_Validation.md) for customisation options.

### Configuring per-request

```swift
struct SensitiveRequest: NetworkRequest, NetworkRequestWithResponseInterceptor {
    let method: HTTPMethod = .get
    var path: URLPath { #URLPath("sensitive/data") }
    let responseInterceptor: NetworkResponseInterceptor = DecryptResponseInterceptor()
}
```

Per-request response interceptors run **after** the global interceptor.

---

## Error interception

Executes when a `URLSession` error maps to a `NetworkTransportError`, or when a response interceptor throws a `NetworkTransportError`. Allows logging, lock-out display, or retry logic.

```swift
public protocol NetworkErrorInterceptor: Sendable {
    func intercept(error: NetworkTransportError) async -> NetworkErrorInterceptorResult
}
```

Return values:

| Result | Effect |
|---|---|
| `.defaultHandling` | Rethrow the error to the call site |
| `.retryRequest` | Re-execute the entire request, re-evaluating request interceptors |

### Creating an error interceptor

```swift
struct LogAndRetryErrorInterceptor: NetworkErrorInterceptor {
    func intercept(error: NetworkTransportError) async -> NetworkErrorInterceptorResult {
        logger.error("Network error: \(error)")
        if error == .noNetworkConnection {
            return .retryRequest
        }
        return .defaultHandling
    }
}
```

---

## Interceptor scope and execution order

### Request interceptors

```
1. Per-request interceptor  (NetworkRequestWithRequestInterceptor)
2. Global interceptor       (NetworkClientConfiguration.requestInterceptor)
```

### Response interceptors

```
1. Global interceptor       (NetworkClientConfiguration.responseInterceptor)
2. Per-request interceptor  (NetworkRequestWithResponseInterceptor)
```

This ordering ensures a global logging interceptor observes the final outgoing request and the raw incoming response.

---

## Chaining interceptors

Each interceptor slot holds a single interceptor. To compose multiple, use array literal syntax or the chaining helpers.

### Array literal syntax (Swift 6+)

All three chained interceptor types conform to `ExpressibleByArrayLiteral`, allowing concise composition:

```swift
// Request interceptors
let config = NetworkClientConfiguration(
    environment: environment,
    requestInterceptor: [authInterceptor, loggingInterceptor, metricsInterceptor],
    responseInterceptor: [cacheInterceptor, businessErrorInterceptor],
    errorInterceptor: [retryInterceptor, analyticsInterceptor]
)
```

Interceptors execute in array order: `first → second → third`

### Chaining methods (alternative API)

For programmatic composition or when storing individual interceptors:

```swift
// Request: execute A then B (A runs first, B runs second)
let combined = interceptorA.chain(before: interceptorB)

// Request: execute B then A (B runs first, A runs second)
let combined = interceptorA.chain(after: interceptorB)

// Arbitrary list (executed in array order: first → second → third)
let combined = ChainedRequestInterceptor.chain(inOrder: [first, second, third])
let combined = ChainedResponseInterceptor.chain(inOrder: [first, second, third])
let combined = ChainedErrorInterceptor.chain(inOrder: [first, second, third])
```

Chained interceptors also conform to their respective protocol, so chains are infinitely composable. Build composite interceptors once at startup and keep them alive for the app's lifetime.
