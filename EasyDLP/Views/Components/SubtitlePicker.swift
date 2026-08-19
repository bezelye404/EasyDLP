import SwiftUI

// MARK: - Subtitle Picker

struct SubtitlePicker: View {
    @Binding var selectedLanguage: SubtitleLanguage
    @Binding var customCode: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Subtitle Language")
                .font(.headline)

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible()), count: 4),
                spacing: 8
            ) {
                ForEach(SubtitleLanguage.allCases) { lang in
                    SubtitleBadge(
                        language: lang,
                        isSelected: selectedLanguage == lang
                    )
                    .onTapGesture {
                        withAnimation(.spring(duration: 0.2)) {
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
        VStack(spacing: 4) {
            Text(language.flag)
                .font(.title3)

            Text(language.displayName)
                .font(.caption2)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background {
            if isSelected {
                RoundedRectangle(cornerRadius: 8)
                    .fill(LinearGradient.brand)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.regularMaterial)
            }
        }
        .foregroundStyle(isSelected ? .white : .primary)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    isSelected ? Color.clear : Color.primary.opacity(0.1),
                    lineWidth: 1
                )
        )
        .scaleEffect(isSelected ? 1.04 : 1.0)
        .animation(.spring(duration: 0.2), value: isSelected)
        .contentShape(Rectangle())
    }
}
