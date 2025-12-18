import SwiftUI

struct PaymentsView: View {
    @EnvironmentObject var firebase: FirebaseManager
    @State private var selectedBooking: Booking?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Pending Payments Stat
                VStack(spacing: 8) {
                    Text("\(firebase.pendingPayments.count)")
                        .pixelFont(size: 48, weight: .bold)
                        .foregroundColor(.orange)
                    Text("PENDING PAYMENTS")
                        .pixelFont(size: 12, weight: .bold)
                        .foregroundColor(PixelTheme.textGray)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
                .pixelCard(borderColor: .orange.opacity(0.5))
                .padding(.horizontal, 16)
                
                // Pending Payments Section
                VStack(alignment: .leading, spacing: 12) {
                    PixelSectionHeader(
                        icon: "⏳",
                        title: "PENDING PAYMENTS",
                        trailing: firebase.pendingPayments.isEmpty ? nil : AnyView(
                            PixelBadge(text: "\(firebase.pendingPayments.count)", color: .orange)
                        )
                    )
                    
                    if firebase.pendingPayments.isEmpty {
                        VStack(spacing: 12) {
                            Text("✓")
                                .pixelFont(size: 32, weight: .bold)
                                .foregroundColor(PixelTheme.mexicanGreen)
                            Text("ALL CAUGHT UP! 🎉")
                                .pixelFont(size: 14, weight: .bold)
                                .foregroundColor(PixelTheme.mexicanGreen)
                            Text("NO PENDING PAYMENTS")
                                .pixelFont(size: 11, weight: .regular)
                                .foregroundColor(PixelTheme.textGray)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                        .pixelCard(borderColor: PixelTheme.mexicanGreen.opacity(0.5))
                    } else {
                        ForEach(firebase.pendingPayments) { booking in
                            PixelPendingPaymentCard(booking: booking) {
                                selectedBooking = booking
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                
                // Recent Payments Section
                if !firebase.completedPayments.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        PixelSectionHeader(icon: "✅", title: "RECENT PAYMENTS")
                        
                        ForEach(firebase.completedPayments.prefix(10)) { booking in
                            PixelCompletedPaymentCard(booking: booking)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                
                Spacer(minLength: 20)
            }
            .padding(.top, 16)
        }
        .background(PixelTheme.darkBackground)
        .refreshable {
            firebase.fetchBookings()
        }
        .sheet(item: $selectedBooking) { booking in
            PixelPaymentMethodSheet(booking: booking)
                .environmentObject(firebase)
                .presentationDetents([.fraction(0.45), .medium])
                .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Pixel Pending Payment Card
struct PixelPendingPaymentCard: View {
    let booking: Booking
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                PixelAvatar(
                    initial: String(booking.name.prefix(1)),
                    color: PixelTheme.mexicanRed,
                    size: 56
                )
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(booking.name.uppercased())
                        .pixelFont(size: 16, weight: .bold)
                        .foregroundColor(.white)
                    Text("\(booking.formattedDate) • \(booking.formattedTime)")
                        .pixelFont(size: 12, weight: .regular)
                        .foregroundColor(PixelTheme.textGray)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 6) {
                    Text("$20")
                        .pixelFont(size: 20, weight: .bold)
                        .foregroundColor(PixelTheme.mexicanGreen)
                    PixelBadge(text: "PENDING", color: .orange)
                        .padding(.top, 2)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .pixelCard(borderColor: .orange.opacity(0.6))
            .overlay(
                Rectangle()
                    .fill(.orange)
                    .frame(width: 4),
                alignment: .leading
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Pixel Completed Payment Card
struct PixelCompletedPaymentCard: View {
    let booking: Booking
    
    var body: some View {
        HStack(spacing: 14) {
            // Square icon for payment method
            ZStack {
                Rectangle()
                    .fill(booking.paymentMethod == .cash ? PixelTheme.mexicanGreen : .blue)
                    .frame(width: 44, height: 44)
                
                Text(booking.paymentMethod == .cash ? "💵" : "💳")
                    .font(.system(size: 20))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(booking.name.uppercased())
                    .pixelFont(size: 14, weight: .bold)
                    .foregroundColor(.white)
                Text(booking.formattedDate)
                    .pixelFont(size: 11, weight: .regular)
                    .foregroundColor(PixelTheme.textGray)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("$20")
                    .pixelFont(size: 13, weight: .bold)
                    .foregroundColor(PixelTheme.textGray)
                Text(booking.paymentMethod?.rawValue.uppercased() ?? "")
                    .pixelFont(size: 11, weight: .regular)
                    .foregroundColor(PixelTheme.textGray)
            }
        }
        .padding(14)
        .pixelCard()
        .opacity(0.7)
    }
}

// MARK: - Pixel Payment Method Sheet
struct PixelPaymentMethodSheet: View {
    let booking: Booking
    @EnvironmentObject var firebase: FirebaseManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingConfirmation = false
    @State private var selectedMethod: PaymentMethod?
    
    var body: some View {
        ZStack {
            PixelTheme.darkBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button("CANCEL") { dismiss() }
                        .pixelFont(size: 12, weight: .bold)
                        .foregroundColor(PixelTheme.textGray)
                    
                    Spacer()
                    
                    Text("💰 CONFIRM PAYMENT")
                        .pixelFont(size: 16, weight: .bold)
                        .foregroundColor(PixelTheme.mexicanGreen)
                    
                    Spacer()
                    
                    // Invisible spacer for alignment
                    Text("CANCEL")
                        .pixelFont(size: 12, weight: .bold)
                        .foregroundColor(.clear)
                }
                .padding(16)
                .background(PixelTheme.cardBackground)
                .overlay(
                    Rectangle()
                        .frame(height: 2)
                        .foregroundColor(PixelTheme.mexicanGreen),
                    alignment: .bottom
                )
                
                VStack(spacing: 24) {
                    // Customer Info
                    VStack(spacing: 8) {
                        Text(booking.name.uppercased())
                            .pixelFont(size: 18, weight: .bold)
                            .foregroundColor(.white)
                        Text("\(booking.formattedDate) @ \(booking.formattedTime)")
                            .pixelFont(size: 12, weight: .regular)
                            .foregroundColor(PixelTheme.textGray)
                        
                        Text("$20")
                            .pixelFont(size: 40, weight: .bold)
                            .foregroundColor(PixelTheme.mexicanGreen)
                            .padding(.top, 8)
                    }
                    .padding(.vertical, 24)
                    
                    Rectangle()
                        .fill(PixelTheme.borderGray)
                        .frame(height: 2)
                        .padding(.horizontal, 16)
                    
                    Text("HOW DID THEY PAY?")
                        .pixelFont(size: 12, weight: .regular)
                        .foregroundColor(PixelTheme.textGray)
                    
                    // Payment Method Buttons
                    VStack(spacing: 12) {
                        Button(action: {
                            selectedMethod = .cash
                            confirmPayment()
                        }) {
                            HStack {
                                Text("💵")
                                    .font(.system(size: 24))
                                Text("CASH")
                                    .pixelFont(size: 16, weight: .bold)
                                Spacer()
                                Text("▶")
                                    .pixelFont(size: 14, weight: .regular)
                            }
                            .foregroundColor(.white)
                            .padding(16)
                            .background(PixelTheme.mexicanGreen)
                        }
                        
                        Button(action: {
                            selectedMethod = .card
                            confirmPayment()
                        }) {
                            HStack {
                                Text("💳")
                                    .font(.system(size: 24))
                                Text("CARD")
                                    .pixelFont(size: 16, weight: .bold)
                                Spacer()
                                Text("▶")
                                    .pixelFont(size: 14, weight: .regular)
                            }
                            .foregroundColor(.white)
                            .padding(16)
                            .background(.blue)
                        }
                    }
                    .padding(.horizontal, 16)
                    
                    // Divider with more spacing
                    Rectangle()
                        .fill(PixelTheme.borderGray)
                        .frame(height: 2)
                        .padding(.horizontal, 16)
                        .padding(.top, 20)
                        .padding(.bottom, 16)
                    
                    // Remove from pending button (bigger and more visible)
                    Button(action: { removeFromPending() }) {
                        HStack(spacing: 8) {
                            Text("🗑️")
                                .font(.system(size: 18))
                            Text("REMOVE FROM PENDING")
                                .pixelFont(size: 13, weight: .bold)
                        }
                        .foregroundColor(PixelTheme.mexicanRed)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(PixelTheme.mexicanRed.opacity(0.1))
                        .overlay(
                            Rectangle()
                                .stroke(PixelTheme.mexicanRed, lineWidth: 2)
                        )
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                    
                    Spacer(minLength: 20)
                }
                .padding(.top, 24)
            }
        }
        .alert("PAYMENT CONFIRMED! 💰", isPresented: $showingConfirmation) {
            Button("OK") { dismiss() }
        } message: {
            Text("\(booking.name)'s $20 (\(selectedMethod?.rawValue ?? "")) recorded.")
        }
    }
    
    private func confirmPayment() {
        guard let method = selectedMethod else { return }
        
        Task {
            try? await firebase.confirmPayment(bookingId: booking.id, method: method)
            showingConfirmation = true
        }
    }
    
    private func removeFromPending() {
        Task {
            try? await firebase.removeFromPending(bookingId: booking.id)
            dismiss()
        }
    }
}

#Preview {
    PaymentsView()
        .environmentObject(FirebaseManager.shared)
}
