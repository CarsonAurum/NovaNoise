//
//  Created by Carson Rau on 5/5/22.
//

import NovaCore
import Darwin

internal func cubicInterp(_ n0: Double, _ n1: Double, _ n2: Double, _ n3: Double, _ a: Double) -> Double {
    let p = (n3 - n2) - (n0 - n1)
    let q = n0 - n1 - p
    let r = n2 - n0
    return p * a * a * a + q * a * a + r * a + n1
}

internal func linearInterp(_ n0: Double, _ n1: Double, _ a: Double) -> Double {
    (1.0 - a) * n0 + (a * n1)
}

internal func sCurve3(_ a: Double) -> Double {
    (a * a * (3.0 - 2.0 * a))
}

internal func sCurve5(_ a: Double) -> Double {
    let a3 = a * a * a
    let a4 = a3 * a
    let a5 = a4 * a
    return (6.0 * a5) - (15.0 * a4) + (10.0 * a3)
}

internal func toCartesian(lat: Double, lon: Double) -> (Double, Double, Double) {
    let r = cos(lat.degreesToRadian)
    let x = r * cos(lon.degreesToRadian)
    let y = sin(lat.degreesToRadian)
    let z = r * sin(lon.degreesToRadian)
    return (x, y, z)
}

internal func clampTo32Bits(_ n: Double) -> Double {
    if n >= 1073741824.0 {
        return (2.0 * n % 1073741824.0) - 1073741824.0
    } else if n <= -1073741824.0 {
        return (2.0 * n % 1073741824.0) + 1073741824.0
    } else {
        return n
    }
}
