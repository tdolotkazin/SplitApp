import SwiftUI
import AVFoundation
import PhotosUI

struct CameraView: View {
    @Bindable var viewModel: ReceiptViewModel
    var onCapture: () -> Void

    @State private var cameraBox = CameraBox()
    @State private var showPhotoPicker = false
    @State private var isDismissing = false
    @Environment(\.dismiss) private var dismiss

    private var camera: CameraManager { cameraBox.manager }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            CameraPreviewView(session: camera.session)
                .ignoresSafeArea()

            // Covers preview before navigation animation starts — prevents GPU competition
            if isDismissing {
                Color.black.ignoresSafeArea()
            }

            // Processing overlay
            if viewModel.isScanning {
                Color.black.opacity(0.6).ignoresSafeArea()
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                        .scaleEffect(1.5)
                    Text("Распознаём чек...")
                        .foregroundStyle(.white)
                        .font(.headline)
                }
            }

            VStack {
                // Close button (top-left)
                HStack {
                    Button { startDismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(.black.opacity(0.4), in: Circle())
                    }
                    .padding(.leading, 16)
                    Spacer()
                }
                .padding(.top, 8)

                Spacer()

                // Bottom bar: [back] [capture] [gallery]
                HStack {
                    Spacer()

                    // Left: back button
                    Button { startDismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 52, height: 52)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    .disabled(viewModel.isScanning)

                    Spacer()

                    // Center: capture button
                    Button {
                        camera.capture { image in
                            Task { await viewModel.process(image: image) }
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .stroke(.white, lineWidth: 3)
                                .frame(width: 80, height: 80)
                            Circle()
                                .fill(.white)
                                .frame(width: 66, height: 66)
                        }
                    }
                    .disabled(viewModel.isScanning)

                    Spacer()

                    // Right: gallery button
                    Button { showPhotoPicker = true } label: {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 22))
                            .foregroundStyle(.white)
                            .frame(width: 52, height: 52)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    .disabled(viewModel.isScanning)

                    Spacer()
                }
                .padding(.bottom, 48)
            }
        }
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            viewModel.items = []
            viewModel.scannedReceiptImageJPEGData = nil
            camera.requestAccessAndStart()
        }
        .onDisappear { camera.stop() }
        .photosPicker(isPresented: $showPhotoPicker, selection: $viewModel.selectedPhoto, matching: .images)
        .onChange(of: viewModel.items.count) { _, count in
            if count > 0 { onCapture() }
        }
        .alert("Ошибка", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private func startDismiss() {
        guard !isDismissing else { return }
        isDismissing = true
        camera.stop()
        // Dismiss after one run loop cycle so the black overlay renders first
        DispatchQueue.main.async { dismiss() }
    }
}

// MARK: - Camera Box (@Observable wrapper for CameraManager)

@Observable
private final class CameraBox {
    let manager = CameraManager()
}

// MARK: - Camera Manager

private final class CameraManager: NSObject {
    let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private var captureHandler: ((UIImage) -> Void)?

    func requestAccessAndStart() {
        Task {
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            guard granted else { return }
            setup()
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.session.startRunning()
            }
        }
    }

    private func setup() {
        guard session.inputs.isEmpty else { return }
        session.beginConfiguration()
        session.sessionPreset = .photo

        guard
            let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
            let input = try? AVCaptureDeviceInput(device: device),
            session.canAddInput(input)
        else {
            session.commitConfiguration()
            return
        }

        session.addInput(input)
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
        }
        session.commitConfiguration()
    }

    func stop() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.stopRunning()
        }
    }

    func capture(completion: @escaping (UIImage) -> Void) {
        guard session.isRunning else { return }
        captureHandler = completion
        photoOutput.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
    }
}

extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        guard error == nil,
              let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else { return }
        DispatchQueue.main.async { [weak self] in
            self?.captureHandler?(image)
            self?.captureHandler = nil
        }
    }
}

// MARK: - Camera Preview

private struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView { PreviewView(session: session) }
    func updateUIView(_ view: PreviewView, context: Context) {}

    final class PreviewView: UIView {
        private let previewLayer: AVCaptureVideoPreviewLayer

        init(session: AVCaptureSession) {
            previewLayer = AVCaptureVideoPreviewLayer(session: session)
            super.init(frame: .zero)
            previewLayer.videoGravity = .resizeAspectFill
            layer.addSublayer(previewLayer)
        }

        required init?(coder: NSCoder) { fatalError() }

        override func layoutSubviews() {
            super.layoutSubviews()
            previewLayer.frame = bounds
        }
    }
}
