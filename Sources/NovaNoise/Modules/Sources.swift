//
//  Created by Carson Rau on 5/7/22.
//

import NovaCore
#if canImport(Foundation)
import func Foundation.floor
#endif

// MARK: - Billow
public final class Billow: Module {
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
    public var persistence = Defaults.persistence
    public var seed = Defaults.seed
    public private(set) var octaveCount = Defaults.octaveCount
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
        var z1 = z * frequency, y1 = y * frequency, x1 = x * frequency, seed = 0
        var value = 0.0, signal = 0.0, curPersistence = 1.0
        var nx = 0.0, ny = 0.0, nz = 0.0
        
        (0..<octaveCount).forEach {
            nx = clampTo32Bits(x1)
            ny = clampTo32Bits(y1)
            nz = clampTo32Bits(z1)
            
            seed = self.seed + $0
            signal = Noise.gradientCoherentNoise3D(nx, ny, nz, seed: seed, quality: quality)
            signal = 2.0 * abs(signal) - 1.0
            value += signal * curPersistence
            
            x1 *= lacunarity
            y1 *= lacunarity
            z1 *= lacunarity
            
            curPersistence *= persistence
        }
        value += 0.5
        return value
    }
}

// MARK: - Checkerboard
public final class Checkerboard: Module {
    public static var moduleCount: Int = 0
    public init() {
        super.init(sourceCount: 0)
    }
    public func getValue(x: Double, y: Double, z: Double) throws -> Double {
        let ix = x |> clampTo32Bits >>> floor >>> Int.init
        let iy = y |> clampTo32Bits >>> floor >>> Int.init
        let iz = z |> clampTo32Bits >>> floor >>> Int.init
        return (ix & 1 ^ iy & 1 ^ iz & 1) != 0 ? -1.0: 1.0
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
        let z1 = z * frequency, x1 = x * frequency
        
        let centerDist = Double.sqrt(Double.pow(x1, 2) + Double.pow(z1, 2))
        let smallerDist = centerDist - floor(centerDist)
        let largerDist = 1.0 - smallerDist
        let nearestDist = min(smallerDist, largerDist)
        return 1.0 - (nearestDist * 4.0)
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
        var x1 = x * frequency, y1 = y * frequency, z1 = z * frequency,
            value = 0.0, curPersistence = 1.0
        var signal, nx, ny, nz: Double
        var seed: Int
        
        for curOctave in 0 ..< octaveCount {
            nx = clampTo32Bits(x1)
            ny = clampTo32Bits(y1)
            nz = clampTo32Bits(z1)
            seed = self.seed + curOctave
            signal = Noise.gradientCoherentNoise3D(nx, ny, nz, seed: seed, quality: quality)
            value += signal * curPersistence
            x1 *= lacunarity
            y1 *= lacunarity
            z1 *= lacunarity
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
        var x1 = x * frequency, y1 = y * frequency, z1 = z * frequency
        var signal = 0.0, value = 0.0, weight = 1.0, offset = 1.0, gain = 2.0
        (0 ..< octaveCount).forEach {
            let nx = clampTo32Bits(x1), ny = clampTo32Bits(y1), nz = clampTo32Bits(z1)
            let seed = (self.seed + $0) & 0x7FFFFFFF
            signal = Noise.gradientCoherentNoise3D(nx, ny, nz, seed: seed, quality: quality)
            signal = abs(signal)
            signal = offset - signal
            Double.pow(signal, 2)
            signal *= weight
            weight = signal * gain
            weight = weight.clamped(to: 0.0 ... 1.0)
            value += signal * weights[$0]
            
            x1 *= lacunarity
            y1 *= lacunarity
            z1 *= lacunarity
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
        let x1 = x * frequency, y1 = y * frequency, z1 = z * frequency
        let centerDist = Double.sqrt(Double.pow(x1, 2) + Double.pow(y1, 2) + Double.pow(z1, 2))
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
        let x1 = x * frequency, y1 = y * frequency, z1 = z * frequency
        let xInt = x1 > 0.0 ? Int(x1) : Int(x1 - 1)
        let yInt = y1 > 0.0 ? Int(y1) : Int(y1 - 1)
        let zInt = z1 > 0.0 ? Int(z1) : Int(z1 - 1)
        var minDist = 2147483647.0
        var xCandidate = 0.0, yCandidate = 0.0, zCandidate = 0.0
        var zCur = zInt - 2, yCur = yInt - 2, xCur = xInt - 2
        while zCur <= zInt + 2 {
            while yCur <= yInt + 2 {
                while xCur <= xInt + 2 {
                    let xPos = .init(xCur) + Noise.valueNoise3D(xCur, yCur, zCur, seed: seed)
                    let yPos = .init(yCur) + Noise.valueNoise3D(xCur, yCur, zCur, seed: seed + 1)
                    let zPos = .init(zCur) + Noise.valueNoise3D(xCur, yCur, zCur, seed: seed + 2)
                    
                    let xDist = xPos - x1, yDist = yPos - y1, zDist = zPos - z1
                    let dist = Double.pow(xDist, 2) + Double.pow(yDist, 2) + Double.pow(zDist, 2)
                    if dist < minDist {
                        minDist = dist
                        xCandidate = xPos
                        yCandidate = yPos
                        zCandidate = zPos
                    }
                    
                    xCur += 1
                }
                yCur += 1
            }
            zCur += 1
        }
        var value = 0.0
        if enableDistance {
            let xDist = xCandidate - x1, yDist = yCandidate - y1, zDist = zCandidate - z1
            value = Double.sqrt(Double.pow(xDist, 2) + Double.pow(yDist, 2) + Double.pow(zDist, 2))
        }
        return value + (displacement * Noise.valueNoise3D(
            .init(floor(xCandidate)), .
            init(floor(yCandidate)),
            .init(floor(zCandidate)),
            seed: seed
        ))
    }
}
