//
//  Created by Carson Rau on 5/5/22.
//

import NovaCore

internal let squareDouble = 2 |> flip(curry(Double.pow))

internal func cubicInterp(
    _ n0: Double, _ n1: Double, _ n2: Double, _ n3: Double, _ a: Double
) -> Double {
    let p = (n3 - n2) - (n0 - n1)
    let q = n0 - n1 - p
    let r = n2 - n0
    return p * Double.pow(a, 3) + q * Double.pow(a, 2) + r * a + n1
}

internal func linearInterp(_ n0: Double, _ n1: Double, _ a: Double) -> Double {
    (1.0 - a) * n0 + (a * n1)
}

internal func sCurve3(_ a: Double) -> Double {
    Double.pow(a, 2) * (3.0 - 2.0 * a)
}

internal func sCurve5(_ a: Double) -> Double {
    let a3 = Double.pow(a, 3)
    let a4 = a3 * a
    let a5 = a4 * a
    return (6.0 * a5) - (15.0 * a4) + (10.0 * a3)
}

internal func toCartesian(lat: Double, lon: Double) -> Point3D {
    let r = Double.cos(lat.degreesToRadian)
    let x = r * Double.cos(lon.degreesToRadian)
    let y = Double.sin(lat.degreesToRadian)
    let z = r * Double.sin(lon.degreesToRadian)
    return .init(x, y, z)
}

internal func clampTo32Bits(_ n: Double) -> Double {
    let boundary: Double = 0b1000000000000000000000000000000
    if n >= boundary {
        return (2.0 * n % boundary) - boundary
    } else if n <= -boundary {
        return (2.0 * n % boundary) + boundary
    } else {
        return n
    }
}

internal extension Point3D {
    func clamped() -> Point3D {
        .init(clampTo32Bits(x), clampTo32Bits(y), clampTo32Bits(z))
    }
    mutating func clamp() {
        self = clamped()
    }
}
