import Foundation

/// Ponte entre o app e o widget: o app grava uma foto do universo
/// no UserDefaults do App Group e o widget lê.
nonisolated enum SnapshotDoUniverso {
    static let idDoGrupo = "group.com.bear.orbita"

    private static let chave = "universo.planetas"

    /// Devolve `false` quando nada mudou, para o app não recarregar o widget à toa.
    @discardableResult
    static func gravar(_ planetas: [PlanetaDoWidget]) -> Bool {
        guard let defaults = UserDefaults(suiteName: idDoGrupo),
              let dados = try? JSONEncoder().encode(planetas) else { return false }
        // sem nada gravado ainda, grava mesmo que a lista seja vazia
        if defaults.data(forKey: chave) != nil, ler() == planetas { return false }
        defaults.set(dados, forKey: chave)
        return true
    }

    static func ler() -> [PlanetaDoWidget] {
        guard let defaults = UserDefaults(suiteName: idDoGrupo),
              let dados = defaults.data(forKey: chave),
              let planetas = try? JSONDecoder().decode([PlanetaDoWidget].self, from: dados)
        else { return [] }
        return planetas
    }
}
