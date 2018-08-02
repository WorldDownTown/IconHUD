//
//  IconConverter.swift
//  Summaricon
//
//  Created by tueno on 2017/04/24.
//  Copyright © 2017年 tueno Ueno. All rights reserved.
//

import Foundation

struct IconConverter {
    static let version = "1.0"

    private struct Constant {
        static let releaseBuildConfigName: String = "Release"
        static let debugBuildConfigName: String = "Debug"
    }

    func staticMode() {
        let arguments: [OptionType] = ConsoleIO.optionsInCommandLineArguments
        if arguments.contains(.help) {
            ConsoleIO.printUsage()
        } else if arguments.contains(.version) {
            ConsoleIO.printVersion()
        } else {
            modifyIcon(ignoreDebugBuild: arguments.contains(.ignoreDebugBuild))
        }
    }

    private func modifyIcon(ignoreDebugBuild: Bool) {
        ConsoleIO.printNotice()
        let buildConfig: String = ConsoleIO.environmentVariable(key: .buildConfig)
        guard buildConfig != Constant.releaseBuildConfigName && (buildConfig != Constant.debugBuildConfigName || !ignoreDebugBuild) else {
            print("\(ConsoleIO.executableName) stopped because it is running for \(buildConfig) build.")
            return
        }
        let appIconSetContentsJsonPaths: [String] = contentsJsonPath
        guard !appIconSetContentsJsonPaths.isEmpty else {
            print("Error: Contents.json not found.")
            return
        }
        let iconImagePaths: [(String, String)] = imagePaths(contentJsonPaths: appIconSetContentsJsonPaths)
        for (pathInAsset, pathInBuildDir) in iconImagePaths {
            print("Copy \(pathInAsset) to \(pathInBuildDir).")
            copyAssetImageToBuildDirectory(pathInAsset: pathInAsset,
                                           pathInBuildDir: pathInBuildDir)
        }
        processImages(imagePaths: iconImagePaths)
    }

    private var contentsJsonPath: [String] {
        let targetDir: String = ConsoleIO.optionArgument(option: .sourceDirName) ?? ConsoleIO.environmentVariable(key: .projectName)
        let path: String = ConsoleIO.environmentVariable(key: .projectRoot) + "/" + targetDir
        return FileManager.default
            .enumerator(atPath: path)?
            .compactMap { $0 as? String }
            .filter { $0.hasSuffix("appiconset") }
            .map { "\(path)/\($0)/Contents.json" }
            ?? []
    }

    private func imagePaths(contentJsonPaths: [String]) -> [(pathInAsset: String, pathInBuildDir: String)] {
        return contentJsonPaths
            .compactMap { (contentJsonPath: String) -> [(pathInAsset: String, pathInBuildDir: String)]? in
                print("Contents.json path -> \(contentJsonPath)")

                return (try? Data(contentsOf: URL(fileURLWithPath: contentJsonPath)))
                    .flatMap { try? JSONSerialization.jsonObject(with: $0) }
                    .flatMap { $0 as? [String: Any] }
                    .map { analyzeJsonAndGetImageNames(jsonDict: $0) }?
                    .map { (pathInAsset: NSString(string: contentJsonPath).deletingLastPathComponent + "/" + $0.imageNameInAsset,
                            pathInBuildDir: ConsoleIO.environmentVariable(key: .configurationBuildDir) + "/" +
                                ConsoleIO.environmentVariable(key: .unlocalizedResourcesFolderPath) + "/" +
                                $0.imageNameInBuildDir) }
            }
            .flatMap { $0 }
    }

    private func processImages(imagePaths: [(pathInAsset: String, pathInBuildDir: String)]) {
        let dateStr: String = currentDate
        let buildConfig: String = ConsoleIO.environmentVariable(key: .buildConfig)
        let caption: String = "\(AppInfo.versionNumber)(\(AppInfo.buildNumber)) \(buildConfig) \n\(AppInfo.branchName) \n\(AppInfo.commitId)"
        let topHUDHeight: Int = 20
        let bottomHUDHeight: Int = 48

        let paths: [String] = imagePaths.map { $0.pathInBuildDir }
        for path in paths {
            let imageWidthStr: String = bash(command: "identify",
                                             currentDirectoryPath: nil,
                                             arguments: ["-format", "%w", path])
            let hudWidth: Int = Int(imageWidthStr) ?? 0
            _ = bash(command: "convert",
                     currentDirectoryPath: nil,
                     arguments: ["-background", "#0008",
                                 "-fill", "white",
                                 "-gravity", "center",
                                 "-size", "\(hudWidth)x\(topHUDHeight)",
                                 "caption:\(dateStr)",
                                 path,
                                 "+swap",
                                 "-gravity", "north",
                                 "-composite", path])
            _ = bash(command: "convert",
                     currentDirectoryPath: nil,
                     arguments: ["-background", "#0008",
                                 "-fill", "white",
                                 "-gravity", "center",
                                 "-size", "\(hudWidth)x\(bottomHUDHeight)",
                                 "caption:\(caption)",
                                 path,
                                 "+swap",
                                 "-gravity", "south",
                                 "-composite", path])
        }
    }

    private var currentDate: String {
        let cal: Calendar = .init(identifier: .gregorian)
        let c: DateComponents = cal.dateComponents([.year, .month, .day, .minute, .hour], from: Date())
        guard let hour = c.hour, let minute = c.minute, let month = c.month, let day = c.day, let year = c.year else { return "" }
        return String(format: "%02d:%02d %02d/%02d %04d", hour, minute, month, day, year)
    }

    private func analyzeJsonAndGetImageNames(jsonDict: [String: Any]) -> [(imageNameInAsset: String, imageNameInBuildDir: String)] {
        return (jsonDict["images"] as? [[String: String]])?
            .compactMap { dic in
                guard let filename = dic["filename"], let size = dic["size"], let scale = dic["scale"], let idiom = dic["idiom"] else { return nil }
                return (imageNameInAsset: filename, imageNameInBuildDir: convertImageName(size: size, scale: scale, idiom: idiom))
            } ?? []
    }

    private func convertImageName(size: String, scale: String, idiom: String) -> String {
        let scaleForFilename: String = scale == "1x" ? "" : "@\(scale)"
        let idiomForFilename: String = idiom == "ipad" ? "~\(idiom)" : ""
        return "AppIcon\(size)\(scaleForFilename)\(idiomForFilename).png"
    }

    /// Copy icon image manually. Otherwise, it modifies already modified icon file when build with cache.
    private func copyAssetImageToBuildDirectory(pathInAsset: String, pathInBuildDir: String) {
        let manager: FileManager = .default
        _ = try? manager.removeItem(atPath: pathInBuildDir)
        _ = try? manager.copyItem(atPath: pathInAsset, toPath: pathInBuildDir)
    }
}
