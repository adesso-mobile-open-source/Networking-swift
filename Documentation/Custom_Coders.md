# Custom en-/decoding

By default, `NetworkClient` uses `JSONEncoder` and `JSONDecoder` for encoding request bodies and decoding response bodies. If your backend uses a different format (e.g., XML, Protocol Buffers, or custom JSON configurations), you can provide custom coders globally via `NetworkClientConfiguration` or per-request via the `httpBodyEncoder` and `httpBodyDecoder` properties.

## How defaults work

When a request is sent:

1. **Per-request coders are checked first**: If `httpBodyEncoder` or `httpBodyDecoder` returns a non-`nil` value on the request, that coder is used.
2. **Global coders are used as fallback**: If the request returns `nil` (the default), `NetworkClient` uses the coders from `NetworkClientConfiguration`.
3. **Built-in JSON coders**: If you don't specify any custom coders during `NetworkClient` initialization, standard `JSONEncoder()` and `JSONDecoder()` instances are used.

This allows you to set global defaults for your entire client while still overriding coders for specific requests when needed.

## `DataEncoding`

```swift
public protocol DataEncoding: Sendable {
    func encode<T: Encodable>(_ model: T) throws -> Data
}
```

Example — a hypothetical XML encoder:

```swift
struct XMLEncoder: DataEncoding {
    func encode<T: Encodable>(_ model: T) throws -> Data {
        // ... your XML serialisation
    }
}
```

## `DataDecoding`

```swift
public protocol DataDecoding: Sendable {
    func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T
}
```

Example:

```swift
struct XMLDecoder: DataDecoding {
    func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        // ... your XML deserialisation
    }
}
```

## Plugging in custom coders

### Globally (via configuration)

```swift
let config = NetworkClientConfiguration(
    environment: environment,
    httpBodyEncoder: XMLEncoder(),
    httpBodyDecoder: XMLDecoder()
)
let networkClient = NetworkClientImpl(configuration: config)
```

### Per-request

Returning a non-`nil` value from `httpBodyEncoder` or `httpBodyDecoder` on the request overrides the global coder for that request only.

**Note**: By default, these properties return `nil` in the protocol extension, meaning the `NetworkClient` will use the global coders from its configuration. Only override these properties when you need a different coder for a specific request.

#### Example: Custom encoder for a single request

```swift
struct SubmitXMLRequest: NetworkRequestWithBody {
    struct RequestBody: Encodable { let value: String }
    let method: HTTPMethod = .post
    var path: URLPath { #URLPath("xml/submit") }
    let body: RequestBody
    
    // Override the global encoder for this request only
    var httpBodyEncoder: DataEncoding? { XMLEncoder() }
}
```

#### Example: Custom decoder for a single request

```swift
struct FetchLegacyDataRequest: NetworkRequestWithResponse {
    struct ResponseBody: Decodable { let data: String }
    let method: HTTPMethod = .get
    var path: URLPath { #URLPath("legacy/data") }
    
    // Override the global decoder for this request only
    var httpBodyDecoder: DataDecoding? {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return decoder
    }
}
```

## JSON is built in

`JSONEncoder` and `JSONDecoder` conform to `DataEncoding` and `DataDecoding` out of the box. Customise them as usual and pass the instances where a coder is expected:

```swift
let decoder = JSONDecoder()
decoder.keyDecodingStrategy = .convertFromSnakeCase
decoder.dateDecodingStrategy = .iso8601

let config = NetworkClientConfiguration(
    environment: environment,
    httpBodyDecoder: decoder
)
```

---

## When to use global vs per-request vs multiple clients

### Use **global coders** when:
- Your entire backend uses the same serialization format (e.g., all endpoints are JSON with snake_case)
- You want a consistent default across all requests

### Use **per-request coders** when:
- A handful of endpoints use a different format than the rest (e.g., one legacy XML endpoint in an otherwise JSON API)
- One endpoint needs special JSON configuration (e.g., different date format)

### Use **separate NetworkClient instances** when:
- You're communicating with entirely different backend services or APIs
- Different logical parts of your backend have fundamentally different configurations (e.g., one uses JSON, another uses XML)
- You have different authentication requirements (public vs authenticated endpoints)

**💡 Tip:** Use [Tagged Clients](Tagged_Clients.md) to enforce at compile time that services receive the correctly-configured client.

See [Interception](Interception.md) for more details on when to use multiple `NetworkClient` instances and how to manage them.

---

## See Also

- [Codable Body](Codable_Body.md) — Standard request/response body handling
- [Interception](Interception.md) — When to use multiple NetworkClient instances
- [Tagged Clients](Tagged_Clients.md) — Type-safe dependency injection for multiple clients
- [Advanced Response Handling](Advanced_Response_Handling.md) — Manual decoding for special cases
