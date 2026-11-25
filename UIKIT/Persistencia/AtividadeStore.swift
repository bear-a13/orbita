import Foundation
import SwiftData


@MainActor
final class AtividadeStore {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }


    func pendentes() -> [Atividade] {
        let descritor = FetchDescriptor<Atividade>(
            predicate: #Predicate { $0.concluidaEm == nil },
            sortBy: [SortDescriptor(\.criadaEm)]
        )
        do {
            return try modelContext.fetch(descritor)
        } catch {
            print("❌ Erro ao carregar atividades: \(error)")
            return []
        }
    }

    func buscar(id: UUID) -> Atividade? {
        var descritor = FetchDescriptor<Atividade>(predicate: #Predicate { $0.id == id })
        descritor.fetchLimit = 1
        return try? modelContext.fetch(descritor).first
    }


    @discardableResult
    func adicionar(titulo: String, descricao: String, prioridade: Prioridade,
                   aparencia: AparenciaPlaneta? = nil) -> Atividade {
        let nova = Atividade(titulo: titulo, descricao: descricao,
                             prioridade: prioridade, aparencia: aparencia)
        modelContext.insert(nova)
        salvar()
        return nova
    }

    func atualizar(_ atividade: Atividade, titulo: String, descricao: String, prioridade: Prioridade) {
        atividade.titulo = titulo
        atividade.descricao = descricao
        if atividade.prioridade != prioridade {
            atividade.prioridade = prioridade
            atividade.aparencia = prioridade.sortearAparencia()
        }
        salvar()
    }

    func concluir(_ atividade: Atividade) {
        atividade.concluidaEm = .now
        salvar()
    }

    private func salvar() {
        do {
            try modelContext.save()
        } catch {
            print("❌ Erro ao salvar: \(error)")
        }
        atualizarSnapshot()
    }
}
