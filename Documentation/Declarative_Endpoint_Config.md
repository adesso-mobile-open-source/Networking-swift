# Declarative endpoint configuration

Each endpoint is declared as a value type — typically a `struct` — that conforms to `NetworkRequest` and any combination of the trait protocols below. The compiler enforces that all required properties are present; no configuration is done at runtime.

## Protocol traits

| Trait | Protocol | When to use |
|---|---|---|
| Query parameters | `NetworkRequestWithQuery` | Endpoint accepts URL query parameters |
| Request body | `NetworkRequestWithBody` | POST / PUT / PATCH with a body |
| Decodable response | `NetworkRequestWithResponse` | Endpoint returns a JSON (or custom) body |
| Optional response body | `NetworkRequestWithResponse` with optional `ResponseBody` | Response body may be empty (use `typealias ResponseBody = SomeType?`) |
| Response headers only | `NetworkRequestWithHeaderResponse` | Only header fields are needed from the response |
| Per-request timeout | `NetworkRequestWithTimeout` | Request needs a different timeout than the session default |
| Per-request request interceptor | `NetworkRequestWithRequestInterceptor` | Custom request mutation for this request only |
| Per-request response interceptor | `NetworkRequestWithResponseInterceptor` | Custom response handling for this request only |
| Per-request error interceptor | `NetworkRequestWithErrorInterceptor` | Custom error handling for this request only |

Protocols are fully composable. Only declare the traits your endpoint actually needs.

---

## Examples

### Static path, response body

```swift
struct GetUsersRequest: NetworkRequestWithResponse {
    typealias ResponseBody = [User]
    let method: HTTPMethod = .get
    var path: URLPath { #URLPath("users") }
}
```

### Dynamic path via macro

```swift
@URLPathTemplate("users/{id}")
struct GetUserRequest: NetworkRequestWithResponse {
    typealias ResponseBody = User
    let method: HTTPMethod = .get
}

// Usage — all parameters are required by the compiler-synthesised initialiser:
let request = GetUserRequest(id: "42")
```

### Query parameters and response

```swift
struct SearchUsersRequest: NetworkRequestWithQuery, NetworkRequestWithResponse {
    struct Query: Encodable {
        let name: String
        let page: Int
    }

    typealias ResponseBody = [User]
    let method: HTTPMethod = .get
    var path: URLPath { #URLPath("users/search") }
    let query: Query
}
```

### Request body, no response

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
```

### Request body and response

```swift
@URLPathTemplate("users/{id}")
struct UpdateUserRequest: NetworkRequestWithBody, NetworkRequestWithResponse {
    struct RequestBody: Encodable { let name: String }
    typealias ResponseBody = User

    let method: HTTPMethod = .put
    let body: RequestBody
    // macro generates: let id: String, var path: URLPath
}
```

### Dynamic path with query parameters

```swift
@URLPathTemplate("accounts/{accountId}/transactions")
struct GetTransactionsRequest: NetworkRequestWithQuery, NetworkRequestWithResponse {
    struct Query: Encodable { let from: Date; let to: Date }
    typealias ResponseBody = [Transaction]
    let method: HTTPMethod = .get
    let query: Query
}
```

### Custom headers per request

```swift
struct AuthenticatedRequest: NetworkRequestWithResponse {
    typealias ResponseBody = SecureResource
    let method: HTTPMethod = .get
    var path: URLPath { #URLPath("secure/resource") }
    var headers: [HTTPHeader: String] {
        [.authorization: "Bearer \(token)"]
    }
}
```

Request-specific headers override `NetworkEnvironment.defaultHeaders` for duplicate keys.
