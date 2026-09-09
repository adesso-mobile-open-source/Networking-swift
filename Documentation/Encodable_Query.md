# Encodable query parameters

Add `NetworkRequestWithQuery` to your request to append typed query parameters to the URL.

```swift
public protocol NetworkRequestWithQuery: NetworkRequest {
    associatedtype Query: Encodable
    var query: Query { get }
    var dateEncodingStrategy: QueryDateEncodingStrategy { get }
}
```

## Defining a query

Declare a nested `Query` struct conforming to `Encodable`. Property names become URL parameter keys:

```swift
struct SearchUsersRequest: NetworkRequestWithQuery, NetworkRequestWithResponse {
    struct Query: Encodable {
        let name: String
        let page: Int
        let active: Bool
    }

    typealias ResponseBody = [User]
    let method: HTTPMethod = .get
    var path: URLPath { #URLPath("users/search") }
    let query: Query
}

// Produces: GET /users/search?active=true&name=Ada&page=1
let request = SearchUsersRequest(query: .init(name: "Ada", page: 1, active: true))
```

Query items are sorted alphabetically by key before being appended, ensuring a deterministic URL for testing and caching.

## Date encoding

The default strategy encodes `Date` values as `yyyy-MM-dd`:

```swift
struct GetTransactionsRequest: NetworkRequestWithQuery {
    struct Query: Encodable { let from: Date; let to: Date }
    let method: HTTPMethod = .get
    var path: URLPath { #URLPath("transactions") }
    let query: Query
    // dateEncodingStrategy defaults to .dateOnly → "2026-01-31"
}
```

Override `dateEncodingStrategy` to use ISO 8601 date-time with UTC offset:

```swift
struct GetEventsRequest: NetworkRequestWithQuery {
    struct Query: Encodable { let after: Date }
    let method: HTTPMethod = .get
    var path: URLPath { #URLPath("events") }
    let query: Query
    let dateEncodingStrategy: QueryDateEncodingStrategy = .dateTimeWithOffset
    // Produces: "2026-01-31T12:45:06+01:00"
}
```

## Dynamic path with query

`@URLPathTemplate` and `NetworkRequestWithQuery` compose freely:

```swift
@URLPathTemplate("accounts/{accountId}/transactions")
struct GetTransactionsRequest: NetworkRequestWithQuery, NetworkRequestWithResponse {
    struct Query: Encodable { let from: Date; let to: Date }
    typealias ResponseBody = [Transaction]
    let method: HTTPMethod = .get
    let query: Query
}

// Usage:
let request = GetTransactionsRequest(accountId: "123", query: .init(from: startDate, to: endDate))
```
