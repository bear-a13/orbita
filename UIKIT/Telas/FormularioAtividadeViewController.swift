import UIKit

@MainActor
protocol FormularioAtividadeDelegate: AnyObject {
    func formularioCriou(titulo: String, descricao: String, prioridade: Prioridade)
    func formularioEditou(_ atividade: Atividade, titulo: String, descricao: String, prioridade: Prioridade)
}


final class FormularioAtividadeViewController: UIViewController {

    enum Modo {
        case nova(Prioridade)
        case editar(Atividade)
    }

    weak var delegate: FormularioAtividadeDelegate?

    private let modo: Modo
    private var prioridadeSelecionada: Prioridade

    private let botaoFechar = UIButton(type: .system)
    private let tituloTelaLabel = UILabel()
    private let botaoSalvar = UIButton(type: .system)

    private let conteudo = UIStackView()
    private let tituloTextField = UITextField()
    private let descricaoTextView = UITextView()
    private let descricaoPlaceholder = UILabel()
    private var cards: [Prioridade: UIButton] = [:]

    init(modo: Modo) {
        self.modo = modo
        switch modo {
        case .nova(let prioridade): prioridadeSelecionada = prioridade
        case .editar(let atividade): prioridadeSelecionada = atividade.prioridade
        }
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) não foi implementado")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Tema.fundoSheet
        //preseta o teclado com cor escura, para deixar o app todo no modo dark
        overrideUserInterfaceStyle = .dark

        configurarCabecalho()
        configurarConteudo()
        preencherSeForEdicao()
        atualizarSelecaoPrioridadeVisual()
        atualizarBotaoSalvar()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if case .nova = modo { tituloTextField.becomeFirstResponder() }
    }

    private func preencherSeForEdicao() {
        guard case .editar(let atividade) = modo else { return }
        tituloTextField.text = atividade.titulo
        descricaoTextView.text = atividade.descricao
        descricaoPlaceholder.isHidden = !atividade.descricao.isEmpty
    }

// cabeçalho com o x e o check
    private func configurarCabecalho() {
        
        var configFechar = UIButton.Configuration.filled()
        configFechar.image = UIImage(systemName: "xmark",
                                     withConfiguration: UIImage.SymbolConfiguration(pointSize: 17, weight: .medium))
        configFechar.cornerStyle = .capsule
        configFechar.baseBackgroundColor = Tema.fundoCampo
        configFechar.baseForegroundColor = Tema.iconeFechar
        botaoFechar.configuration = configFechar
        botaoFechar.accessibilityLabel = "Fechar"
        botaoFechar.addTarget(self, action: #selector(fecharToque), for: .touchUpInside)

        if case .editar = modo {
            tituloTelaLabel.text = "Editar pendência"
        } else {
            tituloTelaLabel.text = "Nova pendência"
        }
        tituloTelaLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        tituloTelaLabel.textColor = .white
        tituloTelaLabel.textAlignment = .center
        tituloTelaLabel.accessibilityTraits = .header

        var configSalvar = UIButton.Configuration.filled()
        configSalvar.image = UIImage(systemName: "checkmark",
                                     withConfiguration: UIImage.SymbolConfiguration(pointSize: 17, weight: .semibold))
        configSalvar.cornerStyle = .capsule
        botaoSalvar.configuration = configSalvar
        // configuracão de permanencia em relação ao check
        botaoSalvar.configurationUpdateHandler = { botao in
            var config = botao.configuration
            if botao.isEnabled {
                config?.baseBackgroundColor = Tema.amareloPrincipal
                config?.baseForegroundColor = Tema.marromEscuro
            } else {
                config?.baseBackgroundColor = Tema.fundoCampo
                config?.baseForegroundColor = Tema.textoPlaceholder.withAlphaComponent(0.5)
            }
            botao.configuration = config
        }
        botaoSalvar.accessibilityLabel = "Salvar"
        botaoSalvar.addTarget(self, action: #selector(salvarToque), for: .touchUpInside)

        [botaoFechar, tituloTelaLabel, botaoSalvar].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        NSLayoutConstraint.activate([
            botaoFechar.topAnchor.constraint(equalTo: view.topAnchor, constant: 21),
            botaoFechar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 35),
            botaoFechar.widthAnchor.constraint(equalToConstant: 44),
            botaoFechar.heightAnchor.constraint(equalToConstant: 44),

            tituloTelaLabel.centerYAnchor.constraint(equalTo: botaoFechar.centerYAnchor),
            tituloTelaLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            botaoSalvar.centerYAnchor.constraint(equalTo: botaoFechar.centerYAnchor),
            botaoSalvar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -35),
            botaoSalvar.widthAnchor.constraint(equalToConstant: 44),
            botaoSalvar.heightAnchor.constraint(equalToConstant: 44)
        ])
    }


    private func configurarConteudo() {
        // título
        tituloTextField.font = .systemFont(ofSize: 17)
        tituloTextField.textColor = .white
        tituloTextField.tintColor = Tema.amareloPrincipal
        tituloTextField.backgroundColor = Tema.fundoCampo
        tituloTextField.layer.cornerRadius = 14
        tituloTextField.attributedPlaceholder = NSAttributedString(
            string: "Ex.: Estudar Astronomia",
            attributes: [.foregroundColor: Tema.textoPlaceholder])
        tituloTextField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        tituloTextField.leftViewMode = .always
        tituloTextField.returnKeyType = .done
        tituloTextField.accessibilityLabel = "Título"
        tituloTextField.delegate = self
        tituloTextField.addTarget(self, action: #selector(tituloMudou), for: .editingChanged)
        tituloTextField.addTarget(self, action: #selector(confirmouNoTeclado), for: .editingDidEndOnExit)
        tituloTextField.heightAnchor.constraint(equalToConstant: 51).isActive = true

        // Prioridade: um cartão por caso do enum
        let seletor = UIStackView()
        seletor.axis = .horizontal
        seletor.distribution = .fillEqually
        seletor.spacing = 10
        for prioridade in Prioridade.allCases {
            let card = criarCard(para: prioridade)
            cards[prioridade] = card
            seletor.addArrangedSubview(card)
        }
        seletor.heightAnchor.constraint(equalToConstant: 112).isActive = true

        // Descrição (UITextView não tem placeholder nativo: usamos um label por cima)
        descricaoTextView.font = .systemFont(ofSize: 17)
        descricaoTextView.textColor = .white
        descricaoTextView.tintColor = Tema.amareloPrincipal
        descricaoTextView.backgroundColor = Tema.fundoCampo
        descricaoTextView.layer.cornerRadius = 14
        descricaoTextView.textContainerInset = UIEdgeInsets(top: 15, left: 11, bottom: 15, right: 11)
        descricaoTextView.accessibilityLabel = "Descrição"
        descricaoTextView.delegate = self
        descricaoTextView.heightAnchor.constraint(equalToConstant: 120).isActive = true

        descricaoPlaceholder.text = "Detalhes, prazo ou contexto"
        descricaoPlaceholder.font = .systemFont(ofSize: 17)
        descricaoPlaceholder.textColor = Tema.textoPlaceholder
        descricaoPlaceholder.isAccessibilityElement = false
        descricaoPlaceholder.translatesAutoresizingMaskIntoConstraints = false
        descricaoTextView.addSubview(descricaoPlaceholder)
        NSLayoutConstraint.activate([
            descricaoPlaceholder.topAnchor.constraint(equalTo: descricaoTextView.topAnchor, constant: 15),
            descricaoPlaceholder.leadingAnchor.constraint(equalTo: descricaoTextView.leadingAnchor, constant: 16)
        ])

        // empilha os campos campos separando por 24 pt
        conteudo.axis = .vertical
        conteudo.spacing = 24
        conteudo.addArrangedSubview(campo("Título *", tituloTextField))
        conteudo.addArrangedSubview(campo("Prioridade *", seletor))
        conteudo.addArrangedSubview(campo("Descrição", descricaoTextView))
        conteudo.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(conteudo)

        NSLayoutConstraint.activate([
            conteudo.topAnchor.constraint(equalTo: botaoFechar.bottomAnchor, constant: 32),
            conteudo.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            conteudo.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24)
        ])
    }
    

    private func campo(_ texto: String, _ controle: UIView) -> UIStackView {
        let rotulo = UILabel()
        rotulo.text = texto
        rotulo.font = .systemFont(ofSize: 15, weight: .semibold)
        rotulo.textColor = .white
        // campo para acessibilidadde
        rotulo.isAccessibilityElement = false
        let pilha = UIStackView(arrangedSubviews: [rotulo, controle])
        pilha.axis = .vertical
        pilha.spacing = 8
        return pilha
    }

    private func criarCard(para prioridade: Prioridade) -> UIButton {
        var config = UIButton.Configuration.plain()
        config.title = prioridade.nome
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { entrada in
            var saida = entrada
            saida.font = .systemFont(ofSize: 14, weight: .semibold)
            return saida
        }

        // respeitar a proporção de 30 / 44 / 64 apartir do figma
        let lado: CGFloat = switch prioridade {
        case .pequena: 30
        case .media: 44
        case .grande: 64
        }
        if let original = UIImage(named: prioridade.aparenciaPadrao.nomeDoAsset) {
            let caixa = CGSize(width: 64, height: 64)
            config.image = UIGraphicsImageRenderer(size: caixa).image { _ in
                let origem = (64 - lado) / 2
                original.draw(in: CGRect(x: origem, y: origem, width: lado, height: lado))
            }.withRenderingMode(.alwaysOriginal)
        }
        config.imagePlacement = .top
        config.imagePadding = 10
        config.background.cornerRadius = 18

        let botao = UIButton(configuration: config)
        botao.accessibilityLabel = "Prioridade \(prioridade.nome)"
        botao.addAction(UIAction { [weak self] _ in
            self?.prioridadeSelecionada = prioridade
            self?.atualizarSelecaoPrioridadeVisual()
        }, for: .touchUpInside)
        return botao
    }

    private func atualizarSelecaoPrioridadeVisual() {
        for (prioridade, botao) in cards {
            let selecionado = prioridade == prioridadeSelecionada
            var config = botao.configuration
            config?.background.backgroundColor = selecionado ? Tema.segmentoSelecionado : Tema.segmentoPadrao
            config?.background.strokeColor = selecionado ? Tema.bordaSelecionada : .clear
            config?.background.strokeWidth = selecionado ? 2 : 0
            config?.baseForegroundColor = selecionado ? .white : Tema.textoSegmento
            botao.configuration = config
            botao.accessibilityTraits = selecionado ? [.button, .selected] : .button
        }
    }

    // o check só fica amarelo quando tem alguma coisa no campo de texto
    private func atualizarBotaoSalvar() {
        botaoSalvar.isEnabled = !tituloLimpo.isEmpty
    }

    private var tituloLimpo: String {
        tituloTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }


    /// Tem algo digitado ou escolhido que ainda não foi salvo?
    var temAlteracoes: Bool {
        guard isViewLoaded else { return false }
        let descricao = descricaoTextView.text ?? ""
        switch modo {
        case .nova(let prioridade):
            return !tituloLimpo.isEmpty || !descricao.isEmpty || prioridadeSelecionada != prioridade
        case .editar(let atividade):
            return tituloLimpo != atividade.titulo
                || descricao != atividade.descricao
                || prioridadeSelecionada != atividade.prioridade
        }
    }

    @objc private func fecharToque() {
        dismiss(animated: true)
    }

    @objc private func tituloMudou() {
        atualizarBotaoSalvar()
    }

    // confirmar no teclado 
    @objc private func confirmouNoTeclado() {
        if botaoSalvar.isEnabled { salvarToque() }
    }

    @objc private func salvarToque() {
        let titulo = tituloLimpo
        guard !titulo.isEmpty else { return }
        let descricao = descricaoTextView.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        switch modo {
        case .nova:
            delegate?.formularioCriou(titulo: titulo, descricao: descricao, prioridade: prioridadeSelecionada)
        case .editar(let atividade):
            delegate?.formularioEditou(atividade, titulo: titulo, descricao: descricao, prioridade: prioridadeSelecionada)
        }
        dismiss(animated: true)
    }
}


extension FormularioAtividadeViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        descricaoPlaceholder.isHidden = !textView.text.isEmpty
    }
}

extension FormularioAtividadeViewController: UITextFieldDelegate {
    // Título aceita no máximo 20 caracteres 
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        guard textField === tituloTextField,
              let atual = textField.text,
              let intervalo = Range(range, in: atual) else { return true }
        return atual.replacingCharacters(in: intervalo, with: string).count <= 20
    }
}
