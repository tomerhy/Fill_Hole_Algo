//
//  ImageHelper.swift
//  HoleFillAlgo
//
//  Created by Tomer Har Yofi on 12/08/2022.
//

import Foundation
import AppKit
import CoreGraphics

enum ImageHelperError: Error {
    case wrongPath
    case failToCreateCGImage
    case failToCreateContext
    case failToLoadImage
    case failToCreateNSImage
    case filesSizeNotMatch
}

struct RGBA {
    var a: UInt8
    var r: UInt8
    var g: UInt8
    var b: UInt8
}

extension NSImage {
    var pngData: Data? {
        guard let tiffRepresentation = tiffRepresentation, let bitmapImage = NSBitmapImageRep(data: tiffRepresentation) else { return nil }
        return bitmapImage.representation(using: .png, properties: [:])
    }
    
    func pngWrite(to url: URL, options: Data.WritingOptions = .atomic) -> Bool {
        do {
            try pngData?.write(to: url, options: options)
            return true
        } catch {
            print(error)
            return false
        }
    }
}

class ImageHelper {
    static let consoleIO = ConsoleIO()
    static let UINT_MAX_FLOAT: CGFloat =  255.0
    static let GRAY_THRESHOLD: Float = 0.5
    
    static func createGrayImage(originalImagePath: String, maskImagePath: String) -> [[Pixel]] {
        var imagePreprocessedMatrix: [[Pixel]] = [[Pixel]]()
        do {
            //load image maskImagePixelData
            guard let maskImagePixelData = try? ImageHelper.convertImageToGray(from: maskImagePath) else {
                throw ImageHelperError.failToLoadImage
            }
            let maskPixelMatrix = maskImagePixelData.0
            let maskImageWidth = Int(maskImagePixelData.1)
            let maskImageHeight = Int(maskImagePixelData.2)
            
            //load image originalImagePixelData
            guard let originalImagePixelData = try? ImageHelper.convertImageToGray(from: originalImagePath) else {
                throw ImageHelperError.failToLoadImage
            }
            let originalPixelMatrix = originalImagePixelData.0
            let originalImageWidth = Int(originalImagePixelData.1)
            let originalImageHeight = Int(originalImagePixelData.2)
            
            guard  maskImageWidth == originalImageWidth,
                   maskImageHeight == originalImageHeight else {
                throw ImageHelperError.filesSizeNotMatch
            }
            
            //combine both matrixes
            var value: Float = 0.0
            for y in 0..<maskImageHeight {
                var pixelArray = [Pixel]()
                for x in 0..<maskImageWidth {
                    
                    let color = maskPixelMatrix[y][x].value
                    if (color > GRAY_THRESHOLD) {
                        // if pixel (y,x) is not a 'hole pixel' convert its color to grayscale
                        value = originalPixelMatrix[y][x].value
                    } else {
                        value = -1;
                    }
                    pixelArray.append( Pixel(x: x, y: y, value: value))
                }
                imagePreprocessedMatrix.append(pixelArray)
            }
        } catch (err: ImageHelperError.failToLoadImage) {
            consoleIO.writeMessage("Unexpected error: failToLoadImage.")
        } catch (err: ImageHelperError.filesSizeNotMatch){
            consoleIO.writeMessage("Unexpected error: filesSizeNotMatch.")
        } catch {
            print(error)
        }
        
        return imagePreprocessedMatrix
    }
    
    static func rgbToGrayscale(RGBA: RGBA) -> CGFloat {
        let red = CGFloat(RGBA.r)
        let green = CGFloat(RGBA.g)
        let blue = CGFloat(RGBA.b)
        let avg = (red + green + blue) / 3;
        return avg / UINT_MAX_FLOAT;
    }
    
    static func savePNG(image: NSImage, path:String) {
        let pathUrl = URL(fileURLWithPath: path)
        let fileName = pathUrl.lastPathComponent
        let newFileNamePath = path.replacingOccurrences(of: fileName, with: "result.png")
        
        let imageRep = NSBitmapImageRep(data: image.tiffRepresentation!)
        let pngData = imageRep?.representation(using: .png, properties: [:])
        do {
            try pngData!.write(to: URL(fileURLWithPath: newFileNamePath))
        } catch {
            print(error)
        }
    }
    
    static func pixelsToImage(pixels: [RGBA], width: Int, height: Int) -> NSImage? {
        guard width > 0 && height > 0 else { return nil }
        guard pixels.count == width * height else { return nil }
        
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue)
        let bitsPerComponent = 8
        let bitsPerPixel = 32
        
        var data = pixels
        guard let providerRef = CGDataProvider(data: NSData(bytes: &data, length: data.count * MemoryLayout<RGBA>.size)) else {
            return nil
        }
        
        guard let cgImage = CGImage(
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bitsPerPixel: bitsPerPixel,
            bytesPerRow: width * MemoryLayout<RGBA>.size,
            space: rgbColorSpace,
            bitmapInfo: bitmapInfo,
            provider: providerRef,
            decode: nil,
            shouldInterpolate: true,
            intent: .defaultIntent
        ) else { return nil }
        
        return NSImage(cgImage: cgImage, size: CGSize(width: width, height: height))
    }

    static func convertImageToGray(from path: String) throws -> ([[Pixel]], Float, Float) {
        guard let image = NSImage(contentsOfFile: path) else {
            throw ImageHelperError.wrongPath
        }
        
        var imageMatrix: [[Pixel]] = [[Pixel]]()

        let pixelData = (image.cgImage(forProposedRect: nil, context: nil, hints: nil)!).dataProvider!.data
        let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)

        for y in 0..<Int(image.size.height) {
            var pixelArray = [Pixel]()
            for x in 0..<Int(image.size.width) {
    
                let pos = CGPoint(x: x, y: y)

                let pixelInfo: Int = ((Int(image.size.width) * Int(pos.y) * 4) + Int(pos.x) * 4)

                let r = data[pixelInfo]
                let g = data[pixelInfo + 1]
                let b = data[pixelInfo + 2]
                let a = data[pixelInfo + 3]
                let pixelRGBA = RGBA(a: a, r: r, g: g, b: b)
                let grayFloat = Float(rgbToGrayscale(RGBA: pixelRGBA))
           
                let pixel = Pixel(x: x, y: y, value: grayFloat)
                pixelArray.append(pixel)
            }
            imageMatrix.append(pixelArray)
        }
        
        return (imageMatrix, Float(image.size.width), Float(image.size.height))
    }
    
    static func fillHole(image: Image, z: Int, epsilon: Float) -> Image {
        var filledImage = image
        for holePixel in image.holePixels {
            let newColor = calculateColor(holePixel: holePixel, boundaryPixels: image.boundaryPixels, z: z, epsilon: epsilon)
            var pixel = image.imagePreprocessedMatrix[holePixel.y][holePixel.x]
            pixel.setValue(value: newColor)
            filledImage.setPixelValue(pixel: pixel)
        }
        return filledImage
    }
    
    static func saveResults(originalImagePath: String, image:Image) {
        
        //create new image
        guard let newImage = pixelsToImage(pixels: image.rgbaFlatArray, width: image.width, height: image.height) else {
            print("error")
            return
        }
        
        //save result
        savePNG(image: newImage, path: originalImagePath)
    }
   
    static func calculateColor(holePixel: Pixel, boundaryPixels:Set<Pixel>, z: Int, epsilon: Float) -> Float {
        var numerator: Float = 0.0;
        var denominator: Float = 0.0;

        for boundaryPixel in boundaryPixels {
            let weight = weight(u: holePixel, v: boundaryPixel, z: z, epsilon: epsilon);
            numerator += weight * boundaryPixel.getValue();
            denominator += weight;
        }

        return numerator / denominator;
    }
            
    static func findHolePixels(pixels: [[Pixel]]) -> Set<Pixel> {
        
        var groupH: Set<Pixel> = Set<Pixel>()
        for i in 1...pixels.count - 1 {
            for j in 1...pixels[0].count - 1 {
                if (pixels[i][j].getValue() == -1) {
                    groupH.insert(pixels[i][j])
                }
            }
        }
        return groupH;
    }
            
    static func weight(u: Pixel, v: Pixel, z: Int, epsilon: Float) -> Float {
        //(Point u, Point v) -> (float) (1 / (Math.pow(FillHoleCalc.euclideanDist(u, v), z) + e))
        return 1 / (powf(euclideanDistance(p1: u, p2: v), Float(z)) + epsilon)
    }
    
    static func euclideanDistance(p1: Pixel, p2: Pixel) -> Float {
        let xVal: Float = Float(p1.x - p2.x)
        let yVal: Float = Float(p1.y - p2.y)
        return sqrtf(xVal * xVal + yVal * yVal)
    }
    
    static func findBoundaryPixels(imagePreprocessedMatrix: [[Pixel]], holePixels: Set<Pixel>, pixelConnectivity: PixelConnectivity) -> Set<Pixel> {
        var boundary = Set<Pixel>()
        
        for holePixel in holePixels {
            let x = holePixel.x
            let y = holePixel.y
            
            for i in -1...1 {
                for j in -1...1 {
                    if (pixelConnectivity == .pixelConnectivityFour && abs(i) + abs(j) == 2) {
                        continue
                    }
                    if (!isHole(pixel: imagePreprocessedMatrix[y + i][x + j])){
                        boundary.insert(imagePreprocessedMatrix[y + i][x + j])
                    }
                }
            }
        }
        return boundary
    }
    
    static func isHole(pixel: Pixel) -> Bool {
        return pixel.getValue() == -1;
    }    
}
