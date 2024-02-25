import CryptoKit
import PackagePlugin
import Foundation

extension PluginContextProtocol {
    func calculateChecksum(for file: Path) throws -> String {
        let data = try Data(contentsOf: URL(fileURLWithPath: file.string))
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02hhx", $0) }.joined()
    }

    func shouldExecutePlugin(for file: File) throws -> Bool {
        let markerPath = outputDirectory.appending("last_checksum")
        let newChecksum = try calculateChecksum(for: file.path)

        if let oldChecksum = try? String(contentsOf: URL(fileURLWithPath: markerPath.string)) {
            return newChecksum != oldChecksum
        }

        // If there's no old checksum, plugin should execute
        return true
    }

    func updateChecksum(for file: File) throws {
        let checksum = try calculateChecksum(for: file.path)
        let markerPath = outputDirectory.appending("last_checksum")
        try checksum.write(to: URL(fileURLWithPath: markerPath.string), atomically: true, encoding: .utf8)
    }
}
