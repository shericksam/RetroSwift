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
    
    
    public init(
        httpMethod:HttpMethod,
        path:String,
        baseUrl:String = RequestModel.defaults.baseUrl ?? "",
        query:[String:Any]? = nil,
        payload:[String:Any?]? = nil,
        headers:[String:String]? = nil,
        contentType: ContentType = .ApplicationJson) {
        
        self.baseUrl = baseUrl
        self.httpMethod = httpMethod
        self.path = path
        self.query = query
        self.payload = payload
        self.headers = headers
        self.contentType = contentType
    }
}

extension RequestModel {
    
    public func asURLRequest() -> URLRequest {
        
        let url = "\(baseUrl)/\(path)"
//        print("url-->", url)
        
        var components = URLComponents(string: url)
//        print("qItems", query ?? "nil")
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
        
        
//        print("payload", payload ?? "nil")
        if let payload = payload,
           let payloadData = try? JSONSerialization
            .data(withJSONObject: payload,
                  options: []) {
            request.httpBody = payloadData
        }
        
        switch self.contentType {
            case .MultiPart:
                request.addValue("multipart/form-data", forHTTPHeaderField: "Content-Type")
            case .ApplicationJson:
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            case .Form:
                request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
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
        
//        let langStr = Locale.current.languageCode != "es" ? "en" : "es"
//        print("langStr------------->", langStr)
//        request.addValue(langStr, forHTTPHeaderField: "Accept-Language")
        return request
    }
}

