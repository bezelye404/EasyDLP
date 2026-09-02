import SwiftUI
import UniformTypeIdentifiers

// MARK: - New Download View

struct NewDownloadView: View {
    @Bindable var downloadManager: DownloadManager
    @State private var url: String = ""
    @State private var selectedMode: DownloadMode = .bestVideo
    @State private var options = DownloadOptions()
    @State private var showFormatSheet = false
    @State private var formatOutput = ""
    @State private var isFetchingFormats = false
    @State private var showDropHighlight = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerSection
                urlInputSection
                modeSelectionSection
                optionsSection
                downloadButton
                Spacer(minLength: 16)
            }
            .padding(28)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .onDrop(of: [.url, .plainText], isTargeted: $showDropHighlight) { providers in
            handleDrop(providers)
        }
        .overlay {
            if showDropHighlight {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.accentColor.opacity(0.5), lineWidth: 2)
                    .background(Color.accentColor.opacity(0.03), in: RoundedRectangle(cornerRadius: 10))
                    .padding(6)
                    .allowsHitTesting(false)
            }
        }
        .sheet(isPresented: $showFormatSheet) {
            FormatSheetView(
                formatOutput: formatOutput,
                selectedFormatId: $options.customFormatId
            )
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("New Download")
                    .font(.title2.bold())
                Text("Paste a URL from YouTube, Twitter, Instagram, TikTok, and more")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    // MARK: - URL Input

    private var urlInputSection: some View {
        HStack(spacing: 10) {
            Image(systemName: "link")
                .font(.body)
                .foregroundStyle(.tertiary)

            TextField("Paste video or playlist URL…", text: $url)
                .textFieldStyle(.plain)
                .font(.body)
                .onSubmit { startDownload() }

            if !url.isEmpty {
                Button {
                    url = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.quaternary)
                }
                .buttonStyle(.plain)
            }

            Button {
                if let clipboard = NSPasteboard.general.string(forType: .string) {
                    url = clipboard
                }
            } label: {
                Label("Paste", systemImage: "doc.on.clipboard")
                    .font(.caption)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    url.isValidURL ? Color.accentColor.opacity(0.4) : Color.primary.opacity(0.08),
                    lineWidth: 0.5
                )
        )
    }

    // MARK: - Mode Selection

    private var modeSelectionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Download Mode")
                .font(.headline)

            LazyVGrid(
                columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                ],
                spacing: 8
            ) {
                ForEach(DownloadMode.allCases) { mode in
                    ModeCard(mode: mode, isSelected: selectedMode == mode)
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedMode = mode
                            }
                        }
                }
            }
        }
    }

    // MARK: - Contextual Options

    @ViewBuilder
    private var optionsSection: some View {
        switch selectedMode {
        case .selectQuality:
            QualityPicker(selectedQuality: $options.quality)
                .transition(.opacity)

        case .videoWithSubtitles, .subtitleOnly:
            SubtitlePicker(
                selectedLanguage: $options.subtitleLanguage,
                customCode: $options.customSubtitleCode
            )
            .transition(.opacity)

        case .playlist:
            PlaylistRangePicker(range: $options.playlistRange)
                .transition(.opacity)

        case .customFormat:
            CustomFormatSection(
                url: url,
                formatId: $options.customFormatId,
                formatOutput: $formatOutput,
                showFormatSheet: $showFormatSheet,
                isFetching: $isFetchingFormats,
                onFetch: fetchFormats
            )
            .transition(.opacity)

        default:
            EmptyView()
        }
    }

    // MARK: - Download Button

    private var downloadButton: some View {
        Button(action: startDownload) {
            HStack(spacing: 6) {
                Image(systemName: "arrow.down.circle")
                Text("Download")
            }
            .primaryButton()
        }
        .buttonStyle(.plain)
        .disabled(url.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        .opacity(url.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.4 : 1.0)
    }

    // MARK: - Actions

    private func startDownload() {
        let trimmed = url.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        downloadManager.startDownload(url: trimmed, mode: selectedMode, options: options)
        url = ""
    }

    private func fetchFormats() {
        guard !url.isEmpty else { return }
        isFetchingFormats = true
        Task {
            let service = YtDlpService()
            do {
                let output = try await service.fetchFormats(url: url)
                formatOutput = output
                isFetchingFormats = false
                showFormatSheet = true
            } catch {
                formatOutput = "Error: \(error.localizedDescription)"
                isFetchingFormats = false
            }
        }
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            if provider.canLoadObject(ofClass: URL.self) {
                _ = provider.loadObject(ofClass: URL.self) { url, _ in
                    if let url {
                        Task { @MainActor in self.url = url.absoluteString }
                    }
                }
                return true
            }
            if provider.canLoadObject(ofClass: String.self) {
                _ = provider.loadObject(ofClass: String.self) { text, _ in
                    if let text {
                        Task { @MainActor in self.url = text }
                    }
                }
                return true
            }
        }
        return false
    }
}

// MARK: - Mode Card

struct ModeCard: View {
    let mode: DownloadMode
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: mode.systemImage)
                .font(.title3)
                .foregroundStyle(isSelected ? .white : .secondary)
                .frame(width: 32, height: 32)

            VStack(spacing: 2) {
                Text(mode.displayName)
                    .font(.caption.weight(.medium))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                Text(mode.description)
                    .font(.caption2)
                    .foregroundStyle(isSelected ? Color.white.opacity(0.7) : Color.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 8)
        .background {
            if isSelected {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.accentColor)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.background)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.clear : Color.primary.opacity(0.06), lineWidth: 0.5)
        )
        .foregroundStyle(isSelected ? .white : .primary)
        .contentShape(Rectangle())
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

// MARK: - Playlist Range Picker

struct PlaylistRangePicker: View {
    @Binding var range: PlaylistRange
    @State private var useRange = false
    @State private var start: Int = 1
    @State private var end: Int = 10

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Playlist Options")
                .font(.headline)

            VStack(spacing: 10) {
                Toggle("Download specific range", isOn: $useRange)
                    .onChange(of: useRange) { _, newValue in
                        range = newValue ? .range(start: start, end: end) : .all
                    }

                if useRange {
                    HStack(spacing: 16) {
                        HStack {
                            Text("From video")
                                .foregroundStyle(.secondary)
                            TextField("1", value: $start, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 60)
                                .onChange(of: start) { _, val in
                                    range = .range(start: val, end: end)
                                }
                        }
                        HStack {
                            Text("to")
                                .foregroundStyle(.secondary)
                            TextField("10", value: $end, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 60)
                                .onChange(of: end) { _, val in
                                    range = .range(start: start, end: val)
                                }
                        }
                    }
                    .transition(.opacity)
                }
            }
            .cardStyle()
        }
    }
}

// MARK: - Custom Format Section

struct CustomFormatSection: View {
    let url: String
    @Binding var formatId: String
    @Binding var formatOutput: String
    @Binding var showFormatSheet: Bool
    @Binding var isFetching: Bool
    let onFetch: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Custom Format")
                .font(.headline)

            VStack(spacing: 10) {
                HStack {
                    TextField("Format ID (e.g., 137+140)", text: $formatId)
                        .textFieldStyle(.roundedBorder)

                    Button(action: onFetch) {
                        if isFetching {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Label("List Formats", systemImage: "list.bullet.rectangle")
                        }
                    }
                    .disabled(url.isEmpty || isFetching)
                }

                Text("Enter the format ID, or click 'List Formats' to see available options.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .cardStyle()
        }
    }
}

// MARK: - Format Sheet

struct FormatSheetView: View {
    let formatOutput: String
    @Binding var selectedFormatId: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                Text("Available Formats")
                    .font(.headline)
                Spacer()
                Button("Done") { dismiss() }
            }

            ScrollView {
                Text(formatOutput)
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
            }
            .background(.background, in: RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.primary.opacity(0.06), lineWidth: 0.5)
            )

            HStack {
                TextField("Enter format ID from the list above", text: $selectedFormatId)
                    .textFieldStyle(.roundedBorder)

                Button("Use This Format") { dismiss() }
                    .disabled(selectedFormatId.isEmpty)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(20)
        .frame(width: 700, height: 500)
    }
}
