import SwiftUI
import WidgetKit

struct UniversoWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "UniversoWidget", provider: UniversoProvider()) { entrada in
            UniversoWidgetView(planetas: entrada.planetas)
                .containerBackground(for: .widget) { FundoDoUniverso() }
        }
        .configurationDisplayName("Universo")
        .description("Suas atividades em órbita, sem sair da tela de início.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

#Preview("Pequeno", as: .systemSmall) {
    UniversoWidget()
} timeline: {
    UniversoEntrada(date: .now, planetas: PlanetaDoWidget.exemplos)
    UniversoEntrada(date: .now, planetas: [])
}

#Preview("Médio", as: .systemMedium) {
    UniversoWidget()
} timeline: {
    UniversoEntrada(date: .now, planetas: PlanetaDoWidget.exemplos)
}

#Preview("Grande", as: .systemLarge) {
    UniversoWidget()
} timeline: {
    UniversoEntrada(date: .now, planetas: PlanetaDoWidget.exemplos)
}
