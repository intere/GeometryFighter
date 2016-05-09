//
//  ShapeType.swift
//  GeometryFighter
//
//  Created by Eric Internicola on 5/8/16.
//  Copyright © 2016 Eric Internicola. All rights reserved.
//

import Foundation

enum ShapeType: Int {
    case Box = 0
    case Sphere
    case Pyramid
    case Torus
    case Capsule
    case Cylider
    case Cone
    case Tube

    static func random() -> ShapeType {
        let maxValue = Tube.rawValue
        let rand = arc4random_uniform(UInt32(maxValue+1))
        return ShapeType(rawValue: Int(rand))!
    }
}
