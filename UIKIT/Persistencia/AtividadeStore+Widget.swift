import Foundation
import WidgetKit

extension AtividadeStore {
    /// Manda para o widget as pendentes, das mais importantes para as menos.
    /// Chamado depois de qualquer mudança e ao abrir o app.
    func atualizarSnapshot() {
        let planetas = pendentes()
            .sorted { a, b in
                a.prioridade.peso != b.prioridade.peso
                    ? a.prioridade.peso > b.prioridade.peso
                    : a.criadaEm < b.criadaEm
            }
            .map { atividade in
                PlanetaDoWidget(id: atividade.id, titulo: atividade.titulo,
                                prioridade: atividade.prioridade, aparencia: atividade.aparencia)
            }
        if SnapshotDoUniverso.gravar(planetas) {
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
}
