import SwiftUI

struct WelcomeView: View {
    @Bindable var state: AppState
    var onOpenFolder: () -> Void

    @State private var hoveredURL: URL?
    @State private var appeared = false
    @State private var buttonHovered = false

    var body: some View {
        ZStack {
            // Background layers
            Theme.bg
            RadialGradient(
                colors: [Theme.accent.opacity(0.06), .clear],
                center: .center,
                startRadius: 50,
                endRadius: 500
            )
            WavesBackground()

            // Content
            VStack(spacing: 0) {
                Spacer()

                // Icon with glow
                ZStack {
                    Circle()
                        .fill(Theme.accent.opacity(0.12))
                        .frame(width: 160, height: 160)
                        .blur(radius: 40)

                    Image(nsImage: NSApp.applicationIconImage)
                        .resizable()
                        .frame(width: 88, height: 88)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .shadow(color: Theme.accent.opacity(0.3), radius: 30, y: 4)
                        .shadow(color: .black.opacity(0.5), radius: 16, y: 8)
                }
                .scaleEffect(appeared ? 1 : 0.8)
                .opacity(appeared ? 1 : 0)

                // Title
                Text("Quantum")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, Theme.textPrimary],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .padding(.top, 24)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 10)

                Text("AI-Powered IDE")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.top, 4)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 8)

                // Open Folder button
                Button(action: onOpenFolder) {
                    HStack(spacing: 8) {
                        Image(systemName: "folder.badge.plus")
                            .font(.system(size: 14))
                        Text("Open Folder")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Theme.accent,
                                            Theme.accent.opacity(0.8)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                            if buttonHovered {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(.white.opacity(0.1))
                            }
                        }
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .shadow(color: Theme.accent.opacity(buttonHovered ? 0.5 : 0.25), radius: buttonHovered ? 16 : 8, y: 2)
                }
                .buttonStyle(.plain)
                .onHover { buttonHovered = $0 }
                .padding(.top, 28)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 6)
                .scaleEffect(buttonHovered ? 1.03 : 1.0)
                .animation(.easeOut(duration: 0.15), value: buttonHovered)

                // Shortcut hint
                HStack(spacing: 4) {
                    KeyCapView("⌘")
                    KeyCapView("O")
                }
                .padding(.top, 10)
                .opacity(appeared ? 0.6 : 0)

                // Recent projects
                if !state.recentProjects.isEmpty {
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(spacing: 6) {
                            Rectangle()
                                .fill(Theme.border)
                                .frame(width: 32, height: 1)
                            Text("RECENT")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Theme.textMuted)
                                .kerning(1.5)
                            Rectangle()
                                .fill(Theme.border)
                                .frame(width: 32, height: 1)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 12)

                        ForEach(state.recentProjects, id: \.path) { url in
                            RecentProjectRow(
                                url: url,
                                isHovered: hoveredURL?.path == url.path,
                                onOpen: { state.openProject(at: url) },
                                onRemove: { state.removeFromRecents(url) }
                            )
                            .onHover { hovering in
                                hoveredURL = hovering ? url : nil
                            }
                        }
                    }
                    .frame(width: 320)
                    .padding(.top, 32)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 12)
                }

                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            withAnimation(.easeOut(duration: 0.7).delay(0.1)) {
                appeared = true
            }
        }
    }
}

// MARK: - Key Cap

private struct KeyCapView: View {
    let key: String
    init(_ key: String) { self.key = key }

    var body: some View {
        Text(key)
            .font(.system(size: 10, weight: .medium, design: .monospaced))
            .foregroundStyle(Theme.textSecondary)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Color.white.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.1), lineWidth: 0.5)
            )
    }
}

// MARK: - Waves

private struct WavesBackground: View {
    @State private var phase: CGFloat = 0

    private struct WaveLine {
        let baseY: CGFloat
        let amplitude: CGFloat
        let frequency: CGFloat
        let speed: CGFloat
        let phaseOffset: CGFloat
        let opacity: Double
        let lineWidth: CGFloat
    }

    private static let lines: [WaveLine] = [
        WaveLine(baseY: 0.68, amplitude: 25, frequency: 0.8, speed: 0.20, phaseOffset: 0.0, opacity: 0.06, lineWidth: 1),
        WaveLine(baseY: 0.71, amplitude: 20, frequency: 1.1, speed: 0.28, phaseOffset: 0.7, opacity: 0.08, lineWidth: 1),
        WaveLine(baseY: 0.74, amplitude: 18, frequency: 1.3, speed: 0.35, phaseOffset: 1.4, opacity: 0.12, lineWidth: 1.2),
        WaveLine(baseY: 0.77, amplitude: 22, frequency: 1.0, speed: 0.25, phaseOffset: 2.1, opacity: 0.10, lineWidth: 1),
        WaveLine(baseY: 0.80, amplitude: 15, frequency: 1.6, speed: 0.42, phaseOffset: 2.8, opacity: 0.16, lineWidth: 1.2),
        WaveLine(baseY: 0.83, amplitude: 20, frequency: 1.2, speed: 0.32, phaseOffset: 3.5, opacity: 0.14, lineWidth: 1),
        WaveLine(baseY: 0.86, amplitude: 12, frequency: 1.9, speed: 0.52, phaseOffset: 4.2, opacity: 0.22, lineWidth: 1.5),
        WaveLine(baseY: 0.88, amplitude: 16, frequency: 1.4, speed: 0.38, phaseOffset: 4.9, opacity: 0.20, lineWidth: 1.2),
        WaveLine(baseY: 0.90, amplitude: 10, frequency: 2.1, speed: 0.58, phaseOffset: 5.6, opacity: 0.30, lineWidth: 1.5),
        WaveLine(baseY: 0.92, amplitude: 14, frequency: 1.5, speed: 0.45, phaseOffset: 6.3, opacity: 0.26, lineWidth: 1.2),
        WaveLine(baseY: 0.95, amplitude: 8, frequency: 2.4, speed: 0.65, phaseOffset: 7.0, opacity: 0.40, lineWidth: 2),
        WaveLine(baseY: 0.97, amplitude: 6, frequency: 2.0, speed: 0.55, phaseOffset: 7.7, opacity: 0.35, lineWidth: 1.5),
    ]

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                // Glow layer — blurred duplicate of lines
                Canvas { context, _ in
                    drawWaves(context: context, width: w, height: h, glow: true)
                }
                .blur(radius: 6)

                // Sharp lines
                Canvas { context, _ in
                    drawWaves(context: context, width: w, height: h, glow: false)
                }
            }
            .frame(width: w, height: h)
        }
        .onAppear {
            withAnimation(.linear(duration: 25).repeatForever(autoreverses: false)) {
                phase = 2 * .pi
            }
        }
    }

    private func drawWaves(context: GraphicsContext, width w: CGFloat, height h: CGFloat, glow: Bool) {
        for line in Self.lines {
            let baseY = h * line.baseY
            var path = Path()
            let step: CGFloat = 2

            let animPhase = phase * line.speed + line.phaseOffset

            let startY = baseY + sin(animPhase) * line.amplitude
            path.move(to: CGPoint(x: 0, y: startY))

            var x: CGFloat = step
            while x <= w {
                let nx = x / w * line.frequency * .pi * 2
                let y = baseY + sin(nx + animPhase) * line.amplitude
                path.addLine(to: CGPoint(x: x, y: y))
                x += step
            }

            let opacity = glow ? line.opacity * 0.6 : line.opacity
            let lineWidth = glow ? line.lineWidth * 3 : line.lineWidth

            context.stroke(
                path,
                with: .color(Theme.accent.opacity(opacity)),
                lineWidth: lineWidth
            )
        }
    }
}

// MARK: - Recent Project Row

private struct RecentProjectRow: View {
    let url: URL
    let isHovered: Bool
    let onOpen: () -> Void
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Theme.folderBlue.opacity(0.12))
                    .frame(width: 32, height: 32)
                Image(systemName: "folder.fill")
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.folderBlue)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(url.lastPathComponent)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(isHovered ? .white : Theme.textPrimary)
                    .lineLimit(1)
                Text(abbreviatePath(url.deletingLastPathComponent().path))
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textMuted)
                    .lineLimit(1)
                    .truncationMode(.head)
            }

            Spacer()

            if isHovered {
                Button(action: onRemove) {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Theme.textMuted)
                        .frame(width: 20, height: 20)
                        .background(Color.white.opacity(0.06))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .transition(.opacity)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(isHovered ? Color.white.opacity(0.06) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(isHovered ? Color.white.opacity(0.06) : Color.clear, lineWidth: 0.5)
        )
        .contentShape(Rectangle())
        .animation(.easeOut(duration: 0.15), value: isHovered)
        .onTapGesture(perform: onOpen)
    }

    private func abbreviatePath(_ path: String) -> String {
        path.replacingOccurrences(of: NSHomeDirectory(), with: "~")
    }
}
