import SwiftData
import SwiftUI

struct ContentView: View {
    @AppStorage("marginColorScheme") private var marginColorScheme = "system"

    private var preferredColorScheme: ColorScheme? {
        switch marginColorScheme {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    var body: some View {
        AppRootContent()
            .preferredColorScheme(preferredColorScheme)
            .animation(.easeInOut(duration: 0.35), value: marginColorScheme)
    }
}

// MARK: - Inner root (sees resolved color scheme from preferredColorScheme)

private struct AppRootContent: View {
    @Environment(\.colorScheme) private var colorScheme
    @Query private var projects: [Project]
    @AppStorage("hasCompletedWelcome") private var hasCompletedWelcome = false

    private enum MainTab: Hashable {
        case home, projects, insights
    }

    @State private var selectedTab: MainTab = .home
    @State private var homeRevealToken = 1

    private var shouldShowWelcome: Bool {
        WelcomeGate.shouldShowWelcome(
            projectCount: projects.count,
            hasCompletedFlag: hasCompletedWelcome
        )
    }

    private var theme: MarginTheme {
        MarginTheme(colorScheme: colorScheme)
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
                TabView(selection: $selectedTab) {
                    DashboardView(homeRevealToken: homeRevealToken)
                        .tabItem { Label("Home", systemImage: "doc.text") }
                        .tag(MainTab.home)

                    ProjectsListView()
                        .tabItem { Label("Projects", systemImage: "books.vertical") }
                        .tag(MainTab.projects)

                    InsightsView()
                        .tabItem { Label("Insights", systemImage: "chart.bar.fill") }
                        .tag(MainTab.insights)
                }
                .background(TabBarAnchorConfigurator(theme: theme).allowsHitTesting(false))
                .onChange(of: selectedTab) { _, newValue in
                    if newValue == .home {
                        homeRevealToken += 1
                    }
                    // Liquid Glass can reset tab item colors after selection changes.
                    TabBarAppearanceHelper.applyToEmbeddedTabBar(theme: theme)
                }
            }
        }
        .environment(\.marginTheme, theme)
        .onAppear {
            TabBarAppearanceHelper.apply(theme: theme)
            TabBarAppearanceHelper.applyToEmbeddedTabBar(theme: theme)
        }
        .task(id: colorScheme) {
            // Tab bar may be created after first layout on iOS 26.
            try? await Task.sleep(for: .milliseconds(50))
            TabBarAppearanceHelper.applyToEmbeddedTabBar(theme: theme)
        }
        .onChange(of: colorScheme) { _, _ in
            let t = MarginTheme(colorScheme: colorScheme)
            TabBarAppearanceHelper.apply(theme: t)
            TabBarAppearanceHelper.applyToEmbeddedTabBar(theme: t)
        }
    }
}

#Preview {
    ContentView()
}
