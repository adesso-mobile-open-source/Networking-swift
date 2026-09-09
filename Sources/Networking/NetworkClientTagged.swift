//
//  NetworkClientTagged.swift
//  Networking
//
//  Created by Niklas Holloh on 25.06.26.
//  Copyright 2026 adesso SE
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  http://www.apache.org/licenses/LICENSE-2.0
//

/// A type-safe wrapper around `NetworkClient` that uses phantom types to distinguish
/// between different client instances at compile time.
///
/// `NetworkClientTagged` allows you to have multiple `NetworkClient` instances with
/// different configurations (e.g., public vs authenticated, different base URLs) and
/// enforce at compile time that the correct client is injected into each part of your app.
///
/// ## Usage
///
/// ```swift
/// // Define tag types (empty enums work well)
/// enum PublicAPI {}
/// enum AuthenticatedAPI {}
///
/// // Tag your clients
/// let publicClient = NetworkClientImpl(...)
///     .tag(with: PublicAPI.self)
///
/// let authenticatedClient = NetworkClientImpl(...)
///     .tag(with: AuthenticatedAPI.self)
///
/// // Use in dependency injection
/// class LoginService {
///     init(client: NetworkClientTagged<PublicAPI>) { ... }
/// }
///
/// class UserRepository {
///     init(client: NetworkClientTagged<AuthenticatedAPI>) { ... }
/// }
/// ```
///
/// The compiler prevents you from accidentally injecting the wrong client:
/// ```swift
/// // ✅ Compiles
/// let loginService = LoginService(client: publicClient)
///
/// // ❌ Compile error: cannot convert NetworkClientTagged<AuthenticatedAPI> to NetworkClientTagged<PublicAPI>
/// let loginService = LoginService(client: authenticatedClient)
/// ```
///
/// See `NetworkClient.tag(with:)` for tagging an existing client.
@NetworkActor
public final class NetworkClientTagged<Tag>: NetworkClient {
    /// The underlying network client that handles all requests.
    private let networkClient: NetworkClient

    /// Creates a new tagged network client wrapping an existing client.
    ///
    /// - Parameter networkClient: The network client to wrap.
    ///
    /// - Note: Use `NetworkClient.tag(with:)` instead of calling this initializer directly.
    init(tagging networkClient: NetworkClient) {
        self.networkClient = networkClient
    }

    /// The configuration of the underlying network client.
    ///
    /// Modifying this property mutates the configuration of the wrapped client.
    public var configuration: NetworkClientConfiguration {
        get { networkClient.configuration }
        set { networkClient.configuration = newValue }
    }

    /// The network environment of the underlying network client.
    ///
    /// Modifying this property mutates the environment of the wrapped client.
    public var environment: NetworkEnvironment {
        get { networkClient.environment }
        set { networkClient.environment = newValue }
    }

    public func send(request requestConfiguration: some NetworkRequest) async throws(NetworkSendError) -> NetworkResponse<EmptyBody> {
        try await networkClient.send(request: requestConfiguration)
    }

    public func send<R>(
        request requestConfiguration: R
    ) async throws(NetworkSendResponseError) -> NetworkResponse<R.ResponseBody>
        where R: NetworkRequestWithResponse {
        try await networkClient.send(request: requestConfiguration)
    }

    public func send<R, T>(request requestConfiguration: R) async throws(NetworkSendOptionalResponseError)
        -> NetworkResponse<R.ResponseBody> where R: NetworkRequestWithResponse, R.ResponseBody == T? {
        try await networkClient.send(request: requestConfiguration)
    }

    public func send(request requestConfiguration: some NetworkRequestWithHeaderResponse) async throws(NetworkSendHeaderResponseError)
        -> [String: String] {
        try await networkClient.send(request: requestConfiguration)
    }

    /// Attempts to re-tag an already-tagged client.
    ///
    /// - Parameter tag: The new tag type.
    /// - Returns: A new tagged client (though this should not be used in
    ///   practice).
    ///
    /// - Warning: This method triggers an assertion failure. You should not tag an instance
    ///   of `NetworkClientTagged` that is already tagged. Tag the underlying `NetworkClient` instead.
    public func tag<T>(with _: T.Type) -> NetworkClientTagged<T> {
        assertionFailure(
            "You should not tag an existing instance of `NetworkClientTagged<\(Tag.self)>`. Tag the underlying NetworkClient instead."
        )
        return .init(tagging: self)
    }
}

public extension NetworkClient {
    /// Creates a type-safe tagged wrapper around this network client instance.
    ///
    /// Tagging allows you to distinguish between different `NetworkClient` instances at compile time
    /// using phantom types. This prevents accidentally injecting the wrong client into services or
    /// repositories that require specific configurations (e.g., authenticated vs public endpoints).
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Define tag types (empty enums recommended)
    /// enum PublicAPI {}
    /// enum AuthenticatedAPI {}
    ///
    /// // Create and tag clients
    /// let publicClient = NetworkClientImpl(configuration: publicConfig)
    ///     .tag(with: PublicAPI.self)
    ///
    /// let authenticatedClient = NetworkClientImpl(configuration: authenticatedConfig)
    ///     .tag(with: AuthenticatedAPI.self)
    ///
    /// // Type-safe dependency injection
    /// class LoginService {
    ///     private let client: NetworkClientTagged<PublicAPI>
    ///
    ///     init(client: NetworkClientTagged<PublicAPI>) {
    ///         self.client = client
    ///     }
    /// }
    ///
    /// // ✅ Compiles
    /// let loginService = LoginService(client: publicClient)
    ///
    /// // ❌ Compile error
    /// let loginService = LoginService(client: authenticatedClient)
    /// ```
    ///
    /// - Parameter tag: The type used to tag this client. Recommended: use empty enums (e.g., `enum PublicAPI {}`).
    /// - Returns: A `NetworkClientTagged<Tag>` wrapping this client instance.
    ///
    /// - Note: The returned tagged client delegates all operations to the original client.
    ///   Multiple tags can be created from the same underlying client if needed.
    func tag<Tag>(with _: Tag.Type) -> NetworkClientTagged<Tag> {
        .init(tagging: self)
    }
}
