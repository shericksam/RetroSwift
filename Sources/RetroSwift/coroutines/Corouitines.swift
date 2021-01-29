//
//  Corouitines.swift
//  playme
//
//  Created by Irving Crespo on 26/10/20.
//  Copyright © 2020 Irving Crespo. All rights reserved.
//

import Foundation

public class Coroutines{
    
    public static func io( work : @escaping () throws -> Void )  {
        let queue = OperationQueue()
        queue.name = UUID().uuidString
        queue.maxConcurrentOperationCount = 1
        queue.addOperation {
            do {
                try work()
            } catch {
                print("Error Coroutines.io", error.localizedDescription)
            }
        }
    }
    
    public static func main( work :@escaping () throws -> Void )  {
        DispatchQueue.main.async {
            do {
                try work()
            } catch {
                print("Error Coroutines.main", error.localizedDescription)
            }
        }
    }
    
}

