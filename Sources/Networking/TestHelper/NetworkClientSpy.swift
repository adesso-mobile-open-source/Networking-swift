//
//  NetworkClientSpy.swift
//  Networking
//
//  Created by Simon Feistel on 30.09.25.
//  Copyright 2026 adesso SE
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  http://www.apache.org/licenses/LICENSE-2.0
//

#if DEBUG
/// Spy for `NetworkClient`, recording requests and stubbing responses.
@NetworkActor
public final class NetworkClientSpy: NetworkClient {
    public init(configuration: NetworkClientConfiguration) {
        self.configuration = configuration
    }

    // MARK: - Protocol Properties

    public var configuration: NetworkClientConfiguration

    public var environment: NetworkEnvironment {
        get { configuration.environment }
        set { configuration.environment = newValue }
    }

    // MARK: - Recorded Calls

    public var sendCallsCount = 0
    public var receivedRequests: [Sendable] = []

    /// Wrapper to work around typed throws limitations in stored closures
    private struct ResponseHandler: Sendable {
        let handler: @Sendable (Sendable) async throws -> Sendable

        func call<E: Error>(_ request: Sendable, as errorType: E.Type) async throws(E) -> Sendable {
            do {
                return try await handler(request)
            } catch let error as E {
                throw error
            } catch {
                // This should never happen if the test is properly written
                fatalError("Stubbed response threw \(type(of: error)), expected \(E.self): \(error)")
            }
        }
    }

    /// Queue of response handlers used to stub responses or throw errors.
    private var sendResponses: [ResponseHandler] = []

    /// Adds a closure to be used for stubbing responses or throwing errors.
    /// The closure should throw the error type matching the `send` overload under test
    /// (e.g. `NetworkSendError`, `NetworkSendResponseError`, `NetworkSendOptionalResponseError`,
    /// `NetworkSendHeaderResponseError`) if it needs to throw.
    public func setSendResponse(_ response: @escaping @Sendable (Sendable) async throws -> Sendable) {
        sendResponses.append(ResponseHandler(handler: response))
    }

    private func handleSend<E: Error>(for requestConfiguration: Sendable, as errorType: E.Type) async throws(E) -> Sendable {
        sendCallsCount += 1
        receivedRequests.append(requestConfiguration)

        guard !sendResponses.isEmpty else {
            fatalError("sendResponse not stubbed")
        }

        let handler = sendResponses.removeFirst()
        return try await handler.call(requestConfiguration, as: errorType)
    }

    // MARK: - Protocol Implementation

    public func send(request requestConfiguration: some NetworkRequest) async throws(NetworkSendError) -> NetworkResponse<EmptyBody> {
        let response = try await handleSend(for: requestConfiguration, as: NetworkSendError.self)
        guard let typedResponse = response as? NetworkResponse<EmptyBody> else {
            fatalError("sendResponse stub has incompatible type \(type(of: response)) for expected NetworkResponse<EmptyBody>")
        }
        return typedResponse
    }

    public func send(request requestConfiguration: some NetworkRequestWithBody) async throws(NetworkSendError)
    -> NetworkResponse<EmptyBody> {
        let response = try await handleSend(for: requestConfiguration, as: NetworkSendError.self)
        guard let typedResponse = response as? NetworkResponse<EmptyBody> else {
            fatalError("sendResponse stub has incompatible type \(type(of: response)) for expected NetworkResponse<EmptyBody>")
        }
        return typedResponse
    }

    public func send<R>(request requestConfiguration: R) async throws(NetworkSendResponseError)
    -> NetworkResponse<R.ResponseBody> where R: NetworkRequestWithResponse {
        let response = try await handleSend(for: requestConfiguration, as: NetworkSendResponseError.self)
        guard let typedResponse = response as? NetworkResponse<R.ResponseBody> else {
            fatalError("sendResponse stub has incompatible type \(type(of: response)) for expected NetworkResponse<\(R.ResponseBody.self)>")
        }

        return typedResponse
    }

    public func send<R>(request requestConfiguration: R) async throws(NetworkSendResponseError)
    -> NetworkResponse<R.ResponseBody> where R: NetworkRequestWithResponse, R: NetworkRequestWithBody {
        let response = try await handleSend(for: requestConfiguration, as: NetworkSendResponseError.self)
        guard let typedResponse = response as? NetworkResponse<R.ResponseBody> else {
            fatalError("sendResponse stub has incompatible type \(type(of: response)) for expected NetworkResponse<\(R.ResponseBody.self)>")
        }

        return typedResponse
    }

    public func send<R, T>(request requestConfiguration: R) async throws(NetworkSendOptionalResponseError)
    -> NetworkResponse<R.ResponseBody> where R: NetworkRequestWithResponse, R.ResponseBody == T? {
        let response = try await handleSend(for: requestConfiguration, as: NetworkSendOptionalResponseError.self)
        guard let typedResponse = response as? NetworkResponse<R.ResponseBody> else {
            fatalError(
                "sendResponse stub has incompatible type \(type(of: response)) for expected NetworkResponse<\(R.ResponseBody.self)?>"
            )
        }

        return typedResponse
    }

    public func send<R, T>(request requestConfiguration: R) async throws(NetworkSendOptionalResponseError)
    -> NetworkResponse<R.ResponseBody> where R: NetworkRequestWithResponse, R: NetworkRequestWithBody, R.ResponseBody == T? {
        let response = try await handleSend(for: requestConfiguration, as: NetworkSendOptionalResponseError.self)
        guard let typedResponse = response as? NetworkResponse<R.ResponseBody> else {
            fatalError(
                "sendResponse stub has incompatible type \(type(of: response)) for expected NetworkResponse<\(R.ResponseBody.self)?>"
            )
        }

        return typedResponse
    }

    public func send(request requestConfiguration: some NetworkRequestWithHeaderResponse) async throws(NetworkSendHeaderResponseError)
    -> [String: String] {
        let response = try await handleSend(for: requestConfiguration, as: NetworkSendHeaderResponseError.self)
        guard let typedResponse = response as? [String: String] else {
            fatalError("sendResponse stub for NetworkRequestWithHeaderResponse must return [String:String] or throw")
        }

        return typedResponse
    }
}
#endif
