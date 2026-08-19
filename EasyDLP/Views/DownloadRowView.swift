import SwiftUI

// MARK: - Download Row View

struct DownloadRowView: View {
    let task: DownloadTask
    let onCancel: () -> Void
    let onRemove: () -> Void
    let onRetry: () -> Void
    let onReveal: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            // File type icon
            fileIcon

            // Title, status, and progress
            VStack(alignment: .leading, spacing: 4) {
                Text(task.displayTitle)
                    .font(.body.bold())
                    .lineLimit(1)

                HStack(spacing: 6) {
                    statusBadge
                    Text(task.status.displayText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                if case .downloading(let progress, _, _) = task.status {
                    ProgressView(value: progress)
                        .tint(.brandGold)
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
        .padding(.vertical, 6)
    }

    // MARK: - File Icon

    private var fileIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(statusColor.opacity(0.12))
                .frame(width: 40, height: 40)

            Image(systemName: task.fileTypeIcon)
                .font(.body)
                .foregroundStyle(statusColor)
        }
    }

    // MARK: - Status Badge

    @ViewBuilder
    private var statusBadge: some View {
        switch task.status {
        case .downloading:
            Circle()
                .fill(Color.brandGold)
                .frame(width: 6, height: 6)

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
                            .foregroundStyle(Color.brandGold)
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
        case .downloading, .merging, .converting, .fetching: .brandGold
        case .completed: .green
        case .failed: .red
        case .cancelled: .orange
        case .queued: .secondary
        }
    }
}
