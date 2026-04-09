import SwiftUI

struct EventPickerView: View {
    @ObservedObject var viewModel: EventsHomeViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var eventToDelete: EventListItem?
    @State private var showDeleteConfirmation = false
    @State private var showCreateSheet = false
    @State private var newEventName = ""
    @State private var nameIsDuplicate = false
    @State private var shakeOffset: CGFloat = 0
    @FocusState private var isNameFieldFocused: Bool

    var body: some View {
        ZStack {
            AppTheme.backgroundGradient.ignoresSafeArea()
            AppTheme.backgroundRadialGlow.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    // MARK: - Выбранное событие
                    sectionLabel("ВЫБРАННОЕ СОБЫТИЕ")
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 10)

                    Group {
                        if let current = viewModel.currentEvent {
                            CurrentEventCardView(event: current)
                        } else {
                            emptySelectionCard
                        }
                    }
                    .padding(.horizontal, 20)

                    // MARK: - Заголовок списка
                    HStack(alignment: .center) {
                        sectionLabel("ВЫБРАТЬ СОБЫТИЕ")
                        Spacer()
                        Button {
                            newEventName = ""
                            showCreateSheet = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "plus")
                                    .font(.system(size: 13, weight: .bold))
                                Text("Новое")
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(AppTheme.accentGradient)
                            .foregroundStyle(AppTheme.accentForeground)
                            .clipShape(Capsule())
                            .shadow(color: AppTheme.accent.opacity(0.35), radius: 8, y: 3)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 10)

                    // MARK: - Список событий
                    LazyVStack(spacing: 8) {
                        ForEach(viewModel.latestEvents) { event in
                            eventCard(event)
                                .padding(.horizontal, 20)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        eventToDelete = event
                                        showDeleteConfirmation = true
                                    } label: {
                                        Label("Удалить", systemImage: "trash.fill")
                                    }
                                }
                        }
                    }
                    .animation(.spring(response: 0.45, dampingFraction: 0.8), value: viewModel.latestEvents.map(\.id))
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationTitle("События")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .alert("Удалить событие?", isPresented: $showDeleteConfirmation) {
            Button("Удалить", role: .destructive) {
                guard let event = eventToDelete else { return }
                eventToDelete = nil
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                viewModel.deleteEvent(event)
            }
            Button("Отмена", role: .cancel) {
                eventToDelete = nil
            }
        } message: {
            Text("Событие «\(eventToDelete?.title ?? "")» будет удалено. Это действие нельзя отменить.")
        }
        .sheet(isPresented: $showCreateSheet) {
            createEventSheet
        }
    }

    // MARK: - Event Card

    private func eventCard(_ event: EventListItem) -> some View {
        let isSelected = event.id == viewModel.currentEvent?.id

        return Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                viewModel.selectEvent(event)
            }
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { dismiss() }
        } label: {
            GlassCard(padding: 14) {
                HStack(spacing: 12) {
                    Text(event.emoji)
                        .font(.system(size: 26))
                        .frame(width: 40, height: 40)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(event.title)
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundStyle(AppTheme.textPrimary)
                        Text(event.subtitle)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(AppTheme.textSecondary)
                    }

                    Spacer()

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(AppTheme.accent)
                            .transition(.scale.combined(with: .opacity))
                    } else {
                        Text(event.amount.euroText(signed: true, minimumFractionDigits: 0))
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(amountColor(for: event.tone))
                    }
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .stroke(isSelected ? AppTheme.accent : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isSelected)
    }

    // MARK: - Create Event Sheet

    private var createEventSheet: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient.ignoresSafeArea()
                AppTheme.backgroundRadialGlow.ignoresSafeArea()

                VStack(spacing: 24) {
                    Text("📌")
                        .font(.system(size: 56))
                        .padding(.top, 32)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("НАЗВАНИЕ СОБЫТИЯ")
                            .font(.system(size: 12, weight: .semibold))
                            .tracking(1.2)
                            .foregroundStyle(AppTheme.textSecondary)
                            .padding(.horizontal, 4)

                        TextField("Например, День рождения", text: $newEventName)
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundStyle(AppTheme.textPrimary)
                            .tint(AppTheme.accent)
                            .padding(.vertical, 14)
                            .padding(.horizontal, 16)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .strokeBorder(
                                        nameIsDuplicate ? Color.red :
                                            isNameFieldFocused ? AppTheme.accent : AppTheme.accent.opacity(0.2),
                                        lineWidth: (nameIsDuplicate || isNameFieldFocused) ? 2 : 1
                                    )
                            )
                            .focused($isNameFieldFocused)
                            .offset(x: shakeOffset)
                            .onChange(of: newEventName) { _, _ in
                                if nameIsDuplicate { nameIsDuplicate = false }
                            }
                            .onSubmit { submitCreate() }

                        if nameIsDuplicate {
                            Text("Событие с таким названием уже существует")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(.red)
                                .padding(.horizontal, 4)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .padding(.horizontal, 20)

                    GlassButton(
                        title: viewModel.isCreatingEvent ? "Создание…" : "Создать событие"
                    ) {
                        submitCreate()
                    }
                    .padding(.horizontal, 20)
                    .disabled(
                        viewModel.isCreatingEvent ||
                        newEventName.trimmingCharacters(in: .whitespaces).isEmpty
                    )
                    .opacity(newEventName.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
                    .animation(.easeInOut(duration: 0.2), value: newEventName.isEmpty)

                    Spacer()
                }
            }
            .navigationTitle("Новое событие")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") { showCreateSheet = false }
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .onAppear { isNameFieldFocused = true }
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Helpers

    private func submitCreate() {
        let name = newEventName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty, !viewModel.isCreatingEvent else { return }

        if viewModel.latestEvents.contains(where: { $0.title.lowercased() == name.lowercased() }) {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.3)) { shakeOffset = 10 }
            withAnimation(.spring(response: 0.2, dampingFraction: 0.3).delay(0.1)) { shakeOffset = -8 }
            withAnimation(.spring(response: 0.2, dampingFraction: 0.4).delay(0.2)) { shakeOffset = 0 }
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            nameIsDuplicate = true
            return
        }

        isNameFieldFocused = false
        Task {
            await viewModel.createEvent(name: name)
            showCreateSheet = false
            try? await Task.sleep(nanoseconds: 250_000_000)
            dismiss()
        }
    }

    private var emptySelectionCard: some View {
        GlassCard(padding: 14) {
            HStack(spacing: 12) {
                Text("❓").font(.system(size: 28))
                Text("Событие не выбрано")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
                Spacer()
            }
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold))
            .tracking(1.2)
            .foregroundStyle(AppTheme.textSecondary)
    }

    private func amountColor(for tone: EventAmountTone) -> Color {
        switch tone {
        case .positive: return Color(red: 0.17, green: 0.76, blue: 0.32)
        case .negative: return Color(red: 0.92, green: 0.29, blue: 0.29)
        case .neutral:  return AppTheme.textSecondary
        }
    }
}
