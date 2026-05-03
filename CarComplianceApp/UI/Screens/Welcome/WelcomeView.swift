import SwiftUI

struct WelcomeView: View {
    var onGetStarted: () -> Void
    var onSkipToDemo: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "car.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(.accentColor)

            VStack(spacing: 12) {
                Text("Car Compliance")
                    .font(.largeTitle)
                    .bold()

                Text("Stay on top of your car's legal, insurance, and maintenance obligations — powered by AI.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 32)
            }

            Spacer()

            VStack(spacing: 16) {
                Button(action: onGetStarted) {
                    Text("Get Started")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }

                Button("Try demo (no API key)", action: onSkipToDemo)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
}
