//
//  UniversoFisico.swift
//  UIKIT
//
//  Created by Bernardo on 13/11/26.
//

import UIKit


@MainActor
final class UniversoFisico: NSObject {
    private let animator: UIDynamicAnimator
    
    private let gravidade = UIGravityBehavior()
    private let colisao = UICollisionBehavior()
    
    private var propriedades: [ObjectIdentifier: UIDynamicItemBehavior] = [:]

    private var arrasto: UIAttachmentBehavior?
    private weak var itemArrastado: UIView?

    var aoBater: ((CGFloat) -> Void)?
    private var ultimaBatida: [ObjectIdentifier: Date] = [:]

    init(referencia: UIView) {
        animator = UIDynamicAnimator(referenceView: referencia)
        super.init()
        colisao.collisionDelegate = self
        
        // Define a gravidade padrão apontando para baixo
        gravidade.gravityDirection = CGVector(dx: 0, dy: 1)
        
        animator.addBehavior(gravidade)
        animator.addBehavior(colisao)
    }

        func adicionar(_ item: UIView, densidade: CGFloat, elasticidade: CGFloat) {
            gravidade.addItem(item)
            colisao.addItem(item)

            let comportamento = UIDynamicItemBehavior(items: [item])
            comportamento.density = densidade
            comportamento.elasticity = elasticidade
            comportamento.friction = 0.2
            // freio "do ar" evita que voem sem parar
            comportamento.resistance = 0.4
            // Regra do Órbita o texto nunca fica de cabeça para baixo
            //ALTERE AQUI PARA O COMPORTAMENTE DE ORBITA TRAVAR
            comportamento.allowsRotation = true
            
            animator.addBehavior(comportamento)
            propriedades[ObjectIdentifier(item)] = comportamento
        }

        func remover(_ item: UIView) {
            if itemArrastado === item { terminarArrasto(velocidade: .zero) }
            gravidade.removeItem(item)
            colisao.removeItem(item)
            ultimaBatida[ObjectIdentifier(item)] = nil
            if let comportamento = propriedades.removeValue(forKey: ObjectIdentifier(item)) {
                animator.removeBehavior(comportamento)
            }
        }

        // mundo

        
        func atualizarLimites(margens: UIEdgeInsets, obstaculos: [CGRect]) {
            colisao.setTranslatesReferenceBoundsIntoBoundary(with: margens)
            colisao.removeAllBoundaries()
            for (indice, retangulo) in obstaculos.enumerated() {
                colisao.addBoundary(withIdentifier: "obstaculo-\(indice)" as NSString,
                                    for: UIBezierPath(ovalIn: retangulo))
            }
        }
    

    // puxa de volta quem ficou fora da área visível
    func trazerParaDentro(de area: CGRect) {
        for item in colisao.items {
            let raioX = min(item.bounds.width / 2, area.width / 2)
            let raioY = min(item.bounds.height / 2, area.height / 2)
            let destino = CGPoint(x: min(max(item.center.x, area.minX + raioX), area.maxX - raioX),
                                  y: min(max(item.center.y, area.minY + raioY), area.maxY - raioY))
            guard destino != item.center else { continue }
            item.center = destino
            animator.updateItem(usingCurrentState: item)
        }
    }

    //muda a direção da gravidade
    func definirGravidade(_ direcao: CGVector) {
        gravidade.gravityDirection = direcao
    }

    //chacoalhão um empurrão instantâneo em direção aleatória para cada planeta.
    func impulsionarTodos(forca: CGFloat = 2) {
        for item in colisao.items {
            let empurrao = UIPushBehavior(items: [item], mode: .instantaneous)
            empurrao.angle = .random(in: 0..<(2 * .pi))
            empurrao.magnitude = forca
            // Um push instantâneo so age uma vez, depois disso tiramos ele do motor.
            empurrao.action = { [weak animator, weak empurrao] in
                guard let empurrao, !empurrao.active else { return }
                animator?.removeBehavior(empurrao)
            }
            animator.addBehavior(empurrao)
        }
    }

    func balancar(aceleracao: CGVector, intervalo: TimeInterval, forca: CGFloat = 2.5) {
        // 1 g no UIKit Dynamics = 1000 pt inércia = velocidade no sentido CONTRÁRIO.
        let ganho = 1000 * forca * CGFloat(intervalo)
        let delta = CGPoint(x: -aceleracao.dx * ganho, y: -aceleracao.dy * ganho)
        for comportamento in propriedades.values {
            for item in comportamento.items where item !== itemArrastado {
                comportamento.addLinearVelocity(delta, for: item)
            }
        }
    }

    //batidas para a vibração

    private func registrarBatida(_ item: UIDynamicItem) {
        guard let comportamento = propriedades[ObjectIdentifier(item)] else { return }
        let v = comportamento.linearVelocity(for: item)
        let velocidade = hypot(v.x, v.y)
        guard velocidade > 180 else { return }

        let id = ObjectIdentifier(item)
        if let ultima = ultimaBatida[id], Date.now.timeIntervalSince(ultima) < 0.12 { return }
        ultimaBatida[id] = .now
        aoBater?(min(1, velocidade / 1500))
    }

    //arrastar e arremessar

    func comecarArrasto(_ item: UIView, ponto: CGPoint) {
        terminarArrasto(velocidade: .zero)
        let deslocamento = UIOffset(horizontal: ponto.x - item.center.x,
                                    vertical: ponto.y - item.center.y)
        let ligacao = UIAttachmentBehavior(item: item,
                                           offsetFromCenter: deslocamento,
                                           attachedToAnchor: ponto)
        ligacao.length = 0
        animator.addBehavior(ligacao)
        arrasto = ligacao
        itemArrastado = item
    }

    func moverArrasto(para ponto: CGPoint) {
        arrasto?.anchorPoint = ponto
    }

    func terminarArrasto(velocidade: CGPoint) {
        guard let ligacao = arrasto else { return }
        animator.removeBehavior(ligacao)
        arrasto = nil
        if let item = itemArrastado, let comportamento = propriedades[ObjectIdentifier(item)] {
            comportamento.addLinearVelocity(velocidade, for: item)
        }
        itemArrastado = nil
    }
}

// UICollisionBehaviorDelegate

extension UniversoFisico: UICollisionBehaviorDelegate {
    // bordas da tela ou botão +
    func collisionBehavior(_ behavior: UICollisionBehavior, beganContactFor item: UIDynamicItem,
                           withBoundaryIdentifier identifier: NSCopying?, at p: CGPoint) {
        registrarBatida(item)
    }

    //p laneta bateu em outro planeta
    func collisionBehavior(_ behavior: UICollisionBehavior, beganContactFor item1: UIDynamicItem,
                           with item2: UIDynamicItem, at p: CGPoint) {
        registrarBatida(item1)
        registrarBatida(item2)
    }
}
