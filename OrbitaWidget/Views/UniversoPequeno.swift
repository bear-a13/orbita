import SwiftUI
import WidgetKit

struct UniversoPequeno: View {
    let planeta: PlanetaDoWidget
    let total: Int

    var body: some View {
        VStack(spacing: 4) {
            GeometryReader { geo in
                // divide pela escala para os anéis do Saturno caberem
                let escala = planeta.aparencia.escalaDaImagem
                let diametro = min(geo.size.width / escala.width, geo.size.height / escala.height)
                PlanetaDoWidgetView(planeta: planeta, diametro: diametro)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            if total > 1 {
                Text("\(total) em órbita")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
        .widgetURL(LinkDoPlaneta.url(para: planeta.id))
    }
}
