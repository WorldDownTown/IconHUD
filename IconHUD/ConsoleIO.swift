//
//  ConsoleIO.swift
//  Summaricon
//
//  Created by tueno on 2017/04/24.
//  Copyright © 2017年 tueno Ueno. All rights reserved.
//

import Foundation

struct ConsoleIO {
    // MARK: Input

    static var optionsInCommandLineArguments: [OptionType] {
        return OptionType.allValues
            .filter { option in option.values.contains(where: { CommandLine.arguments.contains($0) }) }
    }

    static func optionArgument(option: OptionType) -> String? {
        let arguments: [String] = CommandLine.arguments
        let index: Int? = arguments
            .enumerated()
            .first(where: { option.values.contains($0.element) })
            .map { $0.offset + 1 }
        guard let i = index, i < arguments.count, !arguments[i].hasPrefix("-") else {
            return nil
        }
        return arguments[i]
    }

    static func environmentVariable(key: EnvironmentVariable) -> String {
        return ProcessInfo().environment[key.rawValue] ?? ""
    }

    static var executableName: String {
        return CommandLine.arguments
            .first?
            .components(separatedBy: "/")
            .last ?? ""
    }

    // MARK: Output

    static func printVersion() {
        print(IconConverter.version)
    }

    static func printUsage() {
        print("""
        Usage:

             Add the line below to RunScript phase of your Xcode project.

             \(executableName)

        Options:

        \(OptionType.allValues.map { "     [\($0.valuesToPrint)]\($0.usage)" }.joined(separator: "\n"))
        """)
    }

    static func printNotice() {
        print("""

        *** IMPORTANT ***
        \(executableName) currently uses BuildConfig name to detect Relase build.
        So if you change Release BuildConfig name, \(executableName) will process icon even if you want to build for release.

        """)
    }
}
