import SwiftUI

struct BillEntryView: View {
    @StateObject private var viewModel = BillViewModel()
    @StateObject private var keyboardObserver = KeyboardObserver()
    @State private var showParticipantSheet = false
    @State private var emojis: [EmojiPredictModel] = []

    @Environment(\.dismiss) private var dismiss

    private var matcher: EmojiAutoReplaceMatcher {
        EmojiAutoReplaceMatcher(emojis: emojis)
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

                VStack(spacing: 0) {
                    HeaderRow()
                        .padding(.top, 8)
                        .onTapGesture {
                            hideKeyboard()
                        }

                    ScrollViewReader { proxy in
                        List {
                            ForEach(viewModel.items) { item in
                                BillItemRow(
                                    item: item,
                                    matcher: matcher,
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
                                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                        proxy.scrollTo(lastItem.id, anchor: .bottom)
                                    }
                                }
                            }

                            Color.clear
                                .frame(height: 300)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    hideKeyboard()
                                }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                        .animation(.spring(response: 0.5, dampingFraction: 0.75), value: viewModel.items.count)
                    }

                    Spacer()
                        .contentShape(Rectangle())
                        .onTapGesture {
                            hideKeyboard()
                        }

                    if !keyboardObserver.isVisible {
                        AddItemButton {
                            viewModel.addItem()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .transition(.move(edge: .bottom).combined(with: .opacity))

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
                        .transition(.move(edge: .bottom).combined(with: .opacity))

                        GlassButton(title: "Разделить счёт") {
                            viewModel.save()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 8)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: keyboardObserver.isVisible)
                .simultaneousGesture(
                    TapGesture().onEnded { _ in
                        if keyboardObserver.isVisible {
                            hideKeyboard()
                        }
                    }
                )
            }
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
            .task {
                loadEmojis()
            }
        }
    }

    private func loadEmojis() {
        do {
            let parser = EmojiTextParser()
            emojis = try parser.parse()
        } catch {
            print(error.localizedDescription)
        }
    }
}
