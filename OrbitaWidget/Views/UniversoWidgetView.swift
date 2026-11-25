import SwiftUI
import WidgetKit

/// Escolhe o desenho conforme o tamanho do widget.
struct UniversoWidgetView: View {
    @Environment(\.widgetFamily) private var familia
    let planetas: [PlanetaDoWidget]

    var body: some View {
        if let principal = planetas.first {
            switch familia {
            case .systemSmall:
                UniversoPequeno(planeta: principal, total: planetas.count)
            case .systemMedium:
                UniversoMedio(planetas: planetas)
            default:
                UniversoGrande(planetas: planetas)
            }
        } else {
            UniversoVazio()
        }
    }
}
