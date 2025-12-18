import SwiftUI

struct HoursView: View {
    @EnvironmentObject var firebase: FirebaseManager
    @State private var hasChanges = false
    @State private var showingSaveAlert = false
    @State private var showingAddBlockedDate = false
    @State private var showingSlotPicker = false
    @State private var newBlockedDate = Date()
    @State private var newBlockedReason = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Stats Row
                HStack(spacing: 8) {
                    PixelStatCard(value: "\(enabledDaysCount)", label: "Open Days", color: PixelTheme.mexicanGreen)
                    PixelStatCard(value: "\(firebase.blockedDates.count)", label: "Blocked", color: PixelTheme.mexicanRed)
                    
                    Button(action: { showingSlotPicker = true }) {
                        PixelStatCard(value: "\(firebase.slotDurationMinutes)", label: "Min/Slot", color: .blue)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                
                // Business Hours Section
                VStack(alignment: .leading, spacing: 12) {
                    PixelSectionHeader(icon: "⏰", title: "BUSINESS HOURS")
                    
                    ForEach($firebase.businessHours) { $dayHours in
                        PixelDayCard(dayHours: $dayHours, hasChanges: $hasChanges)
                    }
                }
                .padding(.horizontal, 16)
                
                // Blocked Dates Section
                VStack(alignment: .leading, spacing: 12) {
                    PixelSectionHeader(icon: "🚫", title: "BLOCKED DATES")
                    
                    if firebase.blockedDates.isEmpty {
                        HStack(spacing: 8) {
                            Text("✓")
                                .pixelFont(size: 16, weight: .bold)
                                .foregroundColor(PixelTheme.mexicanGreen)
                            Text("NO BLOCKED DATES")
                                .pixelFont(size: 12, weight: .regular)
                                .foregroundColor(PixelTheme.textGray)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(20)
                        .pixelCard()
                    } else {
                        ForEach(firebase.blockedDates) { blockedDate in
                            PixelBlockedDateCard(blockedDate: blockedDate) {
                                firebase.blockedDates.removeAll { $0.id == blockedDate.id }
                                hasChanges = true
                            }
                        }
                    }
                    
                    // Add Blocked Date Button
                    Button(action: { showingAddBlockedDate = true }) {
                        HStack {
                            Text("🚫")
                            Text("BLOCK A DATE")
                                .pixelFont(size: 12, weight: .bold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(PixelTheme.mexicanRed)
                    }
                }
                .padding(.horizontal, 16)
                
                // Info Box
                HStack(alignment: .top, spacing: 12) {
                    Text("ℹ️")
                        .font(.system(size: 16))
                    Text("CHANGES APPLY TO FUTURE BOOKINGS ONLY. EXISTING BOOKINGS WON'T BE AFFECTED.")
                        .pixelFont(size: 10, weight: .regular)
                        .foregroundColor(PixelTheme.textGray)
                }
                .padding(16)
                .pixelCard(borderColor: .blue.opacity(0.5))
                .padding(.horizontal, 16)
                
                // Save Button (if changes)
                if hasChanges {
                    Button(action: { showingSaveAlert = true }) {
                        HStack {
                            Text("💾")
                            Text("SAVE CHANGES")
                                .pixelFont(size: 14, weight: .bold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(PixelTheme.mexicanGreen)
                    }
                    .padding(.horizontal, 16)
                }
                
                Spacer(minLength: 20)
            }
            .padding(.top, 16)
        }
        .background(PixelTheme.darkBackground)
        .alert("SAVE CHANGES", isPresented: $showingSaveAlert) {
            Button("CANCEL", role: .cancel) {}
            Button("SAVE") {
                Task {
                    try? await firebase.saveAvailability()
                    hasChanges = false
                }
            }
        } message: {
            Text("Update availability settings?")
        }
        .sheet(isPresented: $showingSlotPicker) {
            SlotDurationPicker(
                selected: Binding(
                    get: { firebase.slotDurationMinutes },
                    set: { newValue in
                        firebase.slotDurationMinutes = newValue
                        hasChanges = true
                    }
                ),
                onClose: { showingSlotPicker = false }
            )
            .presentationDetents([.fraction(0.45), .medium])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingAddBlockedDate) {
            PixelAddBlockedDateSheet(
                date: $newBlockedDate,
                reason: $newBlockedReason,
                onAdd: {
                    let newBlocked = BlockedDate(
                        date: newBlockedDate,
                        reason: newBlockedReason.isEmpty ? "Blocked" : newBlockedReason
                    )
                    firebase.blockedDates.append(newBlocked)
                    hasChanges = true
                    showingAddBlockedDate = false
                    newBlockedReason = ""
                },
                onCancel: { showingAddBlockedDate = false }
            )
        }
    }
    
    private var enabledDaysCount: Int {
        firebase.businessHours.filter { $0.isEnabled }.count
    }
}

// MARK: - Pixel Day Card
struct PixelDayCard: View {
    @Binding var dayHours: DayHours
    @Binding var hasChanges: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Day indicator bar
                Rectangle()
                    .fill(dayHours.isEnabled ? PixelTheme.mexicanGreen : PixelTheme.textGray)
                    .frame(width: 4)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(dayHours.day.uppercased())
                        .pixelFont(size: 14, weight: .bold)
                        .foregroundColor(dayHours.isEnabled ? .white : PixelTheme.textGray)
                    
                    if dayHours.isEnabled {
                        Text("\(formatTime(dayHours.startTime)) - \(formatTime(dayHours.endTime))")
                            .pixelFont(size: 11, weight: .regular)
                            .foregroundColor(PixelTheme.mexicanGreen)
                    }
                }
                
                Spacer()
                
                // Toggle styled as pixel switch
                PixelToggle(isOn: $dayHours.isEnabled)
                    .onChange(of: dayHours.isEnabled) { _, _ in hasChanges = true }
            }
            
            // Time display when enabled
            if dayHours.isEnabled {
                Rectangle()
                    .fill(PixelTheme.borderGray)
                    .frame(height: 1)
                
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("OPENS")
                            .pixelFont(size: 9, weight: .regular)
                            .foregroundColor(PixelTheme.textGray)
                        Text(formatTime(dayHours.startTime))
                            .pixelFont(size: 12, weight: .bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(PixelTheme.darkBackground)
                            .overlay(
                                Rectangle()
                                    .stroke(PixelTheme.borderGray, lineWidth: 1)
                            )
                    }
                    
                    Text("▶")
                        .pixelFont(size: 12, weight: .regular)
                        .foregroundColor(PixelTheme.textGray)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("CLOSES")
                            .pixelFont(size: 9, weight: .regular)
                            .foregroundColor(PixelTheme.textGray)
                        Text(formatTime(dayHours.endTime))
                            .pixelFont(size: 12, weight: .bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(PixelTheme.darkBackground)
                            .overlay(
                                Rectangle()
                                    .stroke(PixelTheme.borderGray, lineWidth: 1)
                            )
                    }
                    
                    Spacer()
                }
            }
        }
        .padding(12)
        .pixelCard(borderColor: dayHours.isEnabled ? PixelTheme.mexicanGreen.opacity(0.5) : PixelTheme.borderGray)
        .opacity(dayHours.isEnabled ? 1.0 : 0.7)
    }
    
    private func formatTime(_ time: String) -> String {
        let parts = time.split(separator: ":")
        guard parts.count == 2, let hour = Int(parts[0]) else { return time }
        let ampm = hour >= 12 ? "PM" : "AM"
        let hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
        return "\(hour12):\(parts[1]) \(ampm)"
    }
}

// MARK: - Pixel Toggle (Square Style)
struct PixelToggle: View {
    @Binding var isOn: Bool
    
    var body: some View {
        Button(action: { isOn.toggle() }) {
            ZStack(alignment: isOn ? .trailing : .leading) {
                Rectangle()
                    .fill(isOn ? PixelTheme.mexicanGreen : PixelTheme.borderGray)
                    .frame(width: 48, height: 24)
                
                Rectangle()
                    .fill(.white)
                    .frame(width: 20, height: 20)
                    .padding(2)
            }
            .animation(.easeInOut(duration: 0.15), value: isOn)
        }
    }
}

// MARK: - Pixel Blocked Date Card
struct PixelBlockedDateCard: View {
    let blockedDate: BlockedDate
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(PixelTheme.mexicanRed)
                .frame(width: 4)
            
            Text("📅")
                .font(.system(size: 16))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(blockedDate.formattedDate.uppercased())
                    .pixelFont(size: 12, weight: .bold)
                    .foregroundColor(.white)
                Text(blockedDate.reason.uppercased())
                    .pixelFont(size: 10, weight: .regular)
                    .foregroundColor(PixelTheme.textGray)
            }
            
            Spacer()
            
            Button(action: onRemove) {
                Text("✕")
                    .pixelFont(size: 14, weight: .bold)
                    .foregroundColor(PixelTheme.mexicanRed)
                    .padding(8)
            }
        }
        .padding(12)
        .background(PixelTheme.mexicanRed.opacity(0.1))
        .overlay(
            Rectangle()
                .stroke(PixelTheme.mexicanRed.opacity(0.5), lineWidth: 2)
        )
    }
}

// MARK: - Pixel Add Blocked Date Sheet
struct PixelAddBlockedDateSheet: View {
    @Binding var date: Date
    @Binding var reason: String
    let onAdd: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        ZStack {
            PixelTheme.darkBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button("CANCEL") { onCancel() }
                        .pixelFont(size: 12, weight: .bold)
                        .foregroundColor(PixelTheme.textGray)
                    
                    Spacer()
                    
                    Text("🚫 BLOCK DATE")
                        .pixelFont(size: 16, weight: .bold)
                        .foregroundColor(PixelTheme.mexicanRed)
                    
                    Spacer()
                    
                    Button("ADD") { onAdd() }
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
                
                VStack(spacing: 16) {
                    DatePicker("DATE TO BLOCK", selection: $date, displayedComponents: .date)
                        .pixelFont(size: 12, weight: .bold)
                        .tint(PixelTheme.mexicanRed)
                        .padding(16)
                        .pixelCard()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("REASON (OPTIONAL)")
                            .pixelFont(size: 11, weight: .regular)
                            .foregroundColor(PixelTheme.textGray)
                        
                        PixelTextField(placeholder: "E.G. HOLIDAY, VACATION...", text: $reason)
                    }
                    .padding(16)
                    .pixelCard()
                    
                    Spacer()
                }
                .padding(16)
            }
        }
    }
}

// MARK: - Slot Duration Picker Sheet
struct SlotDurationPicker: View {
    @Binding var selected: Int
    let onClose: () -> Void
    
    private var options: [Int] {
        stride(from: 5, through: 190, by: 5).map { $0 }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Button("CLOSE") { onClose() }
                    .pixelFont(size: 12, weight: .bold)
                    .foregroundColor(PixelTheme.textGray)
                
                Spacer()
                
                Text("⏱ SLOT DURATION")
                    .pixelFont(size: 16, weight: .bold)
                    .foregroundColor(PixelTheme.mexicanRed)
                
                Spacer()
                
                // alignment spacer
                Text("CLOSE")
                    .pixelFont(size: 12, weight: .bold)
                    .foregroundColor(.clear)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)
            .background(PixelTheme.cardBackground)
            .overlay(
                Rectangle()
                    .frame(height: 2)
                    .foregroundColor(PixelTheme.mexicanRed),
                alignment: .bottom
            )
            
            VStack(spacing: 12) {
                Text("SELECT SLOT LENGTH (MINUTES)")
                    .pixelFont(size: 12, weight: .regular)
                    .foregroundColor(PixelTheme.textGray)
                
                Picker("SLOT LENGTH", selection: $selected) {
                    ForEach(options, id: \.self) { minutes in
                        Text("\(minutes) MIN")
                            .pixelFont(size: 16, weight: .bold)
                            .foregroundColor(.white)
                            .tag(minutes)
                    }
                }
                .pickerStyle(.wheel)
                .labelsHidden()
                .frame(height: 160)
                .tint(PixelTheme.mexicanRed)
            }
            .padding(.horizontal, 16)
            
            Button(action: { onClose() }) {
                HStack {
                    Text("💾")
                    Text("USE \(selected) MIN")
                        .pixelFont(size: 14, weight: .bold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(PixelTheme.mexicanGreen)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .background(PixelTheme.darkBackground)
    }
}

#Preview {
    HoursView()
        .environmentObject(FirebaseManager.shared)
}
