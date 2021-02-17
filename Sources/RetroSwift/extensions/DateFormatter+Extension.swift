//
//  DateFormatter.swift
//  ios-gap-mobile
//
//  Created by Erick Guerrero on 28/01/21.
//  Copyright © 2021 Erick Guerrero. All rights reserved.
//

import Foundation

public extension DateFormatter {
    static let isoDateFormatter: DateFormatter = {
        var dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        return dateFormatter
    }()
    
    static let standard: DateFormatter = {
        var dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return dateFormatter
    }()
    
    static let dateNoTimeFormatter: DateFormatter = {
        var dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter
    }()
    
    static func createFormatter(_ str: String) -> DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = str
        return dateFormatter
    }
}
