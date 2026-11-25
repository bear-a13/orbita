import WidgetKit

struct UniversoEntrada: TimelineEntry {
    let date: Date
    let planetas: [PlanetaDoWidget]
}

struct UniversoProvider: TimelineProvider {
    func placeholder(in context: Context) -> UniversoEntrada {
        UniversoEntrada(date: .now, planetas: PlanetaDoWidget.exemplos)
    }

    func getSnapshot(in context: Context, completion: @escaping (UniversoEntrada) -> Void) {
        let planetas = SnapshotDoUniverso.ler()
        // na galeria, quem ainda não tem tarefas vê os exemplos
        let usarExemplos = context.isPreview && planetas.isEmpty
        completion(UniversoEntrada(date: .now, planetas: usarExemplos ? PlanetaDoWidget.exemplos : planetas))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<UniversoEntrada>) -> Void) {
        let entrada = UniversoEntrada(date: .now, planetas: SnapshotDoUniverso.ler())
        // só o app muda a lista, e ele mesmo pede a atualização
        completion(Timeline(entries: [entrada], policy: .never))
    }
}
