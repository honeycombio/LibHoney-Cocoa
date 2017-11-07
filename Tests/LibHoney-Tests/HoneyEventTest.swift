//
//  HoneyEventTest.swift
//  LibHoney-Tests
//
//  Created by Chong Han Chua on 11/7/17.
//

import XCTest
@testable import LibHoney

class HoneyEventTest: XCTestCase {
    
    func testDataMerge() {
        let config = HoneyConfig(writeKey: "TestWriteKey", dataset: "TestDataset")
        let data: [String: HoneyEventType] = [
            "foo": .int(1),
            "bar": .string("Hello, world")
        ]
        
        let event = HoneyEvent(config: config, data: data)
        if let foo: HoneyEventType = event.data["foo"], let bar: HoneyEventType = event.data["bar"] {
            XCTAssert(foo == .int(1), "Test data foo is recorded successfully")
            XCTAssert(bar == .string("Hello, world"), "Test data bar is recorded successfully")
        } else {
            XCTFail()
        }
    }
    
    func testConfigSet() {
        let config = HoneyConfig(writeKey: "TestWriteKey", dataset: "TestDataset")
        let event = HoneyEvent(config: config)
        XCTAssert(event.writeKey == "TestWriteKey")
        XCTAssert(event.dataset == "TestDataset")
        
        event.writeKey = "Hello, world"
        event.dataset = "Hello, data"
        event.apiHost = "www.example.com"
        event.sampleRate = 100
        XCTAssert(event.writeKey == "Hello, world")
        XCTAssert(event.dataset == "Hello, data")
        XCTAssert(event.apiHost == "www.example.com")
        XCTAssert(event.sampleRate == 100)
    }
    
    func testAddData() {
        let config = HoneyConfig(writeKey: "TestWriteKey", dataset: "TestDataset")
        let event = HoneyEvent(config: config)
        event.add(key: "foo", value: 100)
        event.add(key: "bar", value: "Hello, world")
        event.add(key: "validate", value: false)
        event.add(key: "number", value: 1.1)
        
        if let foo: HoneyEventType = event.data["foo"],
            let bar: HoneyEventType = event.data["bar"],
            let validate: HoneyEventType = event.data["validate"],
            let number: HoneyEventType = event.data["number"]
        {
            XCTAssert(foo == .int(100), "Test data foo is recorded successfully")
            XCTAssert(bar == .string("Hello, world"), "Test data bar is recorded successfully")
            XCTAssert(validate == .bool(false), "Test data foo is recorded successfully")
            XCTAssert(number == .double(1.1), "Test data foo is recorded successfully")
        } else {
            XCTFail()
        }
    }
    
}
