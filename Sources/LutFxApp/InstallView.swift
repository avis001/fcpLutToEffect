import SwiftUI
import UniformTypeIdentifiers
import LutFxKit

struct InstallView: View {
    @EnvironmentObject private var model: AppModel
    @State private var dropTargeted = false
    @State private var showingImporter = false

    private static let cubeType = UTType(filenameExtension: "cube") ?? .data

    var body: some View {
        VStack(spacing: 12) {
            if model.items.isEmpty {
                dropZone
            } else {
                lutList
                controls
            }
        }
        .padding()
        .onDrop(of: [.fileURL], isTargeted: $dropTargeted) { handleDrop($0) }
        .fileImporter(isPresented: $showingImporter,
                      allowedContentTypes: [.folder, Self.cubeType],
                      allowsMultipleSelection: true) { result in
            if case .success(let urls) = result { model.addURLs(urls) }
        }
    }

    private var dropZone: some View {
        VStack(spacing: 14) {
            Image(systemName: "square.stack.3d.down.right")
                .font(.system(size: 52))
                .foregroundStyle(.secondary)
            Text("Drop .cube files or folders here")
                .font(.title3)
            Text("Each LUT becomes its own effect in Final Cut Pro's Effects browser.")
                .foregroundStyle(.secondary)
            Button("Choose Files…") { showingImporter = true }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8]))
                .foregroundStyle(dropTargeted ? Color.accentColor : Color.secondary.opacity(0.4))
        )
    }

    private var lutList: some View {
        List {
            ForEach(model.items) { item in
                LutRow(item: item)
            }
        }
        .listStyle(.inset)
        .overlay(alignment: .bottomTrailing) {
            if dropTargeted {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color.accentColor, lineWidth: 2)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private var controls: some View {
        VStack(spacing: 10) {
            if model.finishedInstall {
                Label("Done. Restart Final Cut Pro, then look in Effects browser → \(model.sanitizedCategory).",
                      systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
            HStack(spacing: 12) {
                TextField("Category", text: $model.category)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 240)
                Toggle("Overwrite existing", isOn: $model.overwrite)
                Spacer()
                Button("Add More…") { showingImporter = true }
                Button("Clear") { model.clear() }
                    .disabled(model.isInstalling)
                Button {
                    Task { await model.installAll() }
                } label: {
                    if model.isInstalling {
                        ProgressView().controlSize(.small)
                    } else {
                        Text("Install \(model.installableCount) Effect\(model.installableCount == 1 ? "" : "s")")
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(model.installableCount == 0 || model.isInstalling)
            }
        }
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        var urls: [URL] = []
        let group = DispatchGroup()
        for provider in providers {
            group.enter()
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                defer { group.leave() }
                if let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) {
                    urls.append(url)
                } else if let url = item as? URL {
                    urls.append(url)
                }
            }
        }
        group.notify(queue: .main) {
            model.addURLs(urls)
        }
        return !providers.isEmpty
    }
}

private struct LutRow: View {
    let item: LutItem

    var body: some View {
        HStack(spacing: 10) {
            previewView
                .frame(width: 96, height: 54)
                .clipShape(RoundedRectangle(cornerRadius: 4))
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name).fontWeight(.medium)
                statusView
                    .font(.caption)
                    .foregroundStyle(statusColor)
            }
            Spacer()
            if !item.sizeLabel.isEmpty {
                Text(item.sizeLabel)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }

    @ViewBuilder private var previewView: some View {
        if let preview = item.preview {
            Image(decorative: preview, scale: 1)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            Rectangle().fill(.quaternary)
                .overlay {
                    if case .pending = item.state { ProgressView().controlSize(.small) }
                }
        }
    }

    private var statusView: Text {
        switch item.state {
        case .pending: return Text("Reading…")
        case .ready: return Text("Ready")
        case .invalid(let why): return Text(why)
        case .installing: return Text("Installing…")
        case .installed(let status): return Text(status)
        case .failed(let why): return Text(why)
        }
    }

    private var statusColor: Color {
        switch item.state {
        case .invalid, .failed: return .red
        case .installed: return .green
        default: return .secondary
        }
    }
}
