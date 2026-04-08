import SwiftUI
import PhotosUI

struct EventsFlowView: View {
    @StateObject private var viewModel = EventsFlowViewModel()
    @State private var selectedPhoto: PhotosPickerItem?

    var body: some View {
        NavigationStack(path: $viewModel.path) {
            EventsHomeView(
                viewModel: viewModel.homeViewModel,
                onScanTap: { viewModel.showCamera = true },
                onAddTap: viewModel.openReceiptInput
            )
            .task {
                await viewModel.homeViewModel.loadDataIfNeeded()
                await viewModel.receiptInputViewModel.loadDraftIfNeeded()
            }
            .navigationDestination(for: EventRoute.self) { route in
                switch route {
                case .receiptInput:
                    ReceiptInputView(viewModel: viewModel.receiptInputViewModel)
                        .navigationBarBackButtonHidden(true)
                }
            }
            .sheet(isPresented: $viewModel.showCamera, onDismiss: {
                viewModel.handlePendingImage()
            }) {
                CameraPickerSheet(
                    onCapture: { image in viewModel.storeCapturedImage(image) },
                    onCancel: { viewModel.showCamera = false }
                )
                .ignoresSafeArea()
            }
            .photosPicker(isPresented: $viewModel.showPhotoPicker, selection: $selectedPhoto, matching: .images)
            .onChange(of: selectedPhoto) { photo in
                guard let photo else { return }
                selectedPhoto = nil
                Task {
                    guard let data = try? await photo.loadTransferable(type: Data.self),
                          let image = UIImage(data: data) else { return }
                    viewModel.storeCapturedImage(image)
                    viewModel.handlePendingImage()
                }
            }
        }
    }
}

// MARK: - Camera bridge

private struct CameraPickerSheet: UIViewControllerRepresentable {
    let onCapture: (UIImage) -> Void
    let onCancel: () -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onCapture: onCapture, onCancel: onCancel) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onCapture: (UIImage) -> Void
        let onCancel: () -> Void

        init(onCapture: @escaping (UIImage) -> Void, onCancel: @escaping () -> Void) {
            self.onCapture = onCapture
            self.onCancel = onCancel
        }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage { onCapture(image) }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onCancel()
        }
    }
}

#Preview {
    EventsFlowView()
}
