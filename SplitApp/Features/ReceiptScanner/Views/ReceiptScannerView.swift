import SwiftUI

struct ReceiptScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ReceiptScannerViewModel

    let onCapture: () -> Void

    var body: some View {
        ZStack {
            Color(red: 0.08, green: 0.09, blue: 0.11)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                VStack(spacing: 20) {
                    scanFrame
                    Text("Наведите на чек")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.78))
                }
                .padding(.top, 30)

                Spacer()

                controls
                    .padding(.bottom, 34)
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
        }
        .navigationBarHidden(true)
    }

    private var topBar: some View {
        HStack {
            Button(action: { dismiss() }, label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                    Text("Отмена")
                }
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.8))
            })

            Spacer()

            Button(action: viewModel.toggleFlash) {
                Image(systemName: viewModel.isFlashEnabled ? "sun.max.fill" : "sun.max")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.white.opacity(0.78))
            }
        }
    }

    private var scanFrame: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.accentColor.opacity(0.95), lineWidth: 3)
                .frame(height: 390)

            VStack(spacing: 12) {
                ForEach(0..<8) { index in
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color.white.opacity(index < 4 ? 0.14 : 0.08))
                        .frame(width: CGFloat(240 - index * 13), height: 12)
                }
            }
            .padding(.top, -70)

            Rectangle()
                .fill(Color.accentColor.opacity(0.65))
                .frame(height: 2)

            VStack {
                HStack {
                    cornerL
                    Spacer()
                    cornerR
                }
                Spacer()
                HStack {
                    cornerL.rotationEffect(Angle(degrees: 180))
                    Spacer()
                    cornerR.rotationEffect(Angle(degrees: 180))
                }
            }
            .padding(1)
        }
    }

    private var controls: some View {
        HStack {
            cameraSideButton(icon: "square.and.arrow.up")
            Spacer()

            Button(action: onCapture) {
                ZStack {
                    Circle()
                        .stroke(.white.opacity(0.88), lineWidth: 6)
                        .frame(width: 97, height: 97)
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 79, height: 79)
                }
            }

            Spacer()
            cameraSideButton(icon: "photo")
        }
    }

    private func cameraSideButton(icon: String) -> some View {
        Button(action: {}, label: {
            Circle()
                .fill(Color.white.opacity(0.14))
                .frame(width: 64, height: 64)
                .overlay {
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(.white.opacity(0.85))
                }
        })
    }

    private var cornerL: some View {
        VStack(alignment: .leading, spacing: 0) {
            Rectangle().frame(width: 26, height: 4)
            Rectangle().frame(width: 4, height: 26)
        }
        .foregroundStyle(Color.accentColor)
    }

    private var cornerR: some View {
        VStack(alignment: .trailing, spacing: 0) {
            Rectangle().frame(width: 26, height: 4)
            Rectangle().frame(width: 4, height: 26)
        }
        .foregroundStyle(Color.accentColor)
    }
}

#Preview {
    ReceiptScannerView(viewModel: ReceiptScannerViewModel(), onCapture: {})
}
