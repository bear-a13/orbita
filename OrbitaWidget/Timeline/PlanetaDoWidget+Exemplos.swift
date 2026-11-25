import Foundation

extension PlanetaDoWidget {
    static let exemplos: [PlanetaDoWidget] = [
        exemplo("Entregar projeto", .grande, .jupiter),
        exemplo("Estudar cálculo", .grande, .saturno),
        exemplo("Passear com o cão", .media, .terra),
        exemplo("Pagar o boleto", .media, .marte),
        exemplo("Enviar relatório", .pequena, .lua),
    ]

    private static func exemplo(_ titulo: String, _ prioridade: Prioridade,
                                _ aparencia: AparenciaPlaneta) -> PlanetaDoWidget {
        PlanetaDoWidget(id: UUID(), titulo: titulo, prioridade: prioridade, aparencia: aparencia)
    }
}
