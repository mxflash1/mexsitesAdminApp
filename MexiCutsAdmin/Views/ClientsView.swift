import SwiftUI

struct ClientsView: View {
    @EnvironmentObject var firebase: FirebaseManager
    @State private var searchText = ""
    @State private var selectedClient: Client?
    @State private var showingClientDetail = false
    @State private var sortBy: SortOption = .recent
    
    enum SortOption {
        case recent, name, visits
    }
    
    private var filteredClients: [Client] {
        var clients = firebase.clients
        
        // Filter by search
        if !searchText.isEmpty {
            clients = clients.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.phone.contains(searchText)
            }
        }
        
        // Sort
        switch sortBy {
        case .recent:
            clients.sort { $0.createdAt > $1.createdAt }
        case .name:
            clients.sort { $0.name < $1.name }
        case .visits:
            clients.sort { $0.bookingCount > $1.bookingCount }
        }
        
        return clients
    }
    
    private var newThisWeek: Int {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        return firebase.clients.filter { $0.createdAt > weekAgo }.count
    }
    
    private var totalVisits: Int {
        firebase.clients.reduce(0) { $0 + $1.bookingCount }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Stats Row
                HStack(spacing: 8) {
                    PixelStatCard(value: "\(firebase.clients.count)", label: "Total", color: PixelTheme.mexicanRed)
                    PixelStatCard(value: "\(newThisWeek)", label: "New", color: PixelTheme.mexicanGreen)
                    PixelStatCard(value: "\(totalVisits)", label: "Visits", color: .blue)
                }
                .padding(.horizontal, 16)
                
                // Search Bar
                HStack(spacing: 12) {
                    Text("🔍")
                        .font(.system(size: 16))
                    
                    TextField("SEARCH NAME OR PHONE...", text: $searchText)
                        .pixelFont(size: 12, weight: .regular)
                        .foregroundColor(.white)
                        .autocapitalization(.none)
                    
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Text("✕")
                                .pixelFont(size: 14, weight: .bold)
                                .foregroundColor(PixelTheme.textGray)
                        }
                    }
                }
                .padding(12)
                .pixelCard()
                .padding(.horizontal, 16)
                
                // Sort Options
                HStack(spacing: 8) {
                    PixelSortButton(title: "RECENT", icon: "⏰", isSelected: sortBy == .recent) {
                        sortBy = .recent
                    }
                    PixelSortButton(title: "NAME", icon: "🔤", isSelected: sortBy == .name) {
                        sortBy = .name
                    }
                    PixelSortButton(title: "VISITS", icon: "📈", isSelected: sortBy == .visits) {
                        sortBy = .visits
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                
                // Loading
                if firebase.isLoading {
                    ProgressView()
                        .tint(PixelTheme.mexicanRed)
                        .padding()
                }
                
                // Client List
                VStack(spacing: 12) {
                    if filteredClients.isEmpty {
                        VStack(spacing: 12) {
                            Text("👤")
                                .font(.system(size: 40))
                            Text(searchText.isEmpty ? "NO CLIENTS YET" : "NO CLIENTS FOUND")
                                .pixelFont(size: 14, weight: .bold)
                                .foregroundColor(PixelTheme.textGray)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                        .pixelCard()
                    } else {
                        ForEach(filteredClients) { client in
                            PixelClientCard(client: client, isNew: isNewClient(client))
                                .onTapGesture {
                                    selectedClient = client
                                    showingClientDetail = true
                                }
                        }
                    }
                }
                .padding(.horizontal, 16)
                
                Spacer(minLength: 20)
            }
            .padding(.top, 16)
        }
        .background(PixelTheme.darkBackground)
        .refreshable {
            firebase.fetchClients()
        }
        .sheet(isPresented: $showingClientDetail) {
            if let client = selectedClient {
                PixelClientDetailView(client: client)
                    .environmentObject(firebase)
            }
        }
    }
    
    private func isNewClient(_ client: Client) -> Bool {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        return client.createdAt > weekAgo
    }
}

// MARK: - Pixel Sort Button
struct PixelSortButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(icon)
                    .font(.system(size: 12))
                Text(title)
                    .pixelFont(size: 10, weight: isSelected ? .bold : .regular)
            }
            .foregroundColor(isSelected ? .white : PixelTheme.textGray)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? PixelTheme.mexicanRed : PixelTheme.cardBackground)
            .overlay(
                Rectangle()
                    .stroke(isSelected ? PixelTheme.mexicanRed : PixelTheme.borderGray, lineWidth: 2)
            )
        }
    }
}

// MARK: - Pixel Client Card
struct PixelClientCard: View {
    let client: Client
    let isNew: Bool
    
    private let colors: [Color] = [
        PixelTheme.mexicanRed,
        PixelTheme.mexicanGreen,
        .blue,
        .orange,
        .purple,
        .pink
    ]
    
    private var avatarColor: Color {
        colors[abs(client.name.hashValue) % colors.count]
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Square avatar
            PixelAvatar(
                initial: client.initials,
                color: avatarColor,
                size: 50
            )
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(client.name.uppercased())
                        .pixelFont(size: 13, weight: .bold)
                        .foregroundColor(.white)
                    
                    if isNew {
                        PixelBadge(text: "NEW", color: PixelTheme.mexicanGreen)
                    }
                }
                
                Text(client.phone)
                    .pixelFont(size: 12, weight: .regular)
                    .foregroundColor(PixelTheme.mexicanGreen)
                
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Text("📅")
                            .font(.system(size: 10))
                        Text("\(client.bookingCount) VISITS")
                            .pixelFont(size: 10, weight: .regular)
                            .foregroundColor(PixelTheme.textGray)
                    }
                    
                    HStack(spacing: 4) {
                        Text("⏰")
                            .font(.system(size: 10))
                        Text(client.formattedJoinDate.uppercased())
                            .pixelFont(size: 10, weight: .regular)
                            .foregroundColor(PixelTheme.textGray)
                    }
                }
            }
            
            Spacer()
            
            Text("▶")
                .pixelFont(size: 14, weight: .regular)
                .foregroundColor(PixelTheme.textGray)
        }
        .padding(12)
        .pixelCard()
    }
}

// MARK: - Pixel Client Detail View
struct PixelClientDetailView: View {
    let client: Client
    @EnvironmentObject var firebase: FirebaseManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingDeleteAlert = false
    
    private let colors: [Color] = [
        PixelTheme.mexicanRed,
        PixelTheme.mexicanGreen,
        .blue,
        .orange,
        .purple,
        .pink
    ]
    
    private var avatarColor: Color {
        colors[abs(client.name.hashValue) % colors.count]
    }
    
    private var clientBookings: [Booking] {
        firebase.bookings.filter { $0.userId == client.id || $0.phone.contains(client.phone.suffix(9)) }
    }
    
    var body: some View {
        ZStack {
            PixelTheme.darkBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("👤 CLIENT DETAILS")
                        .pixelFont(size: 16, weight: .bold)
                        .foregroundColor(PixelTheme.mexicanRed)
                    
                    Spacer()
                    
                    Button("DONE") { dismiss() }
                        .pixelFont(size: 12, weight: .bold)
                        .foregroundColor(PixelTheme.mexicanGreen)
                }
                .padding(16)
                .background(PixelTheme.cardBackground)
                .overlay(
                    Rectangle()
                        .frame(height: 2)
                        .foregroundColor(PixelTheme.mexicanRed),
                    alignment: .bottom
                )
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Profile Header
                        VStack(spacing: 12) {
                            PixelAvatar(
                                initial: client.initials,
                                color: avatarColor,
                                size: 80
                            )
                            
                            Text(client.name.uppercased())
                                .pixelFont(size: 18, weight: .bold)
                                .foregroundColor(.white)
                            
                            Text(client.phone)
                                .pixelFont(size: 14, weight: .regular)
                                .foregroundColor(PixelTheme.mexicanGreen)
                            
                            Text("MEMBER SINCE \(client.formattedJoinDate.uppercased())")
                                .pixelFont(size: 10, weight: .regular)
                                .foregroundColor(PixelTheme.textGray)
                        }
                        .padding(.vertical, 24)
                        
                        // Quick Actions
                        HStack(spacing: 12) {
                            Button(action: {
                                if let url = URL(string: "tel:\(client.phone)") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                HStack {
                                    Text("📞")
                                    Text("CALL")
                                        .pixelFont(size: 12, weight: .bold)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(PixelTheme.mexicanGreen)
                            }
                            
                            Button(action: {
                                if let url = URL(string: "sms:\(client.phone)") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                HStack {
                                    Text("💬")
                                    Text("SMS")
                                        .pixelFont(size: 12, weight: .bold)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(.blue)
                            }
                        }
                        
                        // Stats
                        HStack(spacing: 12) {
                            VStack(spacing: 4) {
                                Text("\(client.bookingCount)")
                                    .pixelFont(size: 24, weight: .bold)
                                    .foregroundColor(PixelTheme.mexicanRed)
                                Text("VISITS")
                                    .pixelFont(size: 10, weight: .regular)
                                    .foregroundColor(PixelTheme.textGray)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .pixelCard()
                            
                            VStack(spacing: 4) {
                                Text("$\(client.bookingCount * 20)")
                                    .pixelFont(size: 24, weight: .bold)
                                    .foregroundColor(PixelTheme.mexicanGreen)
                                Text("SPENT")
                                    .pixelFont(size: 10, weight: .regular)
                                    .foregroundColor(PixelTheme.textGray)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .pixelCard()
                        }
                        
                        // Booking History
                        if !clientBookings.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                PixelSectionHeader(icon: "📅", title: "BOOKING HISTORY")
                                
                                ForEach(clientBookings.prefix(5)) { booking in
                                    HStack(spacing: 12) {
                                        Rectangle()
                                            .fill(booking.isPast ? PixelTheme.textGray : PixelTheme.mexicanGreen)
                                            .frame(width: 10, height: 10)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(booking.formattedDate.uppercased())
                                                .pixelFont(size: 12, weight: .bold)
                                                .foregroundColor(.white)
                                            Text(booking.formattedTime)
                                                .pixelFont(size: 10, weight: .regular)
                                                .foregroundColor(PixelTheme.textGray)
                                        }
                                        
                                        Spacer()
                                        
                                        Text("$20")
                                            .pixelFont(size: 12, weight: .regular)
                                            .foregroundColor(PixelTheme.textGray)
                                    }
                                    .padding(12)
                                    .pixelCard()
                                }
                            }
                        }
                        
                        // Delete Button
                        Button(action: { showingDeleteAlert = true }) {
                            HStack {
                                Text("🗑️")
                                Text("DELETE CLIENT")
                                    .pixelFont(size: 14, weight: .bold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.red.opacity(0.8))
                        }
                        .padding(.top, 20)
                    }
                    .padding(16)
                }
            }
        }
        .alert("DELETE CLIENT?", isPresented: $showingDeleteAlert) {
            Button("CANCEL", role: .cancel) {}
            Button("DELETE", role: .destructive) {
                Task {
                    try? await firebase.deleteClient(client.id)
                    dismiss()
                }
            }
        } message: {
            Text("Delete \(client.name)?")
        }
    }
}

#Preview {
    ClientsView()
        .environmentObject(FirebaseManager.shared)
}
