import SwiftUI
import AppKit

// MARK: - ViewModel

@MainActor
final class ContentViewModel: ObservableObject {
    @Published var results: [JobResult] = []
    @Published var selectedPreset: Preset = allPresets[0]
    @Published var isProcessing = false
    @Published var outputDir: URL = defaultOutputDir()

    static func defaultOutputDir() -> URL {
        let desktop = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
        let dir = desktop.appendingPathComponent("Kompresio Output")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    func processURLs(_ urls: [URL]) {
        isProcessing = true
        let preset = selectedPreset
        let dir = outputDir

        // Ensure output dir exists
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        Task.detached(priority: .userInitiated) {
            var newResults: [JobResult] = []
            for url in urls {
                do {
                    let result = try ImageProcessor.process(url: url, preset: preset, outputDir: dir)
                    newResults.append(JobResult(state: .done(result)))
                } catch {
                    newResults.append(JobResult(state: .failed(url, error.localizedDescription)))
                }
            }
            await MainActor.run {
                self.results.insert(contentsOf: newResults, at: 0)
                // Keep only last 50
                if self.results.count > 50 { self.results = Array(self.results.prefix(50)) }
                self.isProcessing = false
            }
        }
    }

    func clearResults() { results = [] }

    func revealInFinder(_ url: URL) {
        NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: "")
    }

    func changeOutputDir() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.prompt = "Choose Output Folder"
        panel.begin { [weak self] response in
            if response == .OK, let url = panel.url {
                self?.outputDir = url
            }
        }
    }
}

struct JobResult: Identifiable {
    let id = UUID()
    enum State {
        case done(ProcessResult)
        case failed(URL, String)
    }
    let state: State
}

// MARK: - Main View

struct ContentView: View {
    @ObservedObject var viewModel: ContentViewModel
    @State private var isDragOver = false

    var body: some View {
        VStack(spacing: 0) {
            header
            presetPicker
            dropZone
            resultsList
            footer
        }
        .frame(width: 360)
        .background(Color(NSColor.windowBackgroundColor))
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Image(systemName: "photo.stack.fill")
                .foregroundStyle(.tint)
            Text("Kompresio")
                .font(.headline)
            Spacer()
            if viewModel.isProcessing {
                ProgressView()
                    .scaleEffect(0.7)
                    .frame(width: 18, height: 18)
            }
            Button(action: { NSApplication.shared.terminate(nil) }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color(NSColor.controlBackgroundColor))
    }

    // MARK: - Preset Picker

    private var presetPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(allPresets) { preset in
                    presetChip(preset)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
        }
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
    }

    private func presetChip(_ preset: Preset) -> some View {
        let selected = viewModel.selectedPreset == preset
        return Button(action: { viewModel.selectedPreset = preset }) {
            VStack(spacing: 2) {
                Text(preset.name)
                    .font(.caption.weight(.semibold))
                Text(preset.format.rawValue)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(selected ? Color.accentColor : Color(NSColor.controlColor))
            )
            .foregroundStyle(selected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Drop Zone

    private var dropZone: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    isDragOver ? Color.accentColor : Color.secondary.opacity(0.3),
                    style: StrokeStyle(lineWidth: 2, dash: [6])
                )
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isDragOver
                              ? Color.accentColor.opacity(0.07)
                              : Color(NSColor.controlBackgroundColor).opacity(0.4))
                )

            VStack(spacing: 6) {
                Image(systemName: isDragOver ? "arrow.down.circle.fill" : "photo.badge.plus")
                    .font(.system(size: 30))
                    .foregroundStyle(isDragOver ? Color.accentColor : .secondary)
                    .symbolEffect(.bounce, value: isDragOver)
                Text(isDragOver ? "Release to compress" : "Drop images here")
                    .font(.callout.weight(.medium))
                    .foregroundStyle(isDragOver ? Color.accentColor : .secondary)
                Text("JPG · PNG · WebP · HEIC · GIF · TIFF")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(height: 110)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .onDrop(of: [.fileURL], isTargeted: $isDragOver) { providers in
            Task {
                var urls: [URL] = []
                for provider in providers {
                    if let url = try? await provider.loadItem(forTypeIdentifier: "public.file-url") as? URL {
                        urls.append(url)
                    } else if let data = try? await provider.loadItem(forTypeIdentifier: "public.file-url") as? Data,
                              let url = URL(dataRepresentation: data, relativeTo: nil) {
                        urls.append(url)
                    }
                }
                let imageURLs = urls.filter { $0.isImageFile }
                if !imageURLs.isEmpty {
                    viewModel.processURLs(imageURLs)
                }
            }
            return true
        }
    }

    // MARK: - Results

    private var resultsList: some View {
        Group {
            if viewModel.results.isEmpty {
                VStack(spacing: 4) {
                    Text("No results yet")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 160)
            } else {
                ScrollView {
                    LazyVStack(spacing: 1) {
                        ForEach(viewModel.results) { job in
                            ResultRow(job: job, onReveal: {
                                if case .done(let r) = job.state {
                                    viewModel.revealInFinder(r.outputURL)
                                }
                            })
                        }
                    }
                }
                .frame(height: 160)
            }
        }
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: 8) {
            Button(action: viewModel.changeOutputDir) {
                Label(outputDirLabel, systemImage: "folder")
                    .font(.caption)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)

            Spacer()

            if !viewModel.results.isEmpty {
                Button("Clear", action: viewModel.clearResults)
                    .font(.caption)
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
    }

    private var outputDirLabel: String {
        let name = viewModel.outputDir.lastPathComponent
        return name.isEmpty ? "Desktop/Kompresio Output" : name
    }
}

// MARK: - Result Row

struct ResultRow: View {
    let job: JobResult
    let onReveal: () -> Void

    var body: some View {
        switch job.state {
        case .done(let result):
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.system(size: 14))

                VStack(alignment: .leading, spacing: 2) {
                    Text(result.outputURL.lastPathComponent)
                        .font(.caption.weight(.medium))
                        .lineLimit(1)
                    HStack(spacing: 4) {
                        Text(result.originalBytes.fileSizeString)
                            .foregroundStyle(.secondary)
                        Image(systemName: "arrow.right")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(result.compressedBytes.fileSizeString)
                            .foregroundStyle(.green)
                        Text(String(format: "−%.0f%%", result.savingsPct))
                            .font(.caption2.bold())
                            .foregroundStyle(.green)
                    }
                    .font(.caption)
                }

                Spacer()

                Button(action: onReveal) {
                    Image(systemName: "folder")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.3))

        case .failed(let url, let msg):
            HStack(spacing: 8) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.red)
                    .font(.system(size: 14))
                VStack(alignment: .leading, spacing: 2) {
                    Text(url.lastPathComponent)
                        .font(.caption.weight(.medium))
                        .lineLimit(1)
                    Text(msg)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .lineLimit(1)
                }
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
        }
    }
}
