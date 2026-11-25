import SwiftUI

struct UniversoMedio: View {
    let planetas: [PlanetaDoWidget]

    private let maximo = 3
    private let espaco: CGFloat = 8

    var body: some View {
        GeometryReader { geo in
            let visiveis = Array(planetas.prefix(maximo))
            let diametro = diametroBase(para: visiveis, em: geo.size)
            HStack(spacing: espaco) {
                ForEach(visiveis) { planeta in
                    PlanetaComLink(planeta: planeta,
                                   diametro: diametro * planeta.prioridade.fatorNoWidget)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .overlay(alignment: .bottomTrailing) {
            ContadorRestante(quantidade: planetas.count - maximo)
        }
    }

    /// Maior diâmetro com que todos cabem lado a lado.
    private func diametroBase(para planetas: [PlanetaDoWidget], em tamanho: CGSize) -> CGFloat {
        var larguras: CGFloat = 0
        var maiorAltura: CGFloat = 1
        for planeta in planetas {
            let escala = planeta.aparencia.escalaDaImagem
            let fator = planeta.prioridade.fatorNoWidget
            larguras += escala.width * fator
            maiorAltura = max(maiorAltura, escala.height * fator)
        }
        let larguraUtil = tamanho.width - espaco * CGFloat(planetas.count - 1)
        return min(larguraUtil / max(larguras, 0.1), tamanho.height / maiorAltura)
    }
}
