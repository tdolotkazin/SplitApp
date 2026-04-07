import SwiftUI

struct SearchBar: View {
    @Binding var searchText: String
    @FocusState private var isFocused: Bool


    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(AppTheme.textTertiary.opacity(0.6))

            TextField("Поиск", text: $searchText)
                .font(.system(size: 17, weight: .regular, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
                .focused($isFocused)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

            if !searchText.isEmpty {
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        searchText = ""
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(AppTheme.textTertiary.opacity(0.6))
                }
                .buttonStyle(PlainButtonStyle())
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isFocused ? AppTheme.inputBackgroundFocused : AppTheme.inputBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isFocused ? AppTheme.accent.opacity(0.3) : Color.clear, lineWidth: 1.5)
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isFocused)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: searchText.isEmpty)
    }
}
