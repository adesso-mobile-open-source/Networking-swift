//
//  TestHelpers.swift
//  Networking
//
//  Created by Niklas Holloh on 14.06.26.
//  Copyright 2026 adesso SE
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  http://www.apache.org/licenses/LICENSE-2.0
//

import Foundation

// MARK: - ActorBox

/// A simple actor-isolated box for concurrency-safe mutation in tests.
/// Replaces the former `ActorIsolated` from the removed Extensions module.
actor ActorBox<T: Sendable> {
    private var _value: T

    init(_ value: T) {
        _value = value
    }

    func get() -> T { _value }
    func set(_ value: T) { _value = value }
    func withValue(_ transform: (inout T) -> Void) { transform(&_value) }
}

// MARK: - String.random

extension String {
    /// Returns a random UUID string, useful for generating unique test values.
    static func random() -> String {
        UUID().uuidString
    }
}
