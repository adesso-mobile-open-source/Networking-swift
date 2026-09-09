//
//  NetworkRequestWithTimeout.swift
//  Networking
//
//  Created by Simon Feistel on 02.04.26.
//  Copyright 2026 adesso SE
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  http://www.apache.org/licenses/LICENSE-2.0
//

import Foundation

/// An opt-in protocol that allows a `NetworkRequest` to override the globally configured
/// `URLSession` timeout on a per-request basis.
///
/// ## When to conform
/// Only conform when a specific request genuinely requires a different timeout than the global
/// default — for example, a file upload or a long-polling endpoint. Conforming is an explicit,
/// intentional decision; requests that are satisfied by the global timeout should **not** conform.
///
/// - Note: No default value is provided for `timeout` intentionally. Every conformance must
///   declare an explicit value so the non-standard timeout is always a visible, reviewable
///   decision at the call site.
public protocol NetworkRequestWithTimeout: NetworkRequest {
    /// The timeout interval in seconds for this request.
    ///
    /// This value is set on `URLRequest.timeoutInterval` and overrides the
    /// `URLSession`-level `timeoutIntervalForRequest` for this request only.
    /// All other requests continue to use the globally configured session timeout.
    var timeout: TimeInterval { get }
}
