//
//  DateOnlyDateEncodingStrategy.swift
//  Networking
//
//  Created by Simon Feistel on 03.03.26.
//  Copyright 2026 adesso SE
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  http://www.apache.org/licenses/LICENSE-2.0
//

import Foundation

public extension JSONEncoder.DateEncodingStrategy {
    /// A `DateEncodingStrategy` that encodes `Date` values as ISO‑8601 date‑only strings
    /// in the form `YYYY-MM-DD` (e.g. `1970-05-15`).
    ///
    /// The encoder:
    /// - Normalizes the `Date` to midnight in the current calendar’s time zone.
    /// - Formats the normalized date as a date‑only ISO‑8601 string using `ISO8601DateFormatter`.
    static var dateOnlyISO8601: Self {
        .custom { date, encoder in
            let dateOnlyEncoder = DateOnlyISO8601Encoder(date: date, encoder: encoder)
            try dateOnlyEncoder.encode()
        }
    }
}

/// Helper responsible for encoding `Date` values as *date‑only* ISO‑8601 strings (`YYYY-MM-DD`).
///
/// This mirrors `DateOnlyISO8601Decoder`:
/// - Normalizes the date to midnight in the current calendar/time zone.
/// - Encodes a single `String` value like `2025-12-31`.
private struct DateOnlyISO8601Encoder {
    /// The `Date` to encode.
    private let date: Date
    /// The underlying `Encoder` to which the value is written.
    private let encoder: any Encoder

    init(date: Date, encoder: any Encoder) {
        self.date = date
        self.encoder = encoder
    }

    /// Encodes the wrapped `Date` as a `YYYY-MM-DD` ISO‑8601 string.
    func encode() throws {
        // Interpret the date in the *current* calendar/time zone.
        var calendar = Calendar.current
        calendar.timeZone = .current
        let components = calendar.dateComponents([.year, .month, .day], from: date)

        guard let normalizedDate = calendar.date(from: components) else {
            let container = encoder.singleValueContainer()
            throw EncodingError.invalidValue(
                date,
                EncodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "Could not normalize date to midnight in current timezone"
                )
            )
        }

        // Format as `YYYY-MM-DD` using a fixed POSIX locale so the wire format
        // is stable and independent of the user's region settings.
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = .current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"

        let string = formatter.string(from: normalizedDate)

        var container = encoder.singleValueContainer()
        try container.encode(string)
    }
}
