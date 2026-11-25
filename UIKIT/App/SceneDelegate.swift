import UIKit
import SwiftData

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    private var universoVC: UniversoViewController?

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Atividade.self,
        ])
        // com o App Group do widget, o SwiftData copia o banco antigo para a pasta do grupo e passa a usar ela
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("❌ Erro fatal ao criar o ModelContainer do SwiftData: \(error)")
        }
    }()

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        let window = UIWindow(windowScene: windowScene)
        
        let store = AtividadeStore(modelContext: sharedModelContainer.mainContext)
        
        let universoVC = UniversoViewController(store: store)
        self.universoVC = universoVC
        
        window.rootViewController = universoVC
        self.window = window
        window.makeKeyAndVisible()

        // abertura a frio vinda de um planeta do widget
        abrir(URL: connectionOptions.urlContexts.first?.url)
    }

    // app já aberto: toque no planeta do widget
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        abrir(URL: URLContexts.first?.url)
    }

    private func abrir(URL url: URL?) {
        guard let url, let id = LinkDoPlaneta.id(em: url) else { return }
        universoVC?.abrirAtividade(id: id)
    }

    func sceneDidDisconnect(_ scene: UIScene) {}
    func sceneDidBecomeActive(_ scene: UIScene) {}
    func sceneWillResignActive(_ scene: UIScene) {}
    func sceneWillEnterForeground(_ scene: UIScene) {}
    func sceneDidEnterBackground(_ scene: UIScene) {
        //salvar as alterações quando sair
        try? sharedModelContainer.mainContext.save()
    }
}
