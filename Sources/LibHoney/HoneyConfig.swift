//
//  HoneyConfig.swift
//  LibHoney-Swift
//
//  Created by Chong Han Chua on 11/6/17.
//  Copyright © 2017 Honeycomb.io. All rights reserved.
//

import Foundation

@objc
public class HoneyConfigDefaults: NSObject {
    @objc public static let apiHost = "https://api.honeycomb.io"
    @objc public static let sampleRate: UInt = 1
    @objc public static let maxBatchSize: UInt = 50
    @objc public static let sendFrequency: TimeInterval = 0.1 // 100ms
}

public struct HoneyConfig {
    
    /// WriteKey is the Honeycomb authentication token. If it is specified during
    /// libhoney initialization, it will be used as the default write key for all
    /// events. If absent, write key must be explicitly set on an event.
    /// Find your team write key at https://ui.honeycomb.io/account
    var writeKey: String?
    
    /// Dataset is the name of the Honeycomb dataset to which to send these events.
    /// If it is specified during libhoney initialization, it will be used as the
    /// default dataset for all events. If absent, dataset must be explicitly set
    /// on an event.
    var dataset: String?
    
    /// APIHost is the hostname for the Honeycomb API server to which to send this
    /// event. default: https://api.honeycomb.io/
    var apiHost: String
    
    /// SampleRate is the rate at which to sample this event. Default is 1,
    /// meaning no sampling. If you want to send one event out of every 250 times
    /// Send() is called, you would specify 250 here.
    var sampleRate: UInt
    
    /// The number of events to collect into a batch before sending.
    var maxBatchSize: UInt
    
    /// The maximum amount of time to wait for batching event before sending.
    /// Specified in seconds.
    var sendFrequency: TimeInterval
    
    init(writeKey: String? = nil, dataset: String? = nil,
         apiHost: String = HoneyConfigDefaults.apiHost,
         sampleRate: UInt = HoneyConfigDefaults.sampleRate,
         maxBatchSize: UInt = HoneyConfigDefaults.maxBatchSize,
         sendFrequency: TimeInterval = HoneyConfigDefaults.sendFrequency,
         mockEndPoint: ((URLRequest) -> Void)? = nil) {
        self.writeKey = writeKey
        self.dataset = dataset
        self.apiHost = apiHost
        self.sampleRate = sampleRate
        self.maxBatchSize = maxBatchSize
        self.sendFrequency = sendFrequency
    }
}
