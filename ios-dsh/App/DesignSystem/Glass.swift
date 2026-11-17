import SwiftUI

/// Liquid Glass 的落点。iOS 26 SDK（Swift 6.2）下是真玻璃；
/// 用旧 SDK 编译、或跑在 iOS 26 以前的系统上，退化成 `.ultraThinMaterial`。
struct GlassBackground<S: Shape>: View {
    let shape: S
    var tint: Color?
    var interactive = false
    var material: Material = .ultraThinMaterial

    var body: some View {
        #if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            shape
                .fill(.clear)
                .glassEffect(glassValue, in: shape)
        } else {
            shape.fill(material)
        }
        #else
        shape.fill(material)
        #endif
    }

    #if compiler(>=6.2)
    @available(iOS 26.0, *)
    private var glassValue: Glass {
        var value = Glass.regular
        if let tint {
            value = value.tint(tint)
        }
        if interactive {
            value = value.interactive()
        }
        return value
    }
    #endif
}

extension View {
    /// 玻璃底板。只给 chrome 和可交互卡片用。
    func ncnsGlass(
        cornerRadius: CGFloat = 20,
        tint: Color? = nil,
        interactive: Bool = false,
        material: Material = .ultraThinMaterial
    ) -> some View {
        background(
            GlassBackground(
                shape: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous),
                tint: tint,
                interactive: interactive,
                material: material
            )
        )
    }

    func ncnsPill(tint: Color? = nil, interactive: Bool = true) -> some View {
        background(
            GlassBackground(shape: Capsule(), tint: tint, interactive: interactive)
        )
    }
}

/// 玻璃胶囊按钮，代替 `.buttonStyle(.glass)`：旧 SDK 也能编过。
struct NcnsGlassButtonStyle: ButtonStyle {
    var prominent = false
    var tint: Color? = nil
    var compact = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(prominent ? Color.white : Color.white.opacity(0.92))
            .padding(.horizontal, compact ? 13 : 18)
            .padding(.vertical, compact ? 7 : 11)
            .background(
                GlassBackground(
                    shape: Capsule(),
                    tint: prominent ? (tint ?? Theme.accent) : nil,
                    interactive: true
                )
            )
            .overlay(
                Capsule()
                    .strokeBorder(Color.white.opacity(prominent ? 0.0 : 0.10), lineWidth: 0.5)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(Motion.snappy, value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == NcnsGlassButtonStyle {
    static var ncnsGlass: NcnsGlassButtonStyle { NcnsGlassButtonStyle() }
    static var ncnsProminent: NcnsGlassButtonStyle { NcnsGlassButtonStyle(prominent: true) }
    static func ncnsTinted(_ color: Color) -> NcnsGlassButtonStyle {
        NcnsGlassButtonStyle(prominent: true, tint: color)
    }
}
