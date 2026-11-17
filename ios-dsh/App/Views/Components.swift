import SwiftUI

/// 没有真封面时用的「生成封面」：双色渐变 + 一个大号首字母。
struct ArtworkView: View {
    let index: Int
    let initial: String
    var cornerRadius: CGFloat = 18
    var showsInitial = true

    var body: some View {
        ZStack {
            Theme.artwork(index)
            RadialGradient(
                colors: [Color.white.opacity(0.22), Color.clear],
                center: .topLeading,
                startRadius: 0,
                endRadius: 260
            )
            if showsInitial {
                Text(initial)
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.85))
                    .blendMode(.overlay)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(Color.white.opacity(0.10), lineWidth: 0.5)
        )
    }
}

struct StatusDot: View {
    var color: Color = Theme.mint
    var pulsing = true

    @State private var expanded = false

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 7, height: 7)
            .overlay(
                Circle()
                    .stroke(color.opacity(0.55), lineWidth: 1)
                    .scaleEffect(expanded ? 2.4 : 1)
                    .opacity(expanded ? 0 : 0.9)
            )
            .onAppear {
                guard pulsing else { return }
                withAnimation(.easeOut(duration: 1.5).repeatForever(autoreverses: false)) {
                    expanded = true
                }
            }
    }
}

struct ProgressLine: View {
    var progress: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.18))
                Capsule()
                    .fill(Theme.liveGradient)
                    .frame(width: max(4, geo.size.width * min(max(progress, 0), 1)))
            }
        }
        .frame(height: 2)
    }
}

/// 工具运行中的流光：一条 1.5pt 的光从左扫到右，不用 spinner。
struct ShimmerLine: View {
    var color: Color = Theme.mint

    var body: some View {
        TimelineView(.animation) { context in
            GeometryReader { geo in
                let cycle = 2.0
                let time = context.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: cycle) / cycle
                let width = geo.size.width * 0.45
                LinearGradient(
                    colors: [Color.clear, color.opacity(0.9), Color.clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: width)
                .offset(x: -width + (geo.size.width + width) * time)
            }
        }
        .frame(height: 1.5)
        .clipped()
    }
}

struct SectionHeader: View {
    let title: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)
            Spacer()
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(NcnsGlassButtonStyle(compact: true))
            }
        }
    }
}

struct EmptyHint: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.system(size: 14))
            .foregroundStyle(Theme.muted)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 18)
    }
}
