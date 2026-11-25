//
//  Prioridade.swift
//  UIKIT
//
//  Created by Bernardo on 13/11/26.
//

import Foundation
import CoreGraphics

nonisolated enum Prioridade: String, Codable, CaseIterable {
    case pequena, media, grande
    
    // quanto maior, mais cedo aparece no widget
    var peso: Int {
        switch self {
        case .pequena: return 0
        case .media: return 1
        case .grande: return 2
        }
    }

    var nome: String {
        switch self {
        case .pequena: return "Pequena"
        case .media: return "Média"
        case .grande: return "Grande"
        }
    }
    
    //determina em pontos o diâmetro dos planetas
    var diametroBase: CGFloat {
        switch self {
        case .pequena: return 90
        case .media: return 130
        case .grande: return 200
        }
    }
    
    // cuidado para telas menores. Saturno usa o próprio corpo (170) em vez do da prioridade.
    func diametro(menorLado: CGFloat, aparencia: AparenciaPlaneta? = nil) -> CGFloat {
        let base = aparencia?.diametroCorpo ?? diametroBase
        return base * Self.escala(menorLado: menorLado)
    }

    // iPhone: encolhe abaixo de 440 pt. iPad e Mac: cresce aos poucos, até 1,6x,
    // para os planetas não ficarem perdidos na tela grande.
    private static func escala(menorLado: CGFloat) -> CGFloat {
        guard menorLado > 440 else { return menorLado / 440 }
        return min(1.6, 1 + (menorLado - 440) / 1000)
    }
    
    var elasticidade: CGFloat {
        switch self {
        case .pequena: return 0.55
        case .media: return 0.4
        case .grande: return 0.25
        }
    }
    
    var densidade: CGFloat {
        switch self {
        case .pequena: return 0.6
        case .media: return 1.0
        case .grande: return 2.2
        }
    }

    func tamanhoDoTitulo(menorLado: CGFloat) -> CGFloat {
        let base: CGFloat
        switch self {
        case .pequena: base = 13
        case .media: base = 15
        case .grande: base = 17
        }
        return base * Self.escala(menorLado: menorLado)
    }

    var aparenciaPadrao: AparenciaPlaneta {
        switch self {
        case .pequena: return .lua
        case .media: return .terra
        case .grande: return .jupiter
        }
    }

    var aparencias: [AparenciaPlaneta] {
        switch self {
        case .pequena: return [.lua, .tita]
        case .media: return [.terra, .marte]
        case .grande: return [.jupiter, .saturno]
        }
    }

    func sortearAparencia() -> AparenciaPlaneta {
        return aparencias.randomElement() ?? aparenciaPadrao
    }
}
