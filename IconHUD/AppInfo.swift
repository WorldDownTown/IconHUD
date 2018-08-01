//
//  AppInfo.swift
//  Summaricon
//
//  Created by tueno on 2017/04/25.
//  Copyright © 2017年 Tomonori Ueno. All rights reserved.
//

struct AppInfo {
    static var branchName: String {
        let branchName: String = bash(command: "git",
                                      currentDirectoryPath: ConsoleIO.environmentVariable(key: .projectRoot),
                                      arguments: ["rev-parse", "--abbrev-ref", "HEAD"])
        if branchName == "HEAD" {
            // On Travis CI
            return ConsoleIO.environmentVariable(key: .branchNameOnTravisCI)
        } else {
            return branchName
        }
    }

    static var commitId: String {
        return bash(command: "git",
                    currentDirectoryPath: ConsoleIO.environmentVariable(key: .projectRoot),
                    arguments: ["rev-parse", "--short", "HEAD"])
    }

    static var buildNumber: String {
        let infoPlist: String = ConsoleIO.environmentVariable(key: .infoPlist)
        return bash(command: "/usr/libexec/PlistBuddy",
                    currentDirectoryPath: ConsoleIO.environmentVariable(key: .projectRoot),
                    arguments: ["-c", "Print CFBundleVersion", infoPlist])
    }

    static var versionNumber: String {
        let infoPlist: String = ConsoleIO.environmentVariable(key: .infoPlist)
        return bash(command: "/usr/libexec/PlistBuddy",
                    currentDirectoryPath: ConsoleIO.environmentVariable(key: .projectRoot),
                    arguments: ["-c", "Print CFBundleShortVersionString", infoPlist])
    }
}
