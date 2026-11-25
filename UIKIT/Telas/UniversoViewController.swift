import UIKit

final class UniversoViewController: UIViewController {

    private let fundoImageView = UIImageView()
    private let estadoVazioLabel = UILabel()
    private var fisica: UniversoFisico?
    private let botaoNovaAtividade = BotaoNovaAtividade()
    private let lequeView = LequeView()
    private let sensor = SensorDeMovimento()
    // vibração quando o planeta bate
    private let vibracaoBatida = UIImpactFeedbackGenerator(style: .rigid)
    private let vibracaoConcluir = UIImpactFeedbackGenerator(style: .heavy)

   
    private let store: AtividadeStore

    
    private var planetas: [PlanetaView] = []
    private var ultimoTamanho = CGSize.zero

    

    init(store: AtividadeStore) {
        self.store = store
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) não foi implementado")
    }

    // iclo de vida

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        configurarFundo()
        configurarEstadoVazio()
        configurarBotao()
        configurarToqueForaDoLeque()

        fisica = UniversoFisico(referencia: view)

        sensor.aoMudarGravidade = { [weak self] direcao in
            guard let self else { return }
            let gravidadeFinal = UIAccessibility.isReduceMotionEnabled
                ? CGVector(dx: 0, dy: 1)
                : self.converterParaInterface(direcao)
            self.fisica?.definirGravidade(gravidadeFinal)
        }

        sensor.aoChacoalhar = { [weak self] in
            self?.chacoalhar()
        }

        sensor.aoBalancar = { [weak self] aceleracao, intervalo in
            guard let self, !UIAccessibility.isReduceMotionEnabled else { return }
            self.fisica?.balancar(aceleracao: self.converterParaInterface(aceleracao), intervalo: intervalo)
        }
// assim é possivel controlar o nivel de vibração
        vibracaoBatida.prepare()
        fisica?.aoBater = { [weak self] intensidade in
            self?.vibracaoBatida.impactOccurred(intensity: 0.3 + 0.7 * intensidade)
            self?.vibracaoBatida.prepare()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        sensor.iniciar()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sensor.parar()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        fisica?.atualizarLimites(margens: view.safeAreaInsets,
                                 obstaculos: [botaoNovaAtividade.frame])

        // girar o iPad ou redimensionar a janela pode deixar planetas do lado de fora
        if view.bounds.size != ultimoTamanho {
            ultimoTamanho = view.bounds.size
            fisica?.trazerParaDentro(de: view.bounds.inset(by: view.safeAreaInsets))
        }
    }

    // O sensor fala no eixo do aparelho em pé. No iPad a tela gira, então o vetor gira junto.
    private func converterParaInterface(_ v: CGVector) -> CGVector {
        switch view.window?.windowScene?.effectiveGeometry.interfaceOrientation {
        case .landscapeRight: return CGVector(dx: v.dy, dy: -v.dx)
        case .landscapeLeft: return CGVector(dx: -v.dy, dy: v.dx)
        case .portraitUpsideDown: return CGVector(dx: -v.dx, dy: -v.dy)
        default: return v
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if planetas.isEmpty { carregarAtividadesDoBanco() }
        // mantém o widget em dia com o que está em órbita
        store.atualizarSnapshot()
        if let id = atividadePendenteDeAbertura {
            atividadePendenteDeAbertura = nil
            abrirAtividadeAgora(id)
        }
    }


    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake { chacoalhar() }
    }

    private func chacoalhar() {
        guard !UIAccessibility.isReduceMotionEnabled else { return }
        fisica?.impulsionarTodos()
    }

    //fundo e estado vazio

    private func configurarFundo() {
        fundoImageView.image = UIImage(named: "fundo-ceu")
        fundoImageView.contentMode = .scaleAspectFill
        fundoImageView.clipsToBounds = true
        fundoImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(fundoImageView)

        NSLayoutConstraint.activate([
            fundoImageView.topAnchor.constraint(equalTo: view.topAnchor),
            fundoImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            fundoImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            fundoImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    private func configurarEstadoVazio() {
        estadoVazioLabel.text = "Nenhuma atividade em órbita.\nToque em + para criar a primeira."
        estadoVazioLabel.numberOfLines = 0
        estadoVazioLabel.textAlignment = .center
        estadoVazioLabel.font = .systemFont(ofSize: 15, weight: .medium)
        estadoVazioLabel.textColor = Tema.textoClaro.withAlphaComponent(0.8)
        estadoVazioLabel.alpha = 0
        estadoVazioLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(estadoVazioLabel)

        NSLayoutConstraint.activate([
            estadoVazioLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            estadoVazioLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            estadoVazioLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 32)
        ])
    }

    private func atualizarEstadoVazio() {
        let vazio = planetas.isEmpty
        UIView.animate(withDuration: 0.3) { self.estadoVazioLabel.alpha = vazio ? 1 : 0 }
    }


    private func configurarBotao() {
        botaoNovaAtividade.delegate = self
        botaoNovaAtividade.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(botaoNovaAtividade)

        lequeView.delegate = self
        lequeView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(lequeView)

        NSLayoutConstraint.activate([
            botaoNovaAtividade.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            botaoNovaAtividade.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            botaoNovaAtividade.widthAnchor.constraint(equalToConstant: 140),
            botaoNovaAtividade.heightAnchor.constraint(equalToConstant: 90),

            lequeView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            lequeView.bottomAnchor.constraint(equalTo: botaoNovaAtividade.topAnchor, constant: -12)
        ])
    }

    private func configurarToqueForaDoLeque() {
        let toque = UITapGestureRecognizer(target: self, action: #selector(tocouFora(_:)))
        // não conta se o toque for nos planetas e botões
        toque.cancelsTouchesInView = false
        view.addGestureRecognizer(toque)
    }

    @objc private func tocouFora(_ gesto: UITapGestureRecognizer) {
        guard botaoNovaAtividade.estaAberto else { return }
        let ponto = gesto.location(in: view)
        if lequeView.frame.contains(ponto) || botaoNovaAtividade.frame.contains(ponto) { return }
        abrirLeque(false)
    }

    private func abrirLeque(_ abrir: Bool) {
        botaoNovaAtividade.alternarEstado(aberto: abrir)
        lequeView.alternar(abrir: abrir)
    }

    // Planetas

    private func carregarAtividadesDoBanco() {
        semearExemplosNaPrimeiraVez()
        for atividade in store.pendentes() {
            criarPlaneta(para: atividade)
        }
        atualizarEstadoVazio()
    }

    // exemplos no inicio, primeira vez
    //
    private func semearExemplosNaPrimeiraVez() {
        let chave = "jaSemeouPlanetasIniciais"
        guard !UserDefaults.standard.bool(forKey: chave) else { return }
        UserDefaults.standard.set(true, forKey: chave)
        guard store.pendentes().isEmpty else { return }

        let exemplos: [(String, Prioridade, AparenciaPlaneta)] = [
            ("pressione: concluir", .grande, .jupiter),
            ("Toque: editar", .grande, .saturno),
        ]
        for (titulo, prioridade, aparencia) in exemplos {
            store.adicionar(titulo: titulo, descricao: "", prioridade: prioridade, aparencia: aparencia)
        }
    }

   
    private func criarPlaneta(para atividade: Atividade, centro: CGPoint? = nil) {
        guard let fisica else { return }
        let menorLado = min(view.bounds.width, view.bounds.height)
        let prioridade = atividade.prioridade
        let aparencia = atividade.aparencia
        let diametro = prioridade.diametro(menorLado: menorLado, aparencia: aparencia)

        let planeta = PlanetaView(
            atividadeID: atividade.id,
            titulo: atividade.titulo,
            nomeDoAsset: aparencia.nomeDoAsset,
            diametro: diametro,
            escalaDaImagem: aparencia.escalaDaImagem,
            corDoTitulo: UIColor(hex: aparencia.corDoTituloHex),
            tamanhoDoTitulo: prioridade.tamanhoDoTitulo(menorLado: menorLado)
        )
        planeta.delegate = self
        planeta.center = centro ?? posicaoLivre(diametro: diametro,
                                                larguraVisivel: diametro * aparencia.escalaDaImagem.width)

        // logica para o saturno, não sei pq fui inventar
        if aparencia == .saturno {
            view.insertSubview(planeta, belowSubview: botaoNovaAtividade)
        } else {
            view.insertSubview(planeta, aboveSubview: estadoVazioLabel)
        }

        fisica.adicionar(planeta, densidade: prioridade.densidade, elasticidade: prioridade.elasticidade)
        planetas.append(planeta)
        atualizarEstadoVazio()
    }

    // Tira o planeta da física e da lista
    private func removerPlaneta(_ planeta: PlanetaView, animado: Bool) {
        fisica?.remover(planeta)
        planetas.removeAll { $0 === planeta }
        atualizarEstadoVazio()

        guard animado else {
            planeta.removeFromSuperview()
            return
        }
        // encha um pouco e depois encolhe até sumir.
        UIView.animateKeyframes(withDuration: 0.35, delay: 0, options: [.calculationModeCubic], animations: {
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.3) {
                planeta.transform = CGAffineTransform(scaleX: 1.12, y: 1.12)
            }
            UIView.addKeyframe(withRelativeStartTime: 0.3, relativeDuration: 0.7) {
                planeta.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
                planeta.alpha = 0
            }
        }, completion: { _ in
            planeta.removeFromSuperview()
        })
    }

    private func posicaoLivre(diametro: CGFloat, larguraVisivel: CGFloat) -> CGPoint {
        let area = view.bounds.inset(by: view.safeAreaInsets)
        let raio = diametro / 2
        let margemX = min(larguraVisivel / 2 + 8, area.width / 2)
        let faixaY = (area.minY + raio + 8)...max(area.minY + raio + 8, area.maxY - raio - 8)

        let botao = botaoNovaAtividade.frame
        var vizinhos = planetas.map { ($0.center, $0.bounds.width / 2) }
        vizinhos.append((CGPoint(x: botao.midX, y: botao.midY), max(botao.width, botao.height) / 2))

        var melhor = CGPoint(x: area.midX, y: faixaY.lowerBound)
        var maiorFolga = -CGFloat.infinity

        for _ in 0..<60 {
            let candidato = CGPoint(x: .random(in: (area.minX + margemX)...(area.maxX - margemX)),
                                    y: .random(in: faixaY))
            let folga = vizinhos.map { centro, raioVizinho in
                hypot(centro.x - candidato.x, centro.y - candidato.y) - raio - raioVizinho
            }.min() ?? .infinity

            if folga > 8 { return candidato }
            if folga > maiorFolga { maiorFolga = folga; melhor = candidato }
        }
        return melhor
    }

    // MARK: - Deep link do widget

    private var atividadePendenteDeAbertura: UUID?

    /// Chamado pelo SceneDelegate quando o app é aberto por um planeta do widget.
    func abrirAtividade(id: UUID) {
        if viewIfLoaded?.window != nil {
            abrirAtividadeAgora(id)
        } else {
            // app ainda não está na tela (abertura a frio): guarda para o viewDidAppear
            atividadePendenteDeAbertura = id
        }
    }

    private func abrirAtividadeAgora(_ id: UUID) {
        // o widget pode estar atrasado e mostrar uma atividade já concluída
        guard let atividade = store.buscar(id: id), atividade.concluidaEm == nil else { return }
        // não joga fora o que a pessoa estava escrevendo
        if let formulario = presentedViewController as? FormularioAtividadeViewController,
           formulario.temAlteracoes { return }
        if botaoNovaAtividade.estaAberto { abrirLeque(false) }
        // se já existe uma folha aberta, fecha antes de mostrar a do planeta tocado
        if let apresentado = presentedViewController {
            apresentado.dismiss(animated: false) { [weak self] in
                self?.abrirFormulario(.editar(atividade))
            }
        } else {
            abrirFormulario(.editar(atividade))
        }
    }

    private func abrirFormulario(_ modo: FormularioAtividadeViewController.Modo) {
        let formulario = FormularioAtividadeViewController(modo: modo)
        formulario.delegate = self
        if let sheet = formulario.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.selectedDetentIdentifier = .large
            sheet.prefersGrabberVisible = true
        }
        present(formulario, animated: true)
    }
}

// planetaViewDelegate

extension UniversoViewController: PlanetaViewDelegate {
    // toque para editar
    func planetaFoiTocado(_ planeta: PlanetaView) {
        if botaoNovaAtividade.estaAberto { abrirLeque(false); return }
        guard let atividade = store.buscar(id: planeta.atividadeID) else { return }
        abrirFormulario(.editar(atividade))
    }

    /*
     A conclusão agora é por pressão longa de 1,5 s, não mais pelo duplo toque.
     */
    func planetaFoiPressionadoLongo(_ planeta: PlanetaView) {
        if let atividade = store.buscar(id: planeta.atividadeID) {
            store.concluir(atividade)
        }
        vibracaoConcluir.impactOccurred(intensity: 1.0)
        UIAccessibility.post(notification: .announcement, argument: "Atividade concluída")
        removerPlaneta(planeta, animado: !UIAccessibility.isReduceMotionEnabled)
    }

    func planeta(_ planeta: PlanetaView, arrastou gesto: UIPanGestureRecognizer) {
        let ponto = gesto.location(in: view)
        switch gesto.state {
        case .began: fisica?.comecarArrasto(planeta, ponto: ponto)
        case .changed: fisica?.moverArrasto(para: ponto)
        case .ended, .cancelled: fisica?.terminarArrasto(velocidade: gesto.velocity(in: view))
        default: break
        }
    }
}

//BotaoNovaAtividadeDelegate

extension UniversoViewController: BotaoNovaAtividadeDelegate {
    func botaoFoiTocado() {
        abrirLeque(!botaoNovaAtividade.estaAberto)
    }
}

//  LequeViewDelegate

extension UniversoViewController: LequeViewDelegate {
    func lequeSelecionou(prioridade: Prioridade) {
        abrirLeque(false)
        abrirFormulario(.nova(prioridade))
    }
}

//

extension UniversoViewController: FormularioAtividadeDelegate {
    func formularioCriou(titulo: String, descricao: String, prioridade: Prioridade) {
        let atividade = store.adicionar(titulo: titulo, descricao: descricao, prioridade: prioridade)
        criarPlaneta(para: atividade)
    }

    func formularioEditou(_ atividade: Atividade, titulo: String, descricao: String, prioridade: Prioridade) {
        guard let planeta = planetas.first(where: { $0.atividadeID == atividade.id }) else { return }
        let prioridadeAntiga = atividade.prioridade

        store.atualizar(atividade, titulo: titulo, descricao: descricao, prioridade: prioridade)

        if prioridadeAntiga == prioridade {
            planeta.atualizarTitulo(titulo)
        } else {
           
            let centro = planeta.center
            removerPlaneta(planeta, animado: false)
            criarPlaneta(para: atividade, centro: centro)
        }
    }
}

