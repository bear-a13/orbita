//
//  PlanetaView.swift
//  UIKIT
//
//  Created by Bernardo on 13/11/26.
//
import UIKit

@MainActor
protocol PlanetaViewDelegate: AnyObject {
    func planetaFoiTocado(_ planeta: PlanetaView)
    func planetaFoiPressionadoLongo(_ planeta: PlanetaView)
    func planeta(_ planeta: PlanetaView, arrastou gesto: UIPanGestureRecognizer)
}

final class PlanetaView: UIView {
    let atividadeID: UUID
    weak var delegate: PlanetaViewDelegate?

    private let imagem = UIImageView()
    private let rotulo = UILabel()
    //muito importante para a fisica determinando o foramto circular
    override var collisionBoundsType: UIDynamicItemCollisionBoundsType { .ellipse }
    
    private let tempoParaConcluir: TimeInterval = 1.5
    private let vibracaoSegurar = UIImpactFeedbackGenerator(style: .heavy)
    private var timerSegurar: Timer?
    private var inicioSegurar: Date?
    private var anelProgresso: CAShapeLayer?

    init(atividadeID: UUID, titulo: String, nomeDoAsset: String,
         diametro: CGFloat, escalaDaImagem: CGSize = CGSize(width: 1, height: 1),
         corDoTitulo: UIColor = .white, tamanhoDoTitulo: CGFloat = 15) {
        
        self.atividadeID = atividadeID
        
        // O frame inicial é SÓ a bola (o diâmetro)
        super.init(frame: CGRect(x: 0, y: 0, width: diametro, height: diametro))
        
        configurarVisual(titulo: titulo, nomeDoAsset: nomeDoAsset,
                         diametro: diametro, escalaDaImagem: escalaDaImagem,
                         corDoTitulo: corDoTitulo, tamanhoDoTitulo: tamanhoDoTitulo)
        configurarGestos()
        configurarAcessibilidade(titulo: titulo)
    }

    required init?(coder: NSCoder) { fatalError("PlanetaView é criada só por código") }
    
    private func configurarVisual(titulo: String, nomeDoAsset: String,
                                      diametro: CGFloat, escalaDaImagem: CGSize,
                                      corDoTitulo: UIColor, tamanhoDoTitulo: CGFloat) {
            
            clipsToBounds = false

            imagem.image = UIImage(named: nomeDoAsset)
            imagem.contentMode = .scaleAspectFit
            
            let tamanho = CGSize(width: diametro * escalaDaImagem.width,
                                 height: diametro * escalaDaImagem.height)
            
            imagem.frame = CGRect(x: (diametro - tamanho.width) / 2,
                                  y: (diametro - tamanho.height) / 2,
                                  width: tamanho.width, height: tamanho.height)
            addSubview(imagem)

            rotulo.text = titulo
            rotulo.numberOfLines = 2
            rotulo.textAlignment = .center
            rotulo.adjustsFontSizeToFitWidth = true
            rotulo.minimumScaleFactor = 0.6
            rotulo.textColor = corDoTitulo
            rotulo.font = .systemFont(ofSize: tamanhoDoTitulo, weight: .semibold)
            
            rotulo.layer.shadowColor = UIColor.black.cgColor
            rotulo.layer.shadowOpacity = 0.25
            rotulo.layer.shadowRadius = 2
            rotulo.layer.shadowOffset = CGSize(width: 0, height: 1)
            
            rotulo.frame = bounds.insetBy(dx: diametro * 0.14, dy: diametro * 0.3)
            rotulo.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            addSubview(rotulo)
        }
    private func configurarGestos() {
            
            let simples = UITapGestureRecognizer(target: self, action: #selector(tocouUmaVez))
            
            let arrasto = UIPanGestureRecognizer(target: self, action: #selector(arrastou(_:)))
            
            // Começa rápido (0,2 s) para o anel aparecer logo; o tempo real é contado por nós.
            let longo = UILongPressGestureRecognizer(target: self, action: #selector(pressionouLongo(_:)))
            longo.minimumPressDuration = 0.2

            addGestureRecognizer(simples)
            addGestureRecognizer(arrasto)
            addGestureRecognizer(longo)
        }

        private func configurarAcessibilidade(titulo: String) {
            isAccessibilityElement = true
            accessibilityLabel = titulo
            accessibilityHint = "Toque para editar. Segure por 1,5 segundos para concluir."
            
            
            // Como o toque duplo no VoiceOver ativa o item, criamos uma ação explícita para concluir
            accessibilityCustomActions = [
                UIAccessibilityCustomAction(name: "Concluir") { [weak self] _ in
                    guard let self else { return false }
                    self.delegate?.planetaFoiPressionadoLongo(self)
                    return true
                }
            ]
        }

        func atualizarTitulo(_ titulo: String) {
            rotulo.text = titulo
            accessibilityLabel = titulo
        }

        @objc private func tocouUmaVez() { delegate?.planetaFoiTocado(self) }
        @objc private func pressionouLongo(_ gesto: UILongPressGestureRecognizer) {
            switch gesto.state {
            case .began: comecarSegurar()
            case .ended, .cancelled, .failed: cancelarSegurar()
            default: break
            }
        }

        private func comecarSegurar() {
            // anel amarelo em volta do planeta que vai se fechando até concluir

            let anel = CAShapeLayer()
            let raio = bounds.width / 2
            anel.path = UIBezierPath(arcCenter: CGPoint(x: bounds.midX, y: bounds.midY), radius: raio,
                                     startAngle: -.pi / 2, endAngle: .pi * 1.5, clockwise: true).cgPath
            anel.fillColor = UIColor.clear.cgColor
            anel.strokeColor = Tema.amareloPrincipal.cgColor
            anel.lineWidth = 5
            anel.lineCap = .round

            layer.addSublayer(anel)
            anelProgresso = anel

            inicioSegurar = Date()
            vibracaoSegurar.prepare()
            timerSegurar = Timer.scheduledTimer(withTimeInterval: 0.07, repeats: true) { [weak self] _ in
                MainActor.assumeIsolated { self?.avancarSegurar() }
            }
        }

        private func avancarSegurar() {
            guard let inicio = inicioSegurar else { return }
            let progresso = min(1, Date().timeIntervalSince(inicio) / tempoParaConcluir)

            CATransaction.begin()
            CATransaction.setDisableActions(true)
            anelProgresso?.strokeEnd = progresso
            CATransaction.commit()

            // vibração constante que fica mais forte perto do fim
            vibracaoSegurar.impactOccurred(intensity: 0.4 + 0.6 * progresso)


            if progresso >= 1 {
                pararSegurar()
                delegate?.planetaFoiPressionadoLongo(self)
            }
        }

        private func cancelarSegurar() {
            guard inicioSegurar != nil else { return }
            pararSegurar()
        }

        private func pararSegurar() {
            timerSegurar?.invalidate()
            timerSegurar = nil
            inicioSegurar = nil
            anelProgresso?.removeFromSuperlayer()
            anelProgresso = nil
        }

        @objc private func arrastou(_ gesto: UIPanGestureRecognizer) { delegate?.planeta(self, arrastou: gesto) }
    }

