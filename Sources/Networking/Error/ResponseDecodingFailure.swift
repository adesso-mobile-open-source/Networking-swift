//
//  ResponseDecodingFailure.swift
//  Networking
//
//  Created by Niklas Holloh on 09.09.26.
//  Copyright 2026 adesso SE
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  http://www.apache.org/licenses/LICENSE-2.0
//

/// Internal error used while decoding a response body.
///
/// `send` overloads with a non-optional `ResponseBody` (`NetworkSendResponseError`) surface
/// both cases as-is. Overloads with an optional `ResponseBody` (`NetworkSendOptionalResponseError`)
/// absorb `.responseHasNoData` into a `nil` body instead of throwing it, so only
/// `.cannotDecodeResponseBody` is ever converted into their public error type.
enum ResponseDecodingFailure: Error, Equatable {
    /// The response has no data, but was expected to have data.
    case responseHasNoData

    /// The response body received does not match the specified type. DecoderError.
    case cannotDecodeResponseBody(String)
}
