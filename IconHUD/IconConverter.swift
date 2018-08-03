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

    private struct PathInfo {
        let inAsset: String
        let inBuildDir: String
    }

    private struct ImageNameInfo {
        let inAsset: String
        let inBuildDir: String
    }

    private var contentsJSONPaths: [String] {
        let targetDir: String = ConsoleIO.optionArgument(option: .sourceDirName) ?? ConsoleIO.environmentVariable(key: .projectName)
        let path: String = ConsoleIO.environmentVariable(key: .projectRoot) + "/" + targetDir
        return FileManager.default
            .enumerator(atPath: path)?
            .compactMap { $0 as? String }
            .filter { $0.hasSuffix("appiconset") }
            .map { "\(path)/\($0)/Contents.json" }
            ?? []
    }

    private var currentDate: String {
        let cal: Calendar = .init(identifier: .gregorian)
        let c: DateComponents = cal.dateComponents([.year, .month, .day, .minute, .hour], from: Date())
        guard let hour = c.hour, let minute = c.minute, let month = c.month, let day = c.day, let year = c.year else { return "" }
        return String(format: "%02d:%02d %02d/%02d %04d", hour, minute, month, day, year)
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
        guard buildConfig != Constant.releaseBuildConfigName,
            buildConfig != Constant.debugBuildConfigName || !ignoreDebugBuild else {
                print("\(ConsoleIO.executableName) stopped because it is running for \(buildConfig) build.")
                return
        }
        let appIconSetContentsJSONPaths: [String] = contentsJSONPaths
        print(appIconSetContentsJSONPaths)
        guard !appIconSetContentsJSONPaths.isEmpty else {
            print("Error: Contents.json not found.")
            return
        }
        let iconImagePaths: [PathInfo] = imagePaths(jsonPaths: appIconSetContentsJSONPaths)
        for pathInfo in iconImagePaths {
            print("Copy \(pathInfo.inAsset) to \(pathInfo.inBuildDir).")
            copyAssetImageToBuildDirectory(pathInfo: pathInfo)
        }
        processImages(imagePaths: iconImagePaths)
    }

    private func imagePaths(jsonPaths: [String]) -> [PathInfo] {
        return jsonPaths
            .compactMap { imagePaths(jsonPath: $0) }
            .flatMap { $0 }
    }

    private func imagePaths(jsonPath: String) -> [PathInfo]? {
        print("Contents.json path -> \(jsonPath)")
        return (try? Data(contentsOf: URL(fileURLWithPath: jsonPath)))
            .flatMap { try? JSONSerialization.jsonObject(with: $0) }
            .flatMap { $0 as? [String: Any] }
            .map { analyzeJSONAndGetImageNames(jsonDict: $0) }?
            .map { PathInfo(inAsset: NSString(string: jsonPath).deletingLastPathComponent + "/" + $0.inAsset,
                            inBuildDir: ConsoleIO.environmentVariable(key: .configurationBuildDir) + "/" +
                                ConsoleIO.environmentVariable(key: .unlocalizedResourcesFolderPath) + "/" +
                                $0.inBuildDir) }
    }

    private func analyzeJSONAndGetImageNames(jsonDict: [String: Any]) -> [ImageNameInfo] {
        return (jsonDict["images"] as? [[String: String]])?
            .compactMap { dic in
                guard let filename = dic["filename"], let size = dic["size"], let scale = dic["scale"], let idiom = dic["idiom"] else { return nil }
                return ImageNameInfo(inAsset: filename, inBuildDir: convertImageName(size: size, scale: scale, idiom: idiom))
            } ?? []
    }

    private func convertImageName(size: String, scale: String, idiom: String) -> String {
        let scaleForFilename: String = scale == "1x" ? "" : "@\(scale)"
        let idiomForFilename: String = idiom == "ipad" ? "~\(idiom)" : ""
        return "AppIcon\(size)\(scaleForFilename)\(idiomForFilename).png"
    }

    /// Copy icon image manually. Otherwise, it modifies already modified icon file when build with cache.
    private func copyAssetImageToBuildDirectory(pathInfo: PathInfo) {
        let manager: FileManager = .default
        _ = try? manager.removeItem(atPath: pathInfo.inBuildDir)
        _ = try? manager.copyItem(atPath: pathInfo.inAsset, toPath: pathInfo.inBuildDir)
    }

    private func processImages(imagePaths: [PathInfo]) {
        let dateStr: String = currentDate
        let buildConfig: String = ConsoleIO.environmentVariable(key: .buildConfig)
        let caption: String = "\(AppInfo.versionNumber)(\(AppInfo.buildNumber)) \(buildConfig) \n\(AppInfo.branchName) \n\(AppInfo.commitId)"
        let topHUDHeight: Int = 20
        let bottomHUDHeight: Int = 48

        let paths: [String] = imagePaths.map { $0.inBuildDir }
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
}
