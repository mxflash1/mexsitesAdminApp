import SwiftUI
import FirebaseCore

@main
struct MexiCutsAdminApp: App {
    @StateObject private var firebaseManager = FirebaseManager.shared
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            if firebaseManager.isAuthenticated {
                ContentView()
                    .environmentObject(firebaseManager)
                    .onAppear {
                        firebaseManager.fetchBookings()
                        firebaseManager.fetchClients()
                        firebaseManager.fetchAvailability()
                    }
            } else {
                LoginView()
                    .environmentObject(firebaseManager)
            }
        }
    }
}

