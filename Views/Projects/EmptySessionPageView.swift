import SwiftUI

struct EmptySessionPageView: View {
    @Environment(\.marginTheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            TypewriterText(
                text: "No sessions yet.\nThis is where your pages will live.",
                fontSize: 13
            )
            .lineSpacing(15)
        }
        .padding(.top, 32)
        .padding(.leading, 60)
        .padding(.trailing, 24)
        .frame(maxWidth: .infinity, minHeight: 140, alignment: .topLeading)
        .paperSurface(ruledLines: true, redMargin: true)
    }
}
