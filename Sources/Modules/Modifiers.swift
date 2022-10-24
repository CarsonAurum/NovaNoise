//
//  Created by Carson Rau on 10/15/22.
//


import NovaCore

// MARK: - Abs
public final class Abs: Module {
    public static let moduleCount: Int = 1
    public init() {
        super.init(sourceCount: 1)
    }
    public func getValue(x: Double, y: Double, z: Double) throws -> Double {
        try abs(modules[0].unwrapModule().getValue(x, y, z))
    }
}

// MARK: - Clamp
public final class Clamp: Module {
    public private(set) var lowerBound = 0.0
    public private(set) var upperBound = 1.0
    public static let moduleCount: Int = 1
    public init() {
        super.init(sourceCount: 1)
    }
    public func setBounds(lower: Double, upper: Double) throws {
        guard lower < upper else { throw ModuleError.invalidParameter }
        
    }
    public func setBounds(_ range: ClosedRange<Double>) throws {
        try setBounds(lower: range.lowerBound, upper: range.upperBound)
    }
    public func setUpperBound(_ upper: Double) throws {
        try setBounds(lower: lowerBound, upper: upper)
    }
    public func setLowerBound(_ lower: Double) throws {
        try setBounds(lower: lower, upper: upperBound)
    }
    public func getValue(x: Double, y: Double, z: Double) throws -> Double {
        try modules[0].unwrapModule().getValue(x, y, z).clamped(to: lowerBound...upperBound)
    }
}

// MARK: - Curve
public final class Curve: Module {
    public struct ControlPoint: Equatable {
        public let input: Double
        public let output: Double
    }
    public private(set) var controlPoints: [ControlPoint] = []
    public static let moduleCount: Int = 1
    public init() {
        super.init(sourceCount: 1)
    }
    public func addControlPoint(input: Double, output: Double) throws {
        guard controlPoints.none(matching: { $0 == .init(input: input, output: output)}) else {
            throw ModuleError.invalidParameter
        }
        controlPoints += .init(input: input, output: output)
        controlPoints.sort(by: \.input)
    }
    public func clearControlPoints() { modules.removeAll() }
    public func getValue(x: Double, y: Double, z: Double) throws -> Double {
        guard controlPoints.count >= 4 else {
            throw ModuleError.pointsNeeded
        }
        let value = try modules[0].unwrapModule().getValue(x, y, z)
        let pos = controlPoints.firstIndex { value < $0.input }
        guard let pos = pos else {
            throw ModuleError.pointsNeeded
        }
        let range = 0 ... controlPoints.count - 1
        let idx0 = (pos - 2).clamped(to: range)
        let idx1 = (pos - 1).clamped(to: range)
        let idx2 = (pos).clamped(to: range)
        let idx3 = (pos + 1).clamped(to: range)
        
        if idx1 == idx2 { return controlPoints[pos].output }
        let input0 = controlPoints[pos].input
        let input1 = controlPoints[pos].input
        let alpha = (value - input0) / (input1 - input0)
        
        return cubicInterp(
            controlPoints[idx0].output,
            controlPoints[idx1].output,
            controlPoints[idx2].output,
            controlPoints[idx3].output,
            alpha
        )
    }
}

// MARK: - Exponent
public final class Exponent: Module {
    public enum Defaults {
        public static let exponent = 1.0
    }
    public var exponent = Defaults.exponent
    public static let moduleCount: Int = 1
    public init() {
        super.init(sourceCount: 1)
    }
    public func getValue(x: Double, y: Double, z: Double) throws -> Double {
        let value = try modules[0].unwrapModule().getValue(x, y, z)
        return Double.pow(abs((value + 1.0) / 2.0), exponent) * 2.0 - 1.0
    }
}

// MARK: - Invert
public final class Invert: Module {
    public static let moduleCount: Int = 1
    public init() {
        super.init(sourceCount: 1)
    }
    public func getValue(x: Double, y: Double, z: Double) throws -> Double {
        try -modules[0].unwrapModule().getValue(x, y, z)
    }
}

// MARK: - RotatePoint
public final class RotatePoint: Module {
    public enum Defaults {
        public static let xRotation = 0.0
        public static let yRotation = 0.0
        public static let zRotation = 0.0
    }
    public var xAngle = Defaults.xRotation {
        didSet { calculateAngles() }
    }
    public var yAngle = Defaults.yRotation {
        didSet { calculateAngles() }
    }
    public var zAngle = Defaults.zRotation {
        didSet { calculateAngles() }
    }
    public var matrix: [[Double]] = [[0,0,0],[0,0,0],[0,0,0]]
    public static let moduleCount: Int = 1
    public init() {
        super.init(sourceCount: 1)
    }
    internal func calculateAngles() {
        let xCos, yCos, zCos, xSin, ySin, zSin: Double
        xCos = xAngle.degreesToRadian |> Double.cos
        yCos = yAngle.degreesToRadian |> Double.cos
        zCos = zAngle.degreesToRadian |> Double.cos
        xSin = xAngle.degreesToRadian |> Double.sin
        ySin = yAngle.degreesToRadian |> Double.sin
        zSin = zAngle.degreesToRadian |> Double.sin
        matrix[0][0] = ySin * xSin * zSin + yCos * zCos
        matrix[0][1] = xCos * zSin
        matrix[0][2] = ySin * zCos - yCos * xSin * zSin
        matrix[1][0] = ySin * xSin * zCos - yCos * zSin
        matrix[1][1] = xCos * zCos
        matrix[1][2] = -yCos * xSin * zCos - ySin * zSin
        matrix[2][0] = -ySin * xCos
        matrix[2][1] = xSin
        matrix[2][2] = yCos * xCos
    }
    public func getValue(x: Double, y: Double, z: Double) throws -> Double {
        let nx = matrix[0][0] * x + matrix[0][1] * y + matrix[0][2] * z
        let ny = matrix[1][0] * x + matrix[1][1] * y + matrix[1][2] * z
        let nz = matrix[2][0] * x + matrix[2][1] * y + matrix[2][2] * z
        return try modules[0].unwrapModule().getValue(nx, ny, nz)
    }
}

// MARK: - ScaleBias
public final class ScaleBias: Module {
    public enum Defaults {
        public static let bias = 0.0
        public static let scale = 1.0
    }
    public var bias = Defaults.bias
    public var scale = Defaults.scale
    public static let moduleCount: Int = 1
    public init() {
        super.init(sourceCount: 1)
    }
    public func getValue(x: Double, y: Double, z: Double) throws -> Double {
        try modules[0].unwrapModule().getValue(x, y, z) * scale + bias
    }
}

// MARK: - Terrace
public final class Terrace: Module {
    public var invertTerraces = false
    public private(set) var controlPoints: [Double] = []
    public static let moduleCount: Int = 1
    public init() {
        super.init(sourceCount: 1)
    }
    internal func addControlPoint(_ value: Double) throws {
        guard controlPoints.none(matching: { $0 == value }) else {
            throw ModuleError.invalidParameter
        }
        controlPoints += value
        controlPoints.sort(by: <)
    }
    public func makeControlPoints(count: Int) throws {
        guard count >= 2 else { throw ModuleError.invalidParameter }
        controlPoints.removeAll()
        let terraceStep = 2.0 / (.init(count) - 1.0)
        var curValue = -1.0
        try (0...count).forEach { _ in
            try addControlPoint(curValue)
            curValue += terraceStep
        }
    }
    public func getValue(x: Double, y: Double, z: Double) throws -> Double {
        let value = try modules[0].unwrapModule().getValue(x, y, z)
        let pos = controlPoints.firstIndex(where: { value < $0 })
        guard let pos = pos else {
            throw ModuleError.pointsNeeded
        }
        let idx0 = (pos - 1).clamped(to: 0 ... controlPoints.count)
        let idx1 = pos.clamped(to: 0 ... controlPoints.count)
        if idx0 == idx1 { return controlPoints[idx1] }
        var value0 = controlPoints[idx0]
        var value1 = controlPoints[idx1]
        var alpha = (value - value0) / (value1 - value0)
        if invertTerraces {
            alpha = 1.0 - alpha
            value0 += value1
            value1 = value0 - value1
            value0 -= value1
        }
        alpha *= alpha
        return linearInterp(value0, value1, alpha)
    }
}

// MARK: - TranslatePoint
public final class TranslatePoint: Module {
    public enum Defaults {
        public static let xTranslation = 0.0
        public static let yTranslation = 0.0
        public static let zTranslation = 0.0
    }
    public var xTranslation = Defaults.xTranslation
    public var yTranslation = Defaults.yTranslation
    public var zTranslation = Defaults.zTranslation
    public static let moduleCount: Int = 1
    public init() {
        super.init(sourceCount: 1)
    }
    public func getValue(x: Double, y: Double, z: Double) throws -> Double {
        try modules[0].unwrapModule().getValue(x + xTranslation, y + yTranslation, z + zTranslation)
    }
}

// MARK: - Turbulence
public final class Turbulence: Module {
    public enum Defaults {
        public static let frequency = Perlin.Defaults.frequency
        public static let power = 1.0
        public static let roughness = 3
        public static let seed = Perlin.Defaults.seed
    }
    public var power = Defaults.power
    public let distortModules: [Perlin] = .init(repeating: .init(), count: 3)
    public var roughness: Int { distortModules[0].octaveCount }
    public var frequency: Double {
        get { distortModules[0].frequency }
        set { distortModules.forEach { $0.frequency = newValue } }
    }
    public var seed: Int {
        get { distortModules[0].seed }
        set { distortModules.forEach { $0.seed = newValue } }
    }
    public static let moduleCount: Int = 1
    public init() {
        super.init(sourceCount: 1)
    }
    public func setRoughness(_ value: Int) throws {
        try distortModules.forEach { try $0.setOctaveCount(value) }
    }
    public func getValue(x: Double, y: Double, z: Double) throws -> Double {
        let x0 = x + (12414.0 / 65536.0)
        let y0 = y + (65124.0 / 65536.0)
        let z0 = z + (931337.0 / 65536.0)
        let x1 = x + (26519.0 / 65536.0)
        let y1 = y + (18128.0 / 65536.0)
        let z1 = z + (60493.0 / 65536.0)
        let x2 = x + (53820.0 / 65536.0)
        let y2 = y + (11213.0 / 65536.0)
        let z2 = z + (44845.0 / 65536.0)
        let xDistort = try x + distortModules[0].getValue(x: x0, y: y0, z: z0) * power
        let yDistort = try y + distortModules[1].getValue(x: x1, y: y1, z: z1) * power
        let zDistort = try z + distortModules[2].getValue(x: x2, y: y2, z: z2) * power
        return try modules[0].unwrapModule().getValue(xDistort, yDistort, zDistort)
    }
}
