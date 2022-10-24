//
//  Created by Carson Rau on 5/7/22.
//


import NovaCore
import CoreGraphics
#if canImport(Foundation)
import func Foundation.floor
#endif

// MARK: - Billow
/// A noise module capable of outputting 3D "billowy" noise.
///
/// This "billowy" noise is often most suited for clouds and/or rocks.
/// This module is nearly identical to the ``Perlin`` module, except that this module modifies each octave with an absolute value
/// function.
public final class Billow: Module {
    /// The default values associated with the billow module.
    public enum Defaults {
        /// Default ``Billow/frequency``.
        ///
        /// frequency = 1.0
        public static let frequency = 1.0
        /// Default ``Billow/lacunarity``.
        ///
        /// lacunarity = 2.0
        public static let lacunarity = 2.0
        /// Default ``Billow/octaveCount``
        ///
        /// octaveCount = 6
        public static let octaveCount = 6
        /// Default ``Billow/persistence``
        ///
        /// persistence = 0.5
        public static let persistence = 0.5
        /// Default ``Billow/quality``
        ///
        /// quality = `.standard`
        public static let quality: Noise.Quality = .standard
        /// Default ``Billow/seed``
        ///
        /// seed = 0
        public static let seed = 0
        /// Default maximum to the range of allowed octaves for this module.
        ///
        /// maxOctave = 30.
        public static let maxOctave = 30
    }
    /// The frequency of the first octave.
    public var frequency = Defaults.frequency
    /// The frequency multiplier between successive octaves.
    public var lacunarity = Defaults.lacunarity
    /// The quality of the generated noise from this module.
    public var quality = Defaults.quality
    /// Persistence for the noise.
    public var persistence = Defaults.persistence
    /// The seed used by the noise function.
    public var seed = Defaults.seed
    /// The total number of octaves that will be generated.
    public private(set) var octaveCount = Defaults.octaveCount
    public static let moduleCount: Int = 0
    /// Create a new Billow module with the default values.
    public init() { super.init(sourceCount: 0) }
    /// Create a new Billow module wherein different values may be provided on initialization.
    ///
    /// - Note: Any parameters left `nil`, the corresponding default value will be used.
    /// - Parameters:
    ///   - frequency: The frequency value to use.
    ///   - lacunarity: The lacunarity value to use.
    ///   - quality: The quality value to use.
    ///   - persistence: The persistence value to use.
    ///   - seed: The seed value to use.
    ///   - octaveCount: The octaveCount value to use.
    public init(
        frequency: Double?,
        lacunarity: Double?,
        quality: Noise.Quality?,
        persistence: Double?,
        seed: Int?,
        octaveCount: Int?
    ) {
        self.frequency = frequency ?? Defaults.frequency
        self.lacunarity = lacunarity ?? Defaults.lacunarity
        self.quality = quality ?? Defaults.quality
        self.persistence = persistence ?? Defaults.persistence
        self.seed = seed ?? Defaults.seed
        self.octaveCount = octaveCount ?? Defaults.octaveCount
        super.init(sourceCount: 0)
    }
    /// Modify the ``octaveCount`` value.
    ///
    /// - Parameter n: The new octave count.
    /// - Throws: ``BaseModule/ModuleError/invalidParameter`` in the event that the given value is not within the range
    /// [1, maxOctave].
    public func setOctaveCount(_ n: Int) throws {
        guard n.isBetween(1...Defaults.maxOctave) else {
            throw ModuleError.invalidParameter
        }
        octaveCount = n
    }
    public func getValue(x: Double, y: Double, z: Double) throws -> Double {
        var initialPoint: Point3D = .init(x, y, z), clampedPoint: Point3D = .zero
        var seed = 0, value = 0.0, signal = 0.0, curPersistence = 1.0
        initialPoint *= frequency
        for x in 0 ..< octaveCount {
            clampedPoint = initialPoint.clamped()
            seed = self.seed + x
            signal = Noise.gradientCoherentNoise3D(point: clampedPoint, seed: seed, quality: quality)
            signal = 2.0 * abs(signal) - 1.0
            value += signal * curPersistence
            initialPoint *= lacunarity
            curPersistence *= persistence
        }
        value += 0.5
        return value
    }
}

// MARK: - Checkerboard
/// A noise module capable of outputting a checkerboard pattern.
///
/// This noise module outputs unit-sides blocks of values alternating between -1.0 and +1.0 (discrete).
/// This noise module is not useful by itself, but it is often used for debugging purposes.
public final class Checkerboard: Module {
    public static var moduleCount: Int = 0
    public init() {
        super.init(sourceCount: 0)
    }
    public func getValue(x: Double, y: Double, z: Double) throws -> Double {
        let val: Point3D = .init(x, y, z).clamped()
        return ((Int(val.x) & 1 ^ Int(val.y) & 1 ^ Int(val.z) & 1)) != 0 ? -1.0: 1.0
    }
}
// MARK: - Const
public final class Const: Module {
    public static var moduleCount: Int = 0
    public var value: Double = 0.0
    public init() {
        super.init(sourceCount: 0)
    }
    public func getValue(x: Double, y: Double, z: Double) throws -> Double {
        value
    }
}
// MARK: - Cylinders
public final class Cylinders: Module {
    public enum Defaults {
        public static let frequency = 1.0
    }
    public var frequency = Defaults.frequency
    public static let moduleCount: Int = 0
    public init() {
        super.init(sourceCount: 0)
    }
    public func getValue(x: Double, y: Double, z: Double) throws -> Double {
        let point: CGPoint = .init(x: x, y: z)
        let centerDist = point.magnitude
        let smallerDist = centerDist - floor(centerDist)
        let largerDist = 1.0 - smallerDist
        let nearestDist = min(smallerDist, largerDist)
        return 1.0 - nearestDist * 4.0
    }
}
// MARK: - Perlin
public final class Perlin: Module {
    public enum Defaults {
        public static let frequency = 1.0
        public static let lacunarity = 2.0
        public static let octaveCount = 6
        public static let persistence = 0.5
        public static let quality: Noise.Quality = .standard
        public static let seed = 0
        public static let maxOctave = 30
    }
    public var frequency = Defaults.frequency
    public var lacunarity = Defaults.lacunarity
    public var quality = Defaults.quality
    public private(set) var octaveCount = Defaults.octaveCount
    public var persistence = Defaults.persistence
    public var seed = Defaults.seed
    public static let moduleCount: Int = 0
    public init() {
        super.init(sourceCount: 0)
    }
    public func setOctaveCount(_ n: Int) throws {
        guard n.isBetween(1...Defaults.maxOctave) else {
            throw ModuleError.invalidParameter
        }
        octaveCount = n
    }
    public func getValue(x: Double, y: Double, z: Double) throws -> Double {
        var initialPoint: Point3D = .init(x, y, z) * frequency, clampedPoint: Point3D = .zero
        var value = 0.0, curPersistence = 1.0, signal = 0.0, seed = 0
        for curOctave in 0 ..< octaveCount {
            clampedPoint = initialPoint.clamped()
            seed = self.seed + curOctave
            signal = Noise.gradientCoherentNoise3D(point: clampedPoint, seed: seed, quality: quality)
            value += signal * curPersistence
            initialPoint *= lacunarity
            curPersistence *= persistence
        }
        return value
    }
}
// MARK: - Ridged Multi
public final class RidgedMulti: Module {
    public enum Defaults {
        public static let frequency = 1.0
        public static let lacunarity = 2.0
        public static let octaveCount = 6
        public static let quality: Noise.Quality = .standard
        public static let seed = 0
        public static let maxOctave = 30
    }
    public var frequency = Defaults.frequency
    public var lacunarity = Defaults.lacunarity
    public var quality = Defaults.quality
    public private(set) var octaveCount = Defaults.octaveCount
    public var weights: [Double]
    public var seed = Defaults.seed
    public static let moduleCount: Int = 0
    public init() {
        weights = .init(capacity: Defaults.maxOctave)
        super.init(sourceCount: 0)
        // Calculate weights
        var freq = 1.0
        (0 ..< Defaults.maxOctave).forEach {
            weights[$0] = Double.pow(freq, -1.0)
            freq *= lacunarity
        }
    }
    public func setOctaveCount(_ n: Int) throws {
        guard n.isBetween(1...Defaults.maxOctave) else {
            throw ModuleError.invalidParameter
        }
        octaveCount = n
    }
    public func getValue(x: Double, y: Double, z: Double) throws -> Double {
        var initialPoint: Point3D = .init(x, y, z) * frequency
        var signal = 0.0, value = 0.0, weight = 1.0, offset = 1.0, gain = 2.0
        (0 ..< octaveCount).forEach {
            let clampedPoint = initialPoint.clamped()
            let seed = (self.seed + $0) & 0x7FFFFFFF
            signal = Noise.gradientCoherentNoise3D(point: clampedPoint, seed: seed, quality: quality)
            signal = abs(signal)
            signal = offset - signal
            signal = Double.pow(signal, 2)
            signal *= weight
            weight = signal * gain
            weight = weight.clamped(to: 0.0 ... 1.0)
            value += signal * weights[$0]
            initialPoint *= lacunarity
        }
        return (value * 1.25) - 1.0
    }
}
// MARK: - Spheres
public final class Spheres: Module {
    public enum Defaults {
        public static let frequency = 1.0
    }
    public var frequency = Defaults.frequency
    public static let moduleCount: Int = 0
    public init() {
        super.init(sourceCount: 0)
    }
    public func getValue(x: Double, y: Double, z: Double) throws -> Double {
        let initialPoint: Point3D = .init(x, y, z)
        let centerDist = initialPoint.magnitude
        let smallerDist = centerDist - floor(centerDist)
        let largerDist = 1.0 - smallerDist
        let nearestDist = min(smallerDist, largerDist)
        return 1.0 - (nearestDist * 4.0)
    }
}

// MARK: - Voronoi
public final class Voronoi: Module {
    public enum Defaults {
        public static let displacement = 1.0
        public static let frequency = 1.0
        public static let seed = 0
    }
    public var displacement = Defaults.displacement
    public var enableDistance = false
    public var frequency = Defaults.frequency
    public var seed = Defaults.seed
    public static let moduleCount: Int = 0
    public init() {
        super.init(sourceCount: 0)
    }
    public func getValue(x: Double, y: Double, z: Double) throws -> Double {
        let initialPoint: Point3D = .init(x, y, z) * frequency
        let pointInt: Point3D = .init(
            initialPoint.x > 0.0 ? Int(initialPoint.x) : Int(initialPoint.x - 1),
            initialPoint.y > 0.0 ? Int(initialPoint.y) : Int(initialPoint.y - 1),
            initialPoint.z > 0.0 ? Int(initialPoint.z) : Int(initialPoint.z - 1)
        )
        var minDist = 2147483647.0
        var pointCandidate: Point3D = .zero
        var pointCur: Point3D = .init(pointInt.x - 2, pointInt.y - 2, pointInt.z - 2)
        while pointCur.z <= pointInt.z + 2 {
            while pointCur.y <= pointInt.y + 2 {
                while pointCur.x <= pointInt.x + 2 {
                    let pointPos: Point3D = .init(
                        .init(pointCur.x) + Noise.valueNoise3D(point: pointCur, seed: seed),
                        .init(pointCur.y) + Noise.valueNoise3D(point: pointCur, seed: seed + 1),
                        .init(pointCur.z) + Noise.valueNoise3D(point: pointCur, seed: seed + 2)
                    )
                    let dist = (pointPos - initialPoint).magnitude
                    if dist < minDist {
                        minDist = dist
                        pointCandidate = pointPos
                    }
                    
                    pointCur.x += 1
                }
                pointCur.y += 1
            }
            pointCur.z += 1
        }
        var value = 0.0
        if enableDistance {
            value = (pointCur - initialPoint).magnitude
        }
        return value + displacement * Noise.valueNoise3D(
            point: (pointCandidate |> mutEach { $0 = floor($0) }),
            seed: seed
        )
    }
}
