import SwiftUI

public extension Color {
    static let appPrimary = Color("AppPrimary")
    static let appSecondary = Color("AppSecondary")
    static let appBackground = Color("AppBackground")
}

public struct AppTitleStyle: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .font(.largeTitle.weight(.bold))
            .foregroundStyle(Color.appPrimary)
    }
}

public struct AppBodyStyle: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .font(.body)
            .foregroundStyle(Color.appSecondary)
    }
}

public extension View {
    func appTitleStyle() -> some View {
        modifier(AppTitleStyle())
    }

    func appBodyStyle() -> some View {
        modifier(AppBodyStyle())
    }

    func appScreenBackground() -> some View {
        background(Color.appBackground.ignoresSafeArea())
    }
}
