import SwiftUI

struct FileContentView: View {
    @Bindable var state: AppState
    @Environment(\.fontZoom) private var zoom

    var body: some View {
        Group {
            if let file = state.selectedFile {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 6) {
                        Image(nsImage: FileIconResolver.icon(for: file))
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 14 * zoom, height: 14 * zoom)
                        Text(file.name)
                            .font(.zoomed(size: 12, zoom: zoom, weight: .semibold))
                            .foregroundStyle(Theme.textPrimary)
                            .lineLimit(1)
                        Spacer()
                        Text(file.url.deletingLastPathComponent().lastPathComponent)
                            .font(.zoomed(size: 11, zoom: zoom))
                            .foregroundStyle(Theme.textMuted)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Theme.bgHeader)

                    Rectangle()
                        .fill(Theme.border)
                        .frame(height: 1)

                    CodeView(
                        content: state.fileContent,
                        fileExtension: file.url.pathExtension,
                        zoom: zoom
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 36))
                        .foregroundStyle(Theme.textMuted)
                    Text("Select a file to view")
                        .font(.zoomed(size: 12, zoom: zoom))
                        .foregroundStyle(Theme.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Theme.bg)
            }
        }
        .clipped()
    }
}
