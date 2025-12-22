import SwiftUI

// MARK: - App Colors (ShapeStyle-compatible)

public extension ShapeStyle where Self == Color {
    static var appPrimary: Color {
        Color("AppPrimary")
    }

    static var appSecondary: Color {
        Color("AppSecondary")
    }

    static var appBackground: Color {
        Color("AppBackground")
    }
}

// MARK: - Text Styles

public struct AppTitleStyle: ViewModifier {
    public init() {}

    public func body(content: Content) -> some View {
        content
            .font(.largeTitle.weight(.bold))
            .foregroundStyle(.appPrimary)
    }
}

public struct AppBodyStyle: ViewModifier {
    public init() {}

    public func body(content: Content) -> some View {
        content
            .font(.body)
            .foregroundStyle(.appSecondary)
    }
}

// MARK: - View Extensions

public extension View {

    func appTitleStyle() -> some View {
        modifier(AppTitleStyle())
    }

    func appBodyStyle() -> some View {
        modifier(AppBodyStyle())
    }

    func appScreenBackground() -> some View {
        background(
            Color.appBackground
                .ignoresSafeArea()
        )
    }
}

