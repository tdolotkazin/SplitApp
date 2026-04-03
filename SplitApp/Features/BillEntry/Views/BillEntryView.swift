import SwiftUI

struct BillEntryView: View {
    @StateObject private var viewModel = BillViewModel()
    @StateObject private var keyboardObserver = KeyboardObserver()
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var showParticipantSheet = false
    @State private var selectedTab: TabItem = .events
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
                                            amount: amount,
                                            assignedTo: nil
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
                                    .font(.title2.bold())
                                    .foregroundStyle(AppTheme.textPrimary)
                                Spacer()
                                Text("€\(NSDecimalNumber(decimal: viewModel.total).stringValue)")
                                    .font(.title.bold())
                                    .foregroundStyle(AppTheme.accent)
                                    .contentTransition(.numericText())
                            }
                        }
                        .padding(.horizontal, 20)
                        .transition(.move(edge: .bottom).combined(with: .opacity))

                        GlassButton(title: "Разделить счёт") {
                            viewModel.save()
                            dismiss()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 8)
                        .transition(.move(edge: .bottom).combined(with: .opacity))

                        CustomTabBar(selectedTab: $selectedTab)
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
                        dismiss()
                    }
                    .foregroundStyle(AppTheme.accent)
                    .font(.system(size: 17, weight: .semibold))
                }
            }
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(themeManager.currentTheme == .light ? .light : .dark, for: .navigationBar)
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
        .preferredColorScheme(themeManager.currentTheme == .light ? .light : .dark)
    }
}

#Preview {
    BillEntryView()
}
