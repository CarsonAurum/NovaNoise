//
//  Created by Carson Rau on 5/5/22.
//

import NovaCore

/// Conform to this type to implement additional noise modules.
public typealias Module = BaseModule & ModuleProtocol

/// The underlying protocol conformance required by all modules.
public protocol ModuleProtocol {
    /// The number of modules required for this module to execute correctly.
    static var moduleCount: Int { get }
    ///  Generates an output value given the coordinates of the specified input value.
    ///
    /// - Precondition: All source modules required by this noise module must have been passed to a variant of
    /// ``BaseModule/setSourceModule(_:at:)-3jpeb``.
    /// - Parameters:
    ///   - x: The x coordinate of the input value.
    ///   - y: The y coordinate of the input value.
    ///   - z: The z coordiante of the input value.
    /// - Throws: ``BaseModule/ModuleError/noModule`` if any of the required modules are missing.
    /// - Returns: The calculated output value.
    func getValue(x: Double, y: Double, z: Double) throws -> Double
}
// Convenience value funcs
public extension ModuleProtocol {
    /// A convenience function to access the core ``getValue(x:y:z:)`` function.
    ///
    /// - Parameter value: A tuple in the form (x, y, z).
    /// - Throws: Any errors from the ``getValue(x:y:z:)`` function.
    /// - Returns The calculated output value from ``getValue(x:y:z:)``
    func getValue(_ value: (Double, Double, Double)) throws -> Double {
        try getValue(x: value.0, y: value.1, z: value.2)
    }
}
/// A base class for noise modules.
open class BaseModule {
    public enum ModuleError: Error {
        case noModule
        case invalidIndex
        case invalidParameter
        case pointsNeeded
    }
    internal var modules: [Module?]
    public init(sourceCount count: Int) {
        if count > 0 {
            modules = Array.init(repeating: nil, count: count)
        } else {
            modules = []
        }
    }
    public func getSourceModule(at index: Int) throws -> Module {
        guard index.isBetween(0 ... modules.count) else {
            throw ModuleError.invalidIndex
        }
        return try modules[index].unwrapOrThrow(ModuleError.noModule)
    }
    public func setSourceModule(_ module: Module, at index: Int) throws {
        guard index.isBetween(0 ... modules.count) else {
            throw ModuleError.invalidIndex
        }
        modules[index] = module
    }
    public func setSourceModule(_ module: Module?, at index: Int) throws {
        try setSourceModule(module.unwrapOrThrow(ModuleError.noModule), at: index)
    }
}

