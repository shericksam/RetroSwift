//
//  File.swift
//  
//
//  Created by Erick Guerrero on 28/01/21.
//

import Foundation

public extension CodingUserInfoKey {
    // Helper property to retrieve the context
    static let managedObjectContext = CodingUserInfoKey(rawValue: "managedObjectContext")
}
