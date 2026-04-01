import SwiftUI
import PhotosUI

struct ContentView: View {

    @State private var vm = ReceiptViewModel()
    @State private var showCamera = false
    @State private var showPhotoPicker = false

    var body: some View {
        NavigationStack {
            Group {
                if vm.isScanning {
                    ProgressView("Распознаём чек...")
                } else if vm.items.isEmpty {
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
                    Task { await vm.process(image: image) }
                }
                .ignoresSafeArea()
            }
            .photosPicker(isPresented: $showPhotoPicker, selection: $vm.selectedPhoto, matching: .images)
            .alert("Ошибка", isPresented: .constant(vm.errorMessage != nil)) {
                Button("OK") { vm.errorMessage = nil }
            } message: {
                Text(vm.errorMessage ?? "")
            }
        }
    }

    // MARK: - Subviews

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
                ForEach(vm.items) { item in
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
                    Text(vm.total, format: .currency(code: "RUB"))
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
                if !vm.items.isEmpty {
                    Divider()
                    Button("Очистить", systemImage: "trash", role: .destructive) {
                        vm.items = []
                    }
                }
            } label: {
                Image(systemName: "plus")
            }
        }
    }
}

// MARK: - Camera bridge (UIKit required — SwiftUI has no native camera API)

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
    ContentView()
}

#Preview("С позициями") {
    // Превью напрямую показывает список — без необходимости пробрасывать vm
    NavigationStack {
        List {
            Section("Позиции") {
                ForEach([
                    ReceiptItem(name: "Молоко 3.2%", amount: 89.90),
                    ReceiptItem(name: "Хлеб белый", amount: 45.00),
                    ReceiptItem(name: "Кефир 1л", amount: 67.50),
                    ReceiptItem(name: "Масло сливочное", amount: 210.00),
                ]) { item in
                    HStack {
                        Text(item.name).lineLimit(2)
                        Spacer()
                        Text(item.amount, format: .currency(code: "RUB")).monospacedDigit()
                    }
                }
            }
            Section {
                HStack {
                    Text("Итого").bold()
                    Spacer()
                    Text(Decimal(412.40), format: .currency(code: "RUB")).bold().monospacedDigit()
                }
            }
        }
        .navigationTitle("Сканер чеков")
    }
}
