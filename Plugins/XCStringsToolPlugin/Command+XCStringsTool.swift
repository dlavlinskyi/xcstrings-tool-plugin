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
        guard try context.shouldExecutePlugin(for: file) else {
            // Skip execution if the input hasn't changed
            print("XCStringsTool: Skipping generation for ‘\(file.path.lastComponent)‘, no changes detected.")
            return nil
        }

        try FileManager().createDirectory(atPath: context.outputDirectory.string, withIntermediateDirectories: true)

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

extension PluginContextProtocol {
    var outputDirectory: Path {
        pluginWorkDirectory.appending(subpath: "XCStringsTool").appending(subpath: packageID)
    }

    func outputPath(for file: File) -> Path {
        outputDirectory.appending("\(file.path.stem).swift")
    }
}

