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
            VStack(spacing: 24) {
                headerSection
                urlInputSection
                modeSelectionSection
                optionsSection
                downloadButton
                Spacer(minLength: 24)
            }
            .padding(32)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .onDrop(of: [.url, .plainText], isTargeted: $showDropHighlight) { providers in
            handleDrop(providers)
        }
        .overlay {
            if showDropHighlight {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.brandGold, lineWidth: 3)
                    .background(Color.brandGold.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))
                    .padding(8)
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
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                Text("Paste a URL from YouTube, Twitter, Instagram, TikTok, and more")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    // MARK: - URL Input

    private var urlInputSection: some View {
        HStack(spacing: 12) {
            Image(systemName: "link")
                .font(.title3)
                .foregroundStyle(Color.brandGold)

            TextField("Paste video or playlist URL…", text: $url)
                .textFieldStyle(.plain)
                .font(.body)
                .onSubmit { startDownload() }

            if !url.isEmpty {
                Button {
                    url = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
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
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    url.isValidURL ? Color.brandGold.opacity(0.5) : Color.clear,
                    lineWidth: 1.5
                )
        )
    }

    // MARK: - Mode Selection

    private var modeSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Download Mode")
                .font(.headline)

            LazyVGrid(
                columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                ],
                spacing: 12
            ) {
                ForEach(DownloadMode.allCases) { mode in
                    ModeCard(mode: mode, isSelected: selectedMode == mode)
                        .onTapGesture {
                            withAnimation(.spring(duration: 0.3)) {
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
                .transition(.move(edge: .top).combined(with: .opacity))

        case .videoWithSubtitles, .subtitleOnly:
            SubtitlePicker(
                selectedLanguage: $options.subtitleLanguage,
                customCode: $options.customSubtitleCode
            )
            .transition(.move(edge: .top).combined(with: .opacity))

        case .playlist:
            PlaylistRangePicker(range: $options.playlistRange)
                .transition(.move(edge: .top).combined(with: .opacity))

        case .customFormat:
            CustomFormatSection(
                url: url,
                formatId: $options.customFormatId,
                formatOutput: $formatOutput,
                showFormatSheet: $showFormatSheet,
                isFetching: $isFetchingFormats,
                onFetch: fetchFormats
            )
            .transition(.move(edge: .top).combined(with: .opacity))

        default:
            EmptyView()
        }
    }

    // MARK: - Download Button

    private var downloadButton: some View {
        Button(action: startDownload) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.down.circle.fill")
                Text("Download")
            }
            .goldButton()
        }
        .buttonStyle(.plain)
        .disabled(url.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        .opacity(url.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1.0)
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
        VStack(spacing: 10) {
            Image(systemName: mode.systemImage)
                .font(.title2)
                .foregroundStyle(isSelected ? .white : Color.brandGold)
                .frame(width: 36, height: 36)

            VStack(spacing: 3) {
                Text(mode.displayName)
                    .font(.caption.bold())
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                Text(mode.description)
                    .font(.caption2)
                    .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 8)
        .background {
            if isSelected {
                RoundedRectangle(cornerRadius: 12)
                    .fill(LinearGradient.brand)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.regularMaterial)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.clear : Color.primary.opacity(0.08), lineWidth: 1)
        )
        .foregroundStyle(isSelected ? .white : .primary)
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .shadow(color: isSelected ? Color.brandGold.opacity(0.3) : .clear, radius: 8, y: 4)
        .contentShape(Rectangle())
        .animation(.spring(duration: 0.3), value: isSelected)
    }
}

// MARK: - Playlist Range Picker

struct PlaylistRangePicker: View {
    @Binding var range: PlaylistRange
    @State private var useRange = false
    @State private var start: Int = 1
    @State private var end: Int = 10

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Playlist Options")
                .font(.headline)

            VStack(spacing: 12) {
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
        VStack(alignment: .leading, spacing: 12) {
            Text("Custom Format")
                .font(.headline)

            VStack(spacing: 12) {
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
        VStack(spacing: 16) {
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
                    .padding()
            }
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))

            HStack {
                TextField("Enter format ID from the list above", text: $selectedFormatId)
                    .textFieldStyle(.roundedBorder)

                Button("Use This Format") { dismiss() }
                    .disabled(selectedFormatId.isEmpty)
                    .buttonStyle(.borderedProminent)
                    .tint(Color.brandGold)
            }
        }
        .padding(24)
        .frame(width: 700, height: 500)
    }
}
