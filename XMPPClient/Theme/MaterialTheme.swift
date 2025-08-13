import SwiftUI

struct MaterialTheme {
    static let primary = Color(red: 0.38, green: 0.49, blue: 0.98)
    static let primaryContainer = Color(red: 0.90, green: 0.93, blue: 1.0)
    static let secondary = Color(red: 0.38, green: 0.46, blue: 0.55)
    static let secondaryContainer = Color(red: 0.87, green: 0.93, blue: 1.0)
    static let tertiary = Color(red: 0.49, green: 0.38, blue: 0.71)
    static let surface = Color(red: 0.99, green: 0.98, blue: 1.0)
    static let surfaceVariant = Color(red: 0.91, green: 0.90, blue: 0.96)
    static let background = Color(red: 0.99, green: 0.98, blue: 1.0)
    static let error = Color(red: 0.73, green: 0.11, blue: 0.14)
    static let onPrimary = Color.white
    static let onSecondary = Color.white
    static let onSurface = Color(red: 0.10, green: 0.11, blue: 0.13)
    static let onSurfaceVariant = Color(red: 0.28, green: 0.30, blue: 0.34)
    static let outline = Color(red: 0.46, green: 0.48, blue: 0.53)
    
    static let cardElevation: CGFloat = 2
    static let buttonElevation: CGFloat = 1
    static let fabElevation: CGFloat = 6
    
    static let cornerRadius: CGFloat = 12
    static let smallCornerRadius: CGFloat = 8
    static let largeCornerRadius: CGFloat = 16
}

extension View {
    func materialCard() -> some View {
        self
            .background(MaterialTheme.surface)
            .cornerRadius(MaterialTheme.cornerRadius)
            .shadow(color: .black.opacity(0.1), radius: MaterialTheme.cardElevation, x: 0, y: 1)
    }
    
    func materialButton(style: MaterialButtonStyle = .filled) -> some View {
        self
            .padding(.horizontal, 24)
            .padding(.vertical, 10)
            .background(style == .filled ? MaterialTheme.primary : Color.clear)
            .foregroundColor(style == .filled ? MaterialTheme.onPrimary : MaterialTheme.primary)
            .cornerRadius(MaterialTheme.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: MaterialTheme.cornerRadius)
                    .stroke(MaterialTheme.outline, lineWidth: style == .outlined ? 1 : 0)
            )
    }
}

enum MaterialButtonStyle {
    case filled
    case outlined
    case text
}
