import SwiftUI

// MARK: - Pixel Theme Colors & Styles
struct PixelTheme {
    // Colors matching the website
    static let mexicanRed = Color(hex: "CE1126")
    static let mexicanGreen = Color(hex: "006847")
    static let darkBackground = Color(hex: "000000")
    static let cardBackground = Color(hex: "111111")
    static let borderGray = Color(hex: "333333")
    static let textGray = Color(hex: "999999")
    static let accentCyan = Color(hex: "00FFCC")
}

// MARK: - Pixel Font Modifier
struct PixelFont: ViewModifier {
    let size: CGFloat
    let weight: Font.Weight
    
    func body(content: Content) -> some View {
        content
            .font(.system(size: size, weight: weight, design: .monospaced))
    }
}

extension View {
    func pixelFont(size: CGFloat = 14, weight: Font.Weight = .regular) -> some View {
        modifier(PixelFont(size: size, weight: weight))
    }
}

// MARK: - Pixel Card Style (Sharp Edges)
struct PixelCard: ViewModifier {
    var borderColor: Color = PixelTheme.borderGray
    var filled: Bool = true
    
    func body(content: Content) -> some View {
        content
            .background(filled ? PixelTheme.cardBackground : Color.clear)
            .overlay(
                Rectangle()
                    .stroke(borderColor, lineWidth: 2)
            )
    }
}

extension View {
    func pixelCard(borderColor: Color = PixelTheme.borderGray, filled: Bool = true) -> some View {
        modifier(PixelCard(borderColor: borderColor, filled: filled))
    }
}

// MARK: - Pixel Button Style
struct PixelButtonStyle: ButtonStyle {
    var backgroundColor: Color = PixelTheme.mexicanRed
    var foregroundColor: Color = .white
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .pixelFont(size: 14, weight: .bold)
            .foregroundColor(foregroundColor)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(backgroundColor)
            .overlay(
                Rectangle()
                    .stroke(backgroundColor.opacity(0.5), lineWidth: 2)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Pixel Stat Card
struct PixelStatCard: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .pixelFont(size: 24, weight: .bold)
                .foregroundColor(color)
            Text(label)
                .pixelFont(size: 10, weight: .regular)
                .foregroundColor(PixelTheme.textGray)
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .pixelCard(borderColor: color.opacity(0.5))
    }
}

// MARK: - Pixel Section Header
struct PixelSectionHeader: View {
    let icon: String
    let title: String
    var trailing: AnyView? = nil
    
    var body: some View {
        HStack {
            Text("\(icon) \(title)")
                .pixelFont(size: 14, weight: .bold)
                .foregroundColor(PixelTheme.mexicanRed)
                .textCase(.uppercase)
            
            Spacer()
            
            if let trailing = trailing {
                trailing
            }
        }
        .padding(.bottom, 8)
    }
}

// MARK: - Square Avatar (No Circles!)
struct PixelAvatar: View {
    let initial: String
    let color: Color
    var size: CGFloat = 48
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(color)
                .frame(width: size, height: size)
            
            Text(initial)
                .pixelFont(size: size * 0.4, weight: .bold)
                .foregroundColor(.white)
        }
        .overlay(
            Rectangle()
                .stroke(color.opacity(0.5), lineWidth: 2)
        )
    }
}

// MARK: - Pixel Badge
struct PixelBadge: View {
    let text: String
    var color: Color = PixelTheme.mexicanGreen
    
    var body: some View {
        Text(text)
            .pixelFont(size: 10, weight: .bold)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color)
            .textCase(.uppercase)
    }
}

// MARK: - Logo Header View
struct PixelLogoHeader: View {
    @EnvironmentObject var firebase: FirebaseManager
    var showTitle: Bool = true
    
    var body: some View {
        ZStack {
            // Centered logo and text
            VStack(spacing: 2) {
                // MEXI.CUTS Logo
                Image("MexiCutsLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 200, maxHeight: 80)
                
                if showTitle {
                    Text("ADMIN PANEL")
                        .pixelFont(size: 10, weight: .regular)
                        .foregroundColor(PixelTheme.textGray)
                        .tracking(4)
                }
            }
            
            // Logout Button (positioned on right)
            HStack {
                Spacer()
                
                Button(action: { firebase.logout() }) {
                    VStack(spacing: 2) {
                        Image("LogoutIcon")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 48, height: 48)
                        Text("LOGOUT")
                            .pixelFont(size: 8, weight: .regular)
                            .foregroundColor(PixelTheme.textGray)
                    }
                    .padding(.horizontal, 8)
                }
            }
        }
        .padding(.vertical, 12)
    }
}

// MARK: - Hex Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

