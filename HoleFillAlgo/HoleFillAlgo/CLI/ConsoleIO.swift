//
//  ConsoleIO.swift
//  HoleFillAlgo
//
//  Created by Tomer Har Yofi on 12/08/2022.
//

import Foundation

enum OutputType {
    case error
    case standard
}

class ConsoleIO {
    func writeMessage(_ message: String, to: OutputType = .standard) {
        switch to {
        case .standard:
            print("\u{001B}[;m\(message)")
        case .error:
            fputs("\u{001B}[0;31m\(message)\n", stderr)
        }
    }
    
    func printUsage() {
        let executableName = (CommandLine.arguments[0] as NSString).lastPathComponent
        writeMessage("usage:")
        writeMessage("\(executableName) [image path] [mask path] [z] [epsilon] [pixel connectivity: 4/8]")
    }
}
