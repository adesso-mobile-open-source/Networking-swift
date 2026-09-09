//
//  NetworkResponseInterceptorResultTests.swift
//  Networking
//
//  Created by Jan Frederik Zerrath on 19.08.25.
//  Copyright 2026 adesso SE
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  http://www.apache.org/licenses/LICENSE-2.0
//

@testable import Networking

struct NetworkResponseInterceptorResultTests {
    @Test("combine when using two results returns highest precedence",
          arguments: [
              (NetworkResponseInterceptorResult.defaultHandling, NetworkResponseInterceptorResult.defaultHandling, NetworkResponseInterceptorResult.defaultHandling),
              (NetworkResponseInterceptorResult.retryRequest, NetworkResponseInterceptorResult.defaultHandling, NetworkResponseInterceptorResult.retryRequest),
              (NetworkResponseInterceptorResult.defaultHandling, NetworkResponseInterceptorResult.retryRequest, NetworkResponseInterceptorResult.retryRequest),
              (NetworkResponseInterceptorResult.retryRequest, NetworkResponseInterceptorResult.retryRequest, NetworkResponseInterceptorResult.retryRequest),
          ]
    )
    func combine_whenUsingTwoResults_returnsHighestPrecedence(
        first: NetworkResponseInterceptorResult,
        second: NetworkResponseInterceptorResult,
        expected: NetworkResponseInterceptorResult
    ) {
        #expect(first.combine(with: second) == expected)
    }
}
