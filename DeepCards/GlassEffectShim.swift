import SwiftUI

// Shim to allow `.glassEffect(.thick...)` style calls to compile and render
public struct GlassStyle {
    public var material: Material
    public var tint: Color?
    public var isInteractive: Bool
    
    public init(material: Material, tint: Color? = nil, isInteractive: Bool = false) {
        self.material = material
        self.tint = tint
        self.isInteractive = isInteractive
    }
}

public enum Glass {
    case style(GlassStyle)
    
    // Preset similar to the previous `.thick`
    public static var thick: GlassStyle {
        GlassStyle(material: .regularMaterial, tint: nil, isInteractive: false)
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

public extension ShapeStyle where Self == AnyShapeStyle {
    static func rect(cornerRadius: CGFloat) -> AnyShapeStyle { AnyShapeStyle(.background) }
}

public extension View {
    @ViewBuilder
    func glassEffect(_ style: GlassStyle, in shape: some InsettableShape) -> some View {
        self
            .background(
                ZStack {
                    shape.fill(style.tint ?? Color.white.opacity(0.10))
                    shape.fill(style.material)
                }
            )
            .clipShape(shape)
    }

    @ViewBuilder
    func glassEffect(_ style: GlassStyle, in shape: some Shape) -> some View {
        self
            .background(
                ZStack {
                    shape.fill(style.tint ?? Color.white.opacity(0.10))
                    shape.fill(style.material)
                }
            )
            .clipShape(shape)
    }

    // Convenience: circle overload
    @ViewBuilder
    func glassEffect(_ style: GlassStyle, in shape: Circle) -> some View {
        self
            .background(
                ZStack {
                    shape.fill(style.tint ?? Color.white.opacity(0.10))
                    shape.fill(style.material)
                }
            )
            .clipShape(shape)
    }
}
