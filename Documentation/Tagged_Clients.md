# Tagged Network Clients

When your app uses multiple `NetworkClient` instances with different configurations (e.g., public vs authenticated endpoints, different base URLs, or different backend services), it's critical to ensure the correct client is injected into each repository or service. `NetworkClientTagged` provides compile-time safety for this using phantom types.

---

## The problem

Without type-level tagging, all `NetworkClient` instances share the same type:

```swift
// This configuration has just one interceptor adding default HTTP headers like API key and app version.
let publicClient = NetworkClientImpl(configuration: publicConfig)
// This configuration has an interceptor that expects an authenticated session token and will set the Authorization header
// or throw if not authenticated.
let authenticatedClient = NetworkClientImpl(configuration: authenticatedConfig)

class LoginService {
    private let client: NetworkClient
    
    init(client: NetworkClient) {
        self.client = client
    }
}

// ⚠️ Both compile — no way to prevent the wrong client
let loginService = LoginService(client: publicClient)        // Correct
let loginService = LoginService(client: authenticatedClient) // Wrong, because the LoginService must be called without session! But compiles.
```

The compiler cannot distinguish between different client instances. You might accidentally inject an authenticated client into a public service, sending session tokens to unauthenticated endpoints or entirely different backends, posing a security risk.

---

## The solution: Phantom types

`NetworkClientTagged<Tag>` wraps a `NetworkClient` with a phantom type parameter. The `Tag` is never instantiated — it exists only at compile time to distinguish types.

```swift
enum PublicAPI {}
enum AuthenticatedAPI {}

let publicClient = NetworkClientImpl(configuration: publicConfig)
    .tag(with: PublicAPI.self)
// Type: NetworkClientTagged<PublicAPI>

let authenticatedClient = NetworkClientImpl(configuration: authenticatedConfig)
    .tag(with: AuthenticatedAPI.self)
// Type: NetworkClientTagged<AuthenticatedAPI>
```

Now the clients have distinct types. You can require specific tags in your dependency signatures:

```swift
class LoginService {
    private let client: NetworkClientTagged<PublicAPI>
    
    init(client: NetworkClientTagged<PublicAPI>) {
        self.client = client
    }
}

// ✅ Compiles
let loginService = LoginService(client: publicClient)

// ❌ Compile error: cannot convert NetworkClientTagged<AuthenticatedAPI> to NetworkClientTagged<PublicAPI>
let loginService = LoginService(client: authenticatedClient)
```

The compiler enforces that only the correct client can be injected.

---

## How to use tagged clients

### 1. Define tag types

Use empty enums (no cases) as lightweight type markers:

```swift
enum PublicAPI {}
enum AuthenticatedAPI {}
enum AnalyticsAPI {}
```

The enum is never instantiated. It exists solely to provide a unique type for the compiler.

### 2. Create and tag your clients

```swift
// Public client (no authentication)
let publicClient = NetworkClientImpl(
    configuration: NetworkClientConfiguration(
        environment: NetworkEnvironment(base: #URLBase("https://api.example.com"))
    )
).tag(with: PublicAPI.self)

// Authenticated client (adds session token)
let authenticatedClient = NetworkClientImpl(
    configuration: NetworkClientConfiguration(
        environment: NetworkEnvironment(base: #URLBase("https://api.example.com")),
        requestInterceptor: AddSessionTokenInterceptor(sessionProvider: sessionProvider)
    )
).tag(with: AuthenticatedAPI.self)

// Analytics client (different base URL)
let analyticsClient = NetworkClientImpl(
    configuration: NetworkClientConfiguration(
        environment: NetworkEnvironment(base: #URLBase("https://analytics.example.com"))
    )
).tag(with: AnalyticsAPI.self)
```

### 3. Require specific tags in your dependencies

```swift
class LoginService {
    private let client: NetworkClientTagged<PublicAPI>
    
    init(client: NetworkClientTagged<PublicAPI>) {
        self.client = client
    }
    
    func login(email: String, password: String) async throws {
        let request = LoginRequest(body: .init(email: email, password: password))
        try await client.send(request: request)
    }
}

class UserRepository {
    private let client: NetworkClientTagged<AuthenticatedAPI>
    
    init(client: NetworkClientTagged<AuthenticatedAPI>) {
        self.client = client
    }
    
    func fetchProfile() async throws -> User {
        let request = GetProfileRequest()
        return try await client.send(request: request).body
    }
}

class AnalyticsService {
    private let client: NetworkClientTagged<AnalyticsAPI>
    
    init(client: NetworkClientTagged<AnalyticsAPI>) {
        self.client = client
    }
    
    func trackEvent(_ event: AnalyticsEvent) async throws {
        let request = TrackEventRequest(body: event)
        try await client.send(request: request)
    }
}
```

### 4. Wire up dependencies

```swift
// In your dependency injection container or app setup
class NetworkingModule {
    let publicClient: NetworkClientTagged<PublicAPI>
    let authenticatedClient: NetworkClientTagged<AuthenticatedAPI>
    let analyticsClient: NetworkClientTagged<AnalyticsAPI>
    
    init(sessionProvider: SessionProvider) {
        self.publicClient = NetworkClientImpl(
            configuration: NetworkClientConfiguration(
                environment: NetworkEnvironment(base: #URLBase("https://api.example.com"))
            )
        ).tag(with: PublicAPI.self)
        
        self.authenticatedClient = NetworkClientImpl(
            configuration: NetworkClientConfiguration(
                environment: NetworkEnvironment(base: #URLBase("https://api.example.com")),
                requestInterceptor: AddSessionTokenInterceptor(sessionProvider: sessionProvider)
            )
        ).tag(with: AuthenticatedAPI.self)
        
        self.analyticsClient = NetworkClientImpl(
            configuration: NetworkClientConfiguration(
                environment: NetworkEnvironment(base: #URLBase("https://analytics.example.com"))
            )
        ).tag(with: AnalyticsAPI.self)
    }
}

// Inject the correct client
let networking = NetworkingModule(sessionProvider: sessionProvider)
let loginService = LoginService(client: networking.publicClient)
let userRepository = UserRepository(client: networking.authenticatedClient)
let analyticsService = AnalyticsService(client: networking.analyticsClient)
```

---

## Benefits

### ✅ Compile-time safety

The compiler prevents injecting the wrong client. No runtime checks needed.

### ✅ Self-documenting code

When you see `NetworkClientTagged<AuthenticatedAPI>` in a signature, you immediately know which client is required. No need to check implementation details.

### ✅ Refactoring confidence

If you change a dependency's client type, the compiler catches every call site that needs updating.

### ✅ Zero runtime overhead

`NetworkClientTagged` is a thin wrapper that delegates to the underlying client. The phantom type exists only at compile time and is erased after compilation.

---

## Common patterns

### Organizing tags

Keep all your tag types in a single file:

```swift
// NetworkClientTags.swift
enum PublicAPI {}
enum AuthenticatedAPI {}
enum AdminAPI {}
enum AnalyticsAPI {}
enum PaymentAPI {}
```

### Testing

For testing, create a tagged spy:

```swift
let spyClient = NetworkClientSpy(configuration: testConfig)
    .tag(with: PublicAPI.self)

let loginService = LoginService(client: spyClient)
```

---

## When to use tagged clients

### ✅ Use tagged clients when:
- You have multiple client instances with different configurations
- You want compile-time guarantees that the correct client is injected
- You're building a large codebase where mistakes are costly
- You want self-documenting dependency signatures

### ❌ Don't use tagged clients when:
- You only have a single `NetworkClient` in your entire app
- The overhead of defining tag types outweighs the safety benefits (e.g., tiny apps or prototypes)

---

## Related

- [Interception](Interception.md) — When to use multiple `NetworkClient` instances
- [Custom Coders](Custom_Coders.md) — Configuring different coders for different clients
