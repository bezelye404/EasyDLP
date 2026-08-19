import SwiftUI

// MARK: - Brand Colors

extension Color {
    static let brandGold = Color(hue: 0.12, saturation: 0.85, brightness: 0.95)
    static let brandAmber = Color(hue: 0.08, saturation: 0.90, brightness: 0.85)
    static let brandOrange = Color(hue: 0.05, saturation: 0.85, brightness: 0.90)

    static let brandGradientStart = Color(hue: 0.13, saturation: 0.80, brightness: 1.0)
    static let brandGradientEnd = Color(hue: 0.06, saturation: 0.90, brightness: 0.90)
}

// MARK: - Brand Gradient

extension LinearGradient {
    static let brand = LinearGradient(
        colors: [.brandGradientStart, .brandGradientEnd],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - View Modifiers

extension View {
    func cardStyle() -> some View {
        self
            .padding(16)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    func goldButton() -> some View {
        self
            .font(.headline)
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(LinearGradient.brand, in: Capsule())
            .shadow(color: .brandGold.opacity(0.3), radius: 8, y: 4)
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
