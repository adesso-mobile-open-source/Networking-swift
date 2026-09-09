//
//  DateOnlyCompatibleDateDecodingStrategy.swift
//  Networking
//
//  Created by Simon Feistel on 09.01.26.
//  Copyright 2026 adesso SE
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  http://www.apache.org/licenses/LICENSE-2.0
//

import Foundation

public extension JSONDecoder.DateDecodingStrategy {
    /// A `DateDecodingStrategy` that is compatible with multiple ISO‑8601 formats.
    ///
    /// The decoding order is:
    /// 1. Try decoding a full ISO‑8601 date‑time string with optional fractional seconds e.g.
    ///    - `2025-01-02T03:04:05Z`
    ///    - `2025-01-02T03:04:05.123Z`
    /// 2. If that fails, fall back to decoding *date‑only* ISO‑8601 strings in the form
    ///    `YYYY-MM-DD` (e.g. `1970-05-15`)
    ///
    /// Use this strategy when your DTOs model date values as `Date` but the backend may
    /// send either full date‑time values or date‑only values.
    static var dateOnlyCompatibleISO8601: Self {
        .custom { decoder in
            // First attempt: ISO‑8601 date‑time (with or without fractional seconds).
            let optionalMillisecondsISO8601Decoder = OptionalMillisecondsISO8601Decoder(decoder: decoder)
            do {
                return try optionalMillisecondsISO8601Decoder.decode()
            } catch {
                // Fallback: ISO‑8601 date‑only (YYYY‑MM‑DD).
                let dateOnlyDecoder = DateOnlyISO8601Decoder(decoder: decoder)
                return try dateOnlyDecoder.decode()
            }
        }
    }
}

/// A helper responsible for decoding *date‑only* ISO‑8601 strings (`YYYY-MM-DD`)
/// into `Date` values.
///
/// This type:
/// - Accepts strings like `1970-01-01` or `2025-12-31`.
/// - Interprets them as dates in GMT using `ISO8601DateFormatter`.
/// - Normalizes the resulting `Date` to midnight in the current calendar’s time zone,
///   so the decoded value represents the start of that day for the user.
private struct DateOnlyISO8601Decoder {
    /// The underlying `Decoder` from which the date value is read.
    private let decoder: any Decoder

    /// Creates a new instance wrapping the given `Decoder`.
    ///
    /// - Parameter decoder: The decoder that provides the underlying single value container.
    init(decoder: any Decoder) {
        self.decoder = decoder
    }

    /// Decodes a `Date` from a single ISO‑8601 date‑only string (`YYYY-MM-DD`).
    ///
    /// The method:
    /// - Reads a single `String` value from the wrapped decoder.
    /// - Uses `ISO8601DateFormatter` configured for date‑only parsing in GMT.
    /// - Extracts the year, month, and day components from the parsed date.
    /// - Reconstructs a `Date` at midnight in the current calendar’s time zone.
    ///
    /// - Returns: A `Date` value normalized to midnight of the parsed day
    ///   in the current time zone.
    /// - Throws:
    ///   - `DecodingError.dataCorrupted` if the string is not a supported
    ///     ISO‑8601 date‑only format.
    ///   - `DecodingError.dataCorrupted` if the date cannot be normalized to
    ///     midnight in the current time zone.
    func decode() throws -> Date {
        let container = try decoder.singleValueContainer()
        let str = try container.decode(String.self)

        // Configure formatter to accept only date components (no time).
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withYear, .withMonth, .withDay, .withDashSeparatorInDate]
        formatter.timeZone = .gmt

        guard let date = formatter.date(from: str) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unsupported ISO8601 date-only format: \(str)"
            )
        }

        // Normalize to midnight in the *current* calendar/time zone so the resulting `Date`
        // represents the start of the given day for the user.
        var calendar = Calendar.current
        calendar.timeZone = .current
        let components = calendar.dateComponents([.year, .month, .day], from: date)

        guard let normalizedDate = calendar.date(from: components) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Could not normalize date to midnight in current timezone: \(str)"
            )
        }

        return normalizedDate
    }
}
