import CryptoKit
import PackagePlugin
import Foundation

extension PluginContextProtocol {
    func ensureDirectoryExists(_ path: Path) throws {
        let fileManager = FileManager.default
        let directoryPath = URL(fileURLWithPath: path.string)
        if !fileManager.fileExists(atPath: directoryPath.path) {
            try fileManager.createDirectory(at: directoryPath, withIntermediateDirectories: true, attributes: nil)
        }
    }

    func calculateChecksum(for file: Path) throws -> String {
        let data = try Data(contentsOf: URL(fileURLWithPath: file.string))
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02hhx", $0) }.joined()
    }

    func shouldExecutePlugin(for file: File) throws -> Bool {
        try ensureDirectoryExists(outputDirectory) // Ensure the directory for the marker exists

        let markerPath = outputDirectory.appending("last_checksum")
        if let oldChecksum = try? String(contentsOf: URL(fileURLWithPath: markerPath.string)) {
            let newChecksum = try calculateChecksum(for: file.path)
            return newChecksum != oldChecksum
        }

        // If there's no old checksum, plugin should execute
        return true
    }

    func updateChecksum(for file: File) throws {
        try ensureDirectoryExists(outputDirectory) // Ensure the directory for the marker exists before writing

        let newChecksum = try calculateChecksum(for: file.path)
        let markerPath = outputDirectory.appending("last_checksum")
        try newChecksum.write(to: URL(fileURLWithPath: markerPath.string), atomically: true, encoding: .utf8)
    }
}
