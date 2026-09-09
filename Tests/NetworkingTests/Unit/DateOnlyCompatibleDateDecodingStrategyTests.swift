//
//  DateOnlyCompatibleDateDecodingStrategyTests.swift
//  Networking
//
//  Created by Simon Feistel on 09.01.26.
//  Copyright 2026 adesso SE
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  http://www.apache.org/licenses/LICENSE-2.0
//

// swiftlint:disable file_length type_body_length type_name

import Foundation
import Testing

struct DateOnlyCompatibleDateDecodingStrategyTests {
    // MARK: - ISO8601 With Fractional Seconds Tests

    @Test
    func `dateOnlyCompatibleISO8601 when Date String Has Fractional Seconds then Decodes Successfully`() async throws {
        // Given
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .dateOnlyCompatibleISO8601
        let dateString = "2025-11-27T14:30:45.123Z"
        let json = """
        { "date": "\(dateString)" }
        """
        let data = json.data(using: .utf8)!

        // When
        let result = try decoder.decode(TestDateContainer.self, from: data)

        // Then
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let expectedDate = try #require(formatter.date(from: dateString))
        #expect(result.date == expectedDate)
    }

    @Test
    func `dateOnlyCompatibleISO8601 when Date String Has Milliseconds then Decodes Successfully`() async throws {
        // Given
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .dateOnlyCompatibleISO8601
        let dateString = "2025-11-27T14:30:45.999Z"
        let json = """
        { "date": "\(dateString)" }
        """
        let data = json.data(using: .utf8)!

        // When
        let result = try decoder.decode(TestDateContainer.self, from: data)

        // Then
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let expectedDate = try #require(formatter.date(from: dateString))
        #expect(result.date == expectedDate)
    }

    @Test
    func `dateOnlyCompatibleISO8601 when Date String Has Microseconds then Decodes Successfully`() async throws {
        // Given
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .dateOnlyCompatibleISO8601
        let dateString = "2025-11-27T14:30:45.123456Z"
        let json = """
        { "date": "\(dateString)" }
        """
        let data = json.data(using: .utf8)!

        // When
        let result = try decoder.decode(TestDateContainer.self, from: data)

        // Then
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let expectedDate = try #require(formatter.date(from: dateString))
        #expect(result.date == expectedDate)
    }

    // MARK: - ISO8601 Without Fractional Seconds Tests

    @Test
    func `dateOnlyCompatibleISO8601 when Date String Has No Fractional Seconds then Decodes Successfully`() async throws {
        // Given
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .dateOnlyCompatibleISO8601
        let dateString = "2025-11-27T14:30:45Z"
        let json = """
        { "date": "\(dateString)" }
        """
        let data = json.data(using: .utf8)!

        // When
        let result = try decoder.decode(TestDateContainer.self, from: data)

        // Then
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        let expectedDate = try #require(formatter.date(from: dateString))
        #expect(result.date == expectedDate)
    }

    @Test
    func `dateOnlyCompatibleISO8601 when Date String Is Midnight then Decodes Successfully`() async throws {
        // Given
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .dateOnlyCompatibleISO8601
        let dateString = "2025-11-27T00:00:00Z"
        let json = """
        { "date": "\(dateString)" }
        """
        let data = json.data(using: .utf8)!

        // When
        let result = try decoder.decode(TestDateContainer.self, from: data)

        // Then
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        let expectedDate = try #require(formatter.date(from: dateString))
        #expect(result.date == expectedDate)
    }

    @Test
    func `dateOnlyCompatibleISO8601 when Date String Is End Of Day then Decodes Successfully`() async throws {
        // Given
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .dateOnlyCompatibleISO8601
        let dateString = "2025-11-27T23:59:59Z"
        let json = """
        { "date": "\(dateString)" }
        """
        let data = json.data(using: .utf8)!

        // When
        let result = try decoder.decode(TestDateContainer.self, from: data)

        // Then
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        let expectedDate = try #require(formatter.date(from: dateString))
        #expect(result.date == expectedDate)
    }

    // MARK: - Date Only Format Tests

    @Test
    func `dateOnlyCompatibleISO8601 when Date String Is Date Only then Decodes To Midnight In Current Timezone`() async throws {
        // Given
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .dateOnlyCompatibleISO8601
        let dateString = "1970-05-15"
        let json = """
        { "date": "\(dateString)" }
        """
        let data = json.data(using: .utf8)!

        // When
        let result = try decoder.decode(TestDateContainer.self, from: data)

        // Then
        var calendar = Calendar.current
        calendar.timeZone = .current
        let components = DateComponents(year: 1970, month: 5, day: 15)
        let expectedDate = try #require(calendar.date(from: components))
        #expect(result.date == expectedDate)
    }

    @Test
    func `dateOnlyCompatibleISO8601 when Date String Is Current Year Date Only then Decodes Successfully`() async throws {
        // Given
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .dateOnlyCompatibleISO8601
        let dateString = "2026-01-09"
        let json = """
        { "date": "\(dateString)" }
        """
        let data = json.data(using: .utf8)!

        // When
        let result = try decoder.decode(TestDateContainer.self, from: data)

        // Then
        var calendar = Calendar.current
        calendar.timeZone = .current
        let components = DateComponents(year: 2026, month: 1, day: 9)
        let expectedDate = try #require(calendar.date(from: components))
        #expect(result.date == expectedDate)
    }

    @Test
    func `dateOnlyCompatibleISO8601 when Date String Is First Day Of Year then Decodes Successfully`() async throws {
        // Given
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .dateOnlyCompatibleISO8601
        let dateString = "2025-01-01"
        let json = """
        { "date": "\(dateString)" }
        """
        let data = json.data(using: .utf8)!

        // When
        let result = try decoder.decode(TestDateContainer.self, from: data)

        // Then
        var calendar = Calendar.current
        calendar.timeZone = .current
        let components = DateComponents(year: 2025, month: 1, day: 1)
        let expectedDate = try #require(calendar.date(from: components))
        #expect(result.date == expectedDate)
    }

    @Test
    func `dateOnlyCompatibleISO8601 when Date String Is Last Day Of Year then Decodes Successfully`() async throws {
        // Given
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .dateOnlyCompatibleISO8601
        let dateString = "2025-12-31"
        let json = """
        { "date": "\(dateString)" }
        """
        let data = json.data(using: .utf8)!

        // When
        let result = try decoder.decode(TestDateContainer.self, from: data)

        // Then
        var calendar = Calendar.current
        calendar.timeZone = .current
        let components = DateComponents(year: 2025, month: 12, day: 31)
        let expectedDate = try #require(calendar.date(from: components))
        #expect(result.date == expectedDate)
    }

    @Test
    func `dateOnlyCompatibleISO8601 when Date String Is Leap Year Date then Decodes Successfully`() async throws {
        // Given
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .dateOnlyCompatibleISO8601
        let dateString = "2024-02-29"
        let json = """
        { "date": "\(dateString)" }
        """
        let data = json.data(using: .utf8)!

        // When
        let result = try decoder.decode(TestDateContainer.self, from: data)

        // Then
        var calendar = Calendar.current
        calendar.timeZone = .current
        let components = DateComponents(year: 2024, month: 2, day: 29)
        let expectedDate = try #require(calendar.date(from: components))
        #expect(result.date == expectedDate)
    }

    @Test
    func `dateOnlyCompatibleISO8601 when Date String Is Year 2000 Date Only then Decodes Successfully`() async throws {
        // Given
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .dateOnlyCompatibleISO8601
        let dateString = "2000-01-01"
        let json = """
        { "date": "\(dateString)" }
        """
        let data = json.data(using: .utf8)!

        // When
        let result = try decoder.decode(TestDateContainer.self, from: data)

        // Then
        var calendar = Calendar.current
        calendar.timeZone = .current
        let components = DateComponents(year: 2000, month: 1, day: 1)
        let expectedDate = try #require(calendar.date(from: components))
        #expect(result.date == expectedDate)
    }

    @Test
    func `dateOnlyCompatibleISO8601 when Date String Is Historic Date Only then Decodes Successfully`() async throws {
        // Given
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .dateOnlyCompatibleISO8601
        let dateString = "1990-06-15"
        let json = """
        { "date": "\(dateString)" }
        """
        let data = json.data(using: .utf8)!

        // When
        let result = try decoder.decode(TestDateContainer.self, from: data)

        // Then
        var calendar = Calendar.current
        calendar.timeZone = .current
        let components = DateComponents(year: 1990, month: 6, day: 15)
        let expectedDate = try #require(calendar.date(from: components))
        #expect(result.date == expectedDate)
    }

    // MARK: - Edge Case Tests

    @Test
    func `dateOnlyCompatibleISO8601 when Date String Has Zero Milliseconds then Decodes Successfully`() async throws {
        // Given
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .dateOnlyCompatibleISO8601
        let dateString = "2025-11-27T14:30:45.000Z"
        let json = """
        { "date": "\(dateString)" }
        """
        let data = json.data(using: .utf8)!

        // When
        let result = try decoder.decode(TestDateContainer.self, from: data)

        // Then
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let expectedDate = try #require(formatter.date(from: dateString))
        #expect(result.date == expectedDate)
    }

    @Test
    func `dateOnlyCompatibleISO8601 when Date String Has Single Digit Milliseconds then Decodes Successfully`() async throws {
        // Given
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .dateOnlyCompatibleISO8601
        let dateString = "2025-11-27T14:30:45.1Z"
        let json = """
        { "date": "\(dateString)" }
        """
        let data = json.data(using: .utf8)!

        // When
        let result = try decoder.decode(TestDateContainer.self, from: data)

        // Then
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let expectedDate = try #require(formatter.date(from: dateString))
        #expect(result.date == expectedDate)
    }

    @Test
    func `dateOnlyCompatibleISO8601 when Date String Is Leap Year Date With Time then Decodes Successfully`() async throws {
        // Given
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .dateOnlyCompatibleISO8601
        let dateString = "2024-02-29T12:00:00.500Z"
        let json = """
        { "date": "\(dateString)" }
        """
        let data = json.data(using: .utf8)!

        // When
        let result = try decoder.decode(TestDateContainer.self, from: data)

        // Then
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let expectedDate = try #require(formatter.date(from: dateString))
        #expect(result.date == expectedDate)
    }

    // MARK: - Multiple Date Fields Tests

    @Test
    func `dateOnlyCompatibleISO8601 when Multiple Date Fields With Mixed Formats then Decodes All Successfully`() async throws {
        // Given
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .dateOnlyCompatibleISO8601
        let json = """
        {
            "dateWithMilliseconds": "2025-11-27T14:30:45.123Z",
            "dateWithoutMilliseconds": "2025-11-27T14:30:45Z",
            "dateWithMicroseconds": "2025-11-27T14:30:45.123456Z"
        }
        """
        let data = json.data(using: .utf8)!

        // When
        let result = try decoder.decode(TestMultipleDateContainer.self, from: data)

        // Then
        let formatter1 = ISO8601DateFormatter()
        formatter1.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let expectedDate1 = try #require(formatter1.date(from: "2025-11-27T14:30:45.123Z"))

        let formatter2 = ISO8601DateFormatter()
        formatter2.formatOptions = [.withInternetDateTime]
        let expectedDate2 = try #require(formatter2.date(from: "2025-11-27T14:30:45Z"))

        let formatter3 = ISO8601DateFormatter()
        formatter3.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let expectedDate3 = try #require(formatter3.date(from: "2025-11-27T14:30:45.123456Z"))

        #expect(result.dateWithMilliseconds == expectedDate1)
        #expect(result.dateWithoutMilliseconds == expectedDate2)
        #expect(result.dateWithMicroseconds == expectedDate3)
    }

    // MARK: - Array Tests

    @Test
    func `dateOnlyCompatibleISO8601 when Array Of Dates With Mixed Formats then Decodes All Successfully`() async throws {
        // Given
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .dateOnlyCompatibleISO8601
        let json = """
        {
            "dates": [
                "2025-11-27T14:30:45.123Z",
                "2025-11-27T14:30:45Z",
                "2025-11-27T14:30:45.456789Z"
            ]
        }
        """
        let data = json.data(using: .utf8)!

        // When
        let result = try decoder.decode(TestDateArrayContainer.self, from: data)

        // Then
        #expect(result.dates.count == 3)

        let formatter1 = ISO8601DateFormatter()
        formatter1.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let expectedDate1 = try #require(formatter1.date(from: "2025-11-27T14:30:45.123Z"))

        let formatter2 = ISO8601DateFormatter()
        formatter2.formatOptions = [.withInternetDateTime]
        let expectedDate2 = try #require(formatter2.date(from: "2025-11-27T14:30:45Z"))

        let formatter3 = ISO8601DateFormatter()
        formatter3.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let expectedDate3 = try #require(formatter3.date(from: "2025-11-27T14:30:45.456789Z"))

        #expect(result.dates[0] == expectedDate1)
        #expect(result.dates[1] == expectedDate2)
        #expect(result.dates[2] == expectedDate3)
    }

    // MARK: - Nested Object Tests

    @Test
    func `dateOnlyCompatibleISO8601 when Nested Object With Date then Decodes Successfully`() async throws {
        // Given
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .dateOnlyCompatibleISO8601
        let json = """
        {
            "event": {
                "timestamp": "2025-11-27T14:30:45.123Z"
            }
        }
        """
        let data = json.data(using: .utf8)!

        // When
        let result = try decoder.decode(TestNestedDateContainer.self, from: data)

        // Then
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let expectedDate = try #require(formatter.date(from: "2025-11-27T14:30:45.123Z"))
        #expect(result.event.timestamp == expectedDate)
    }

    // MARK: - Error Tests

    @Test
    func `dateOnlyCompatibleISO8601 when Date String Is Invalid then Throws DecodingError`() async throws {
        // Given
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .dateOnlyCompatibleISO8601
        let dateString = "invalid-date-string"
        let json = """
        { "date": "\(dateString)" }
        """
        let data = json.data(using: .utf8)!

        // When / Then
        #expect(throws: DecodingError.self) {
            _ = try decoder.decode(TestDateContainer.self, from: data)
        }
    }

    @Test
    func `dateOnlyCompatibleISO8601 when Date String Has Wrong Format then Throws DecodingError`() async throws {
        // Given
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .dateOnlyCompatibleISO8601
        let dateString = "27-11-2025 14:30:45"
        let json = """
        { "date": "\(dateString)" }
        """
        let data = json.data(using: .utf8)!

        // When / Then
        #expect(throws: DecodingError.self) {
            _ = try decoder.decode(TestDateContainer.self, from: data)
        }
    }

    @Test
    func `dateOnlyCompatibleISO8601 when Date String Is Empty then Throws DecodingError`() async throws {
        // Given
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .dateOnlyCompatibleISO8601
        let json = """
        { "date": "" }
        """
        let data = json.data(using: .utf8)!
        // When / Then
        #expect(throws: DecodingError.self) {
            _ = try decoder.decode(TestDateContainer.self, from: data)
        }
    }

    @Test
    func `dateOnlyCompatibleISO8601 when Date String Has Invalid Month then Throws DecodingError`() async throws {
        // Given
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .dateOnlyCompatibleISO8601
        let dateString = "2025-13-27"
        let json = """
        { "date": "\(dateString)" }
        """
        let data = json.data(using: .utf8)!

        // When / Then
        #expect(throws: DecodingError.self) {
            _ = try decoder.decode(TestDateContainer.self, from: data)
        }
    }

    @Test
    func `dateOnlyCompatibleISO8601 when Date String Has Invalid Day then Throws DecodingError`() async throws {
        // Given
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .dateOnlyCompatibleISO8601
        let dateString = "2025-11-32"
        let json = """
        { "date": "\(dateString)" }
        """
        let data = json.data(using: .utf8)!

        // When / Then
        #expect(throws: DecodingError.self) {
            _ = try decoder.decode(TestDateContainer.self, from: data)
        }
    }
}

// MARK: - Test Types

private struct TestDateContainer: Codable {
    let date: Date
}

private struct TestMultipleDateContainer: Codable {
    let dateWithMilliseconds: Date
    let dateWithoutMilliseconds: Date
    let dateWithMicroseconds: Date
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

// swiftlint:enable file_length type_body_length type_name
