//
//  File.swift
//  
//
//  Created by Carson Rau on 10/24/22.
//

import NovaCore

extension Optional {
    internal func unwrapModule() throws -> Wrapped {
        try unwrapOrThrow(Module.ModuleError.noModule)
    }
}
