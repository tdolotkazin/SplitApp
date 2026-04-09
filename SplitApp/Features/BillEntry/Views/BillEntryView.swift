import SwiftUI

struct BillEntryView: View {
    @StateObject private var viewModel: BillViewModel
    @StateObject private var keyboardObserver = KeyboardObserver()
    @State private var showParticipantSheet = false
    @State private var showSavingAnimation = false
    @State private var savingTextOffset: CGFloat = 0
    @State private var savingTextOpacity: Double = 0
    @FocusState private var isReceiptTitleFocused: Bool
    @Environment(\.dismiss) private var dismiss

    init(viewModel: BillViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
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
                } else if let errorMessage = viewModel.loadErrorMessage, viewModel.items.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(.orange)

                        Text(errorMessage)
                            .font(.system(size: 17, weight: .medium, design: .rounded))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 24)
                } else {
                    VStack(spacing: 0) {
                        receiptTitleCard
                        billTableHeader

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
                                        EdgeInsets(
                                            top: 4,
                                            leading: 20,
                                            bottom: 4,
                                            trailing: 20
                                        )
                                    )
                                    .id(item.id)
                                }
                                .onDelete { indexSet in
                                    indexSet.forEach { index in
                                        let item = viewModel.items[index]
                                        viewModel.removeItem(id: item.id)
                                    }
                                }
                                .onChange(of: viewModel.items.count) { oldCount, newCount in
                                    if newCount > oldCount, let lastItem = viewModel.items.last {
                                        withAnimation(
                                            .spring(response: 0.5, dampingFraction: 0.8)
                                        ) {
                                            proxy.scrollTo(lastItem.id, anchor: .bottom)
                                        }
                                    }
                                }

                                Color.clear
                                    .frame(height: BillEntryLayout.bottomPanelReservedSpace)
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(
                                        EdgeInsets(
                                            top: 0,
                                            leading: 20,
                                            bottom: 0,
                                            trailing: 20
                                        )
                                    )
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        hideKeyboard()
                                    }
                            }
                            .listStyle(.plain)
                            .scrollContentBackground(.hidden)
                            .background(Color.clear)
                        }

                        if !keyboardObserver.isVisible {
                            bottomActionPanel
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    .animation(
                        .spring(response: 0.35, dampingFraction: 0.8),
                        value: keyboardObserver.isVisible
                    )
                    .simultaneousGesture(
                        TapGesture().onEnded { _ in
                            if keyboardObserver.isVisible {
                                hideKeyboard()
                            }
                        }
                    )
                }
            }
            .navigationTitle(viewModel.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена", action: dismissView)
                        .foregroundStyle(AppTheme.textSecondary)
                        .font(.system(size: 17))
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

    private var receiptTitleCard: some View {
        GlassCard(padding: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text("НАЗВАНИЕ ЧЕКА")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .tracking(1.1)
                    .foregroundStyle(AppTheme.textSecondary)

                TextField("Например: ужин в пятницу", text: $viewModel.receiptTitle)
                    .font(AppTheme.fontBody)
                    .foregroundStyle(AppTheme.textPrimary)
                    .focused($isReceiptTitleFocused)
                    .textInputAutocapitalization(.sentences)
                    .submitLabel(.done)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)
                    .background(
                        isReceiptTitleFocused
                            ? AppTheme.inputBackgroundFocused
                            : AppTheme.inputBackground
                    )
                    .clipShape(
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall)
                            .stroke(
                                isReceiptTitleFocused ? AppTheme.accent : Color.clear,
                                lineWidth: 1.5
                            )
                    )
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    private var billTableHeader: some View {
        HStack(spacing: 12) {
            Text("ПОЗИЦИЯ")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .tracking(1.1)
                .foregroundStyle(AppTheme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("СТОИМОСТЬ")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .tracking(1.1)
                .foregroundStyle(AppTheme.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(width: BillEntryColumns.amountWidth, alignment: .center)

            Text("ЧЬЁ")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .tracking(1.1)
                .foregroundStyle(AppTheme.textSecondary)
                .frame(width: BillEntryColumns.participantWidth, alignment: .center)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 4)
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

            GlassButton(title: viewModel.saveButtonTitle) {
                saveAndDismiss()
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 8)
            .disabled(!viewModel.canSave)
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
    let deps = AppDependencies.preview
    BillEntryView(
        viewModel: BillViewModel(
            mode: .create(eventId: nil, scannedItems: [], receiptImageJPEGData: nil),
            eventsRepository: deps.eventsRepository,
            receiptsRepository: deps.receiptsRepository,
            usersRepository: deps.usersRepository,
            networkMonitor: deps.networkMonitor
        )
    )
}
