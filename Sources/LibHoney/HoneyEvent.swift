//
//  HoneyEvent.swift
//  LibHoney-Swift
//
//  Created by Chong Han Chua on 11/6/17.
//  Copyright © 2017 Honeycomb.io. All rights reserved.
//

import Foundation

/// HoneyEvent captures a single event being captured in the system
@objc
public class HoneyEvent: NSObject {
    
    private(set) var data = [String: HoneyEventType]()
    
    // configuration parameters
    var timestamp: Date
    var writeKey: String?
    var dataset: String?
    var apiHost: String
    var sampleRate: UInt
    
    init(config: HoneyConfig, data: [String: HoneyEventType]? = nil) {
        timestamp = Date()
        writeKey = config.writeKey
        dataset = config.dataset
        apiHost = config.apiHost
        sampleRate = config.sampleRate
        
        if let data = data {
            self.data.merge(data) { (_, new) in new }
        }
    }
    
    // MARK: - Add field methods
    
    /// Adds or replaces a field in the current event
    @objc(addKey:intValue:)
    @discardableResult public func add(key: String, value: Int) -> Self {
        data[key] = .int(value)
        return self
    }
    
    /// Adds or replaces a field in the current event
    @objc(addKey:doubleValue:)
    @discardableResult public func add(key: String, value: Double) -> Self {
        data[key] = .double(value)
        return self
    }
    
    /// Adds or replaces a field in the current event
    @objc(addKey:stringValue:)
    @discardableResult public func add(key: String, value: String) -> Self {
        data[key] = .string(value)
        return self
    }
    
    /// Adds or replaces a field in the current event
    @objc(addKey:boolValue:)
    @discardableResult public func add(key: String, value: Bool) -> Self {
        data[key] = .bool(value)
        return self
    }
    
}
