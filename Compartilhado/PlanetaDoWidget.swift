import Foundation

/// Uma atividade reduzida ao que o widget precisa desenhar.
/// Tamanho e cor não são guardados: vêm de `aparencia`, a mesma usada no app.
nonisolated struct PlanetaDoWidget: Codable, Identifiable, Hashable {
    let id: UUID
    let titulo: String
    let prioridade: Prioridade
    let aparencia: AparenciaPlaneta
}
