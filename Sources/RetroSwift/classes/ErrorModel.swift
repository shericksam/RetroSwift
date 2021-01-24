//
//  ErrorModel.swift
//  pleyme
//
//  Created by Erick Guerrero on 28/08/20.
//  Copyright © 2020 Playme. All rights reserved.
//

import Foundation
//import RxRetroSwift

public struct ErrorModel: HasErrorInfo, Codable, Error {
    public var status: Int?
    public var errorCode: Int?
    public var errorDetail: String?
    public var message: String?
    public var errors: [ValidAdonis]?
    
}

extension ErrorModel: LocalizedError {
    public var localizedDescription: String {
        if let errors = self.errors,
           let firts = errors.first{
            return firts.message
        } else if let error = self.errorDetail {
            return error
        }
        return "Error in model"
    }
}
