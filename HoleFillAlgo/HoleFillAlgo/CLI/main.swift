//
//  main.swift
//  HoleFillAlgo
//
//  Created by Tomer Har Yofi on 08/08/2022.
//

import Foundation

let cli = Cli()
if (CommandLine.argc > 1) {
    try cli.parsingArguments(arguments: CommandLine.arguments)
} else {
    cli.printUsage()
}

