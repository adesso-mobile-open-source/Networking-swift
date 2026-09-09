# Compile-time URL safety

Networking enforces URL correctness at compile time through three Swift macros. Invalid URLs, missing parameters, and forbidden characters become **compiler errors**, not runtime crashes.

---

## `#URLBase` — validated base URL

Used in `NetworkEnvironment` to declare the scheme, host, and optional path prefix of an API.

```swift
let environment = NetworkEnvironment(
    base: #URLBase("https://api.example.com/v2")
)
```

The macro rejects the following at compile time:

| Violation | Example | Error |
|---|---|---|
| Missing scheme | `#URLBase("api.example.com")` | Must include a scheme |
| Empty host | `#URLBase("https://")` | Must include a non-empty host |
| Query string | `#URLBase("https://api.example.com?key=x")` | Must not contain a query string |
| Fragment | `#URLBase("https://api.example.com#docs")` | Must not contain a fragment |
| Template params | `#URLBase("https://api.example.com/{version}")` | Must not contain template parameters |
| Unencoded space | `#URLBase("https://api.example .com")` | Must not contain unencoded spaces |

---

## `#URLPath` — validated static path

Used to express a fixed path in a `NetworkRequest`:

```swift
struct GetUsersRequest: NetworkRequestWithResponse {
    typealias ResponseBody = [User]
    let method: HTTPMethod = .get
    var path: URLPath { #URLPath("users") }
}
```

The macro rejects:

| Violation | Example | Error |
|---|---|---|
| Empty string | `#URLPath("")` | Path must not be empty |
| Unencoded space | `#URLPath("my users")` | Use %20 |
| Query character | `#URLPath("users?page=1")` | Use `NetworkRequestWithQuery` |
| Fragment | `#URLPath("users#list")` | Use %23 |
| Template param | `#URLPath("users/{id}")` | Use `@URLPathTemplate` |

---

## `@URLPathTemplate` — paths with dynamic segments

Used when path segments are determined at runtime. The macro extracts `{param}` placeholders and generates typed `let` properties and a `path` computed property.

```swift
@URLPathTemplate("users/{id}/posts/{postId}")
struct GetPostRequest: NetworkRequestWithResponse {
    typealias ResponseBody = Post
    let method: HTTPMethod = .get
}
```

The macro generates (visible in Xcode's macro expansion):

```swift
let id: PathParameterStringConvertible
let postId: PathParameterStringConvertible

var path: URLPath {
    URLPath(unsafeValue: "users/\(id.stringRepresentation)/posts/\(postId.stringRepresentation)")
}
```

Swift's compiler synthesises the memberwise initialiser from the generated `let` properties, so you get a fully type-safe call site.

```swift
let request = GetPostRequest(id: 2, postId: 42)
```

### `PathParameterStringConvertible`

Generated properties are typed as `PathParameterStringConvertible` — a protocol that ships with the library:

```swift
public protocol PathParameterStringConvertible: Sendable {
    var stringRepresentation: String { get }
}
```

The library ships conformances for `String`, `Int`, `Int32`, `Int64`, and `UUID`, so common types work with no extra code:

```swift
let byString = GetPostRequest(id: "42", postId: "7")
let byUUID   = GetPostRequest(id: UUID(), postId: UUID())
let byInt    = GetPostRequest(id: 1, postId: 7)
```

For your own model ID types, add an explicit conformance:

```swift
extension UserID: PathParameterStringConvertible {
    public var stringRepresentation: String { value.uuidString }
}

let request = GetUserRequest(id: myUserID)
```

If your type already conforms to `CustomStringConvertible`, a constrained extension on `PathParameterStringConvertible` provides `stringRepresentation` automatically once you declare the conformance — no body needed:

```swift
extension MyID: PathParameterStringConvertible {}
// stringRepresentation returns description automatically
```

```swift
let request = GetPostRequest(id: "42", postId: "7")
```

Missing or misspelled parameters are caught at compile time.

The macro rejects the same invalid characters as `#URLPath` in the non-placeholder segments, and disallows duplicate parameter names.

---

## URL composition

`URLBase + URLPath` produces a `ResolvedURL` via the `+` operator. `NetworkClientImpl` performs this composition automatically — you never call `+` manually in application code, but you can inspect it in tests or tooling:

```swift
let base = #URLBase("https://api.example.com/v1")
let path = #URLPath("users/profile")
let resolved: ResolvedURL = base + path
// resolved.rawValue == "https://api.example.com/v1/users/profile"
```

The `+` operator handles trailing/leading slash normalisation so neither side needs to coordinate slash placement.

To attach query parameters to a `ResolvedURL`:

```swift
let withQuery = resolved.appending(queryItems: [URLQueryItem(name: "page", value: "2")])
let url: URL = withQuery.url   // non-optional — both inputs are macro-validated
```

In practice, query parameters are always attached via `NetworkRequestWithQuery` — the library handles this internally.
