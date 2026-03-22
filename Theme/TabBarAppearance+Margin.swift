import SwiftUI
import UIKit

/// Applies v2 tab bar styling (Space Mono 8pt, letter-spacing, accent selection).
/// Per-tab top underline is not supported by `UITabBarAppearance`; selection uses accent tint on icon + label.
///
/// iOS 26 Liquid Glass: `UITabBar.appearance()` often does not affect the real floating tab bar. We also
/// locate the embedded `UITabBar` instance and apply the same appearance there, plus
/// `UITabBarController.view.tintColor` (see Apple Developer Forums thread 761056).
enum TabBarAppearanceHelper {
    @MainActor
    static func apply(theme: MarginTheme) {
        let appearance = makeTabBarAppearance(theme: theme)
        let tabBar = UITabBar.appearance()
        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
        tabBar.tintColor = uiColor(theme.accent)
        tabBar.unselectedItemTintColor = uiColor(theme.textTertiary)
    }

    /// Configure the live tab bar used by SwiftUI `TabView` (required on iOS 26+).
    @MainActor
    static func applyToEmbeddedTabBar(theme: MarginTheme) {
        guard let tabBar = findEmbeddedTabBar() else {
            apply(theme: theme)
            return
        }
        apply(theme: theme, to: tabBar)
    }

    @MainActor
    fileprivate static func apply(theme: MarginTheme, to tabBar: UITabBar) {
        let appearance = makeTabBarAppearance(theme: theme)
        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
        tabBar.tintColor = uiColor(theme.accent)
        tabBar.unselectedItemTintColor = uiColor(theme.textTertiary)

        // Selected item inherits from the tab bar controller’s view tint on recent iOS (see Apple dev forums).
        // UITabBar does not expose `tabBarController` like other UIViews; walk the responder chain.
        if let controller = tabBarController(containing: tabBar) {
            controller.view.tintColor = uiColor(theme.accent)
        }

        let normalColor = uiColor(theme.textTertiary)
        let selectedColor = uiColor(theme.accent)
        for item in tabBar.items ?? [] {
            item.setTitleTextAttributes([.foregroundColor: normalColor], for: .normal)
            item.setTitleTextAttributes([.foregroundColor: selectedColor], for: .selected)
        }
    }

    /// Walks the window hierarchy to find the tab bar backing a SwiftUI `TabView`.
    @MainActor
    private static func findEmbeddedTabBar() -> UITabBar? {
        for scene in UIApplication.shared.connectedScenes {
            guard let windowScene = scene as? UIWindowScene else { continue }
            for window in windowScene.windows where window.windowScene != nil && !window.isHidden {
                if let tab = findTabBarController(from: window.rootViewController)?.tabBar {
                    return tab
                }
            }
        }
        return nil
    }

    @MainActor
    private static func tabBarController(containing tabBar: UITabBar) -> UITabBarController? {
        var responder: UIResponder? = tabBar
        while let r = responder {
            if let tab = r as? UITabBarController { return tab }
            responder = r.next
        }
        return nil
    }

    @MainActor
    private static func findTabBarController(from root: UIViewController?) -> UITabBarController? {
        guard let root = root else { return nil }
        if let tab = root as? UITabBarController { return tab }
        for child in root.children {
            if let found = findTabBarController(from: child) { return found }
        }
        if let presented = root.presentedViewController {
            if let found = findTabBarController(from: presented) { return found }
        }
        return nil
    }

    @MainActor
    private static func makeTabBarAppearance(theme: MarginTheme) -> UITabBarAppearance {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = uiColor(theme.background)
        appearance.shadowColor = uiColor(theme.border)

        let stacked = makeItemAppearance(theme: theme)
        appearance.stackedLayoutAppearance = stacked
        appearance.inlineLayoutAppearance = makeItemAppearance(theme: theme)
        appearance.compactInlineLayoutAppearance = makeItemAppearance(theme: theme)
        return appearance
    }

    @MainActor
    private static func makeItemAppearance(theme: MarginTheme) -> UITabBarItemAppearance {
        let item = UITabBarItemAppearance()

        let spaceMono = UIFont(name: "SpaceMono-Regular", size: 8) ?? .systemFont(ofSize: 8)
        let kern: CGFloat = 0.12 * 8

        let normalAttrs: [NSAttributedString.Key: Any] = [
            .font: spaceMono,
            .foregroundColor: uiColor(theme.textTertiary),
            .kern: kern
        ]
        let selectedAttrs: [NSAttributedString.Key: Any] = [
            .font: spaceMono,
            .foregroundColor: uiColor(theme.accent),
            .kern: kern
        ]

        item.normal.titleTextAttributes = normalAttrs
        item.selected.titleTextAttributes = selectedAttrs
        item.normal.iconColor = uiColor(theme.textTertiary)
        item.selected.iconColor = uiColor(theme.accent)
        return item
    }

    /// Explicit RGB — avoids SwiftUI `Color` → `UIColor` resolution issues with tab bar / Liquid Glass.
    @MainActor
    private static func uiColor(_ color: Color) -> UIColor {
        UIColor(color)
    }
}

// MARK: - Anchor view (inside tab content → can resolve `tabBarController` early)

/// Hosts a zero-size view inside the tab interface so we can reach `UITabBarController` reliably.
struct TabBarAnchorConfigurator: UIViewRepresentable {
    var theme: MarginTheme

    func makeUIView(context: Context) -> TabBarAnchorView {
        let v = TabBarAnchorView()
        v.theme = theme
        return v
    }

    func updateUIView(_ uiView: TabBarAnchorView, context: Context) {
        uiView.theme = theme
        uiView.scheduleApply()
    }
}

final class TabBarAnchorView: UIView {
    var theme: MarginTheme?
    private var applyTask: Task<Void, Never>?

    override func didMoveToWindow() {
        super.didMoveToWindow()
        scheduleApply()
    }

    func scheduleApply() {
        guard let theme = theme else { return }
        applyTask?.cancel()
        // Tab bar may attach one runloop after the view appears.
        applyTask = Task { @MainActor in
            TabBarAppearanceHelper.applyToEmbeddedTabBar(theme: theme)
        }
    }
}
