import SwiftUI
import PhotosUI

struct EventsFlowView: View {
    @StateObject private var viewModel = EventsFlowViewModel()
    @State private var selectedPhoto: PhotosPickerItem?

    var body: some View {
        NavigationStack(path: $viewModel.path) {
            EventsHomeView(
                viewModel: viewModel.homeViewModel,
                onScanTap: viewModel.openScanOptions,
                onAddTap: viewModel.openBillEntry
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
            .sheet(isPresented: $viewModel.showBillEntry) {
                BillEntryView()
                    .presentationDragIndicator(.visible)
                    .interactiveDismissDisabled()
            }
            .confirmationDialog("Сканировать чек", isPresented: $viewModel.showScanOptions) {
                Button("Камера") { viewModel.showCamera = true }
                Button("Галерея") { viewModel.showPhotoPicker = true }
                Button("Отмена", role: .cancel) {}
            }
            .sheet(isPresented: $viewModel.showCamera) {
                CameraPickerSheet { image in
                    viewModel.showCamera = false
                    Task { await viewModel.didCaptureImage(image) }
                }
                .ignoresSafeArea()
            }
            .photosPicker(isPresented: $viewModel.showPhotoPicker, selection: $selectedPhoto, matching: .images)
            .onChange(of: selectedPhoto) { _, photo in
                guard let photo else { return }
                selectedPhoto = nil
                Task {
                    guard let data = try? await photo.loadTransferable(type: Data.self),
                          let image = UIImage(data: data) else { return }
                    await viewModel.didCaptureImage(image)
                }
            }
        }
    }
}

private struct CameraPickerSheet: UIViewControllerRepresentable {
    let onCapture: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onCapture: onCapture) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onCapture: (UIImage) -> Void
        init(onCapture: @escaping (UIImage) -> Void) { self.onCapture = onCapture }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            picker.dismiss(animated: true)
            if let image = info[.originalImage] as? UIImage { onCapture(image) }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

#Preview {
    EventsFlowView()
}
