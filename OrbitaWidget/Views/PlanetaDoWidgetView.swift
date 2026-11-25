import SwiftUI

/// O planeta com o título. Quem chama decide o diâmetro e o que o toque faz.
struct PlanetaDoWidgetView: View {
    let planeta: PlanetaDoWidget
    let diametro: CGFloat

    private var escala: CGSize { planeta.aparencia.escalaDaImagem }

    var body: some View {
        Image(planeta.aparencia.nomeDoAsset)
            .resizable()
            .comCoresOriginais()
            .scaledToFit()
            .frame(width: diametro * escala.width, height: diametro * escala.height)
            .overlay {
                Text(planeta.titulo)
                    .font(.system(size: max(10, diametro * 0.15), weight: .semibold))
                    .foregroundStyle(Color(hex: planeta.aparencia.corDoTituloHex))
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .minimumScaleFactor(0.7)
                    .shadow(color: .black.opacity(0.25), radius: 1.5, y: 1)
                    .frame(width: diametro * 0.8, height: diametro * 0.8)
            }
            .contentShape(Rectangle())
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(planeta.titulo)
            .accessibilityHint("Abrir no Gravita")
    }
}

/// Planeta que abre a própria atividade. `Link` não funciona no tamanho pequeno.
struct PlanetaComLink: View {
    let planeta: PlanetaDoWidget
    let diametro: CGFloat

    var body: some View {
        Link(destination: LinkDoPlaneta.url(para: planeta.id)) {
            PlanetaDoWidgetView(planeta: planeta, diametro: diametro)
        }
        .buttonStyle(.plain)
    }
}

extension Prioridade {
    /// Diferença de tamanho no widget, mais suave que no app para o texto caber.
    var fatorNoWidget: CGFloat {
        switch self {
        case .grande: return 1
        case .media: return 0.88
        case .pequena: return 0.76
        }
    }
}
