//
//  Image.swift
//  HoleFillAlgo
//
//  Created by Tomer Har Yofi on 12/08/2022.
//

import Foundation


enum PixelConnectivity: Int {
    case pixelConnectivityFour = 4
    case pixelConnectivityEight = 8
}

struct Image {
    static let UINT_MAX_FLOAT: Float =  255.0
    static let UINT_MAX: UInt8 =  255

    let pixelConnectivity: PixelConnectivity
    let z: Int
    let epsilon: Float
    var imagePreprocessedMatrix: [[Pixel]]
    var holePixels: Set<Pixel>
    var boundaryPixels: Set<Pixel>
    
    init(originalImagePath: String, maskImagePath: String, z: Int, epsilon: Float, pixelConnectivity: PixelConnectivity) {
        self.z = z
        self.epsilon = epsilon
        self.pixelConnectivity = pixelConnectivity
        self.imagePreprocessedMatrix = ImageHelper.createGrayImage(originalImagePath: originalImagePath, maskImagePath: maskImagePath)
        self.holePixels = ImageHelper.findHolePixels(pixels: imagePreprocessedMatrix)
        self.boundaryPixels = ImageHelper.findBoundaryPixels(imagePreprocessedMatrix: imagePreprocessedMatrix, holePixels: holePixels, pixelConnectivity: pixelConnectivity)
    }
    
    var width: Int {
        guard let firstPixelRow = imagePreprocessedMatrix.first else {
            return 0
        }
        return firstPixelRow.count
    }
    
    var height: Int {
        let numbersOfRows = self.width-1
        return numbersOfRows < 0 ? 0 : imagePreprocessedMatrix[numbersOfRows].count
    }
    
    var rgbaFlatArray: [RGBA] {
        var returnPixels = [RGBA]()
        for y in 0..<height {
            for x in 0..<width {
                let pixelColor = imagePreprocessedMatrix[y][x].value
                if pixelColor != -1 {
                    let newColor = UInt8(pixelColor * Image.UINT_MAX_FLOAT)
                    returnPixels.append(RGBA(a: Image.UINT_MAX, r: newColor, g: newColor, b: newColor))
                } else {
                    let newColor = UInt8(0 * Image.UINT_MAX_FLOAT)

                    returnPixels.append(RGBA(a: Image.UINT_MAX, r: newColor, g: newColor, b: newColor))
                }
            }
        }
        
        return returnPixels
    }
    
    mutating func setPixelValue(pixel:Pixel){
        self.imagePreprocessedMatrix[pixel.y][pixel.x] = pixel
    }
}
