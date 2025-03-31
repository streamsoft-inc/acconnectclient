//
//  extensions.swift
//  acconnectclient
//
//  Created by Andrija Milovanovic on 30.3.25..
//
import Foundation
import CommonCrypto

extension Encodable {
    func encode() -> Data? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        return try? encoder.encode(self)
    }
}
extension Decodable {
    static func decode(data: Data) throws -> Self {
        return try JSONDecoder().decode(Self.self, from: data)
    }
}

public protocol EmptyResponse {
    static func emptyValue() -> Self
}

public struct Empty: Decodable {
    public static let value = Empty()
}

extension Empty: EmptyResponse {
    public static func emptyValue() -> Empty {
        return value
    }
}
public extension String {

    func hashed() -> String? {
        
        // convert string to utf8 encoded data
        guard let message = data(using: .utf8) else { return nil }
        return message.hashed( )
    }
}
extension Data {
    public func hashed() -> String? {
        
        // setup data variable to hold hashed value
        var digest = Data(count: Int(CC_SHA256_DIGEST_LENGTH))
        
        _ = digest.withUnsafeMutableBytes{ digestBytes -> UInt8 in
            self.withUnsafeBytes { messageBytes -> UInt8 in
                if let mb = messageBytes.baseAddress, let db = digestBytes.bindMemory(to: UInt8.self).baseAddress {
                    let length = CC_LONG(self.count)
                    CC_SHA256(mb, length, db)
                }
                return 0
            }
        }
        return digest.map { String(format: "%02hhx", $0) }.joined()
    }
}
public extension Result {
    
    var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }
    
    var isFailure: Bool {
        return !isSuccess
    }
    
    var value: Success? {
        if case .success(let val) = self { return val }
        return nil
    }
    
    var error: Failure? {
        if case .failure(let err) = self { return err }
        return nil
    }
}

public enum FloatOrString: Codable
{
    case float(Float)
    case string(String)
    
    // Decoding logic
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let floatValue = try? container.decode(Float.self) {
            self = .float(floatValue)
            return
        }
        
        if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
            return
        }
        
        throw DecodingError.typeMismatch(FloatOrString.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected Float or String"))
    }
    
    // Encoding logic
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch self {
        case .float(let floatValue):
            try container.encode(floatValue)
        case .string(let stringValue):
            try container.encode(stringValue)
        }
    }
    
    public var valueF: Float {
        switch self {
        case .float(let floatValue):
            return floatValue
        case .string(let stringValue):
            return Float(stringValue) ?? 0.0
        }
    }
    public var valueS: String {
        switch self {
        case .float(let floatValue):
            return String( floatValue )
        case .string(let stringValue):
            return stringValue
        }
    }
}
