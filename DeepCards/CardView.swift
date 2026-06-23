import SwiftUI

public struct CardView: View {
    let text: String
    var isSelected: Bool
    var onTap: () -> Void

    public init(text: String, isSelected: Bool, onTap: @escaping () -> Void) {
        self.text = text
        self.isSelected = isSelected
        self.onTap = onTap
    }

    public var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                Text(text)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
//                    .fill(isSelected ? Color.accentColor.opacity(0.12) : Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? Color.accentColor : Color.secondary.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}

#Preview("CardView – Unselected") {
    CardView(text: "Sample statement", isSelected: false) {}
}

#Preview("CardView – Selected") {
    CardView(text: "Sample statement", isSelected: true) {}
}
