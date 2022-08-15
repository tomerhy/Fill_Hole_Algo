//
//  Cli.swift
//  HoleFillAlgo
//
//  Created by Tomer Har Yofi on 12/08/2022.
//

import Foundation


enum CliError: Error {
    case InvalidPixelConnectivity
    case ParsingError
}

class Cli {
    
    let consoleIO = ConsoleIO()
    var pixelConnectivity: Int?
    var epsilon: Float?
    var z: Int?
    var originalImagePath: String?
    var maskImagePath: String?
    
    func parsingArguments(arguments: [String]) throws {
        do {
            // parsing arguments
            self.pixelConnectivity = Int(arguments[5])
            self.epsilon = Float(arguments[4])
            self.z = Int(arguments[3])
            self.originalImagePath = arguments[1]
            self.maskImagePath = arguments[2]
            
            if (self.pixelConnectivity != 4 && self.pixelConnectivity != 8) {
                throw CliError.InvalidPixelConnectivity
            }
            
            guard let originalImagePath = self.originalImagePath,
                    let maskImagePath = self.maskImagePath,
                    let z = self.z,
                    let epsilon = self.epsilon else {
                throw CliError.ParsingError
            }
            
            let image = Image(originalImagePath: originalImagePath,
                              maskImagePath: maskImagePath,
                              z: z,
                              epsilon: epsilon,
                              pixelConnectivity: getPixelConnectivity())
            
            let filledImage = ImageHelper.fillHole(image: image, z: z, epsilon: epsilon)
            ImageHelper.saveResults(originalImagePath: originalImagePath, image:filledImage)
            
        } catch (err: CliError.InvalidPixelConnectivity) {
            consoleIO.writeMessage("Invalid connectivity type")
        } catch (err: CliError.ParsingError) {
            printUsage()
        }catch {
            consoleIO.writeMessage("Unexpected error: \(error).")
        }
    }
    
    func getPixelConnectivity() -> PixelConnectivity {
        var returnValue: PixelConnectivity = .pixelConnectivityFour
        switch (self.pixelConnectivity){
        case 4:
            returnValue = .pixelConnectivityFour
            break
        case 8:
            returnValue = .pixelConnectivityEight
            break
        default:
            returnValue = .pixelConnectivityFour
        }
        return returnValue
    }
    
    func printUsage() {
        consoleIO.printUsage()
    }
}
