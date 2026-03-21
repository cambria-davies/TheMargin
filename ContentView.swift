import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Query private var projects: [Project]
    @AppStorage("hasCompletedWelcome") private var hasCompletedWelcome = false

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(MarginTheme(colorScheme: .dark).background)

        // 1px top border
        appearance.shadowColor = UIColor.white.withAlphaComponent(0.04)

        // Literata 9px for tab labels
        let literata9 = UIFont(name: "Literata-Regular", size: 9) ?? .systemFont(ofSize: 9)
        let normalAttrs: [NSAttributedString.Key: Any] = [
            .font: literata9,
            .foregroundColor: UIColor(Color(hex: 0x605850))
        ]
        let selectedAttrs: [NSAttributedString.Key: Any] = [
            .font: literata9,
            .foregroundColor: UIColor(Color(hex: 0xC4956A))
        ]

        appearance.stackedLayoutAppearance.normal.titleTextAttributes = normalAttrs
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = selectedAttrs
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(Color(hex: 0x605850))
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color(hex: 0xC4956A))

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    private var shouldShowWelcome: Bool {
        WelcomeGate.shouldShowWelcome(
            projectCount: projects.count,
            hasCompletedFlag: hasCompletedWelcome
        )
    }

    var body: some View {
        Group {
            if shouldShowWelcome {
                WelcomeView {
                    withAnimation {
                        hasCompletedWelcome = true
                    }
                }
            } else {
                TabView {
                    DashboardView()
                        .tabItem { Label("Home", systemImage: "doc.text") }

                    ProjectsListView()
                        .tabItem { Label("Projects", systemImage: "books.vertical") }

                    InsightsView()
                        .tabItem { Label("Insights", systemImage: "chart.bar.fill") }
                }
                .tint(MarginTheme(colorScheme: colorScheme).amber)
            }
        }
        .environment(\.marginTheme, MarginTheme(colorScheme: colorScheme))
    }
}

#Preview {
    ContentView()
}
