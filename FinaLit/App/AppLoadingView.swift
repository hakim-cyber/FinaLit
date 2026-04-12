import SwiftUI

struct AppLoadingView: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            VStack(spacing: 22) {
                ZStack {
                    Circle()
                        .stroke(AppTheme.separator, lineWidth: 1)
                        .frame(width: 112, height: 112)

                    Circle()
                        .trim(from: 0.18, to: 1)
                        .stroke(
                            AppTheme.accent,
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .frame(width: 88, height: 88)
                        .rotationEffect(.degrees(animate ? 360 : 0))
                        .animation(
                            .linear(duration: 1.1).repeatForever(autoreverses: false),
                            value: animate
                        )

                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundStyle(AppTheme.accent)
                }
                .frame(width: 120, height: 120)

                VStack(spacing: 6) {
                    Text(L10n.Common.finalit)
                        .font(.system(size: 34, weight: .medium))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(L10n.Common.restoringYourWorkspace)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppTheme.textSecondary)
                }

                ProgressView()
                    .tint(AppTheme.accent)
                    .scaleEffect(1.1)
            }
            .appSurface(.elevated, padding: 24, cornerRadius: AppTheme.CornerRadius.hero)
            .padding(.horizontal, 20)
        }
        .onAppear {
            animate = true
        }
    }
}

#Preview {
    AppLoadingView()
}
