import SwiftUI

struct ContentView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        TabView {
            DashboardView()
                .tabItem { Label("Home", systemImage: "doc.text") }

            ProjectsListView()
                .tabItem { Label("Projects", systemImage: "books.vertical") }

            InsightsView()
                .tabItem { Label("Insights", systemImage: "chart.bar.fill") }
        }
        .tint(MarginTheme(colorScheme: colorScheme).amber)
        .environment(\.marginTheme, MarginTheme(colorScheme: colorScheme))
    }
}

#Preview {
    ContentView()
}
