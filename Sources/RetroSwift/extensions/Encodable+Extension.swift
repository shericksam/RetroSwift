//
//
//  Encodable+Extension.swift
//  ios-gap-mobile
//
//  Created by Erick Guerrero on 21/01/21.
//  Copyright © 2021 Erick Guerrero. All rights reserved.
//
//

import Foundation

public extension Encodable {
    var dictionaryValue: [String: Any]? {
        do {
            let encoder = JSONEncoder()
            let formatter = DateFormatter()
            encoder.dateEncodingStrategy = .formatted(formatter)
            
            let data = try encoder.encode(self)
            let jsonObj = try JSONSerialization.jsonObject(with: data, options: [])
            if let dictionary = jsonObj as? [String: String]  {
                return dictionary
            } else if let dictionary = jsonObj as? [String: Any]  {
                return dictionary
            }
        } catch  {
            print("error", error)
            return nil
        }
        return nil
    }
    
    func dictionaryValue(with dateFormatter: String) -> [String: Any]? {
        do {
            let encoder = JSONEncoder()
            let formatter = DateFormatter()
            formatter.dateFormat = dateFormatter
            encoder.dateEncodingStrategy = .formatted(formatter)
            
            let data = try encoder.encode(self)
            let jsonObj = try JSONSerialization.jsonObject(with: data, options: [])
            if let dictionary = jsonObj as? [String: String]  {
                return dictionary
            } else if let dictionary = jsonObj as? [String: Any]  {
                return dictionary
            }
        } catch  {
            print("error", error)
            return nil
        }
        return nil
    }
}

public extension Dictionary {
    func percentEncoded() -> Data? {
        return map { key, value in
            let escapedKey = "\(key)".addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? ""
            let escapedValue = "\(value)".addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? ""
            return escapedKey + "=" + escapedValue
        }
        .joined(separator: "&")
        .data(using: .utf8)
    }
}

public extension CharacterSet {
    static let urlQueryValueAllowed: CharacterSet = {
        let generalDelimitersToEncode = ":#[]@" // does not include "?" or "/" due to RFC 3986 - Section 3.4
        let subDelimitersToEncode = "!$&'()*+,;="
        
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "\(generalDelimitersToEncode)\(subDelimitersToEncode)")
        return allowed
    }()
}
