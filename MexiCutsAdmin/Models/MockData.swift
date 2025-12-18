import Foundation

// MARK: - Booking Model
struct Booking: Identifiable {
    let id: String
    let name: String
    let phone: String
    let timeSlot: String
    let notes: String
    let date: Date
    var paymentStatus: PaymentStatus
    var paymentMethod: PaymentMethod?
    var userId: String?
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: date)
    }
    
    var formattedTime: String {
        let parts = timeSlot.split(separator: " ")
        if parts.count >= 3 {
            return "\(parts[1]) \(parts[2])"
        }
        return timeSlot
    }
    
    var isPast: Bool {
        return date < Date()
    }
}

enum PaymentStatus: String {
    case pending = "Pending"
    case paid = "Paid"
}

enum PaymentMethod: String {
    case cash = "Cash"
    case card = "Card"
}

// MARK: - Client Model
struct Client: Identifiable {
    let id: String
    let name: String
    let phone: String
    let createdAt: Date
    let bookingCount: Int
    
    var initials: String {
        let parts = name.split(separator: " ")
        let initials = parts.prefix(2).compactMap { $0.first }.map { String($0) }
        return initials.joined().uppercased()
    }
    
    var formattedJoinDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: createdAt)
    }
}

// MARK: - Business Hours Model
struct DayHours: Identifiable {
    let id = UUID()
    let day: String
    var isEnabled: Bool
    var startTime: String
    var endTime: String
}

// MARK: - Blocked Date Model
struct BlockedDate: Identifiable {
    let id = UUID()
    let date: Date
    let reason: String
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d, yyyy"
        return formatter.string(from: date)
    }
}

// MARK: - Mock Data
class MockData {
    static let shared = MockData()
    
    let bookings: [Booking] = [
        Booking(id: "1", name: "James Wilson", phone: "+61402098123", timeSlot: "2025-12-08 10:00 AM", notes: "Short on sides", date: Calendar.current.date(byAdding: .day, value: 1, to: Date())!, paymentStatus: .pending),
        Booking(id: "2", name: "Michael Chen", phone: "+61412345678", timeSlot: "2025-12-08 10:30 AM", notes: "", date: Calendar.current.date(byAdding: .day, value: 1, to: Date())!, paymentStatus: .pending),
        Booking(id: "3", name: "David Thompson", phone: "+61423456789", timeSlot: "2025-12-08 02:00 PM", notes: "Fade please", date: Calendar.current.date(byAdding: .day, value: 1, to: Date())!, paymentStatus: .pending),
        Booking(id: "4", name: "Chris Martinez", phone: "+61434567890", timeSlot: "2025-12-09 09:00 AM", notes: "Same as last time", date: Calendar.current.date(byAdding: .day, value: 2, to: Date())!, paymentStatus: .pending),
        Booking(id: "5", name: "Ryan O'Brien", phone: "+61445678901", timeSlot: "2025-12-09 11:00 AM", notes: "", date: Calendar.current.date(byAdding: .day, value: 2, to: Date())!, paymentStatus: .pending),
        // Past bookings
        Booking(id: "6", name: "James Wilson", phone: "+61402098123", timeSlot: "2025-12-01 10:00 AM", notes: "", date: Calendar.current.date(byAdding: .day, value: -6, to: Date())!, paymentStatus: .paid, paymentMethod: .cash),
        Booking(id: "7", name: "Michael Chen", phone: "+61412345678", timeSlot: "2025-11-30 02:30 PM", notes: "Buzz cut", date: Calendar.current.date(byAdding: .day, value: -7, to: Date())!, paymentStatus: .paid, paymentMethod: .card),
        Booking(id: "8", name: "Alex Kim", phone: "+61467890123", timeSlot: "2025-11-29 11:30 AM", notes: "", date: Calendar.current.date(byAdding: .day, value: -8, to: Date())!, paymentStatus: .paid, paymentMethod: .cash),
    ]
    
    let clients: [Client] = [
        Client(id: "1", name: "James Wilson", phone: "0402098123", createdAt: Calendar.current.date(byAdding: .day, value: -60, to: Date())!, bookingCount: 8),
        Client(id: "2", name: "Michael Chen", phone: "0412345678", createdAt: Calendar.current.date(byAdding: .day, value: -45, to: Date())!, bookingCount: 5),
        Client(id: "3", name: "Chris Martinez", phone: "0434567890", createdAt: Calendar.current.date(byAdding: .day, value: -30, to: Date())!, bookingCount: 3),
        Client(id: "4", name: "Ryan O'Brien", phone: "0445678901", createdAt: Calendar.current.date(byAdding: .day, value: -20, to: Date())!, bookingCount: 2),
        Client(id: "5", name: "Alex Kim", phone: "0467890123", createdAt: Calendar.current.date(byAdding: .day, value: -15, to: Date())!, bookingCount: 4),
        Client(id: "6", name: "Sam Nguyen", phone: "0478901234", createdAt: Calendar.current.date(byAdding: .day, value: -5, to: Date())!, bookingCount: 1),
        Client(id: "7", name: "Jake Brown", phone: "0489012345", createdAt: Calendar.current.date(byAdding: .day, value: -2, to: Date())!, bookingCount: 1),
    ]
    
    var businessHours: [DayHours] = [
        DayHours(day: "Monday", isEnabled: false, startTime: "09:00", endTime: "17:00"),
        DayHours(day: "Tuesday", isEnabled: true, startTime: "15:30", endTime: "16:30"),
        DayHours(day: "Wednesday", isEnabled: false, startTime: "09:00", endTime: "17:00"),
        DayHours(day: "Thursday", isEnabled: true, startTime: "15:30", endTime: "16:30"),
        DayHours(day: "Friday", isEnabled: false, startTime: "09:00", endTime: "17:00"),
        DayHours(day: "Saturday", isEnabled: true, startTime: "08:00", endTime: "18:00"),
        DayHours(day: "Sunday", isEnabled: false, startTime: "09:00", endTime: "17:00"),
    ]
    
    var blockedDates: [BlockedDate] = [
        BlockedDate(date: Calendar.current.date(from: DateComponents(year: 2025, month: 12, day: 25))!, reason: "Christmas Day"),
        BlockedDate(date: Calendar.current.date(from: DateComponents(year: 2025, month: 12, day: 26))!, reason: "Boxing Day"),
        BlockedDate(date: Calendar.current.date(from: DateComponents(year: 2026, month: 1, day: 1))!, reason: "New Year's Day"),
    ]
    
    var upcomingBookings: [Booking] {
        bookings.filter { !$0.isPast }.sorted { $0.date < $1.date }
    }
    
    var pastBookings: [Booking] {
        bookings.filter { $0.isPast }.sorted { $0.date > $1.date }
    }
    
    var pendingPayments: [Booking] {
        bookings.filter { $0.isPast && $0.paymentStatus == .pending }
    }
}

