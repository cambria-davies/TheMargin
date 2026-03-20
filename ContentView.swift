import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Text("Dashboard")
                .tabItem {
                    Label("Home", systemImage: "doc.text")
                }

            Text("Projects")
                .tabItem {
                    Label("Projects", systemImage: "books.vertical")
                }

            Text("Insights")
                .tabItem {
                    Label("Insights", systemImage: "chart.bar.fill")
                }
        }
    }
}

#Preview {
    ContentView()
}
