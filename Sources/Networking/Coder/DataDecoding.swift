//
//  DataDecoding.swift
//  Networking
//
//  Created by Niklas Holloh on 18.05.22.
//  Copyright 2026 adesso SE
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  http://www.apache.org/licenses/LICENSE-2.0
//

import Foundation

/// A wrapper protocol for `JSONDecoder`.
public protocol DataDecoding: Sendable {
    /// Decodes given data into the specified decodable type.
    /// - Parameters:
    ///   - type: The `Decodable` conforming type to decode into.
    ///   - data: The data to decode from.
    /// - Returns: An instance of `type` or throws if decoding was unsuccessful.
    func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T
}
