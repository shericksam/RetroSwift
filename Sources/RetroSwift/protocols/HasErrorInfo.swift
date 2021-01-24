//
//  HasErrorInfo.swift
//  
//
//  Created by Zamiel Guerrero on 24/01/21.
//

import Foundation

public protocol HasErrorInfo {
    
    var status: Int? { get set }
    var errorCode:Int? { get set }
    var errorDetail:String? { get set }
    
    init()
}
