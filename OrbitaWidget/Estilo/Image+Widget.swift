import SwiftUI
import WidgetKit

extension Image {
    /// Mantém as cores do planeta quando a tela de início está no modo tingido (iOS 18+).
    @ViewBuilder
    func comCoresOriginais() -> some View {
        if #available(iOS 18.0, *) {
            widgetAccentedRenderingMode(.fullColor)
        } else {
            self
        }
    }
}
