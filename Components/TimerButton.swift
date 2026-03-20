import SwiftUI

struct TimerButton: View {
    let label: String
    let icon: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(label, systemImage: icon, action: action)
            .labelStyle(.iconOnly)
            .font(.system(size: 20))
            .foregroundStyle(tint)
            .frame(width: 44, height: 44)
            .background(Circle().stroke(tint.opacity(0.5), lineWidth: 1.5))
    }
}
