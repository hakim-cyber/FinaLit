import SwiftUI
import UIKit

enum AppTone: String, Codable {
    case accent
    case success
    case warning
    case danger
    case info
    case slate
    case teal
    case blue
    case amber
    case orange
    case rose
    case green
}

enum AppTheme {
    static let background = Color("AppBackground")
    static let surfacePrimary = Color("AppSurfacePrimary")
    static let surfaceSecondary = Color("AppSurfaceSecondary")
    static let surfaceElevated = Color("AppSurfaceElevated")
    static let separator = Color("AppSeparator")
    static let textPrimary = Color("AppTextPrimary")
    static let textSecondary = Color("AppTextSecondary")
    static let textTertiary = Color("AppTextTertiary")
    static let accent = Color("AppAccent")
    static let success = Color("AppSuccess")
    static let warning = Color("AppWarning")
    static let danger = Color("AppDanger")
    static let info = Color("AppInfo")
    static let chartPrimary = Color("AppChartPrimary")
    static let chartSecondary = Color("AppChartSecondary")
    static let inverseText = Color.white

    enum Spacing {
        static let screen: CGFloat = 20
        static let section: CGFloat = 24
        static let card: CGFloat = 16
        static let compact: CGFloat = 8
        static let regular: CGFloat = 12
    }

    enum CornerRadius {
        static let small: CGFloat = 10
        static let medium: CGFloat = 14
        static let large: CGFloat = 18
        static let hero: CGFloat = 22
    }

    enum Typography {
        static let heroLabel = Font.system(size: 13, weight: .semibold)
        static let heroAmount = Font.system(size: 34, weight: .semibold, design: .rounded)
        static let sectionTitle = Font.system(size: 17, weight: .semibold)
        static let sectionLink = Font.system(size: 13, weight: .semibold)
        static let headline = Font.system(size: 16, weight: .semibold)
        static let body = Font.system(size: 15)
        static let bodySemibold = Font.system(size: 15, weight: .semibold)
        static let caption = Font.system(size: 13)
        static let detail = Font.system(size: 12)
        static let badge = Font.system(size: 11, weight: .semibold)
        static let formLabel = Font.system(size: 11, weight: .semibold)
        static let toolbarIcon = Font.system(size: 17, weight: .medium)
        static let rowIcon = Font.system(size: 15, weight: .medium)
        static let badgeIcon = Font.system(size: 11, weight: .medium)
        static let compactRowIcon = Font.system(size: 13, weight: .medium)
    }

    enum Metrics {
        static let statCardMinHeight: CGFloat = 88
        static let actionCardMinHeight: CGFloat = 120
        static let floatingActionSize: CGFloat = 56
    }

    static func tint(for tone: AppTone) -> Color {
        switch tone {
        case .accent:
            return accent
        case .success:
            return success
        case .warning:
            return warning
        case .danger:
            return danger
        case .info:
            return info
        case .slate:
            return .adaptive(light: "6E7B86", dark: "99A4AE")
        case .teal:
            return .adaptive(light: "4B817C", dark: "7FBDB5")
        case .blue:
            return .adaptive(light: "5C7F98", dark: "8EB2C8")
        case .amber:
            return .adaptive(light: "A17631", dark: "D6AD69")
        case .orange:
            return .adaptive(light: "B27646", dark: "D79B74")
        case .rose:
            return .adaptive(light: "A16679", dark: "CF99A6")
        case .green:
            return .adaptive(light: "4F8B66", dark: "7BC596")
        }
    }

    static func softFill(for tone: AppTone) -> Color {
        tint(for: tone).opacity(0.14)
    }

    static func softBorder(for tone: AppTone) -> Color {
        tint(for: tone).opacity(0.24)
    }

    static func configureAppearance() {
        let background = UIColor(named: "AppBackground") ?? .systemBackground
        let accent = UIColor(named: "AppAccent") ?? .systemTeal
        UINavigationBar.appearance().tintColor = accent
        UITabBar.appearance().tintColor = accent

        UITableView.appearance().backgroundColor = background
        UICollectionView.appearance().backgroundColor = background
    }
}

enum AppSurfaceStyle {
    case primary
    case secondary
    case elevated
    case tinted(AppTone)
}

struct AppSectionHeader: View {
    let title: LocalizedStringKey
    var actionTitle: LocalizedStringKey?
    var action: (() -> Void)?

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(title)
                .font(AppTheme.Typography.sectionTitle)
                .foregroundStyle(AppTheme.textPrimary)

            Spacer()

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(AppTheme.Typography.sectionLink)
                    .foregroundStyle(AppTheme.accent)
            }
        }
    }
}

struct AppToneBadge: View {
    let title: LocalizedStringKey
    let systemImage: String
    let tone: AppTone

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(AppTheme.Typography.badgeIcon)
            Text(title)
                .font(AppTheme.Typography.badge)
        }
        .foregroundStyle(AppTheme.tint(for: tone))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(AppTheme.softFill(for: tone))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(AppTheme.softBorder(for: tone), lineWidth: 1)
        )
    }
}

struct AppThinProgressBar: View {
    let progress: Double
    var tone: AppTone = .accent

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(AppTheme.surfaceSecondary)
                Capsule()
                    .fill(AppTheme.tint(for: tone))
                    .frame(width: geometry.size.width * min(max(progress, 0), 1))
            }
        }
        .frame(height: 4)
    }
}

struct AppFilledButtonStyle: ButtonStyle {
    var tone: AppTone = .accent
    var compact = false
    var fillsWidth = true

    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTheme.Typography.bodySemibold)
            .foregroundStyle(isEnabled ? AppTheme.inverseText : AppTheme.textTertiary)
            .frame(maxWidth: fillsWidth ? .infinity : nil)
            .padding(.vertical, compact ? 12 : 16)
            .background(
                RoundedRectangle(cornerRadius: compact ? AppTheme.CornerRadius.medium : AppTheme.CornerRadius.large)
                    .fill(isEnabled ? AppTheme.tint(for: tone) : AppTheme.surfaceSecondary)
            )
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

private struct AppSurfaceModifier: ViewModifier {
    let style: AppSurfaceStyle
    let padding: CGFloat
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(border, lineWidth: 1)
            )
    }

    private var background: Color {
        switch style {
        case .primary:
            return AppTheme.surfacePrimary
        case .secondary:
            return AppTheme.surfaceSecondary
        case .elevated:
            return AppTheme.surfaceElevated
        case .tinted(let tone):
            return AppTheme.softFill(for: tone)
        }
    }

    private var border: Color {
        switch style {
        case .tinted(let tone):
            return AppTheme.softBorder(for: tone)
        default:
            return AppTheme.separator
        }
    }
}

private struct AppInputModifier: ViewModifier {
    let multiline: Bool

    func body(content: Content) -> some View {
        content
            .font(AppTheme.Typography.body)
            .foregroundStyle(AppTheme.textPrimary)
            .padding(multiline ? AppTheme.Spacing.card : AppTheme.Spacing.regular)
            .frame(minHeight: multiline ? nil : 50)
            .background(AppTheme.surfaceSecondary, in: RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                    .stroke(AppTheme.separator, lineWidth: 1)
            )
    }
}

extension View {
    func appSurface(
        _ style: AppSurfaceStyle = .primary,
        padding: CGFloat = AppTheme.Spacing.card,
        cornerRadius: CGFloat = AppTheme.CornerRadius.large
    ) -> some View {
        modifier(AppSurfaceModifier(style: style, padding: padding, cornerRadius: cornerRadius))
    }

    func appInputStyle() -> some View {
        modifier(AppInputModifier(multiline: false))
    }

    func appTextAreaStyle() -> some View {
        modifier(AppInputModifier(multiline: true))
    }

    func appFieldLabelStyle() -> some View {
        font(AppTheme.Typography.formLabel)
            .foregroundStyle(AppTheme.textSecondary)
    }
}

private extension Color {
    static func adaptive(light: String, dark: String) -> Color {
        Color(
            UIColor { traits in
                UIColor(hex: traits.userInterfaceStyle == .dark ? dark : light)
            }
        )
    }
}

private extension UIColor {
    convenience init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&int)

        let red, green, blue: CGFloat
        switch cleaned.count {
        case 6:
            red = CGFloat((int >> 16) & 0xFF) / 255
            green = CGFloat((int >> 8) & 0xFF) / 255
            blue = CGFloat(int & 0xFF) / 255
        default:
            red = 0
            green = 0
            blue = 0
        }

        self.init(red: red, green: green, blue: blue, alpha: 1)
    }
}
