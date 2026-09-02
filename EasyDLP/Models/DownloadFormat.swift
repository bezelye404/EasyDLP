import Foundation

// MARK: - Video Quality

enum VideoQuality: String, CaseIterable, Identifiable {
    case uhd4k = "2160"
    case qhd2k = "1440"
    case fullHD = "1080"
    case hd = "720"
    case sd = "480"
    case low = "360"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .uhd4k: "2160p (4K UHD)"
        case .qhd2k: "1440p (2K QHD)"
        case .fullHD: "1080p (Full HD)"
        case .hd: "720p (HD)"
        case .sd: "480p (SD)"
        case .low: "360p"
        }
    }

    var shortName: String {
        "\(rawValue)p"
    }

    var badge: String {
        switch self {
        case .uhd4k: "4K"
        case .qhd2k: "2K"
        case .fullHD: "FHD"
        case .hd: "HD"
        case .sd: "SD"
        case .low: "360"
        }
    }
}

// MARK: - Subtitle Language

enum SubtitleLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case turkish = "tr"
    case german = "de"
    case french = "fr"
    case spanish = "es"
    case all = "all"
    case custom = "custom"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .english: "English"
        case .turkish: "Turkish"
        case .german: "German"
        case .french: "French"
        case .spanish: "Spanish"
        case .all: "All Available"
        case .custom: "Custom Code"
        }
    }

    var flag: String {
        switch self {
        case .english: "🇬🇧"
        case .turkish: "🇹🇷"
        case .german: "🇩🇪"
        case .french: "🇫🇷"
        case .spanish: "🇪🇸"
        case .all: "🌍"
        case .custom: "🏳️"
        }
    }
}

// MARK: - Format Info (for Custom Format listing)

struct FormatInfo: Identifiable {
    let id: String
    let ext: String
    let resolution: String?
    let filesize: String?
    let note: String?
    let vcodec: String?
    let acodec: String?

    var isVideoOnly: Bool { acodec == "none" || acodec == nil }
    var isAudioOnly: Bool { vcodec == "none" || vcodec == nil }
}
