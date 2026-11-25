import SwiftUI

struct UniversoVazio: View {
    var body: some View {
        VStack(spacing: 6) {
            Image(AparenciaPlaneta.lua.nomeDoAsset)
                .resizable()
                .comCoresOriginais()
                .scaledToFit()
                .frame(width: 48, height: 48)
                .opacity(0.55)
                .accessibilityHidden(true)
            Text("Nada em órbita")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.9))
            Text("Toque para criar uma atividade")
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.75))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
