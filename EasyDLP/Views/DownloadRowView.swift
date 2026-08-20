import SwiftUI

// MARK: - Download Row View

struct DownloadRowView: View {
    let task: DownloadTask
    let onCancel: () -> Void
    let onRemove: () -> Void
    let onRetry: () -> Void
    let onReveal: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // File type icon
            fileIcon

            // Title, status, and progress
            VStack(alignment: .leading, spacing: 3) {
                Text(task.displayTitle)
                    .font(.body.weight(.medium))
                    .lineLimit(1)

                HStack(spacing: 5) {
                    statusBadge
                    Text(task.status.displayText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                if case .downloading(let progress, _, _) = task.status {
                    ProgressView(value: progress)
                        .tint(Color.accentColor)
                }
            }

            Spacer()

            // Time ago
            Text(task.createdAt.timeAgoDisplay)
                .font(.caption2)
                .foregroundStyle(.tertiary)

            // Action buttons
            actionButtons
        }
        .padding(.vertical, 4)
    }

    // MARK: - File Icon

    private var fileIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(statusColor.opacity(0.08))
                .frame(width: 36, height: 36)

            Image(systemName: task.fileTypeIcon)
                .font(.callout)
                .foregroundStyle(statusColor)
        }
    }

    // MARK: - Status Badge

    @ViewBuilder
    private var statusBadge: some View {
        switch task.status {
        case .downloading:
            Circle()
                .fill(Color.accentColor)
                .frame(width: 5, height: 5)

        case .merging, .converting, .fetching:
            ProgressView()
                .controlSize(.mini)

        case .completed:
            Image(systemName: "checkmark.circle.fill")
                .font(.caption2)
                .foregroundStyle(.green)

        case .failed:
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.caption2)
                .foregroundStyle(.red)

        case .cancelled:
            Image(systemName: "xmark.circle.fill")
                .font(.caption2)
                .foregroundStyle(.orange)

        case .queued:
            Image(systemName: "clock")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Action Buttons

    @ViewBuilder
    private var actionButtons: some View {
        HStack(spacing: 4) {
            if task.status.isActive {
                Button(action: onCancel) {
                    Image(systemName: "xmark.circle")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Cancel download")
            } else {
                if case .failed = task.status {
                    Button(action: onRetry) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Retry download")
                }

                if case .completed = task.status {
                    Button(action: onReveal) {
                        Image(systemName: "folder")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Reveal in Finder")
                }

                Button(action: onRemove) {
                    Image(systemName: "trash")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Remove from list")
            }
        }
    }

    // MARK: - Helpers

    private var statusColor: Color {
        switch task.status {
        case .downloading, .merging, .converting, .fetching: .accentColor
        case .completed: .green
        case .failed: .red
        case .cancelled: .orange
        case .queued: .secondary
        }
    }
}
