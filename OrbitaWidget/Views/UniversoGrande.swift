import SwiftUI

/// Grade com até 6 planetas: cada um no centro da própria célula.
struct UniversoGrande: View {
    let planetas: [PlanetaDoWidget]

    private let maximo = 6

    var body: some View {
        let visiveis = Array(planetas.prefix(maximo))
        let colunas = visiveis.count > 2 ? 2 : 1

        VStack(spacing: 8) {
            ForEach(linhas(de: visiveis, colunas: colunas), id: \.first?.id) { linha in
                HStack(spacing: 8) {
                    ForEach(linha) { planeta in
                        celula(planeta)
                    }
                }
            }
        }
        .overlay(alignment: .bottomTrailing) {
            ContadorRestante(quantidade: planetas.count - maximo)
        }
    }

    private func linhas(de planetas: [PlanetaDoWidget], colunas: Int) -> [[PlanetaDoWidget]] {
        stride(from: 0, to: planetas.count, by: colunas).map { inicio in
            Array(planetas[inicio..<min(inicio + colunas, planetas.count)])
        }
    }

    private func celula(_ planeta: PlanetaDoWidget) -> some View {
        GeometryReader { geo in
            let escala = planeta.aparencia.escalaDaImagem
            let cabe = min(geo.size.width / escala.width, geo.size.height / escala.height, 200)
            PlanetaComLink(planeta: planeta, diametro: cabe * planeta.prioridade.fatorNoWidget)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
