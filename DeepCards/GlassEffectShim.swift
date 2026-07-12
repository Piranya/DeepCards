import SwiftUI

// Enhanced shim to provide a vibrant glass effect compatible with previous API style
public struct GlassStyle {
    public var material: Material
    public var baseTintOpacity: Double
    public var tint: Color?
    public var isInteractive: Bool

    public init(material: Material, baseTintOpacity: Double = 0.18, tint: Color? = nil, isInteractive: Bool = false) {
        self.material = material
        self.baseTintOpacity = baseTintOpacity
        self.tint = tint
        self.isInteractive = isInteractive
    }
}

public enum Glass {
    // Preset similar to the previous `.thick` but more vibrant
    public static var thick: GlassStyle {
        #if os(iOS)
        return GlassStyle(material: .ultraThinMaterial, baseTintOpacity: 0.22)
        #else
        return GlassStyle(material: .thinMaterial, baseTintOpacity: 0.22)
        #endif
    }
}

public extension GlassStyle {
    func tint(_ color: Color) -> GlassStyle {
        var copy = self
        copy.tint = color
        return copy
    }
    func interactive(_ enabled: Bool = true) -> GlassStyle {
        var copy = self
        copy.isInteractive = enabled
        return copy
    }
}

private struct GlassBackground<S: Shape>: View {
    let shape: S
    let style: GlassStyle

    var body: some View {
        ZStack {
            // Base tint for lift on dark backgrounds
            shape.fill((style.tint ?? Color.white).opacity(style.baseTintOpacity))
            // Material layer for translucency
            shape.fill(style.material)
            // Stronger color tint overlay if provided
            if let tint = style.tint {
                shape.fill(tint)
                    .opacity(0.28)
                    .blendMode(.plusLighter)
            }
            // Subtle highlight and border for depth
            shape.stroke(Color.white.opacity(0.18), lineWidth: 1)
                .blendMode(.overlay)
        }
    }
}

public extension View {
    @ViewBuilder
    func glassEffect(_ style: GlassStyle, in shape: some InsettableShape) -> some View {
        self
            .background(
                GlassBackground(shape: shape, style: style)
            )
            .clipShape(shape)
    }

    @ViewBuilder
    func glassEffect(_ style: GlassStyle, in shape: some Shape) -> some View {
        self
            .background(
                GlassBackground(shape: shape, style: style)
            )
            .clipShape(shape)
    }

    @ViewBuilder
    func glassEffect(_ style: GlassStyle, in shape: Circle) -> some View {
        self
            .background(
                GlassBackground(shape: shape, style: style)
            )
            .clipShape(shape)
    }
}
