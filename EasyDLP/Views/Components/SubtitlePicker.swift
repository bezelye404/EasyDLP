import SwiftUI

// MARK: - Subtitle Picker

struct SubtitlePicker: View {
    @Binding var selectedLanguage: SubtitleLanguage
    @Binding var customCode: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Subtitle Language")
                .font(.headline)

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible()), count: 4),
                spacing: 6
            ) {
                ForEach(SubtitleLanguage.allCases) { lang in
                    SubtitleBadge(
                        language: lang,
                        isSelected: selectedLanguage == lang
                    )
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            selectedLanguage = lang
                        }
                    }
                }
            }

            if selectedLanguage == .custom {
                HStack {
                    Text("Language code:")
                        .foregroundStyle(.secondary)
                    TextField("e.g., ja, ko, pt", text: $customCode)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 140)
                }
                .padding(.top, 4)
                .transition(.opacity)
            }
        }
        .cardStyle()
    }
}

// MARK: - Subtitle Badge

struct SubtitleBadge: View {
    let language: SubtitleLanguage
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 3) {
            Text(language.flag)
                .font(.callout)

            Text(language.displayName)
                .font(.caption2)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background {
            if isSelected {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.accentColor)
            } else {
                RoundedRectangle(cornerRadius: 6)
                    .fill(.background)
            }
        }
        .foregroundStyle(isSelected ? .white : .primary)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(
                    isSelected ? Color.clear : Color.primary.opacity(0.06),
                    lineWidth: 0.5
                )
        )
        .animation(.easeInOut(duration: 0.15), value: isSelected)
        .contentShape(Rectangle())
    }
}
