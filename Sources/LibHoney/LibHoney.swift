//
//  LibHoney.swift
//  LibHoney-Swift
//
//  Created by Chong Han Chua on 11/6/17.
//  Copyright © 2017 Honeycomb.io. All rights reserved.
//

import Foundation
import os.log
#if os(iOS)
import UIKit
#endif

/// LibHoney is the public interface for the SDK for sending events to Honeycomb.
/// Find out more at https://honeycomb.io
@objc
public class LibHoney: NSObject {
    
    // Static convenient methods for access in other parts of the codebase.
    
    /// The singleton instance of libHoney. If shared returns `nil`, it means that
    /// LibHoney has not been configured. Configure LibHoney by calling `configure`,
    /// usually in `application:didFinishLaunchingWithOptions:`
    @objc public private(set) static var shared: LibHoney?
    
    /// Configures the global instance of LibHoney
    ///
    /// - Parameters:
    ///     - writeKey: WriteKey is the Honeycomb authentication token. If it is
    ///                 specified during libhoney initialization, it will be
    ///                 used as the default write key for all events. If absent,
    ///                 write key must be explicitly set on an event.
    ///                 Find your team write key at https://ui.honeycomb.io/account
    ///     - dataset: Dataset is the name of the Honeycomb dataset to which to send these events.
    ///                 If it is specified during libhoney initialization, it will be used as the
    ///                 default dataset for all events. If absent, dataset must be explicitly set
    ///                 on an event.
    ///     - apiHost: APIHost is the hostname for the Honeycomb API server to which to send this
    ///                 event. default: https://api.honeycomb.io/
    ///     - samplerate: SampleRate is the rate at which to sample this event. Default is 1,
    ///                 meaning no sampling. If you want to send one event out of every 250 times
    ///                 Send() is called, you would specify 250 here.
    ///     - maxBatchSize: The number of events to collect into a batch before sending.
    ///     - sendFrequency: The maximum amount of time to wait for batching event before sending.
    ///                 Specified in seconds.
    ///
    @objc public static func configure(writeKey: String, dataset: String,
                          apiHost: String = HoneyConfigDefaults.apiHost,
                          sampleRate: UInt = HoneyConfigDefaults.sampleRate,
                          maxBatchSize: UInt = HoneyConfigDefaults.maxBatchSize,
                          sendFrequency: TimeInterval = HoneyConfigDefaults.sendFrequency) {
        let newConfig = HoneyConfig(writeKey: writeKey, dataset: dataset,
                                    apiHost: apiHost, sampleRate: sampleRate,
                                    maxBatchSize: maxBatchSize,
                                    sendFrequency: sendFrequency)
        shared = LibHoney(config: newConfig)
        os_log("[LibHoney] Initialized LibHoney with writeKey: %@", writeKey)
    }
    
    /// Configures the global instance of LibHoney. This is the version of API
    /// for the basic configuration in Objective-C.
    ///
    /// - Parameters:
    ///     - writeKey: WriteKey is the Honeycomb authentication token. If it is
    ///                 specified during libhoney initialization, it will be
    ///                 used as the default write key for all events. If absent,
    ///                 write key must be explicitly set on an event.
    ///                 Find your team write key at https://ui.honeycomb.io/account
    ///     - dataset: Dataset is the name of the Honeycomb dataset to which to send these events.
    ///                 If it is specified during libhoney initialization, it will be used as the
    ///                 default dataset for all events. If absent, dataset must be explicitly set
    ///                 on an event.
    ///
    @objc public static func configure(writeKey: String, dataset: String) {
        configure(writeKey: writeKey, dataset: dataset,
                  apiHost: HoneyConfigDefaults.apiHost,
                  sampleRate: HoneyConfigDefaults.sampleRate,
                  maxBatchSize: HoneyConfigDefaults.maxBatchSize,
                  sendFrequency: HoneyConfigDefaults.sendFrequency)
    }
    
    // Class properties and methods
    
    let config: HoneyConfig
    let transmission: HoneyTransmission
    private var globalDatastore: [String: HoneyEventType] = [:]
    
    /// Set `collectDeviceStats` to true to automatically collect some basic
    /// information about the device. This only works on iOS right now.
    @objc
    public var collectDeviceStats = true
    
    private init(config: HoneyConfig) {
        self.config = config
        self.transmission = HoneyTransmission(maxBatchSize: config.maxBatchSize,
                                              sendFrequency: config.sendFrequency)
    }
    
    
    /// Adds an integer field in the global scope. All Events created will
    /// inherit this field
    @objc(addKey:intValue:)
    @discardableResult public func add(key: String, value: Int) -> Self {
        globalDatastore[key] = .int(value)
        return self
    }
    
    /// Adds a double field in the global scope. All Events created will
    /// inherit this field
    @objc(addKey:doubleValue:)
    @discardableResult public func add(key: String, value: Double) -> Self {
        globalDatastore[key] = .double(value)
        return self
    }
    
    /// Adds a string field in the global scope. All Events created will
    /// inherit this field
    @objc(addKey:stringValue:)
    @discardableResult public func add(key: String, value: String) -> Self {
        globalDatastore[key] = .string(value)
        return self
    }
    
    /// Adds a boolean field in the global scope. All Events created will
    /// inherit this field
    @objc(addKey:boolValue:)
    @discardableResult public func add(key: String, value: Bool) -> Self {
        globalDatastore[key] = .bool(value)
        return self
    }
    
    /// Creates a new event object prepopulated with any fields present in the
    /// global scope
    @objc public func newEvent() -> HoneyEvent {
        let event = HoneyEvent(config: config, data: globalDatastore)
        
        if collectDeviceStats {
            generateDeviceStats(event: event)
        }
        
        return event
    }
    
    /// Enqueue the supplied event object for sending
    @objc public func send(_ event: HoneyEvent?) {
        if let event = event {
            let sampleRate = max(event.sampleRate, 1)
            var shouldSend = true
            if (sampleRate > 1) {
                let testSample = arc4random_uniform(UInt32(sampleRate)) + 1
                shouldSend = testSample == sampleRate
            }
            if (shouldSend) {
                transmission.enqueue(event: event)
            }
        }
    }
    
    /// Forces all unsent events to be sent to the server
    @objc public func close() {
        transmission.flush()
    }
    
    // Methods to automatically generate system metadata
    
    private func generateDeviceStats(event: HoneyEvent) {
        #if os(iOS)
            let vendorDeviceId = UIDevice.current.identifierForVendor?.uuidString ?? "Vendor ID not available"
            event.add(key: "device_vendored_id", value: vendorDeviceId)
            
            let name = UIDevice.current.name
            event.add(key: "device_name", value: name)
            
            let systemName = UIDevice.current.systemName
            let systemVersion = UIDevice.current.systemVersion
            event.add(key: "device_system_name", value: "\(systemName) \(systemVersion)")
            
            var sysInfo = utsname()
            uname(&sysInfo)
            let machine = Mirror(reflecting: sysInfo.machine)
            let identifier = machine.children.reduce("") { identifier, element in
                guard let value = element.value as? Int8, value != 0 else { return identifier }
                return identifier + String(UnicodeScalar(UInt8(value)))
            }
            event.add(key: "device_model", value: identifier)
            
            let uiIdiom = UIDevice.current.userInterfaceIdiom
            let uiIdiomString = getDeviceUIIdiomString(idiom: uiIdiom)
            event.add(key: "device_ui_idiom", value: uiIdiomString)
            
            let orientation = UIDevice.current.orientation
            let orientationString = getDeviceOrientationString(orientation: orientation)
            event.add(key: "device_orientation", value: orientationString)
            
            let batteryState = UIDevice.current.batteryState
            let batteryStateString = getBatteryStateString(batteryState: batteryState)
            event.add(key: "device_battery_state", value: batteryStateString)
            
            let batteryLevel = UIDevice.current.batteryLevel
            event.add(key: "device_battery_level", value: Double(batteryLevel))
            
        #endif
    }
    
    private func getDeviceUIIdiomString(idiom: UIUserInterfaceIdiom) -> String {
        switch idiom {
        case .phone:
            return "Phone"
        case .pad:
            return "Pad"
        case .tv:
            return "TV"
        case .carPlay:
            return "CarPlay"
        default:
            return "unspecified"
        }
    }
    
    private func getDeviceOrientationString(orientation: UIDeviceOrientation) -> String {
        switch orientation {
        case .portrait: // Device oriented vertically, home button on the bottom
            return "Portrait"
        case .portraitUpsideDown: // Device oriented vertically, home button on the top
            return "Portrait upside down"
        case .landscapeLeft: // Device oriented horizontally, home button on the right
            return "Landscape left"
        case .landscapeRight: // Device oriented horizontally, home button on the left
            return "Landscape right"
        case .faceUp: // Device oriented flat, face up
            return "Face up"
        case .faceDown: // Device oriented flat, face down
            return "Face down"
        default:
            return "unknown"
        }
    }
    
    private func getBatteryStateString(batteryState: UIDeviceBatteryState) -> String {
        switch batteryState {
        case .unknown:
            return "unknown"
        case .unplugged: // on battery, discharging
            return "unplugged"
        case .charging: // plugged in, less than 100%
            return "charging"
        case .full: // plugged in, at 100%
            return "full"
        }
    }
    
}
