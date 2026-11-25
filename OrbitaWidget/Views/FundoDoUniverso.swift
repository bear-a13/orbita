import SwiftUI

struct FundoDoUniverso: View {
    var body: some View {
        ZStack {
            Color(hex: 0x0B1430)
            Image("fundo-ceu")
                .resizable()
                .scaledToFill()
        }
    }
}
