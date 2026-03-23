import SwiftUI

struct DatabaseErrorView: View {
    let error: Error

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("Unable to Load Data")
                .font(.title2.weight(.semibold))

            Text("The Margin couldn't open its database. Try restarting the app. If the problem persists, you may need to reinstall.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Text(error.localizedDescription)
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.top, 8)
        }
        .padding(32)
    }
}
