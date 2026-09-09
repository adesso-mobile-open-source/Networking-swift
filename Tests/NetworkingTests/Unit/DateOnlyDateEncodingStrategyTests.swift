//
//  DateOnlyDateEncodingStrategyTests.swift
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
import Testing

struct DateOnlyDateEncodingStrategyTests {
    // MARK: - Date Only Format Tests

    @Test
    func `dateOnlyISO8601 when Date Is Midnight InCurrentTimezone then EncodesToDateOnlyString`() async throws {
        // Given
        var calendar = Calendar.current
        calendar.timeZone = .current
        let components = DateComponents(year: 1970, month: 5, day: 15)
        let date = try #require(calendar.date(from: components))

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .dateOnlyISO8601

        let container = TestDateContainer(date: date)

        // When
        let data = try encoder.encode(container)

        // Then
        let jsonString = try #require(String(data: data, encoding: .utf8))
        #expect(jsonString.contains(#""date":"1970-05-15""#))
    }

    @Test
    func `dateOnlyISO8601 when Date Is CurrentYearMidday then EncodesToDateOnlyString`() async throws {
        // Given
        var calendar = Calendar.current
        calendar.timeZone = .current
        let components = DateComponents(year: 2026, month: 1, day: 9, hour: 12, minute: 34, second: 56)
        let date = try #require(calendar.date(from: components))

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .dateOnlyISO8601

        let container = TestDateContainer(date: date)

        // When
        let data = try encoder.encode(container)

        // Then
        let jsonString = try #require(String(data: data, encoding: .utf8))
        #expect(jsonString.contains(#""date":"2026-01-09""#))
    }

    @Test
    func `dateOnlyISO8601 when Date Is FirstDayOfYear then EncodesToDateOnlyString`() async throws {
        // Given
        var calendar = Calendar.current
        calendar.timeZone = .current
        let components = DateComponents(year: 2025, month: 1, day: 1, hour: 23, minute: 59, second: 59)
        let date = try #require(calendar.date(from: components))

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .dateOnlyISO8601

        let container = TestDateContainer(date: date)

        // When
        let data = try encoder.encode(container)

        // Then
        let jsonString = try #require(String(data: data, encoding: .utf8))
        #expect(jsonString.contains(#""date":"2025-01-01""#))
    }

    @Test
    func `dateOnlyISO8601 when Date Is LastDayOfYear then EncodesToDateOnlyString`() async throws {
        // Given
        var calendar = Calendar.current
        calendar.timeZone = .current
        let components = DateComponents(year: 2025, month: 12, day: 31, hour: 8, minute: 0, second: 0)
        let date = try #require(calendar.date(from: components))

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .dateOnlyISO8601

        let container = TestDateContainer(date: date)

        // When
        let data = try encoder.encode(container)

        // Then
        let jsonString = try #require(String(data: data, encoding: .utf8))
        #expect(jsonString.contains(#""date":"2025-12-31""#))
    }

    @Test
    func `dateOnlyISO8601 when Date IsLeapYearDate then EncodesToDateOnlyString`() async throws {
        // Given
        var calendar = Calendar.current
        calendar.timeZone = .current
        let components = DateComponents(year: 2024, month: 2, day: 29, hour: 12, minute: 0, second: 0)
        let date = try #require(calendar.date(from: components))

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .dateOnlyISO8601

        let container = TestDateContainer(date: date)

        // When
        let data = try encoder.encode(container)

        // Then
        let jsonString = try #require(String(data: data, encoding: .utf8))
        #expect(jsonString.contains(#""date":"2024-02-29""#))
    }

    @Test
    func `dateOnlyISO8601 when Date IsYear2000 then EncodesToDateOnlyString`() async throws {
        // Given
        var calendar = Calendar.current
        calendar.timeZone = .current
        let components = DateComponents(year: 2000, month: 1, day: 1, hour: 1, minute: 2, second: 3)
        let date = try #require(calendar.date(from: components))

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .dateOnlyISO8601

        let container = TestDateContainer(date: date)

        // When
        let data = try encoder.encode(container)

        // Then
        let jsonString = try #require(String(data: data, encoding: .utf8))
        #expect(jsonString.contains(#""date":"2000-01-01""#))
    }

    @Test
    func `dateOnlyISO8601 when Date IsHistoric then EncodesToDateOnlyString`() async throws {
        // Given
        var calendar = Calendar.current
        calendar.timeZone = .current
        let components = DateComponents(year: 1990, month: 6, day: 15, hour: 18, minute: 30, second: 0)
        let date = try #require(calendar.date(from: components))

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .dateOnlyISO8601

        let container = TestDateContainer(date: date)

        // When
        let data = try encoder.encode(container)

        // Then
        let jsonString = try #require(String(data: data, encoding: .utf8))
        #expect(jsonString.contains(#""date":"1990-06-15""#))
    }

    // MARK: - Normalization / Time Component Tests

    @Test
    func `dateOnlyISO8601 when Date HasTimeComponents then EncodesNormalizedDateOnly`() async throws {
        // Given
        var calendar = Calendar.current
        calendar.timeZone = .current
        let components = DateComponents(
            year: 2025,
            month: 11,
            day: 27,
            hour: 23,
            minute: 59,
            second: 59
        )
        let date = try #require(calendar.date(from: components))

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .dateOnlyISO8601
        let container = TestDateContainer(date: date)

        // When
        let data = try encoder.encode(container)

        // Then
        let jsonString = try #require(String(data: data, encoding: .utf8))
        #expect(jsonString.contains(#""date":"2025-11-27""#))
    }

    // MARK: - Multiple Date Fields Tests

    @Test
    func `dateOnlyISO8601 when MultipleDateFields then EncodesAllAsDateOnly`() async throws {
        // Given
        var calendar = Calendar.current
        calendar.timeZone = .current

        let date1 = try #require(calendar.date(from: DateComponents(year: 2025, month: 11, day: 27, hour: 14, minute: 30)))
        let date2 = try #require(calendar.date(from: DateComponents(year: 2025, month: 1, day: 1, hour: 0, minute: 0)))
        let date3 = try #require(calendar.date(from: DateComponents(year: 2024, month: 2, day: 29, hour: 12, minute: 0)))

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .dateOnlyISO8601

        let container = TestMultipleDateContainer(
            dateWithTime: date1,
            dateAtMidnight: date2,
            leapYearDate: date3
        )

        // When
        let data = try encoder.encode(container)

        // Then
        let jsonString = try #require(String(data: data, encoding: .utf8))
        #expect(jsonString.contains(#""dateWithTime":"2025-11-27""#))
        #expect(jsonString.contains(#""dateAtMidnight":"2025-01-01""#))
        #expect(jsonString.contains(#""leapYearDate":"2024-02-29""#))
    }

    // MARK: - Array Tests

    @Test
    func `dateOnlyISO8601 whenArrayOfDates then EncodesAllAsDateOnly`() async throws {
        // Given
        var calendar = Calendar.current
        calendar.timeZone = .current

        let date1 = try #require(calendar.date(from: DateComponents(year: 2025, month: 11, day: 27, hour: 14, minute: 30)))
        let date2 = try #require(calendar.date(from: DateComponents(year: 2025, month: 11, day: 27, hour: 0, minute: 0)))
        let date3 = try #require(calendar.date(from: DateComponents(year: 2025, month: 11, day: 27, hour: 23, minute: 59)))

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .dateOnlyISO8601

        let container = TestDateArrayContainer(dates: [date1, date2, date3])

        // When
        let data = try encoder.encode(container)

        // Then
        let jsonString = try #require(String(data: data, encoding: .utf8))
        // All should encode to the same date-only string.
        #expect(jsonString.contains(#""dates":["2025-11-27","2025-11-27","2025-11-27"]"#))
    }

    // MARK: - Nested Object Tests

    @Test
    func `dateOnlyISO8601 whenNestedObjectWithDate thenEncodesDateOnly`() async throws {
        // Given
        var calendar = Calendar.current
        calendar.timeZone = .current
        let date = try #require(calendar.date(from: DateComponents(year: 2025, month: 11, day: 27, hour: 14, minute: 30)))

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .dateOnlyISO8601

        let container = TestNestedDateContainer(event: .init(timestamp: date))

        // When
        let data = try encoder.encode(container)

        // Then
        let jsonString = try #require(String(data: data, encoding: .utf8))
        #expect(jsonString.contains(#""timestamp":"2025-11-27""#))
    }
}

// MARK: - Test Types

private struct TestDateContainer: Codable {
    let date: Date
}

private struct TestMultipleDateContainer: Codable {
    let dateWithTime: Date
    let dateAtMidnight: Date
    let leapYearDate: Date
}

private struct TestDateArrayContainer: Codable {
    let dates: [Date]
}

private struct TestNestedDateContainer: Codable {
    struct Event: Codable {
        let timestamp: Date
    }

    let event: Event
}
