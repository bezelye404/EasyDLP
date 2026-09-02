import SwiftUI

// MARK: - Quality Picker

struct QualityPicker: View {
    @Binding var selectedQuality: VideoQuality

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Video Quality")
                .font(.headline)

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible()), count: 3),
                spacing: 6
            ) {
                ForEach(VideoQuality.allCases) { quality in
                    QualityBadge(
                        quality: quality,
                        isSelected: selectedQuality == quality
                    )
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            selectedQuality = quality
                        }
                    }
                }
            }
        }
        .cardStyle()
    }
}

// MARK: - Quality Badge

struct QualityBadge: View {
    let quality: VideoQuality
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 3) {
            Text(quality.badge)
                .font(.system(size: 13, weight: .semibold, design: .rounded))

            Text(quality.shortName)
                .font(.caption2)
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
