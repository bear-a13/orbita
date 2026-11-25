import Foundation

/// Link que o widget abre e o app entende: gravita://planeta/<id>
nonisolated enum LinkDoPlaneta {
    private static let esquema = "gravita"
    private static let host = "planeta"

    static func url(para id: UUID) -> URL {
        URL(string: "\(esquema)://\(host)/\(id.uuidString)")!
    }

    static func id(em url: URL) -> UUID? {
        guard url.scheme == esquema, url.host() == host else { return nil }
        return UUID(uuidString: url.lastPathComponent)
    }
}
