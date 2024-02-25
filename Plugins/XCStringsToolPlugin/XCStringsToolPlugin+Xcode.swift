#if canImport(XcodeProjectPlugin)
import PackagePlugin
import XcodeProjectPlugin

extension XCStringsToolPlugin: XcodeBuildToolPlugin {
    func createBuildCommands(
        context: XcodePluginContext,
        target: XcodeTarget
    ) throws -> [Command] {
        try target.inputFiles
            .filter { $0.path.extension == "xcstrings" }
            .compactMap { try .xcstringstool(for: $0, using: context) }
    }
}
#endif
