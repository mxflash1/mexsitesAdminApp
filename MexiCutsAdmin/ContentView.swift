import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack {
            // Full black background
            PixelTheme.darkBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Logo Header
                PixelLogoHeader()
                    .frame(maxWidth: .infinity)
                    .background(PixelTheme.cardBackground)
                    .overlay(
                        Rectangle()
                            .frame(height: 2)
                            .foregroundColor(PixelTheme.mexicanRed),
                        alignment: .bottom
                    )
                
                // Content Area
                TabView(selection: $selectedTab) {
                    PaymentsView()
                        .tag(0)
                    
                    HoursView()
                        .tag(1)
                    
                    CalendarView()
                        .tag(2)
                    
                    ClientsView()
                        .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Custom Pixel Tab Bar
                PixelTabBar(selectedTab: $selectedTab)
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Custom Pixel Tab Bar
struct PixelTabBar: View {
    @Binding var selectedTab: Int
    
    let tabs: [(iconName: String, label: String)] = [
        ("PaymentsIcon", "PAYMENTS"),
        ("HoursIcon", "HOURS"),
        ("CalendarIcon", "CALENDAR"),
        ("ClientsIcon", "CLIENTS")
    ]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                PixelTabItem(
                    iconName: tabs[index].iconName,
                    label: tabs[index].label,
                    isSelected: selectedTab == index
                )
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        selectedTab = index
                    }
                }
            }
        }
        .background(PixelTheme.cardBackground)
        .overlay(
            Rectangle()
                .frame(height: 3)
                .foregroundColor(PixelTheme.mexicanRed),
            alignment: .top
        )
    }
}

struct PixelTabItem: View {
    let iconName: String
    let label: String
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            Image(iconName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 32, height: 32)
                .opacity(isSelected ? 1.0 : 0.7)
            
            Text(label)
                .pixelFont(size: 9, weight: isSelected ? .bold : .regular)
                .foregroundColor(isSelected ? PixelTheme.mexicanRed : PixelTheme.textGray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(isSelected ? PixelTheme.mexicanRed.opacity(0.1) : Color.clear)
        .overlay(
            Rectangle()
                .frame(height: 3)
                .foregroundColor(isSelected ? PixelTheme.mexicanRed : Color.clear),
            alignment: .top
        )
    }
}

#Preview {
    ContentView()
        .environmentObject(FirebaseManager.shared)
}
