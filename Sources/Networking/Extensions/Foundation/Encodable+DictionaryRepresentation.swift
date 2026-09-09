//
//  Encodable+DictionaryRepresentation.swift
//  Networking
//
//  Created by Niklas Holloh on 25.04.22.
//  Copyright 2026 adesso SE
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  http://www.apache.org/licenses/LICENSE-2.0
//

import DictionaryCoder
import Foundation

public extension Encodable {
    /// Returns a dictionary representation of an `Encodable` object or throws,
    /// if the type is incompatible with JSON.
    var dictionaryRepresentation: [String: Sendable] {
        get throws {
            try DictionaryEncoder().encode(self)
        }
    }

    /// Returns a dictionary representation using a custom date encoding strategy.
    func dictionaryRepresentation(
        dateEncodingStrategy: DictionaryDateEncodingStrategy
    ) throws -> [String: Sendable] {
        try DictionaryEncoder(dateEncodingStrategy: dateEncodingStrategy).encode(self)
    }
}
