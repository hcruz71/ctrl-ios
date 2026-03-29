import SwiftUI

struct LaunchScreenView: View {
    @State private var logoOpacity: Double = 0
    @State private var logoScale: Double = 0.8
    @State private var blueLineWidth: CGFloat = 0
    @State private var goldLineWidth: CGFloat = 0
    @State private var linesOpacity: Double = 0

    var body: some View {
        ZStack {
            Color(hex: "#0D1B2A").ignoresSafeArea()

            VStack(spacing: 0) {
                Image("VERALogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 22))
                    .opacity(logoOpacity)
                    .scaleEffect(logoScale)

                Spacer().frame(height: 16)

                HStack(spacing: 6) {
                    // Blue line — expands left to right
                    HStack {
                        Rectangle()
                            .fill(Color(hex: "#1A6EDB"))
                            .frame(width: blueLineWidth, height: 3)
                            .clipShape(RoundedRectangle(cornerRadius: 1.5))
                        Spacer(minLength: 0)
                    }
                    .frame(width: 44)

                    // Gold line — expands right to left
                    HStack {
                        Spacer(minLength: 0)
                        Rectangle()
                            .fill(Color(hex: "#D4A017"))
                            .frame(width: goldLineWidth, height: 3)
                            .clipShape(RoundedRectangle(cornerRadius: 1.5))
                    }
                    .frame(width: 44)
                }
                .opacity(linesOpacity)
            }
        }
        .onAppear { startAnimation() }
    }

    private func startAnimation() {
        // Logo fades in and scales up
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
            logoOpacity = 1.0
            logoScale = 1.0
        }

        // Blue line expands left to right
        withAnimation(.easeOut(duration: 0.4).delay(0.5)) {
            blueLineWidth = 44
            linesOpacity = 1.0
        }

        // Gold line expands right to left
        withAnimation(.easeOut(duration: 0.4).delay(0.7)) {
            goldLineWidth = 44
        }

        // Subtle glow pulse
        withAnimation(.easeInOut(duration: 0.3).delay(1.0)) {
            linesOpacity = 0.9
        }
    }
}
