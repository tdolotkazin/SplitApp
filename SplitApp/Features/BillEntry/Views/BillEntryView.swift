import SwiftUI

struct BillEntryView: View {
    @StateObject private var viewModel = BillViewModel()
    @StateObject private var keyboardObserver = KeyboardObserver()
    @State private var showParticipantSheet = false
    @Environment(\.dismiss) private var dismiss

    init(mode: BillViewModel.Mode) {
        _viewModel = StateObject(wrappedValue: BillViewModel(mode: mode))
    }

    init(eventId: UUID? = nil) {
        _viewModel = StateObject(
            wrappedValue: BillViewModel(
                mode: .create(
                    eventId: eventId,
                    scannedItems: ScannedReceiptStore.shared.consume()
                )
            )
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ZStack {
                    AppTheme.backgroundGradient
                        .ignoresSafeArea()

                    AppTheme.backgroundRadialGlow
                        .ignoresSafeArea()
                }
                .dismissKeyboardOnTap()

                if viewModel.isLoading && viewModel.items.isEmpty {
                    ProgressView("Загрузка чека...")
                        .font(.system(size: 17, weight: .medium, design: .rounded))
                } else if let errorMessage = viewModel.loadErrorMessage,
                          viewModel.items.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(.orange)

                        Text(errorMessage)
                            .font(.system(size: 17, weight: .medium, design: .rounded))
                            .multilineTextAlignment(.center)

                        Button("Попробовать снова") {
                            Task {
                                await viewModel.reload()
                            }
                        }
                    }
                    .padding(24)
                } else {
                    VStack(spacing: 0) {
                        HeaderRow()
                            .padding(.top, 8)
                            .onTapGesture(perform: hideKeyboard)

                        if let statusMessage = viewModel.statusMessage {
                            let statusIcon = viewModel.isNetworkAvailable
                                ? "info.circle.fill"
                                : "wifi.slash"
                            let statusColor: Color = viewModel.isNetworkAvailable
                                ? AppTheme.accent
                                : .orange

                            HStack(spacing: 10) {
                                Image(systemName: statusIcon)
                                    .foregroundStyle(statusColor)

                                Text(statusMessage)
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundStyle(AppTheme.textSecondary)

                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .padding(.horizontal, 20)
                            .padding(.bottom, 8)
                        }

                        ScrollViewReader { proxy in
                            List {
                                ForEach(viewModel.items) { item in
                                    BillItemRow(
                                        item: item,
                                        onAssign: {
                                            viewModel.selectedItemForAssignment = item
                                            showParticipantSheet = true
                                        },
                                        onDelete: {
                                            viewModel.removeItem(id: item.id)
                                        },
                                        onUpdate: { name, amount in
                                            viewModel.updateItem(
                                                id: item.id,
                                                name: name,
                                                amount: amount
                                            )
                                        }
                                    )
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(
                                        EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0)
                                    )
                                    .id(item.id)
                                }
                                .onDelete { indexSet in
                                    indexSet.forEach { index in
                                        let item = viewModel.items[index]
                                        viewModel.removeItem(id: item.id)
                                    }
                                }

                                Color.clear
                                    .frame(height: 300)
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                                    .contentShape(Rectangle())
                                    .onTapGesture(perform: hideKeyboard)
                            }
                            .listStyle(.plain)
                            .scrollContentBackground(.hidden)
                            .animation(
                                .spring(response: 0.5, dampingFraction: 0.75),
                                value: viewModel.items.count
                            )
                            .onChange(of: viewModel.items.count) { oldCount, newCount in
                                guard newCount > oldCount,
                                      let lastItem = viewModel.items.last else {
                                    return
                                }

                                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                    proxy.scrollTo(lastItem.id, anchor: .bottom)
                                }
                            }
                        }

                        Spacer()
                            .contentShape(Rectangle())
                            .onTapGesture {
                                hideKeyboard()
                            }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .animation(nil, value: viewModel.items.count)
                }
            }
            .overlay(alignment: .bottom) {
                bottomActionPanel
                    .padding(.bottom, 8)
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .navigationTitle("Ввод чека")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 0) {
                        TextField("Название чека", text: $viewModel.receiptTitle)
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundStyle(AppTheme.textPrimary)
                            .tint(AppTheme.accent)
                            .multilineTextAlignment(.center)
                            .frame(minWidth: 150, maxWidth: 250)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(.ultraThinMaterial)
                            .background(AppTheme.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(AppTheme.cardBorder, lineWidth: 1)
                            )
                    }
                }

                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена", action: dismissView)
                    .foregroundStyle(AppTheme.textSecondary)
                    .font(.system(size: 17))
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово", action: saveAndDismiss)
                    .foregroundStyle(AppTheme.accent)
                    .font(.system(size: 17, weight: .semibold))
                    .disabled(!viewModel.canSave)
                }
            }
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .task {
                await load()
            }
            .sheet(isPresented: $showParticipantSheet) {
                let selectedId = viewModel.selectedItemForAssignment?.id
                let currentAssigned = selectedId.flatMap { id in
                    viewModel.items.first(where: { $0.id == id })?.assignedTo
                } ?? []

                ParticipantPickerSheet(
                    participants: viewModel.participants,
                    selectedParticipants: currentAssigned,
                    onToggle: { participant in
                        if let itemId = selectedId {
                            viewModel.toggleParticipant(to: itemId, participant: participant)
                        }
                    },
                    onDone: {
                        showParticipantSheet = false
                    }
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
        }
    }

    private var bottomActionPanel: some View {
        VStack(spacing: 0) {
            AddItemButton {
                viewModel.addItem()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)

            GlassCard {
                HStack {
                    Text("Итого")
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)
                    Spacer()
                    Text("€\(NSDecimalNumber(decimal: viewModel.total).stringValue)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.accent)
                        .contentTransition(.numericText())
                }
            }
            .padding(.horizontal, 20)

            GlassButton(title: "Разделить счёт") {
                saveAndDismiss()
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 8)
        }
    }

    private func load() async {
        await viewModel.load()
    }

    private func saveAndDismiss() {
        Task {
            if await viewModel.save() {
                dismiss()
            }
        }
    }

    private func dismissView() {
        dismiss()
    }
}

private enum BillEntryLayout {
    static let bottomPanelReservedSpace: CGFloat = 228
}

#Preview {
    BillEntryView()
}
