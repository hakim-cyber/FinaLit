import SwiftUI

struct AppLoadingView: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            Color(hex: "0A0A0F").ignoresSafeArea()

            VStack(spacing: 22) {
                ZStack {
                    Circle()
                        .stroke(Color(hex: "1F2937"), lineWidth: 1)
                        .frame(width: 112, height: 112)

                    Circle()
                        .trim(from: 0.18, to: 1)
                        .stroke(
                            Color(hex: "6366F1"),
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
                        .foregroundStyle(Color(hex: "6366F1"))
                }
                .frame(width: 120, height: 120)

                VStack(spacing: 6) {
                    Text("FinaLit")
                        .font(.system(size: 34, weight: .light, design: .serif))
                        .foregroundStyle(.white)
                    Text("Restoring your workspace")
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Color(hex: "6B7280"))
                }

                ProgressView()
                    .tint(Color(hex: "6366F1"))
                    .scaleEffect(1.1)
            }
            .padding(.vertical, 34)
            .padding(.horizontal, 24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(hex: "111118"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color(hex: "1F2937"), lineWidth: 1)
                    )
            )
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
