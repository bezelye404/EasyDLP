import Foundation
import Observation

// MARK: - Download Mode

enum DownloadMode: String, CaseIterable, Identifiable, Codable {
    case bestVideo
    case audioOnly
    case selectQuality
    case playlist
    case videoWithSubtitles
    case subtitleOnly
    case customFormat

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .bestVideo: "Best Quality Video"
        case .audioOnly: "Audio Only (MP3)"
        case .selectQuality: "Select Video Quality"
        case .playlist: "Download Playlist"
        case .videoWithSubtitles: "Video with Subtitles"
        case .subtitleOnly: "Subtitle Only"
        case .customFormat: "Custom Format"
        }
    }

    var systemImage: String {
        switch self {
        case .bestVideo: "film"
        case .audioOnly: "music.note"
        case .selectQuality: "slider.horizontal.3"
        case .playlist: "list.bullet.rectangle"
        case .videoWithSubtitles: "captions.bubble"
        case .subtitleOnly: "text.bubble"
        case .customFormat: "wrench.and.screwdriver"
        }
    }

    var description: String {
        switch self {
        case .bestVideo: "Grabs the highest quality video and audio as MP4"
        case .audioOnly: "Extract audio and convert to MP3"
        case .selectQuality: "Choose from 360p to 4K resolution"
        case .playlist: "Download entire playlist or a specific range"
        case .videoWithSubtitles: "Download video with embedded subtitles"
        case .subtitleOnly: "Download subtitle files (.srt) only"
        case .customFormat: "Pick a specific format from available options"
        }
    }
}

// MARK: - Download Status

enum DownloadStatus: Equatable {
    case queued
    case fetching
    case downloading(progress: Double, speed: String?, eta: String?)
    case merging
    case converting
    case completed
    case failed(error: String)
    case cancelled

    var isActive: Bool {
        switch self {
        case .queued, .fetching, .downloading, .merging, .converting:
            return true
        default:
            return false
        }
    }

    var displayText: String {
        switch self {
        case .queued: return "Queued"
        case .fetching: return "Fetching info…"
        case .downloading(let p, let speed, let eta):
            var text = "\(Int(p * 100))%"
            if let speed { text += " · \(speed)" }
            if let eta { text += " · ETA \(eta)" }
            return text
        case .merging: return "Merging formats…"
        case .converting: return "Converting audio…"
        case .completed: return "Completed"
        case .failed(let error): return "Failed: \(error)"
        case .cancelled: return "Cancelled"
        }
    }

    var progress: Double {
        switch self {
        case .downloading(let p, _, _): p
        case .completed: 1.0
        default: 0
        }
    }
}

// MARK: - Download Task

@Observable
class DownloadTask: Identifiable {
    let id: UUID
    let url: String
    let mode: DownloadMode
    let options: DownloadOptions
    let createdAt: Date

    var title: String?
    var status: DownloadStatus
    var outputPath: URL?
    var process: Process?
    var outputLines: [String] = []

    var displayTitle: String {
        title ?? url
    }

    var fileTypeIcon: String {
        switch mode {
        case .audioOnly: "music.note"
        case .subtitleOnly: "doc.text"
        default: "film"
        }
    }

    init(url: String, mode: DownloadMode, options: DownloadOptions) {
        self.id = UUID()
        self.url = url
        self.mode = mode
        self.options = options
        self.status = .queued
        self.createdAt = Date()
    }
}
