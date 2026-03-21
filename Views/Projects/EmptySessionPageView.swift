import SwiftUI

struct EmptySessionPageView: View {
    @Environment(\.marginTheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("No sessions yet.\nThis is where your pages will live.")
                .font(.typewriter(13))
                .foregroundStyle(theme.textDim)
                .lineSpacing(6)
        }
        .padding(.top, 32)
        .padding(.leading, 60)
        .padding(.trailing, 24)
        .frame(maxWidth: .infinity, minHeight: 140, alignment: .topLeading)
        .paperSurface(ruledLines: true, redMargin: true)
    }
}
