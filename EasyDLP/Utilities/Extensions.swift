import SwiftUI

// MARK: - Brand Colors

extension Color {
    /// Primary accent — uses the system accent color for a native macOS feel
    static let brandAccent = Color.accentColor
}

// MARK: - View Modifiers

extension View {
    func cardStyle() -> some View {
        self
            .padding(14)
            .background(.background, in: RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.primary.opacity(0.06), lineWidth: 0.5)
            )
    }

    func primaryButton() -> some View {
        self
            .font(.body.weight(.medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 6))
    }
}

// MARK: - URL Validation

extension String {
    var isValidURL: Bool {
        guard let url = URL(string: self),
              let scheme = url.scheme,
              !scheme.isEmpty,
              url.host != nil
        else { return false }
        return ["http", "https"].contains(scheme.lowercased())
    }
}

// MARK: - Date Formatting

extension Date {
    var timeAgoDisplay: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}
