//
//  OptionalMillisecondsDateDecodingStrategy.swift
//  Networking
//
//  Created by Simon Feistel on 27.11.25.
//  Copyright 2026 adesso SE
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  http://www.apache.org/licenses/LICENSE-2.0
//

import Foundation

/// Extension to `JSONDecoder.DateDecodingStrategy` providing an ISO 8601 decoding strategy
/// that accepts dates both with and without fractional seconds.
public extension JSONDecoder.DateDecodingStrategy {
    /// A custom decoding strategy that first attempts to decode ISO 8601 dates
    /// with fractional seconds and then falls back to ISO 8601 without fractional seconds.
    static var optionalMillisecondsISO8601: Self {
        .custom { decoder in
            let optionalMillisecondsISO8601Decoder = OptionalMillisecondsISO8601Decoder(decoder: decoder)
            return try optionalMillisecondsISO8601Decoder.decode()
        }
    }
}

/// Helper responsible for decoding ISO 8601 date strings with optional fractional seconds.
struct OptionalMillisecondsISO8601Decoder {
    /// The underlying decoder used to extract the date string.
    private let decoder: any Decoder

    /// Creates a decoder using the given underlying `Decoder`.
    ///
    /// - Parameter decoder: The decoder used to obtain the single value container.
    init(decoder: any Decoder) {
        self.decoder = decoder
    }

    /// Decodes a `Date` from an ISO 8601 string with optional fractional seconds.
    ///
    /// The method first tries to decode using `.withFractionalSeconds`, then
    /// falls back to decoding without fractional seconds. If both attempts fail,
    /// a `DecodingError.dataCorrupted` error is thrown.
    ///
    /// - Returns: The decoded `Date` value.
    /// - Throws: `DecodingError` if the date string cannot be parsed.
    func decode() throws -> Date {
        let container = try decoder.singleValueContainer()
        let str = try container.decode(String.self)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        // Try fractions first
        if let date = formatter.date(from: str) {
            return date
        }
        // Fallback to without fractions
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: str) {
            return date
        }
        // Give up
        throw DecodingError.dataCorruptedError(
            in: container,
            debugDescription: "Unsupported ISO8601 date format: \(str)"
        )
    }
}
