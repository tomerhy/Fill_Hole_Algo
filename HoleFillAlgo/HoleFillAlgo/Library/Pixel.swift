//
//  Pixel.swift
//  HoleFillAlgo
//
//  Created by Tomer Har Yofi on 12/08/2022.
//

import Foundation

struct Pixel {
    let x: Int
    let y: Int
    var value: Float
    var proxy: String { return "\(x) \(y)" }
    
    init(x: Int, y: Int, value: Float) {
        self.x = x
        self.y = y
        self.value = value
    }

    func getValue() -> Float{
        return value;
    }
    
    mutating func setValue(value: Float) {
        self.value = value
    }
}

extension Pixel: Hashable, Equatable {
    static func == (lhs: Pixel, rhs: Pixel) -> Bool {
        return lhs.proxy == rhs.proxy
    }
}
