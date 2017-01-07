
import Foundation

public extension Double {

    public static func random(min: Double, max: Double) -> Double {
        let random = Double(arc4random(UInt64.self)) / Double(UInt64.max)
        return (random * (max - min)) + min
    }

}

