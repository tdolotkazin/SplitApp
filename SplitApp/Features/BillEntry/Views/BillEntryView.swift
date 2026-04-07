import SwiftUI

struct BillEntryView: View {
    @StateObject private var viewModel = BillViewModel()
    @State private var showParticipantSheet = false
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
                    HeaderRow()
                        .padding(.top, 8)
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
                                        amount: amount,
                                        assignedTo: nil
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
                        viewModel.save()
                    }
                    .foregroundStyle(AppTheme.accent)
                    .font(.system(size: 17, weight: .semibold))
                }
            }
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .sheet(isPresented: $showParticipantSheet) {
                ParticipantPickerSheet(
                    participants: viewModel.participants,
                    onSelect: { participant in
                        if let itemId = viewModel.selectedItemForAssignment?.id {
                            viewModel.assignParticipant(to: itemId, participant: participant)
                        }
                        showParticipantSheet = false
                    }
                )
                .presentationDetents([.medium, .fraction(0.5)])
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
                viewModel.save()
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
