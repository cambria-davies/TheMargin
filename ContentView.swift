import SwiftUI

struct ContentView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        TabView {
            DashboardView()
                .tabItem { Label("Home", systemImage: "doc.text") }

            Text("Projects")
                .tabItem { Label("Projects", systemImage: "books.vertical") }

            Text("Insights")
                .tabItem { Label("Insights", systemImage: "chart.bar.fill") }
        }
        .tint(MarginTheme(colorScheme: colorScheme).amber)
        .environment(\.marginTheme, MarginTheme(colorScheme: colorScheme))
    }
}

#Preview {
    ContentView()
}
