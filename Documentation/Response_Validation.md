# Response validation

`NetworkClient` validates the HTTP status code of every response automatically, using the `allowedStatusCodes` range declared on each `NetworkRequest`. If the response code falls outside that range, `.transport(.errorStatusCode)` is thrown as part of whichever `send`-overload-specific error type applies (e.g. `NetworkSendError`, `NetworkSendResponseError` — see [Sending Requests](Sending_Requests.md#error-handling)).

**💡 For advanced scenarios** like decoding error response bodies or handling multiple response types per status code, see [Advanced Response Handling](Advanced_Response_Handling.md).

---

## Execution order

Status code validation happens automatically in this order:

1. **URLSession** returns the HTTP response
2. **Status code validation** checks if response code is in `allowedStatusCodes` range
3. If validation fails: `NetworkTransportError.errorStatusCode` is thrown → error interceptors run (if configured)
4. If validation succeeds: Response interceptors run → body is decoded → result returned

**Key points:**
- Status validation is built into `NetworkClient`, not implemented via a response interceptor
- If status validation fails, response interceptors never run (the error is thrown before they execute)
- Error interceptors can catch status code errors and retry the request or handle them gracefully

## Default behaviour

By default every request accepts status codes in `200..<300`. No additional configuration is required:

```swift
struct GetUsersRequest: NetworkRequestWithResponse {
    typealias ResponseBody = [User]
    let method: HTTPMethod = .get
    var path: URLPath { #URLPath("users") }
    // allowedStatusCodes defaults to 200..<300
}
```

## Customising the accepted status range per request

Override `allowedStatusCodes` directly on the request type:

```swift
struct AcceptCreatedRequest: NetworkRequestWithResponse {
    typealias ResponseBody = Resource
    let method: HTTPMethod = .post
    var path: URLPath { #URLPath("resources") }

    // Accept 200 OK and 201 Created only
    var allowedStatusCodes: Range<Int> { 200..<202 }
}
```

## Disabling status validation for a single request

Return the widest possible range to skip validation entirely for one request:

```swift
struct RawRequest: NetworkRequest {
    let method: HTTPMethod = .get
    var path: URLPath { #URLPath("raw/endpoint") }

    var allowedStatusCodes: Range<Int> { 100..<600 }
}
```

## Custom validation and error handling

For complex scenarios beyond simple status code ranges, you have two options:

### Option 1: Response interceptor (for global logic)

Implement `NetworkResponseInterceptor` to apply custom validation logic before responses are processed:

```swift
struct APIErrorInterceptor: NetworkResponseInterceptor {
    func intercept(response: inout HTTPResponse) async throws(NetworkTransportError) -> NetworkResponseInterceptorResult {
        guard (200..<300).contains(response.urlResponse.statusCode) else {
            let errorBody = try? JSONDecoder().decode(APIError.self, from: response.data)
            // Interceptors can only throw NetworkTransportError, so custom domain errors are
            // wrapped via .interceptorError — see Interception.md.
            throw .interceptorError(AppError.apiError(code: response.urlResponse.statusCode, body: errorBody))
        }
        return .defaultHandling
    }
}
```

Note that a per-request response interceptor runs **after** status code validation, so it only sees responses with an accepted status code unless it is attached at a point where the error is caught and re-inspected.

See [Interception](Interception.md) for full details on how to configure response interceptors.

### Option 2: Manual decoding (for per-request logic)

For request-specific needs like decoding error bodies or handling multiple response types, use manual decoding:

```swift
do {
    try await client.send(request: request) // NetworkRequestWithResponse → NetworkSendResponseError
} catch let NetworkSendResponseError.transport(.errorStatusCode(code, response)) {
    // Decode structured error from response.data
    if let apiError = try? JSONDecoder().decode(APIError.self, from: response.data) {
        // Handle typed error
    }
}
```

See [Advanced Response Handling](Advanced_Response_Handling.md) for detailed examples and patterns.

---

## See Also

- [Advanced Response Handling](Advanced_Response_Handling.md) — Decoding error bodies, status-specific responses
- [Interception](Interception.md) — Response and error interceptors
- [Sending Requests](Sending_Requests.md) — Error handling with typed throws
