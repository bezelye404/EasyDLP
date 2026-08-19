import Foundation

// MARK: - Download Options

struct DownloadOptions {
    var quality: VideoQuality = .fullHD
    var subtitleLanguage: SubtitleLanguage = .english
    var customSubtitleCode: String = ""
    var customFormatId: String = ""
    var playlistRange: PlaylistRange = .all

    var effectiveSubtitleCode: String {
        if subtitleLanguage == .custom {
            return customSubtitleCode.isEmpty ? "en" : customSubtitleCode
        }
        return subtitleLanguage.rawValue
    }
}

// MARK: - Playlist Range

enum PlaylistRange: Equatable {
    case all
    case range(start: Int, end: Int)

    var displayText: String {
        switch self {
        case .all: "Entire playlist"
        case .range(let start, let end): "Videos \(start) to \(end)"
        }
    }
}
