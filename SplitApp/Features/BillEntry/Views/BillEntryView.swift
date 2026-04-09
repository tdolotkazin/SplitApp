import SwiftUI

struct BillEntryView: View {
    @StateObject private var viewModel = BillViewModel()
    @State private var showParticipantSheet = false
    @State private var showSavingAnimation = false
    @State private var savingTextOffset: CGFloat = 0
    @State private var savingTextOpacity: Double = 0
    @Environment(\.dismiss) private var dismiss

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

                VStack(spacing: 0) {
                    receiptNameField
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 4)

                    HeaderRow()
                        .onTapGesture {
                            hideKeyboard()
                        }

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
                            .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                        }
                        .onDelete { indexSet in
                            indexSet.forEach { index in
                                let item = viewModel.items[index]
                                viewModel.removeItem(id: item.id)
                            }
                        }

                        Color.clear
                            .frame(height: BillEntryLayout.bottomPanelReservedSpace)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                hideKeyboard()
                            }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .animation(nil, value: viewModel.items.count)
                }

                if showSavingAnimation {
                    savingOverlay
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
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") {
                        dismiss()
                    }
                    .foregroundStyle(AppTheme.textSecondary)
                    .font(.system(size: 17))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") {
                        triggerSave()
                    }
                    .foregroundStyle(AppTheme.accent)
                    .font(.system(size: 17, weight: .semibold))
                }
            }
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
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

    private var receiptNameField: some View {
        TextField("Название чека", text: $viewModel.receiptName)
            .font(.system(size: 20, weight: .semibold, design: .rounded))
            .foregroundStyle(AppTheme.textPrimary)
            .multilineTextAlignment(.center)
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(AppTheme.accent.opacity(0.25), lineWidth: 1)
            )
    }

    private var savingOverlay: some View {
        ZStack {
            Color.black.opacity(0.01)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            Text(viewModel.receiptName.isEmpty ? "Чек" : viewModel.receiptName)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.accent)
                .shadow(color: AppTheme.accent.opacity(0.6), radius: 16, y: 4)
                .offset(y: savingTextOffset)
                .opacity(savingTextOpacity)
                .allowsHitTesting(false)
        }
    }

    private func triggerSave() {
        hideKeyboard()
        viewModel.save()

        showSavingAnimation = true
        savingTextOffset = 0
        savingTextOpacity = 0

        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            savingTextOpacity = 1
        }

        withAnimation(.spring(response: 0.7, dampingFraction: 0.65).delay(0.15)) {
            savingTextOffset = -160
            savingTextOpacity = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            showSavingAnimation = false
            savingTextOffset = 0
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
                triggerSave()
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 8)
        }
    }
}

private enum BillEntryLayout {
    static let bottomPanelReservedSpace: CGFloat = 228
}

#Preview {
    BillEntryView()
}
