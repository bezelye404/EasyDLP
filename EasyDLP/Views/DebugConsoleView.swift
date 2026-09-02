import SwiftUI
import AppKit

// MARK: - Debug Console View

struct DebugConsoleView: View {
    @State private var searchText = ""
    @State private var selectedCategory: LogCategory?
    @State private var selectedLevel: LogLevel = .debug
    @State private var autoScroll = true

    private var logStore: LogStore { LogStore.shared }

    private var filteredEntries: [LogEntry] {
        logStore.filteredEntries(
            searchText: searchText,
            category: selectedCategory,
            minLevel: selectedLevel
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            filterBar
            Divider()

            if filteredEntries.isEmpty {
                emptyState
            } else {
                logList
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Debug Console")
                    .font(.title2.bold())
                Text("\(logStore.entries.count) log entries")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                let text = logStore.copyAll(
                    searchText: searchText,
                    category: selectedCategory,
                    minLevel: selectedLevel
                )
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(text, forType: .string)
            } label: {
                Label("Copy All", systemImage: "doc.on.doc")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .disabled(filteredEntries.isEmpty)

            Button {
                logStore.clear()
            } label: {
                Label("Clear", systemImage: "trash")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 18)
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.tertiary)
                TextField("Search logs…", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.body)

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.quaternary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(.background, in: RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 0.5)
            )

            Picker("Category", selection: $selectedCategory) {
                Text("All Categories").tag(Optional<LogCategory>.none)
                Divider()
                ForEach(LogCategory.allCases) { cat in
                    Text(cat.rawValue).tag(Optional(cat))
                }
            }
            .frame(width: 150)

            Picker("Level", selection: $selectedLevel) {
                ForEach(LogLevel.allCases) { level in
                    Text(level.rawValue).tag(level)
                }
            }
            .frame(width: 100)

            Toggle(isOn: $autoScroll) {
                Image(systemName: "arrow.down.to.line")
            }
            .toggleStyle(.button)
            .controlSize(.small)
            .help("Auto-scroll to latest")
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "ladybug")
                .font(.system(size: 40))
                .foregroundStyle(.quaternary)
            Text("No Log Entries")
                .font(.body.bold())
                .foregroundStyle(.secondary)
            Text("Logs will appear here as the app runs")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Log List

    private var logList: some View {
        ScrollViewReader { proxy in
            List(filteredEntries) { entry in
                LogEntryRow(entry: entry)
                    .id(entry.id)
                    .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
            .font(.system(.caption, design: .monospaced))
            .onChange(of: filteredEntries.count) { _, _ in
                if autoScroll, let last = filteredEntries.last {
                    proxy.scrollTo(last.id, anchor: .bottom)
                }
            }
        }
    }
}

// MARK: - Log Entry Row

struct LogEntryRow: View {
    let entry: LogEntry

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // Timestamp
            Text(entry.formattedDate)
                .foregroundStyle(.tertiary)
                .frame(width: 85, alignment: .leading)

            // Level badge
            Text(entry.level.rawValue)
                .font(.system(.caption2, design: .monospaced, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 5)
                .padding(.vertical, 1)
                .background(levelColor, in: RoundedRectangle(cornerRadius: 3))
                .frame(width: 50)

            // Category
            Text(entry.category.rawValue)
                .foregroundStyle(.secondary)
                .frame(width: 70, alignment: .leading)

            // Message
            Text(entry.message)
                .foregroundStyle(.primary)
                .lineLimit(3)
                .textSelection(.enabled)

            Spacer(minLength: 0)
        }
        .padding(.vertical, 2)
    }

    private var levelColor: Color {
        switch entry.level {
        case .debug: .gray
        case .info: .blue
        case .warning: .orange
        case .error: .red
        }
    }
}
