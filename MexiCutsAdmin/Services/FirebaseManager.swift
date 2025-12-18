import Foundation
import FirebaseCore
import FirebaseFirestore

class FirebaseManager: ObservableObject {
    static let shared = FirebaseManager()
    
    private var db: Firestore!
    private var currentClientId: String?
    
    @Published var bookings: [Booking] = []
    @Published var clients: [Client] = []
    @Published var businessHours: [DayHours] = []
    @Published var blockedDates: [BlockedDate] = []
    @Published var slotDurationMinutes: Int = 30
    @Published var isLoading = false
    @Published var error: String?
    @Published var isAuthenticated = false
    @Published var currentClientName: String = ""
    
    private init() {
        // Don't initialize Firebase yet - wait for login
        // Check if user was previously logged in
        if let savedClientId = UserDefaults.standard.string(forKey: "currentClientId") {
            currentClientId = savedClientId
            // Try to restore previous session
            if let config = ClientConfigStore.shared.getConfig(for: savedClientId) {
                configureFirebase(with: config)
                isAuthenticated = true
            }
        }
    }
    
    private func configureFirebase(with config: ClientConfig) {
        print("🔧 Configuring Firebase for client: \(config.clientName)")
        
        // Check if Firebase app with this name exists
        let appName = "client_\(config.clientId)"
        
        if let existingApp = FirebaseApp.app(name: appName) {
            print("♻️ Reusing existing Firebase app")
            db = Firestore.firestore(app: existingApp)
        } else {
            // Create new Firebase configuration
            let options = FirebaseOptions(
                googleAppID: config.firebaseConfig.appId,
                gcmSenderID: config.firebaseConfig.messagingSenderId
            )
            options.apiKey = config.firebaseConfig.apiKey
            options.projectID = config.firebaseConfig.projectId
            options.storageBucket = config.firebaseConfig.storageBucket
            options.databaseURL = config.firebaseConfig.databaseURL
            
            // Configure new Firebase app
            FirebaseApp.configure(name: appName, options: options)
            
            if let app = FirebaseApp.app(name: appName) {
                db = Firestore.firestore(app: app)
                print("✅ Firebase configured for \(config.clientName)")
            } else {
                print("❌ Failed to configure Firebase")
            }
        }
        
        currentClientId = config.clientId
        currentClientName = config.clientName
    }
    
    // MARK: - Bookings
    
    func fetchBookings() {
        isLoading = true
        
        db.collection("bookings")
            .addSnapshotListener { [weak self] snapshot, error in
                self?.isLoading = false
                
                if let error = error {
                    self?.error = error.localizedDescription
                    print("❌ Error fetching bookings: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self?.bookings = []
                    return
                }
                
                self?.bookings = documents.compactMap { doc -> Booking? in
                    let data = doc.data()
                    
                    guard let name = data["name"] as? String,
                          let phone = data["phone"] as? String,
                          let timeSlot = data["timeSlot"] as? String else {
                        return nil
                    }
                    
                    let notes = data["notes"] as? String ?? ""
                    let paymentStatusRaw = data["paymentStatus"] as? String ?? "pending"
                    let paymentMethodRaw = data["paymentMethod"] as? String
                    let userId = data["userId"] as? String
                    
                    let paymentStatus: PaymentStatus = paymentStatusRaw == "paid" ? .paid : .pending
                    var paymentMethod: PaymentMethod? = nil
                    if let methodRaw = paymentMethodRaw {
                        paymentMethod = methodRaw == "cash" ? .cash : .card
                    }
                    
                    // Parse date from timeSlot
                    let date = self?.parseTimeSlot(timeSlot) ?? Date()
                    
                    return Booking(
                        id: doc.documentID,
                        name: name,
                        phone: phone,
                        timeSlot: timeSlot,
                        notes: notes,
                        date: date,
                        paymentStatus: paymentStatus,
                        paymentMethod: paymentMethod,
                        userId: userId
                    )
                }
                
                print("✅ Fetched \(self?.bookings.count ?? 0) bookings")
            }
    }
    
    func deleteBooking(_ bookingId: String) async throws {
        try await db.collection("bookings").document(bookingId).delete()
        print("✅ Deleted booking: \(bookingId)")
    }
    
    func updateBooking(_ bookingId: String, data: [String: Any]) async throws {
        try await db.collection("bookings").document(bookingId).updateData(data)
        print("✅ Updated booking: \(bookingId)")
    }
    
    func addBooking(_ data: [String: Any]) async throws {
        try await db.collection("bookings").addDocument(data: data)
        print("✅ Added new booking")
    }
    
    // MARK: - Clients (Users)
    
    func fetchClients() {
        isLoading = true
        
        db.collection("users")
            .addSnapshotListener { [weak self] snapshot, error in
                self?.isLoading = false
                
                if let error = error {
                    self?.error = error.localizedDescription
                    print("❌ Error fetching clients: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self?.clients = []
                    return
                }
                
                self?.clients = documents.compactMap { doc -> Client? in
                    let data = doc.data()
                    
                    guard let name = data["name"] as? String,
                          let phone = data["phone"] as? String else {
                        return nil
                    }
                    
                    let bookingCount = data["bookingCount"] as? Int ?? 0
                    
                    var createdAt = Date()
                    if let timestamp = data["createdAt"] as? Timestamp {
                        createdAt = timestamp.dateValue()
                    }
                    
                    return Client(
                        id: doc.documentID,
                        name: name,
                        phone: phone,
                        createdAt: createdAt,
                        bookingCount: bookingCount
                    )
                }
                
                print("✅ Fetched \(self?.clients.count ?? 0) clients")
            }
    }
    
    func deleteClient(_ clientId: String) async throws {
        try await db.collection("users").document(clientId).delete()
        print("✅ Deleted client: \(clientId)")
    }
    
    // MARK: - Availability Settings
    
    func fetchAvailability() {
        db.collection("settings").document("availability")
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("❌ Error fetching availability: \(error)")
                    // Use defaults
                    self?.setupDefaultHours()
                    return
                }
                
                guard let data = snapshot?.data(),
                      let businessHoursData = data["businessHours"] as? [String: [String: Any]] else {
                    self?.setupDefaultHours()
                    return
                }
                
                // Slot duration (minutes) stored at the root of the availability doc
                if let slotDuration = data["slotDuration"] as? Int {
                    self?.slotDurationMinutes = slotDuration
                } else {
                    self?.slotDurationMinutes = 30
                }
                
                let days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
                
                self?.businessHours = days.compactMap { day -> DayHours? in
                    guard let dayData = businessHoursData[day] else {
                        return DayHours(day: day, isEnabled: false, startTime: "09:00", endTime: "17:00")
                    }
                    
                    let isEnabled = dayData["enabled"] as? Bool ?? false
                    let startTime = dayData["startTime"] as? String ?? "09:00"
                    let endTime = dayData["endTime"] as? String ?? "17:00"
                    
                    return DayHours(day: day, isEnabled: isEnabled, startTime: startTime, endTime: endTime)
                }
                
                // Parse blocked dates
                if let blockedDatesData = data["blockedDates"] as? [String: [String: Any]] {
                    self?.blockedDates = blockedDatesData.compactMap { (dateString, dateData) -> BlockedDate? in
                        let formatter = DateFormatter()
                        formatter.dateFormat = "yyyy-MM-dd"
                        
                        guard let date = formatter.date(from: dateString) else { return nil }
                        let reason = dateData["reason"] as? String ?? "Blocked"
                        
                        return BlockedDate(date: date, reason: reason)
                    }
                }
                
                print("✅ Fetched availability settings")
            }
    }
    
    func saveAvailability() async throws {
        var businessHoursDict: [String: [String: Any]] = [:]
        
        for dayHours in businessHours {
            businessHoursDict[dayHours.day] = [
                "enabled": dayHours.isEnabled,
                "startTime": dayHours.startTime,
                "endTime": dayHours.endTime,
                "slotDuration": 30
            ]
        }
        
        var blockedDatesDict: [String: [String: Any]] = [:]
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        for blockedDate in blockedDates {
            let dateString = formatter.string(from: blockedDate.date)
            blockedDatesDict[dateString] = [
                "reason": blockedDate.reason
            ]
        }
        
        try await db.collection("settings").document("availability").setData([
            "businessHours": businessHoursDict,
            "blockedDates": blockedDatesDict,
            "slotDuration": slotDurationMinutes
        ], merge: true)
        
        print("✅ Saved availability settings")
    }
    
    // MARK: - Payments
    
    func confirmPayment(bookingId: String, method: PaymentMethod) async throws {
        // First check if booking is in payment sheet, if not add it
        let bookingDoc = try await db.collection("bookings").document(bookingId).getDocument()
        guard let data = bookingDoc.data() else {
            throw NSError(domain: "FirebaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Booking not found"])
        }
        
        let addedToPaymentSheet = data["addedToPaymentSheet"] as? Bool ?? false
        
        // If not in sheet yet, add it first
        if !addedToPaymentSheet {
            print("⚠️ Booking not in payment sheet yet, adding now...")
            try await addBookingToPaymentSheet(bookingId: bookingId)
        }
        
        // Update Firestore
        try await db.collection("bookings").document(bookingId).updateData([
            "paymentStatus": "paid",
            "paymentMethod": method == .cash ? "cash" : "card",
            "paymentConfirmedAt": FieldValue.serverTimestamp()
        ])
        print("✅ Confirmed payment for: \(bookingId)")
        
        // Mirror website behavior: update Google Sheet via Cloud Function
        await syncPaymentToSheet(bookingId: bookingId, method: method)
    }
    
    // Add booking to payment sheet if not already there
    private func addBookingToPaymentSheet(bookingId: String) async throws {
        guard let url = URL(string: "https://testpaymentsheetadd-tktzr4t4nq-uc.a.run.app?bookingId=\(bookingId)") else {
            print("❌ Invalid test endpoint URL")
            return
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        if let httpResponse = response as? HTTPURLResponse {
            let responseText = String(data: data, encoding: .utf8) ?? ""
            print("📝 Add to payment sheet response (\(httpResponse.statusCode)): \(responseText)")
            
            if httpResponse.statusCode != 200 {
                print("⚠️ Non-200 response when adding to payment sheet, but continuing...")
            } else {
                print("✅ Successfully added booking to payment sheet")
            }
        }
    }
    
    // Remove booking from pending payments (mark as paid without tracking)
    func removeFromPending(bookingId: String) async throws {
        try await db.collection("bookings").document(bookingId).updateData([
            "paymentStatus": "paid",
            "paymentMethod": "cash",
            "paymentConfirmedAt": FieldValue.serverTimestamp()
        ])
        print("✅ Removed from pending: \(bookingId)")
    }
    
    // MARK: - Authentication (Multi-Tenant)
    
    func login(username: String, password: String) async throws {
        print("🔐 Attempting login for: \(username)")
        
        let trimmedUsername = username.trimmingCharacters(in: .whitespaces)
        
        // Get client configuration based on credentials
        let config = try await ClientConfigStore.shared.getConfigForCredentials(
            username: trimmedUsername,
            password: password
        )
        
        // Configure Firebase for this client
        await MainActor.run {
            self.configureFirebase(with: config)
            self.isAuthenticated = true
            
            // Save session
            UserDefaults.standard.set(config.clientId, forKey: "currentClientId")
            
            print("✅ Logged in as \(config.clientName)")
        }
    }
    
    func logout() {
        isAuthenticated = false
        currentClientId = nil
        currentClientName = ""
        
        // Clear saved session
        UserDefaults.standard.removeObject(forKey: "currentClientId")
        
        // Clear all data
        bookings = []
        clients = []
        businessHours = []
        blockedDates = []
        
        print("✅ Logged out")
    }
    
    // MARK: - Helpers
    
    private func parseTimeSlot(_ timeSlot: String) -> Date {
        // Format: "2025-12-08 10:00 AM"
        let parts = timeSlot.split(separator: " ")
        guard parts.count >= 3 else { return Date() }
        
        let datePart = String(parts[0])
        let timePart = String(parts[1])
        let ampm = String(parts[2])
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd h:mm a"
        
        if let date = formatter.date(from: "\(datePart) \(timePart) \(ampm)") {
            return date
        }
        
        return Date()
    }
    
    private func setupDefaultHours() {
        businessHours = [
            DayHours(day: "Monday", isEnabled: false, startTime: "09:00", endTime: "17:00"),
            DayHours(day: "Tuesday", isEnabled: true, startTime: "15:30", endTime: "16:30"),
            DayHours(day: "Wednesday", isEnabled: false, startTime: "09:00", endTime: "17:00"),
            DayHours(day: "Thursday", isEnabled: true, startTime: "15:30", endTime: "16:30"),
            DayHours(day: "Friday", isEnabled: false, startTime: "09:00", endTime: "17:00"),
            DayHours(day: "Saturday", isEnabled: true, startTime: "08:00", endTime: "18:00"),
            DayHours(day: "Sunday", isEnabled: false, startTime: "09:00", endTime: "17:00"),
        ]
    }
    
    // MARK: - Computed Properties
    
    var upcomingBookings: [Booking] {
        bookings.filter { !$0.isPast }.sorted { $0.date < $1.date }
    }
    
    var pastBookings: [Booking] {
        bookings.filter { $0.isPast }.sorted { $0.date > $1.date }
    }
    
    var pendingPayments: [Booking] {
        bookings.filter { $0.isPast && $0.paymentStatus == .pending }
    }
    
    var completedPayments: [Booking] {
        bookings.filter { $0.paymentStatus == .paid }
    }
    
    func bookingsForDate(_ date: Date) -> [Booking] {
        bookings.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }
    
    // MARK: - Payment Sync Helpers
    
    private func syncPaymentToSheet(bookingId: String, method: PaymentMethod) async {
        guard let url = URL(string: "https://updatepaymentstatus-tktzr4t4nq-uc.a.run.app") else { return }
        
        // Match website format: "10 December 2025"
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM yyyy"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        let paymentDate = formatter.string(from: Date())
        
        let payload: [String: Any] = [
            "bookingId": bookingId,
            "paymentMethod": method == .cash ? "cash" : "card",
            "paymentDate": paymentDate,
            "methodOnly": false
        ]
        
        do {
            let data = try JSONSerialization.data(withJSONObject: payload, options: [])
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = data
            
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                print("⚠️ Payment sheet sync responded with status: \(httpResponse.statusCode)")
            } else {
                print("✅ Payment sheet sync succeeded for \(bookingId)")
            }
        } catch {
            print("❌ Payment sheet sync failed: \(error.localizedDescription)")
        }
    }
}

