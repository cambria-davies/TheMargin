import SwiftUI

struct StatCardView: View {
    let label: String
    let value: String
    let isHighlighted: Bool

    @Environment(\.marginTheme) private var theme

    init(label: String, value: String, isHighlighted: Bool = false) {
        self.label = label
        self.value = value
        self.isHighlighted = isHighlighted
    }

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.display(22))
                .foregroundStyle(isHighlighted ? theme.amber : theme.text)
            Text(label.uppercased())
                .font(.literata(9, weight: .medium))
                .foregroundStyle(theme.textDim)
                .tracking(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(theme.surface)
        .clipShape(.rect(cornerRadius: 12))
    }
}
