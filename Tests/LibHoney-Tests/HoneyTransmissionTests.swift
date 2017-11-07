//
//  HoneyTransmissionTests.swift
//  LibHoney-SwiftTests
//
//  Created by Chong Han Chua on 11/7/17.
//

import XCTest
@testable import LibHoney

class HoneyTransmissionTests: XCTestCase {
    
    let defaultConfig = HoneyConfig(writeKey: "UnitTestKey", dataset: "UnitTestDataset")
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testSendOne() {
        let expectation = XCTestExpectation(description: "Fires in 1.0 seconds")
        
        let event = HoneyEvent(config: defaultConfig, data: [:])
        let transmission = HoneyTransmission(maxBatchSize: 10, sendFrequency: 1.0,
                                             mockEndpoint: { urlRequest in
                                                
                                                expectation.fulfill()
        }
        )
        
        transmission.enqueue(event: event)
        wait(for: [expectation], timeout: 3.0)
    }
    
    func testSendBatches() {
        let expectation = XCTestExpectation(description: "Fires immediately after 10 events")
        
        let transmission = HoneyTransmission(maxBatchSize: 10, sendFrequency: 3.0,
                                             mockEndpoint: { urlRequest in
                                                expectation.fulfill()
        }
        )
                                                
        
        for i in 0..<10 {
            let event = HoneyEvent(config: defaultConfig, data: [:])
            event.add(key: "index", value: i)
            transmission.enqueue(event: event)
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testMultipleDatasets() {
        let expectation = XCTestExpectation(description: "2 separate datasets fire almost simultaneously")
        var seenDataset1 = false
        var seenDataset2 = false
        
        let transmission = HoneyTransmission(maxBatchSize: 10, sendFrequency: 0.6,
                                             mockEndpoint: { urlRequest in
                                                
                                                if let url = urlRequest.url?.absoluteString {
                                                    print(url)
                                                    if url == "https://api.honeycomb.io/1/batch/testDataset1" {
                                                        seenDataset1 = true
                                                    }
                                                    if url == "https://api.honeycomb.io/1/batch/testDataset2" {
                                                        seenDataset2 = true
                                                    }
                                                }
                                                
                                                if seenDataset1 && seenDataset2 {
                                                    expectation.fulfill()
                                                }
        }
        )
        
        var config1 = defaultConfig
        config1.dataset = "testDataset1"
        
        var config2 = defaultConfig
        config2.dataset = "testDataset2"
        
        let event1 = HoneyEvent(config: config1, data: [:])
        let event2 = HoneyEvent(config: config2, data: [:])
        transmission.enqueue(event: event1)
        transmission.enqueue(event: event2)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testTimerCancellation() {
        let expectation = XCTestExpectation(description: "Timer gets canceled and doesn't fire twice")
        
        var count = 0
        
        let transmission = HoneyTransmission(maxBatchSize: 10, sendFrequency: 1.0,
                                             mockEndpoint: { urlRequest in
                                                count += 1
                                                XCTAssert(count <= 1)
        }
        )
        
        for i in 0..<10 {
            let event = HoneyEvent(config: defaultConfig, data: [:])
            event.add(key: "index", value: i)
            transmission.enqueue(event: event)
        }
        
        let result = XCTWaiter.wait(for: [expectation], timeout: 3.0)
        if result == .timedOut {
            XCTAssert(true)
        }
    }
    
    
    
    func testSingleJSON() {
        let expectation = XCTestExpectation(description: "Fires in 1.0 seconds")
        
        let event = HoneyEvent(config: defaultConfig, data: [:])
        event.add(key: "bee", value: true)
        event.add(key: "foo", value: 1.25)
        event.add(key: "bar", value: 25536)
        event.add(key: "url", value: "https://honeycomb.io")
        
        let transmission = HoneyTransmission(maxBatchSize: 10, sendFrequency: 0.3,
                                             mockEndpoint: { urlRequest in
                                                if let data = urlRequest.httpBody {
                                                    if let jsonStr = String(data: data, encoding: .utf8) {
                                                        XCTAssert(jsonStr.contains("\"foo\":1.25"))
                                                        XCTAssert(jsonStr.contains("\"bar\":25536"))
                                                        XCTAssert(jsonStr.contains("\"bee\":true"))
                                                        XCTAssert(jsonStr.contains("\"url\":\"https:\\/\\/honeycomb.io\""))
                                                        expectation.fulfill()
                                                    }
                                                }
        }
        )
        
        transmission.enqueue(event: event)
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testMultipleJSON() {
        let expectation = XCTestExpectation(description: "Fires in 0.3 seconds")
        
        let transmission = HoneyTransmission(maxBatchSize: 10, sendFrequency: 0.3,
                                             mockEndpoint: { urlRequest in
                                                if let data = urlRequest.httpBody {
                                                    if let jsonStr = String(data: data, encoding: .utf8) {
                                                        XCTAssert(jsonStr.contains("\"foo\":1.25"))
                                                        XCTAssert(jsonStr.contains("\"bar\":25536"))
                                                        XCTAssert(jsonStr.contains("\"bee\":true"))
                                                        XCTAssert(jsonStr.contains("\"url\":\"https:\\/\\/honeycomb.io\""))
                                                        XCTAssert(jsonStr.contains("\"bar\":10000000"))
                                                        XCTAssert(jsonStr.contains("\"bee\":false"))
                                                        XCTAssert(jsonStr.contains("\"url\":\"https:\\/\\/ui.honeycomb.io\""))
                                                        expectation.fulfill()
                                                    }
                                                }
        }
        )
        
        let event = HoneyEvent(config: defaultConfig, data: [:])
        event.add(key: "bee", value: true)
        event.add(key: "foo", value: 1.25)
        event.add(key: "bar", value: 25536)
        event.add(key: "url", value: "https://honeycomb.io")
        
        let event2 = HoneyEvent(config: defaultConfig, data: [:])
        event2.add(key: "bee", value: false)
        event2.add(key: "foo", value: 1.39)
        event2.add(key: "bar", value: 10000000)
        event2.add(key: "url", value: "https://ui.honeycomb.io")
        
        transmission.enqueue(event: event)
        transmission.enqueue(event: event2)
        wait(for: [expectation], timeout: 3.0)
    }
    
    func testInvalidEnqueue() {
        let expectation = XCTestExpectation(description: "Expect to never fire")
        
        let transmission = HoneyTransmission(maxBatchSize: 10, sendFrequency: 0.3,
                                             mockEndpoint: { urlRequest in
                                                XCTFail()
        }
        )
        
        for i in 0..<10 {
            let event = HoneyEvent(config: defaultConfig, data: [:])
            event.dataset = nil
            event.add(key: "index", value: i)
            transmission.enqueue(event: event)
        }
        
        let result = XCTWaiter.wait(for: [expectation], timeout: 1.0)
        if result == .timedOut {
            XCTAssert(true)
        }
    }
    
    func testFlush() {
        let expectation = XCTestExpectation(description: "Expect to flush immediately")
        
        let transmission = HoneyTransmission(maxBatchSize: 10, sendFrequency: 2.0,
                                             mockEndpoint: { urlRequest in
                                                expectation.fulfill()
        }
        )
        
        let event = HoneyEvent(config: defaultConfig, data: [:])
        event.add(key: "bee", value: true)
        
        let event2 = HoneyEvent(config: defaultConfig, data: [:])
        event2.add(key: "bee", value: false)

        transmission.enqueue(event: event)
        transmission.enqueue(event: event2)
        
        transmission.flush()
        
        let result = XCTWaiter.wait(for: [expectation], timeout: 1.0)
        if result == .timedOut {
            XCTFail()
        }
    }
    
    func testHTTPHeaders() {
        let expectation = XCTestExpectation(description: "Fires in 1.0 seconds")
        
        let transmission = HoneyTransmission(maxBatchSize: 10, sendFrequency: 0.3,
                                             mockEndpoint: { urlRequest in
                                                if let headers = urlRequest.allHTTPHeaderFields {
                                                    XCTAssert(headers["X-Honeycomb-Team"] == "UnitTestKey")
                                                    expectation.fulfill()
                                                } else {
                                                    XCTFail()
                                                }
        }
        )
        
        let event = HoneyEvent(config: defaultConfig, data: [:])
        transmission.enqueue(event: event)
        wait(for: [expectation], timeout: 1.0)
    }
    
}
