import SwiftUI

/// "+3": quantas atividades não couberam.
struct ContadorRestante: View {
    let quantidade: Int

    var body: some View {
        if quantidade > 0 {
            Text("+\(quantidade)")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(.black.opacity(0.45), in: Capsule())
                .accessibilityLabel("Mais \(quantidade) em órbita")
        }
    }
}
