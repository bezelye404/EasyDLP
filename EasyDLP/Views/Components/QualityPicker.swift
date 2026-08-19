import SwiftUI

// MARK: - Quality Picker

struct QualityPicker: View {
    @Binding var selectedQuality: VideoQuality

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Video Quality")
                .font(.headline)

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible()), count: 3),
                spacing: 8
            ) {
                ForEach(VideoQuality.allCases) { quality in
                    QualityBadge(
                        quality: quality,
                        isSelected: selectedQuality == quality
                    )
                    .onTapGesture {
                        withAnimation(.spring(duration: 0.2)) {
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
        VStack(spacing: 4) {
            Text(quality.badge)
                .font(.system(size: 14, weight: .heavy, design: .rounded))

            Text(quality.shortName)
                .font(.caption2)
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
