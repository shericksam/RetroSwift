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
            formatter.dateFormat = "AppConstants.DateFormatISO"
            encoder.dateEncodingStrategy = .formatted(formatter)
            
            let data = try encoder.encode(self)
            //            print("data", data)
            let jsonObj = try JSONSerialization.jsonObject(with: data, options: [])
            //            print("jsonObj", jsonObj)
            if let dictionary = jsonObj as? [String: String]  {
                //                print("dictionary <--", dictionary)
                return dictionary
            } else if let dictionary = jsonObj as? [String: Any]  {
                //                print("dictionary any -->", dictionary)
                return dictionary
            }
        } catch  {
            print("error", error)
            return nil
        }
        //        print("nothing")
        return nil
    }
}
