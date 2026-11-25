//
//  AparenciaPlaneta.swift
//  UIKIT
//
//  Created by Bernardo on 13/11/26.
//

import Foundation
import CoreGraphics

nonisolated enum AparenciaPlaneta: String, Codable, CaseIterable {
    case lua, terra, jupiter, marte, tita, saturno

    var nomeDoAsset: String { "planeta-\(rawValue)" }

    // nil = usa o diâmetro da prioridade. Saturno tem o corpo menor que Júpiter (170 vs 200),
    // porque os anéis fazem ele parecer maior do que é.
    var diametroCorpo: CGFloat? {
        switch self {
        case .saturno: return 170
        default: return nil
        }
    }

    // Tamanho da imagem em relação ao corpo. No asset do Saturno o corpo mede 200 de uma
    // imagem de 353,49 x 269,77, então essa proporção é fixa e vale para qualquer diâmetro.
    var escalaDaImagem: CGSize {
        switch self {
        case .saturno: return CGSize(width: 353.49 / 200, height: 269.77 / 200)
        default: return CGSize(width: 1, height: 1)
        }
    }

    var corDoTituloHex: UInt32 {
        switch self {
        case .lua: return 0x1E2236
        case .terra: return 0x061A30
        case .jupiter, .saturno: return 0x3A1E0C
        case .marte: return 0xFFFFFF
        case .tita: return 0x05221F
        }
    }
}
