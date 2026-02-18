import SwiftUI

struct AppLoadingView: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.30),
                    Color.cyan.opacity(0.22),
                    Color.white
                ],
                startPoint: animate ? .topLeading : .bottomTrailing,
                endPoint: animate ? .bottomTrailing : .topLeading
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                ZStack {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .stroke(Color.blue.opacity(0.22), lineWidth: 2)
                            .frame(width: 96, height: 96)
                            .scaleEffect(animate ? 1.2 + CGFloat(index) * 0.18 : 0.70)
                            .opacity(animate ? 0.0 : 0.75)
                            .animation(
                                .easeOut(duration: 1.5)
                                    .repeatForever(autoreverses: false)
                                    .delay(Double(index) * 0.28),
                                value: animate
                            )
                    }

                    Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(Color.blue)
                }
                .frame(width: 120, height: 120)

                VStack(spacing: 8) {
                    Text("Preparing your dashboard")
                        .font(.title3.weight(.semibold))
                    Text("Loading your profile securely...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                ProgressView()
                    .tint(.blue)
                    .scaleEffect(1.1)
            }
            .padding(.horizontal, 24)
        }
        .onAppear {
            animate = true
        }
    }
}

#Preview {
    AppLoadingView()
}
