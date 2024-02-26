import Foundation
import PackagePlugin

protocol PluginContextProtocol {
    var pluginWorkDirectory: PackagePlugin.Path { get }
    var packageID: String { get }
    func tool(named name: String) throws -> PluginContext.Tool
}

extension PluginContext: PluginContextProtocol {
    var packageID: String { `package`.id }
}

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin
extension XcodePluginContext: PluginContextProtocol {
    var packageID: String { return xcodeProject.id }
}
#endif

extension Command {
    static func xcstringstool(for file: File, using context: PluginContextProtocol) throws -> Command? {
        print("XCStringsTool: Starting at \(context.outputPath(for: file).string)")

        print("XCStringsTool: xcodeProject.id \((context as? XcodePluginContext)?.xcodeProject.id)")
        print("XCStringsTool: XcodePluginContext at \((context as? XcodePluginContext))")
        print("XCStringsTool: PluginContext at \((context as? PluginContext)?.package.targets.first?.name)")

        guard try context.shouldExecutePlugin(for: file) else {
            // Skip execution if the input hasn't changed
            print("XCStringsTool: Skipping generation for ‘\(file.path.lastComponent)‘, no changes detected.")
            return .noopCommand(registeringOutputDirectory: context.outputPath(for: file).removingLastComponent())
        }

        try? FileManager().createDirectory(atPath: context.outputDirectory.string, withIntermediateDirectories: true)

        // Proceed with command execution
        let command = Command.buildCommand(
            displayName: "XCStringsTool: Generate Swift code for ‘\(file.path.lastComponent)‘",
            executable: try context.tool(named: "xcstrings-tool").path,
            arguments: [
                file.path.string,
                context.outputPath(for: file).string
            ],
            inputFiles: [
                file.path
            ],
            outputFiles: [
                context.outputPath(for: file)
            ]
        )

        // Update the checksum after successful command creation
        try context.updateChecksum(for: file)

        return command
    }
}

extension Command {
    static func noopCommand(registeringOutputDirectory outputDir: Path) -> Command {
        Command.prebuildCommand(
            displayName: "No-Op Command",
            executable: .init("/bin/echo"),
            arguments: ["No operation" + outputDir.string],
            outputFilesDirectory: outputDir
        )
    }
}

extension PluginContextProtocol {
    var outputDirectory: Path {
        pluginWorkDirectory.appending(subpath: "XCStringsTool").appending(subpath: packageID)
    }

    func outputPath(for file: File) -> Path {
        outputDirectory.appending("\(file.path.stem).swift")
    }
}

