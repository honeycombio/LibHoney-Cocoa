//
//  HoneyEventType.swift
//  LibHoney-SwiftPackageDescription
//
//  Created by Chong Han Chua on 11/6/17.
//

import Foundation

enum HoneyEventType {
    case int(Int), double(Double), string(String), bool(Bool)
}

enum HoneyEventTypeError: Error {
    case decoding(String)
}

 func ==(lhs: HoneyEventType, rhs: HoneyEventType) -> Bool {
    switch (lhs, rhs) {
    case let (.int(a), .int(b)):
        return a == b
    case let (.double(a), .double(b)):
        return a == b
    case let (.string(a), .string(b)):
        return a == b
    case let (.bool(a), .bool(b)):
        return a == b
    default:
        return false
    }
}

extension HoneyEventType: Codable {
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(Int.self) {
            self = .int(value)
            return
        }
        
        if let value = try? container.decode(Double.self) {
            self = .double(value)
            return
        }
        
        if let value = try? container.decode(Bool.self) {
            self = .bool(value)
            return
        }
        
        if let value = try? container.decode(String.self) {
            self = .string(value)
            return
        }
        
        throw HoneyEventTypeError.decoding("Error decoding: \(dump(container))")
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .int(let value):
            try container.encode(value)
        case .double(let value):
            try container.encode(value)
        case .bool(let value):
            try container.encode(value)
        case .string(let value):
            try container.encode(value)
        }
    }
}
