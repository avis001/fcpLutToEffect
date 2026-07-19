import SwiftUI
import LutFxKit

struct ManageView: View {
    @EnvironmentObject private var model: AppModel
    @State private var pendingDelete: EffectLibrary.Effect?

    private var byCategory: [(category: String, effects: [EffectLibrary.Effect])] {
        Dictionary(grouping: model.installed, by: \.category)
            .sorted { $0.key.localizedLowercase < $1.key.localizedLowercase }
            .map { (category: $0.key, effects: $0.value) }
    }

    var body: some View {
        Group {
            if model.installed.isEmpty {
                VStack(spacing: 8) {
                    Text("No installed LUT effects found.")
                        .foregroundStyle(.secondary)
                    Text(model.effectsRoot.path)
                        .font(.caption.monospaced())
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(byCategory, id: \.category) { group in
                        Section("\(group.category) (\(group.effects.count))") {
                            ForEach(group.effects) { effect in
                                EffectRow(effect: effect,
                                          onReveal: { reveal(effect) },
                                          onDelete: { pendingDelete = effect })
                            }
                        }
                    }
                }
                .listStyle(.inset)
            }
        }
        .padding()
        .onAppear { model.refreshInstalled() }
        .toolbar {
            Button {
                model.refreshInstalled()
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
        }
        .confirmationDialog(
            "Remove \"\(pendingDelete?.name ?? "")\" from Final Cut Pro?",
            isPresented: Binding(get: { pendingDelete != nil },
                                 set: { if !$0 { pendingDelete = nil } })
        ) {
            Button("Remove Effect", role: .destructive) {
                if let effect = pendingDelete { model.uninstall(effect) }
                pendingDelete = nil
            }
        } message: {
            Text("The effect template is deleted; the .cube file stays in the Custom LUTs folder. Restart Final Cut Pro to see the change.")
        }
    }

    private func reveal(_ effect: EffectLibrary.Effect) {
        NSWorkspace.shared.activateFileViewerSelecting([effect.directory])
    }
}

private struct EffectRow: View {
    let effect: EffectLibrary.Effect
    let onReveal: () -> Void
    let onDelete: () -> Void
    @State private var thumbnail: NSImage?

    var body: some View {
        HStack(spacing: 10) {
            Group {
                if let thumbnail {
                    Image(nsImage: thumbnail).resizable().aspectRatio(contentMode: .fill)
                } else {
                    Rectangle().fill(.quaternary)
                }
            }
            .frame(width: 64, height: 36)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            Text(effect.name)
            Spacer()
            Button("Reveal", action: onReveal)
                .buttonStyle(.link)
            Button(role: .destructive, action: onDelete) {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
        }
        .task {
            guard thumbnail == nil, let url = effect.thumbnail else { return }
            let data = await Task.detached { try? Data(contentsOf: url) }.value
            if let data { thumbnail = NSImage(data: data) }
        }
    }
}
