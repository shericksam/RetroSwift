//
//
//  RequestModel.swift
//  ios-gap-mobile
//
//  Created by Erick Guerrero on 30/10/20.
//  Copyright © 2020 Erick Guerrero. All rights reserved.
//
//

import Foundation

public struct RequestModelDefaults {
    public var baseUrl:String?
    public var staticHeaders: [String: String]?
}

public enum ContentType {
    case MultiPart
    case ApplicationJson
    case Form
    case raw
}

public struct RequestModel {
    
    public static var defaults:RequestModelDefaults = RequestModelDefaults()
    
    public enum HttpMethod:String {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
        case patch = "PATCH"
        case delete = "DELETE"
        case head = "HEAD"
        case options = "OPTIONS"
    }
    
    var baseUrl:String
    var httpMethod:HttpMethod
    var path:String
    var query: [String:Any]?
    var payload: [String:Any?]?
    var headers:[String:String]?
    var contentType: ContentType = .ApplicationJson
    var options: JSONSerialization.WritingOptions = []
    
    public init(
        httpMethod:HttpMethod,
        path:String,
        baseUrl:String = RequestModel.defaults.baseUrl ?? "",
        query:[String:Any]? = nil,
        payload:[String:Any?]? = nil,
        headers:[String:String]? = nil,
        contentType: ContentType = .ApplicationJson,
        options: JSONSerialization.WritingOptions = []) {
        
        self.baseUrl = baseUrl
        self.httpMethod = httpMethod
        self.path = path
        self.query = query
        self.payload = payload
        self.headers = headers
        self.contentType = contentType
        self.options = options
    }
}

extension RequestModel {
    
    public func asURLRequest() -> URLRequest {
        
        let url = "\(baseUrl)/\(path)"
        
        var components = URLComponents(string: url)
        if let qItems = query {
            let queryItems:[URLQueryItem] = qItems.reduce([], { (result, current) -> [URLQueryItem] in
                var _result = result
                _result.append(URLQueryItem(name: current.key, value: "\(current.value)"))
                return _result
            })
            components?.queryItems = queryItems
        }
        
        var request = URLRequest(url: (components?.url!)!)
        request.httpMethod = httpMethod.rawValue
        
        if let payload = payload,
           let payloadData = try? JSONSerialization
            .data(withJSONObject: payload,
                  options: self.options) {
            request.httpBody = payloadData
        }
        
        switch self.contentType {
            case .MultiPart:
                request.addValue("multipart/form-data", forHTTPHeaderField: "Content-Type")
            case .ApplicationJson:
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            case .Form:
                request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            case .raw:
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = payload?.percentEncoded()
        }
        
        headers?
            .enumerated()
            .forEach {
                request.addValue($0.element.value,
                                 forHTTPHeaderField: $0.element.key)
            }
        
        RequestModel.defaults.staticHeaders?
            .enumerated()
            .forEach {
                request.addValue($0.element.value,
                                 forHTTPHeaderField: $0.element.key)
            }
        
        return request
    }
}

