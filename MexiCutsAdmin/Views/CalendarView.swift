import SwiftUI

struct CalendarView: View {
    @EnvironmentObject var firebase: FirebaseManager
    @State private var selectedDate = Date()
    @State private var selectedBooking: Booking?
    @State private var showingAddBooking = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Stats Row - Sharp edges
                HStack(spacing: 8) {
                    PixelStatCard(value: "\(todayBookings)", label: "Today", color: PixelTheme.mexicanRed)
                    PixelStatCard(value: "\(firebase.upcomingBookings.count)", label: "Upcoming", color: PixelTheme.mexicanGreen)
                    PixelStatCard(value: "\(firebase.bookings.count)", label: "Total", color: .blue)
                }
                .padding(.horizontal, 16)
                
                // Loading indicator
                if firebase.isLoading {
                    ProgressView()
                        .tint(PixelTheme.mexicanRed)
                        .padding()
                }
                
                // Calendar - Sharp edges
                VStack(spacing: 0) {
                    DatePicker("", selection: $selectedDate, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .tint(PixelTheme.mexicanRed)
                        .padding(16)
                }
                .background(PixelTheme.cardBackground)
                .overlay(
                    Rectangle()
                        .stroke(PixelTheme.borderGray, lineWidth: 2)
                )
                .padding(.horizontal, 16)
                
                // Bookings for Selected Date
                VStack(alignment: .leading, spacing: 12) {
                    PixelSectionHeader(
                        icon: "📅",
                        title: formattedSelectedDate,
                        trailing: AnyView(
                            Button(action: { showingAddBooking = true }) {
                                Text("+ ADD")
                                    .pixelFont(size: 12, weight: .bold)
                                    .foregroundColor(PixelTheme.mexicanGreen)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .overlay(
                                        Rectangle()
                                            .stroke(PixelTheme.mexicanGreen, lineWidth: 2)
                                    )
                            }
                        )
                    )
                    
                    if bookingsForSelectedDate.isEmpty {
                        PixelEmptyState(
                            icon: "📭",
                            message: "NO BOOKINGS",
                            buttonText: "+ ADD BOOKING",
                            action: { showingAddBooking = true }
                        )
                    } else {
                        ForEach(bookingsForSelectedDate) { booking in
                            PixelBookingCard(booking: booking)
                                .onTapGesture {
                                    selectedBooking = booking
                                }
                        }
                    }
                }
                .padding(.horizontal, 16)
                
                // Upcoming Section
                if !firebase.upcomingBookings.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        PixelSectionHeader(icon: "📍", title: "NEXT UP")
                        
                        ForEach(firebase.upcomingBookings.prefix(5)) { booking in
                            PixelBookingCard(booking: booking, showDate: true)
                                .onTapGesture {
                                    selectedBooking = booking
                                }
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
            PixelBookingDetailView(booking: booking)
                .environmentObject(firebase)
        }
        .sheet(isPresented: $showingAddBooking) {
            PixelAddBookingView()
                .environmentObject(firebase)
        }
    }
    
    private var todayBookings: Int {
        firebase.bookings.filter { Calendar.current.isDateInToday($0.date) }.count
    }
    
    private var formattedSelectedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: selectedDate).uppercased()
    }
    
    private var bookingsForSelectedDate: [Booking] {
        firebase.bookingsForDate(selectedDate)
    }
}

// MARK: - Pixel Booking Card (Sharp Edges)
struct PixelBookingCard: View {
    let booking: Booking
    var showDate: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Sharp edge indicator bar
            Rectangle()
                .fill(booking.isPast ? PixelTheme.textGray : PixelTheme.mexicanRed)
                .frame(width: 4)
            
            // Customer info
            VStack(alignment: .leading, spacing: 4) {
                Text(booking.name.uppercased())
                    .pixelFont(size: 14, weight: .bold)
                    .foregroundColor(.white)
                
                Text(showDate ? "\(booking.formattedDate) • \(booking.formattedTime)" : booking.formattedTime)
                    .pixelFont(size: 12, weight: .regular)
                    .foregroundColor(PixelTheme.textGray)
                
                if !booking.notes.isEmpty {
                    Text(booking.notes)
                        .pixelFont(size: 11, weight: .regular)
                        .foregroundColor(PixelTheme.textGray)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Status badge
            VStack(alignment: .trailing, spacing: 8) {
                PixelBadge(
                    text: booking.isPast ? "DONE" : "SOON",
                    color: booking.isPast ? PixelTheme.textGray : PixelTheme.mexicanGreen
                )
                
                Text("▶")
                    .pixelFont(size: 12, weight: .regular)
                    .foregroundColor(PixelTheme.textGray)
            }
        }
        .padding(12)
        .pixelCard(borderColor: booking.isPast ? PixelTheme.borderGray : PixelTheme.mexicanRed.opacity(0.5))
        .opacity(booking.isPast ? 0.7 : 1.0)
    }
}

// MARK: - Pixel Empty State
struct PixelEmptyState: View {
    let icon: String
    let message: String
    var buttonText: String? = nil
    var action: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 16) {
            Text(icon)
                .font(.system(size: 40))
            
            Text(message)
                .pixelFont(size: 14, weight: .bold)
                .foregroundColor(PixelTheme.textGray)
            
            if let buttonText = buttonText, let action = action {
                Button(action: action) {
                    Text(buttonText)
                        .pixelFont(size: 12, weight: .bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(PixelTheme.mexicanGreen)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .pixelCard()
    }
}

// MARK: - Pixel Booking Detail View
struct PixelBookingDetailView: View {
    let booking: Booking
    @EnvironmentObject var firebase: FirebaseManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingDeleteAlert = false
    
    var body: some View {
        ZStack {
            PixelTheme.darkBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("✏️ BOOKING DETAILS")
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
                    VStack(spacing: 16) {
                        // Customer Section
                        PixelDetailSection(title: "CUSTOMER") {
                            PixelDetailRow(icon: "👤", label: "NAME", value: booking.name.uppercased())
                            PixelDetailRow(icon: "📱", label: "PHONE", value: booking.phone, isLink: true) {
                                if let url = URL(string: "tel:\(booking.phone)") {
                                    UIApplication.shared.open(url)
                                }
                            }
                        }
                        
                        // Appointment Section
                        PixelDetailSection(title: "APPOINTMENT") {
                            PixelDetailRow(icon: "📅", label: "DATE", value: booking.formattedDate.uppercased())
                            PixelDetailRow(icon: "⏰", label: "TIME", value: booking.formattedTime)
                            PixelDetailRow(icon: "💰", label: "PRICE", value: "$20")
                        }
                        
                        // Notes Section
                        if !booking.notes.isEmpty {
                            PixelDetailSection(title: "NOTES") {
                                Text(booking.notes)
                                    .pixelFont(size: 12, weight: .regular)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        
                        // Booking ID
                        PixelDetailSection(title: "ID") {
                            Text(booking.id)
                                .pixelFont(size: 10, weight: .regular)
                                .foregroundColor(PixelTheme.textGray)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        // Delete Button
                        Button(action: { showingDeleteAlert = true }) {
                            HStack {
                                Text("🗑️")
                                Text("CANCEL BOOKING")
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
        .alert("CANCEL BOOKING?", isPresented: $showingDeleteAlert) {
            Button("KEEP", role: .cancel) {}
            Button("CANCEL", role: .destructive) {
                Task {
                    try? await firebase.deleteBooking(booking.id)
                    dismiss()
                }
            }
        } message: {
            Text("Delete \(booking.name)'s booking?")
        }
    }
}

// MARK: - Pixel Detail Section
struct PixelDetailSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .pixelFont(size: 12, weight: .bold)
                .foregroundColor(PixelTheme.mexicanRed)
            
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .pixelCard()
    }
}

// MARK: - Pixel Detail Row
struct PixelDetailRow: View {
    let icon: String
    let label: String
    let value: String
    var isLink: Bool = false
    var action: (() -> Void)? = nil
    
    var body: some View {
        HStack {
            Text(icon)
                .font(.system(size: 16))
            
            Text(label)
                .pixelFont(size: 11, weight: .regular)
                .foregroundColor(PixelTheme.textGray)
                .frame(width: 60, alignment: .leading)
            
            if isLink, let action = action {
                Button(action: action) {
                    Text(value)
                        .pixelFont(size: 12, weight: .bold)
                        .foregroundColor(PixelTheme.mexicanGreen)
                }
            } else {
                Text(value)
                    .pixelFont(size: 12, weight: .bold)
                    .foregroundColor(.white)
            }
            
            Spacer()
        }
    }
}

// MARK: - Pixel Add Booking View
struct PixelAddBookingView: View {
    @EnvironmentObject var firebase: FirebaseManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var phone = ""
    @State private var selectedDate = Date()
    @State private var selectedTime = ""
    @State private var notes = ""
    
    private var availableTimeSlots: [String] {
        generateTimeSlots(for: selectedDate)
    }
    
    private var saveButtonDisabled: Bool {
        name.isEmpty || phone.isEmpty || selectedTime.isEmpty
    }
    
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
                    
                    Text("➕ NEW BOOKING")
                        .pixelFont(size: 16, weight: .bold)
                        .foregroundColor(PixelTheme.mexicanGreen)
                    
                    Spacer()
                    
                    Button("SAVE") { saveBooking() }
                        .pixelFont(size: 12, weight: .bold)
                        .foregroundColor(saveButtonDisabled ? PixelTheme.textGray : PixelTheme.mexicanGreen)
                        .disabled(saveButtonDisabled)
                }
                .padding(16)
                .background(PixelTheme.cardBackground)
                .overlay(
                    Rectangle()
                        .frame(height: 2)
                        .foregroundColor(PixelTheme.mexicanGreen),
                    alignment: .bottom
                )
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Customer Info
                        PixelDetailSection(title: "CUSTOMER INFO") {
                            PixelTextField(placeholder: "FULL NAME", text: $name)
                            PixelTextField(placeholder: "PHONE NUMBER", text: $phone, keyboardType: .phonePad)
                        }
                        
                        // Appointment
                        PixelDetailSection(title: "APPOINTMENT") {
                            DatePicker("DATE", selection: $selectedDate, displayedComponents: .date)
                                .pixelFont(size: 12, weight: .bold)
                                .tint(PixelTheme.mexicanRed)
                            
                            if availableTimeSlots.isEmpty {
                                Text("NO TIME SLOTS AVAILABLE")
                                    .pixelFont(size: 12, weight: .bold)
                                    .foregroundColor(PixelTheme.mexicanRed)
                            } else {
                                Picker("TIME", selection: $selectedTime) {
                                    ForEach(availableTimeSlots, id: \.self) { time in
                                        Text(time)
                                            .pixelFont(size: 12, weight: .regular)
                                            .tag(time)
                                    }
                                }
                                .pixelFont(size: 12, weight: .bold)
                                .tint(PixelTheme.mexicanRed)
                            }
                        }
                        
                        // Notes
                        PixelDetailSection(title: "NOTES (OPTIONAL)") {
                            PixelTextField(placeholder: "SPECIAL REQUESTS...", text: $notes)
                        }
                    }
                    .padding(16)
                }
            }
            .onAppear { resetSelectedTime() }
            .onChange(of: selectedDate) { _ in resetSelectedTime() }
            .onChange(of: firebase.slotDurationMinutes) { _ in resetSelectedTime() }
        }
    }
    
    private func saveBooking() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: selectedDate)
        let timeSlot = "\(dateString) \(selectedTime)"
        
        let data: [String: Any] = [
            "name": name,
            "phone": phone,
            "timeSlot": timeSlot,
            "notes": notes,
            "timestamp": Date()
        ]
        
        Task {
            try? await firebase.addBooking(data)
            dismiss()
        }
    }
    
    // MARK: - Time Slot Helpers
    
    private func resetSelectedTime() {
        selectedTime = availableTimeSlots.first ?? ""
    }
    
    private func generateTimeSlots(for date: Date) -> [String] {
        let duration = firebase.slotDurationMinutes
        guard duration > 0 else { return [] }
        
        let calendar = Calendar.current
        let weekdayIndex = calendar.component(.weekday, from: date) - 1
        let weekdayName = DateFormatter().weekdaySymbols[weekdayIndex]
        
        let dayHours = firebase.businessHours.first { $0.day == weekdayName }
        // If hours are not loaded yet, fall back to a generic window so the user can still schedule.
        let startTimeString = dayHours?.startTime ?? "08:00"
        let endTimeString = dayHours?.endTime ?? "18:00"
        let dayEnabled = dayHours?.isEnabled ?? true
        
        guard dayEnabled else { return [] }
        guard let startDate = dateFor(timeString: startTimeString, on: date),
              let endDate = dateFor(timeString: endTimeString, on: date) else {
            return []
        }
        
        var slots: [String] = []
        var cursor = startDate
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "hh:mm a"
        
        while cursor <= endDate {
            slots.append(displayFormatter.string(from: cursor))
            guard let next = calendar.date(byAdding: .minute, value: duration, to: cursor) else { break }
            cursor = next
        }
        
        return slots
    }
    
    private func dateFor(timeString: String, on date: Date) -> Date? {
        let parts = timeString.split(separator: ":")
        guard parts.count == 2,
              let hour = Int(parts[0]),
              let minute = Int(parts[1]) else { return nil }
        
        var components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        components.hour = hour
        components.minute = minute
        
        return Calendar.current.date(from: components)
    }
}

// MARK: - Pixel Text Field
struct PixelTextField: View {
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        TextField(placeholder, text: $text)
            .pixelFont(size: 14, weight: .regular)
            .foregroundColor(.white)
            .padding(12)
            .background(PixelTheme.darkBackground)
            .overlay(
                Rectangle()
                    .stroke(PixelTheme.borderGray, lineWidth: 1)
            )
            .keyboardType(keyboardType)
            .autocapitalization(.none)
    }
}

#Preview {
    CalendarView()
        .environmentObject(FirebaseManager.shared)
}
