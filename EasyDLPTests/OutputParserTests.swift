import Testing
@testable import EasyDLP

// MARK: - OutputParser Tests

@Suite("OutputParser")
struct OutputParserTests {

    @Test("Parses full progress line with percentage, size, speed, and ETA")
    func fullProgressLine() {
        let line = "[download]  45.2% of  150.00MiB at  5.20MiB/s ETA 00:15"
        let event = OutputParser.parse(line: line)

        if case .progress(let p) = event {
            #expect(abs(p.percentage - 0.452) < 0.001)
            #expect(p.totalSize == "150.00MiB")
            #expect(p.speed == "5.20MiB/s")
            #expect(p.eta == "00:15")
        } else {
            Issue.record("Expected .progress, got \(String(describing: event))")
        }
    }

    @Test("Parses 100% progress")
    func completedProgress() {
        let line = "[download] 100% of 200.00MiB at 10.00MiB/s ETA 00:00"
        let event = OutputParser.parse(line: line)

        if case .progress(let p) = event {
            #expect(abs(p.percentage - 1.0) < 0.001)
        } else {
            Issue.record("Expected .progress, got \(String(describing: event))")
        }
    }

    @Test("Parses fallback progress without speed/ETA")
    func fallbackProgress() {
        let line = "[download]  67.3% of ~  45.00MiB"
        let event = OutputParser.parse(line: line)

        if case .progress(let p) = event {
            #expect(abs(p.percentage - 0.673) < 0.001)
            #expect(p.speed == nil)
            #expect(p.eta == nil)
        } else {
            Issue.record("Expected .progress, got \(String(describing: event))")
        }
    }

    @Test("Parses destination line and extracts title")
    func destinationLine() {
        let line = "[download] Destination: /Users/test/Downloads/My Video Title.mp4"
        let event = OutputParser.parse(line: line)

        if case .destination(let title) = event {
            #expect(title == "My Video Title")
        } else {
            Issue.record("Expected .destination, got \(String(describing: event))")
        }
    }

    @Test("Detects merger event")
    func mergerLine() {
        let line = #"[Merger] Merging formats into "/path/to/output.mp4""#
        let event = OutputParser.parse(line: line)

        if case .merging = event {
            // pass
        } else {
            Issue.record("Expected .merging, got \(String(describing: event))")
        }
    }

    @Test("Detects audio extraction event")
    func extractAudioLine() {
        let line = "[ExtractAudio] Destination: /path/to/output.mp3"
        let event = OutputParser.parse(line: line)

        if case .converting = event {
            // pass
        } else {
            Issue.record("Expected .converting, got \(String(describing: event))")
        }
    }

    @Test("Parses error line")
    func errorLine() {
        let line = "ERROR: [youtube] abc123: Video unavailable"
        let event = OutputParser.parse(line: line)

        if case .error(let msg) = event {
            #expect(msg.contains("Video unavailable"))
        } else {
            Issue.record("Expected .error, got \(String(describing: event))")
        }
    }

    @Test("Returns nil for unrecognised lines")
    func unrecognisedLine() {
        let line = "Some random log output that doesn't match anything"
        let event = OutputParser.parse(line: line)
        #expect(event == nil)
    }

    @Test("Parses info line")
    func infoLine() {
        let line = "[youtube] Extracting URL: https://example.com"
        let event = OutputParser.parse(line: line)

        if case .info = event {
            // pass
        } else {
            Issue.record("Expected .info, got \(String(describing: event))")
        }
    }
}
