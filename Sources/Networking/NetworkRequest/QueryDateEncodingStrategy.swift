//
//  QueryDateEncodingStrategy.swift
//  Networking
//
//  Created by Codex on 13.04.26.
//  Copyright 2026 adesso SE
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  http://www.apache.org/licenses/LICENSE-2.0
//

import DictionaryCoder
import Foundation

/// Describes how `Date` values should be encoded in URL query parameters.
public enum QueryDateEncodingStrategy: Sendable {
    /// Encodes dates as `yyyy-MM-dd` in current time zone.
    case dateOnly
    /// Encodes dates as `yyyy-MM-dd'T'HH:mm:ssxxx` in current time zone.
    case dateTimeWithOffset
}

extension QueryDateEncodingStrategy {
    /// Converts a query-level date strategy into `DictionaryCoder`'s encoding strategy.
    ///
    /// This is used by query serialization in `NetworkClientImpl` so `Date` values
    /// inside `NetworkRequestWithQuery.Query` are encoded consistently before being
    /// transformed into URL query items.
    ///
    /// - Returns: A `DictionaryDateEncodingStrategy` that formats dates as:
    ///   - `.dateOnly`: `yyyy-MM-dd` in current timezone.
    ///   - `.dateTimeWithOffset`: `yyyy-MM-dd'T'HH:mm:ssxxx` in current timezone.
    var dictionaryDateEncodingStrategy: DictionaryDateEncodingStrategy {
        .custom { date, encoder in
            let formatter = DateFormatter()
            formatter.calendar = Calendar(identifier: .gregorian)
            formatter.timeZone = .current
            formatter.locale = Locale(identifier: "en_US_POSIX")

            switch self {
            case .dateOnly:
                var calendar = Calendar.current
                calendar.timeZone = .current
                let components = calendar.dateComponents([.year, .month, .day], from: date)
                let normalizedDate = calendar.date(from: components) ?? date
                formatter.calendar = calendar
                formatter.dateFormat = "yyyy-MM-dd"
                var container = encoder.singleValueContainer()
                try container.encode(formatter.string(from: normalizedDate))
            case .dateTimeWithOffset:
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssxxx"
                var container = encoder.singleValueContainer()
                try container.encode(formatter.string(from: date))
            }
        }
    }
}
