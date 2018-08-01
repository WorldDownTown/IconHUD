//
//  Functions.swift
//  Summaricon
//
//  Created by tueno on 2017/04/25.
//  Copyright © 2017年 Tomonori Ueno. All rights reserved.
//

import Foundation

private func shell(launchPath: String, currentDirectoryPath: String?, arguments: [String]) -> String {
    let process: Process = .init()
    process.launchPath = launchPath
    if let currentDirectoryPath = currentDirectoryPath {
        process.currentDirectoryPath = currentDirectoryPath
    }
    process.arguments = arguments
    let pipe: Pipe = .init()
    process.standardOutput = pipe
    process.launch()
    let data: Data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output: String? = String(data: data, encoding: .utf8)
    return output?.replacingOccurrences(of: "\n", with: "") ?? ""
}

func bash(command: String, currentDirectoryPath: String?, arguments: [String]) -> String {
    let whichPathForCommand: String = shell(launchPath: "/bin/bash",
                                            currentDirectoryPath: nil,
                                            arguments: ["-l", "-c", "which \(command)"])
    return shell(launchPath: whichPathForCommand,
                 currentDirectoryPath: currentDirectoryPath,
                 arguments: arguments)
}
