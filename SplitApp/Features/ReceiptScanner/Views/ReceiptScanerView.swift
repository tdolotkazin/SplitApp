import SwiftUI
import PhotosUI

struct ReceiptScannerView: View {

    @Bindable var viewModel: ReceiptScannerViewModel
    var onCapture: () -> Void

    @State private var showCamera = false
    @State private var showPhotoPicker = false

    var body: some View {
        Group {
            if viewModel.isScanning {
                ProgressView("Распознаём чек...")
            } else if viewModel.items.isEmpty {
                emptyState
            } else {
                itemsList
            }
        }
        .navigationTitle("Сканер чеков")
        .toolbar { toolbarContent }
        .sheet(isPresented: $showCamera) {
            CameraSheet { image in
                showCamera = false
                Task {
                    await viewModel.process(image: image)
                    onCapture()
                }
            }
            .ignoresSafeArea()
        }
        .photosPicker(isPresented: $showPhotoPicker, selection: $viewModel.selectedPhoto, matching: .images)
        .alert("Ошибка", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }


    private var emptyState: some View {
        ContentUnavailableView(
            "Нет данных",
            systemImage: "doc.text.viewfinder",
            description: Text("Сфотографируйте чек или выберите из галереи")
        )
    }

    private var itemsList: some View {
        List {
            Section("Позиции") {
                ForEach(viewModel.items) { item in
                    HStack {
                        Text(item.name).lineLimit(2)
                        Spacer()
                        Text(item.amount, format: .currency(code: "RUB"))
                            .monospacedDigit()
                    }
                }
            }
            Section {
                HStack {
                    Text("Итого").bold()
                    Spacer()
                    Text(viewModel.total, format: .currency(code: "RUB"))
                        .bold().monospacedDigit()
                }
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Menu {
                Button("Камера", systemImage: "camera") { showCamera = true }
                Button("Галерея", systemImage: "photo") { showPhotoPicker = true }
                if !viewModel.items.isEmpty {
                    Divider()
                    Button("Очистить", systemImage: "trash", role: .destructive) {
                        viewModel.items = []
                    }
                }
            } label: {
                Image(systemName: "plus")
            }
        }
    }
}


private struct CameraSheet: UIViewControllerRepresentable {

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

#Preview("Пустой экран") {
    ReceiptScannerView(viewModel: ReceiptScannerViewModel(), onCapture: {})
}
