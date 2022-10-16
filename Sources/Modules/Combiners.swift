//
//  Created by Carson Rau on 5/5/22.
//

import NovaCore

// MARK: - Add
public final class Add: Module {
    public static let moduleCount: Int = 2
    
    public init() {
        super.init(sourceCount: 2)
    }
    
    public func getValue(x: Double, y: Double, z: Double) throws -> Double {
        return try modules[0].unwrapOrThrow(ModuleError.noModule).getValue((x, y, z))
                 + modules[1].unwrapOrThrow(ModuleError.noModule).getValue((x, y, z))
    }
}

// MARK: - Blend
public final class Blend: Module {
    public static let moduleCount: Int = 3
    public init() {
        super.init(sourceCount: 3)
    }
    public func getControlModule() throws -> Module {
        return try modules[2].unwrapOrThrow(ModuleError.noModule)
    }
    public func setControlModule(_ module: Module) {
        modules[2] = module
    }
    
    public func getValue(x: Double, y: Double, z: Double) throws -> Double {
        let v0 = try modules[0].unwrapOrThrow(ModuleError.noModule).getValue((x, y, z))
        let v1 = try modules[1].unwrapOrThrow(ModuleError.noModule).getValue((x, y, z))
        let alpha = try
            (modules[2].unwrapOrThrow(ModuleError.noModule).getValue((x, y, z)) + 1.0) / 2.0
        return linearInterp(v0, v1, alpha)
    }
}

// MARK: - Displace
public final class Displace: Module {
    public enum Axis {
        case x, y, z
    }
    
    public static let moduleCount: Int = 4
    public init() {
        super.init(sourceCount: 4)
    }
    public func getDisplacement(for axis: Axis) throws -> Module {
        var module: Module?
        switch axis {
        case .x:
            module = modules[1]
        case .y:
            module = modules[2]
        case .z:
            module = modules[3]
        }
        return try module.unwrapOrThrow(ModuleError.noModule)
    }
    public func setDisplacement(_ module: Module, for axis: Axis) {
        switch axis {
        case .x:
            modules[1] = module
        case .y:
            modules[2] = module
        case .z:
            modules[3] = module
        }
    }
    public func getValue(x: Double, y: Double, z: Double) throws -> Double {
        let xDisplacement =
            try x + modules[1].unwrapOrThrow(ModuleError.noModule).getValue((x, y, z))
        let yDisplacement =
            try y + modules[2].unwrapOrThrow(ModuleError.noModule).getValue((x, y, z))
        let zDisplacement =
            try z + modules[3].unwrapOrThrow(ModuleError.noModule).getValue((x, y, z))
        return try modules[0]
            .unwrapOrThrow(ModuleError.noModule)
            .getValue(x: xDisplacement, y: yDisplacement, z: zDisplacement)
    }
}

// MARK: - Max
public final class Max: Module {
    public static let moduleCount: Int = 2
    public init() {
        super.init(sourceCount: 2)
    }
    public func getValue(x: Double, y: Double, z: Double) throws -> Double {
        try max(
            modules[0].unwrapOrThrow(ModuleError.noModule).getValue((x, y, z)),
            modules[1].unwrapOrThrow(ModuleError.noModule).getValue((x, y, z))
        )
    }
}

// MARK: - Min
public final class Min: Module {
    public static let moduleCount: Int = 2
    public override init(sourceCount count: Int) {
        super.init(sourceCount: 2)
    }
    public func getValue(x: Double, y: Double, z: Double) throws -> Double {
        try min(
            modules[0].unwrapOrThrow(ModuleError.noModule).getValue((x, y, z)),
            modules[1].unwrapOrThrow(ModuleError.noModule).getValue((x, y, z))
        )
    }
}

// MARK: - Multiply
public final class Multiply: Module {
    public static let moduleCount: Int = 2
    public init() {
        super.init(sourceCount: 2)
    }
    public func getValue(x: Double, y: Double, z: Double) throws -> Double {
        try modules[0].unwrapOrThrow(ModuleError.noModule).getValue((x, y, z))
          * modules[1].unwrapOrThrow(ModuleError.noModule).getValue((x, y, z))
    }
}

// MARK: - Power
public final class Power: Module {
    public static let moduleCount: Int = 2
    public init() {
        super.init(sourceCount: 2)
    }
    public func getValue(x: Double, y: Double, z: Double) throws -> Double {
        try Double.pow(
            modules[0].unwrapOrThrow(ModuleError.noModule).getValue(x: x, y: y, z: z),
            modules[1].unwrapOrThrow(ModuleError.noModule).getValue(x: x, y: y, z: z)
        )
    }
}

// MARK: - Select
public final class Select: Module {
    public enum Defaults {
        public static let edgeFalloff = 0.0
        public static let lowerBound = -1.0
        public static let upperBound = 1.0
    }
    public private(set) var edgeFalloff = Defaults.edgeFalloff
    public private(set) var lowerBound = Defaults.lowerBound
    public private(set) var upperBound = Defaults.upperBound
    public static let moduleCount: Int = 3
    public init() {
        super.init(sourceCount: 3)
    }
    public func getControlModule() throws -> Module {
        try modules[2].unwrapOrThrow(ModuleError.noModule)
    }
    public func setControlModule(_ module: Module) {
        modules[2] = module
    }
    public func setEdgeFalloff(_ newValue: Double) {
        let boundSize = upperBound - lowerBound
        edgeFalloff = min(newValue, boundSize / 2)
    }
    public func setBounds(upper: Double, lower: Double) throws {
        guard upper > lower else {
            throw ModuleError.invalidParameter
        }
        lowerBound = lower
        upperBound = upper
        setEdgeFalloff(edgeFalloff)
    }
    public func setUpperBound(_ bound: Double) throws {
        try setBounds(upper: bound, lower: lowerBound)
    }
    public func setLowerBound(_ bound: Double) throws {
        try setBounds(upper: upperBound, lower: bound)
    }
    public func setBounds(_ bounds: ClosedRange<Double>) throws {
        try setBounds(upper: bounds.upperBound, lower: bounds.lowerBound)
    }
    public func getValue(x: Double, y: Double, z: Double) throws -> Double {
        let controlValue = try modules[2]
            .unwrapOrThrow(ModuleError.noModule)
            .getValue(x: x, y: y, z: z)
        var alpha = 0.0
        if edgeFalloff > 0.0 {
            if controlValue < lowerBound - edgeFalloff {
                return try modules[0]
                    .unwrapOrThrow(ModuleError.noModule)
                    .getValue(x: x, y: y, z: z)
            } else if controlValue < lowerBound + edgeFalloff {
                let lowerCurve = lowerBound - edgeFalloff, upperCurve = lowerBound + edgeFalloff
                alpha = sCurve3((controlValue - lowerCurve) / (upperCurve - lowerCurve))
                return linearInterp(
                    try modules[0].unwrapOrThrow(ModuleError.noModule).getValue(x: x, y: y, z: z),
                    try modules[1].unwrapOrThrow(ModuleError.noModule).getValue(x: x, y: y, z: z),
                    alpha)
            } else if controlValue < upperBound - edgeFalloff {
                return try modules[1]
                    .unwrapOrThrow(ModuleError.noModule)
                    .getValue(x: x, y: y, z: z)
            } else if controlValue < upperBound + edgeFalloff {
                let lowerCurve = upperBound - edgeFalloff, upperCurve = upperBound + edgeFalloff
                alpha = sCurve3((controlValue - lowerCurve) / (upperCurve - lowerCurve))
                return linearInterp(
                    try modules[1].unwrapOrThrow(ModuleError.noModule).getValue(x: x, y: y, z: z),
                    try modules[0].unwrapOrThrow(ModuleError.noModule).getValue(x: x, y: y, z: z),
                    alpha)
            } else {
                return try modules[0]
                    .unwrapOrThrow(ModuleError.noModule)
                    .getValue(x: x, y: y, z: z)
            }
        } else {
            if !controlValue.isBetween(lowerBound...upperBound) {
                return try modules[0]
                    .unwrapOrThrow(ModuleError.noModule)
                    .getValue(x: x, y: y, z: z)
            } else {
                return try modules[1]
                    .unwrapOrThrow(ModuleError.noModule)
                    .getValue(x: x, y: y, z: z)
            }
        }
    }
}
