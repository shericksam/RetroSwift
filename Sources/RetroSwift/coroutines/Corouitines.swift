//
//  Corouitines.swift
//  playme
//
//  Created by Irving Crespo on 26/10/20.
//  Copyright © 2020 Irving Crespo. All rights reserved.
//

import Foundation

class Coroutines{
    
    static func io( work : @escaping () throws -> Void )  {
        DispatchQueue.global(qos: .utility).async {
            do {
                try work()
            } catch {
                print("Error Coroutines.io", error.localizedDescription)
            }
        }
    }
    
    static func main( work :@escaping () throws -> Void )  {
        DispatchQueue.main.async {
            do {
                try work()
            } catch {
                print("Error Coroutines.main", error.localizedDescription)
            }
        }
    }
    
}

