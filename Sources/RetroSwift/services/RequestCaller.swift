//
//  RequestCaller.swift
//  RxRetroSwift
//
//  Created by Erick Guerrero on 2020/12/12.
//

import Foundation
import CoreData

public typealias DecodableError = Decodable & HasErrorInfo

protocol RequestCallerTokenRefresh {
    func onNewToken(token: String)
}

public class RequestCaller {
    
    private lazy var decoder = JSONDecoder()
    private var urlSession:URLSession
//    private let semaphore = DispatchSemaphore(value: 0)
    private let dispatchGroup = DispatchGroup()
    //    private let dispatchAllTask = DispatchGroup()
    private let dispatchQueue = DispatchQueue(label: "RetroSwift")
    private let cache = RetroCache<String, Data>()
    //    var fetchTokenKey: String?
    //    var refreshURLRequest: URLRequest?
    //    var delegate: RequestCallerTokenRefresh?
    var managedObjectContext: NSManagedObjectContext?
    var onFailRequestByAuth: ((URLRequest)-> URLRequest?)?
    
    public init(config:URLSessionConfiguration) {
        urlSession = URLSession(configuration: config)
        
//        if let codingUserInfoKeyManagedObjectContext = CodingUserInfoKey.managedObjectContext  {
//            let managedObjectContext = self.managedObjectContext
//            self.decoder.userInfo[codingUserInfoKeyManagedObjectContext] = managedObjectContext
//        }
//        self.decoder.dateDecodingStrategy = .custom { decoder in
//            let container = try decoder.singleValueContainer()
//            let stringOfDays = try container.decode(String.self)
//            return stringOfDays.toDate()?.date ?? Date()
//        }
    }
    
    public convenience init() {
        self.init(config: URLSessionConfiguration.default)
        
//        if let codingUserInfoKeyManagedObjectContext = CodingUserInfoKey.managedObjectContext  {
//            let managedObjectContext = self.managedObjectContext
//            self.decoder.userInfo[codingUserInfoKeyManagedObjectContext] = managedObjectContext
//        }
//
//        self.decoder.dateDecodingStrategy = .custom { decoder in
//            let container = try decoder.singleValueContainer()
//            let stringOfDays = try container.decode(String.self)
//            return stringOfDays.toDate()?.date ?? Date()
//        }
    }
    
    let higherPriority = DispatchQueue.global(qos: .userInitiated)
    let lowerPriority = DispatchQueue.global(qos: .utility)
    
    public func call<ItemModel:Decodable, RSErrorModel: DecodableError>(_ request: URLRequest)
    -> Swift.Result<ItemModel, RSErrorModel> {
        let semaphoreCall = DispatchSemaphore(value: 0)
        print("<---INIT REQUEST--->",  semaphoreCall)
        print("\(request.httpMethod ?? "--") TO URL:", request.url ?? "no url")
        var err = RSErrorModel()
        err.errorCode = 0
        var result: Swift.Result<ItemModel, RSErrorModel> = .failure(err)
        //        let keyUnique = "\(request.httpMethod ?? "--")TO\(request.url?.absoluteString ?? "no-url")"
        //        if keyUnique != "--TOno-url",
        //           let cachedData = cache[keyUnique] {
        //            do {
        //                let objs = try self.decoder.decode(ItemModel.self, from: cachedData)
        //                result = .success(objs)
        ////                print("data by cache", objs)
        //                 semaphoreCall.signal()
        //            } catch {
        //                print("DecodingError from cahe--->", error.localizedDescription)
        //            }
        //        }
        lowerPriority.async {
            let task = self.urlSession
                .dataTask(with: request) { (data, responseRequest, error) in
                    if let response = data,
                       let responseHttp = responseRequest as? HTTPURLResponse {
                        print("Response \(request.httpMethod ?? "--") http status code:", responseHttp.statusCode)
                        print("\(request.httpMethod ?? "--")  RESULT OF URL:", request.url ?? "no url")
                        err.errorCode = responseHttp.statusCode
                        self.printJS(data: response)
                        switch responseHttp.statusCode {
                            case 200...299:
                                do {
                                    let objs = try self.decoder.decode(ItemModel.self, from: response)
                                    //                                    self.printJS(data: response)
                                    //                                self.cache[keyUnique] = response
                                    result = .success(objs)
                                    semaphoreCall.signal()
                                } catch let error as DecodingError {
                                    print("DecodingError--->", error)
                                    self.printJS(data: response)
                                    err.errorDetail = error.localizedDescription
                                    result = .failure(err)
                                    semaphoreCall.signal()
                                } catch {
                                    print("normal error--->", error)
                                    self.printJS(data: response)
                                    err.errorDetail = error.localizedDescription
                                    result = .failure(err)
                                    semaphoreCall.signal()
                                }
                            case 400:
                                result = self.resolveError(response, request)
                                semaphoreCall.signal()
                                
                            case 401:
                                print("response code 401-->")
                                self.printJS(data: response)
                                self.higherPriority.async {
                                    if let onFailAuth = self.onFailRequestByAuth,
                                       let newRequest = onFailAuth(request) {
                                        result = self.makeAPICall(urlSession: newRequest)
                                        semaphoreCall.signal()
                                    } else {
                                        err.errorDetail = "auth"
                                        result = .failure(err)
                                        semaphoreCall.signal()
                                    }
                                }
                            case 403:
                                err.errorDetail = "forbidden"
                                result = .failure(err)
                                semaphoreCall.signal()
                                
                            case 404...500:
                                result = .failure(err)
                                semaphoreCall.signal()
                                
                            case 501...599:
                                
                                err.errorDetail = "badRequest"
                                result = .failure(err)
                                semaphoreCall.signal()
                                
                            default:
                                err.errorDetail = "requestFailed"
                                result = .failure(err)
                                semaphoreCall.signal()
                                
                        }
                    } else if let error = error {
                        print("no data error--->")
                        err.errorDetail = error.localizedDescription
                        result = .failure(err)
                        semaphoreCall.signal()
                    } else {
                        err.errorDetail = "no data"
                        result = .failure(err)
                        semaphoreCall.signal()
                    }
                    
                }
            task.resume()
        }
        let resultSemaphore = semaphoreCall.wait(wallTimeout: .distantFuture)
        print("resultSemaphore-->", resultSemaphore)
        //        if  semaphoreCall.wait(timeout: .now() + 30) == .timedOut {
        //            err.errorDetail = "timeout"
        //            result = .failure(err)
        //        }
        
        return result
    }
    
    public func simpleCall<ItemModel:Decodable, RSErrorModel: DecodableError>(_ request: URLRequest)
    -> Swift.Result<ItemModel, RSErrorModel> {
        let semaphoreCall = DispatchSemaphore(value: 0)
        print("<---INIT REQUEST--->")
        print("\(request.httpMethod ?? "--") TO URL:", request.url ?? "no url")
        var err = RSErrorModel()
        err.errorCode = 0
        var result: Swift.Result<ItemModel, RSErrorModel> = .failure(err)
        lowerPriority.async {
            let task = self.urlSession
                .dataTask(with: request) { (data, responseRequest, error) in
                    if let response = data,
                       let responseHttp = responseRequest as? HTTPURLResponse {
                        print("Response \(request.httpMethod ?? "--") http status code:", responseHttp.statusCode)
                        print("\(request.httpMethod ?? "--")  RESULT OF URL:", request.url ?? "no url")
                        err.errorCode = responseHttp.statusCode
                        do {
                            if (200...399).contains(responseHttp.statusCode) {
                                let objs = try self.decoder.decode(ItemModel.self, from: response)
                                //                                self.printJS(data: response)
                                result = .success(objs)
                                 semaphoreCall.signal()
                            } else {
                                var error = try self.decoder.decode(RSErrorModel.self, from: response)
                                error.errorCode = responseHttp.statusCode
                                err.errorDetail = error.localizedDescription
                                result = .failure(error)
                                 semaphoreCall.signal()
                            }
                        } catch let errordecod as DecodingError {
                            print("error decoding ", errordecod)
                            self.printJS(data: response)
                            do {
                                var errordec = try self.decoder.decode(RSErrorModel.self, from: response)
                                
                                errordec.errorCode = responseHttp.statusCode
                                errordec.errorDetail = errordec.localizedDescription
                                if errordec.status == 2 {
                                    print("response code 401-->")
                                    self.printJS(data: response)
                                    self.higherPriority.async {
                                        if let onFailAuth = self.onFailRequestByAuth,
                                           let newRequest = onFailAuth(request) {
                                            result = self.makeAPICall(urlSession: newRequest)
                                             semaphoreCall.signal()
                                        } else {
                                            err.errorDetail = "auth"
                                            result = .failure(err)
                                             semaphoreCall.signal()
                                        }
                                    }
                                } else {
                                    result = .failure(errordec)
                                     semaphoreCall.signal()
                                }
                            } catch {
                                print("error decoding 2", error)
                                var decodingError = RSErrorModel()
                                decodingError.errorCode = -1
                                decodingError.errorDetail = error.localizedDescription
                                err.errorDetail = error.localizedDescription
                                result = .failure(err)
                                 semaphoreCall.signal()
                            }
                        } catch {
                            
                            var decodingError = RSErrorModel()
                            decodingError.errorCode = -1
                            decodingError.errorDetail = error.localizedDescription
                            err.errorDetail = error.localizedDescription
                            result = .failure(err)
                             semaphoreCall.signal()
                        }
                    } else if let error = error {
                        print("no data error--->")
                        err.errorDetail = error.localizedDescription
                        result = .failure(err)
                        //                        result = .failure(ApiError.convert(error: error.localizedDescription))
                         semaphoreCall.signal()
                    } else {
                        err.errorDetail = "no data"
                        result = .failure(err)
                        //                        result = .failure(ApiError.convert(error: "no data"))
                         semaphoreCall.signal()
                    }
                    
                }
            task.resume()
        }
        _ =  semaphoreCall.wait(wallTimeout: .distantFuture)
        return result
    }
    
    func makeAPICall<ItemModel:Decodable, RSErrorModel: DecodableError>(urlSession: URLRequest) -> Result<ItemModel, RSErrorModel> {
        dispatchGroup.enter()
        var result: Result<ItemModel, RSErrorModel>!
        let semaphoreTwo = DispatchSemaphore(value: 0)
        
        var err = RSErrorModel()
        err.errorCode = 0
        URLSession.shared.dataTask(with: urlSession) { (data, responseRequest, error) in
            if let response = data,
               let responseHttp = responseRequest as? HTTPURLResponse {
                
                print("makeAPICall.statusCode", responseHttp.statusCode)
                print("makeAPICall URL:", urlSession.url ?? "no url")
                do {
                    let objs = try self.decoder.decode(ItemModel.self, from: response)
                    result = .success(objs)
                } catch let error as DecodingError {
                    print("DecodingError--->", error)
                    self.printJS(data: response, "\(#function) \(String(describing: urlSession.url))")
                    //                    result = .failure(ApiError.decoding(error: error.localizedDescription))
                    err.errorDetail = error.localizedDescription
                    result = .failure(err)
                } catch {
                    print("normal error--->", error)
                    self.printJS(data: response, "\(#function) \(String(describing: urlSession.url))")
                    //                    result = .failure(ApiError.convert(error: error.localizedDescription))
                    err.errorDetail = error.localizedDescription
                    result = .failure(err)
                }
            } else {
                //                result = .failure(ApiError.server(error: "makeAPICall"))
                err.errorDetail = "makeAPICall"
                result = .failure(err)
            }
            semaphoreTwo.signal()
            self.dispatchGroup.leave()
        }.resume()
        
        semaphoreTwo.wait()
        return result
    }
    
    @discardableResult
    func printJS(data: Data, _ tag: String = "") -> [String: Any]? {
        do {
            // make sure this JSON is in the format we expect
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                // try to read out a string array
                print("<---- json \(tag)---->\n")
                print(json)
                print("<---- end - json \(tag)---->")
                return json
            }
        } catch let error as NSError {
            print("Failed to load: \(error.localizedDescription)")
        }
        return nil
    }
    
    func resolveError<ItemModel:Decodable, RSErrorModel: DecodableError>(_ response: Data, _ request: URLRequest) -> Result<ItemModel, RSErrorModel> {
        var err = RSErrorModel()
        err.errorCode = 0
        var result: Swift.Result<ItemModel, RSErrorModel>!
        do {
            self.printJS(data: response, "\(#function))")
            let errorM = try self.decoder.decode(ErrorModel.self, from: response)
            if let firsterror = errorM.errors?.first {
                print("firsterror-->", firsterror)
                //                result = .failure(ApiError.server(error: firsterror.message ))
                err.errorDetail = firsterror.message
                result = .failure(err)
            } else {
                print("errorM.message-->", errorM.message ?? "nothing")
                //                result = .failure(ApiError.server(error: errorM.message ?? "error"))
                err.errorDetail = errorM.message ?? "error"
                result = .failure(err)
            }
        } catch {
            print("Decoding Error in error handle--->", error)
            if let json = self.printJS(data: response, "\(#function) \(String(describing: request.url))") {
                var errorStr = "error in json"
                if let errorsInResponse = json["errors"] as? [String: String],
                   let errorInRequest = errorsInResponse["message"]{
                    errorStr = errorInRequest
                } else if let errorInRequest = (json["message"] as? String) {
                    errorStr = errorInRequest
                } else {
                    let url = self.getDocumentsDirectory().appendingPathComponent("message.txt")
                    
                    let str = String(decoding: response, as: UTF8.self)
                    
                    do {
                        try str.write(to: url, atomically: true, encoding: .utf8)
                        let input = try String(contentsOf: url)
                        print(input)
                    } catch {
                        print(error.localizedDescription)
                    }
                }
                print("errorInRequest", errorStr)
                //                result = .failure(ApiError.server(error: errorStr))
                err.errorDetail = errorStr
                result = .failure(err)
            } else {
                //                result = .failure(ApiError.convert(error: "no data"))
                err.errorDetail = "no data"
                result = .failure(err)
            }
        }
        return result
    }
    
    func getDocumentsDirectory() -> URL {
        // find all possible documents directories for this user
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        
        // just send back the first one, which ought to be the only one
        return paths[0]
    }
    
}


/// I am using a custom result type to support just an Error and not a Type object for success
enum NetworkResponseResult<Error> {
    case success
    case failure(Error)
}


public protocol HasErrorInfo {
    
    var status: Int? { get set }
    var errorCode:Int? { get set }
    var errorDetail:String? { get set }
    
    init()
}

enum ApiError: Error {
    case failFuture
    case convert(error: String)
    case decoding(error: String)
    case server(error: String)
    case invalidAuthToken
    case noInternet
}

extension ApiError: LocalizedError {
    public var localizedDescription: String {
        switch self {
            case .failFuture:
                return NSLocalizedString("Fail in request", comment: "Invalid Request (failFuture) RetroSwiftX")
            case .convert(error: let error):
                return NSLocalizedString("\(error.description)", comment: "Invalid Request (convert) RetroSwiftX")
            case .noInternet:
                return NSLocalizedString("No internet", comment: "Invalid Request (noInternet) RetroSwiftX")
            case .decoding(error: let error):
                return NSLocalizedString("\(error.description)", comment: "Invalid Request (decoding) RetroSwiftX")
            case .server(error: let error):
                return NSLocalizedString("\(error.description)", comment: "Invalid Request (server) RetroSwiftX")
            case .invalidAuthToken:
                return NSLocalizedString("Fail in auth api", comment: "Invalid Request (auth) RetroSwiftX")
        }
    }
}


struct ValidAdonis: Codable {
    var field: String
    var message: String
    var validation: String
    
}
