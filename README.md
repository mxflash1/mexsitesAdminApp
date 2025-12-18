# MexiSites Admin - iOS Multi-Tenant Booking Management App

A **white-label iOS admin panel** built with SwiftUI for managing booking websites. This single iOS app serves multiple clients, each with their own Firebase project and customer-facing website.

## 🎯 Overview

This is a **multi-tenant iOS admin panel** designed as a white-label solution where:

- **One iOS app** serves multiple clients
- Each client has their own **separate Firebase project** and **customer-facing website**
- Clients download the app and log in with their credentials
- The app **dynamically connects** to their Firebase project
- They see **only their own data** (bookings, clients, payments, hours)

## 🏗️ Business Model

### The Service

1. Build booking websites for clients (hair salons, barbershops, etc.)
2. Each client gets:
   - A customer-facing booking website (Firebase-hosted)
   - Their own Firebase project with Firestore database
   - Admin credentials for this iOS app
3. Clients download this **single iOS app** from the App Store
4. They log in with their credentials
5. App connects to **their Firebase project** automatically
6. They manage their business through the app

### Current Status

- **First client:** MexiCuts (your own business)
- **Architecture:** Ready for multiple clients
- **Distribution:** Will be distributed via App Store/TestFlight

## 📱 Features

### 1. Calendar View (Tab 1)
- View bookings by date
- See today's appointments
- View upcoming bookings
- Tap booking to see details
- Add new bookings manually
- Delete/cancel bookings

### 2. Hours View (Tab 2)
- Manage business hours per day (Mon-Sun)
- Enable/disable days
- Set open/close times
- **Configure slot duration** (5-190 minutes in 5-min increments)
- Block specific dates (holidays, vacations)
- Save changes to Firebase

### 3. Payments View (Tab 3)
- View pending payments (past appointments not yet paid)
- Confirm payments (Cash or Card)
- **Auto-syncs to Google Sheets** (payment tracking spreadsheet)
- Remove from pending (for manually tracked payments)
- Shows count of pending payments

### 4. Clients View (Tab 4)
- List all clients/customers
- Search by name or phone
- Sort by: Recent, Name, or Visit count
- View client details (booking history, contact info)
- Call/SMS clients directly
- Delete clients

## 🔐 Authentication System

### Current Implementation

- **Local credential validation** (hardcoded in app)
- Username format: `{clientId}_admin` (e.g., `mexicuts_admin`)
- Each client has unique credentials
- Credentials stored in `ClientConfig.swift`

### Login Flow

1. User enters username and password
2. App extracts `clientId` from username (part before `_`)
3. App looks up client's Firebase configuration
4. Validates credentials
5. Dynamically configures Firebase connection
6. Connects to their Firestore database
7. User sees their data

### Current Credentials (MexiCuts)

- **Username:** `mexicuts_admin`
- **Password:** `Martina2016.`
- **Firebase Project:** `mexicuts-booking`

## 🏛️ Architecture: Multi-Tenant Design

### Key Concept

**One app, multiple Firebase backends**

```
iOS App (Single Codebase)
    ↓
Login with credentials
    ↓
ClientConfig.swift looks up client
    ↓
Dynamically configures Firebase
    ↓
Connects to Client's Firebase Project
    ↓
Client sees ONLY their data
```

### Technical Implementation

1. **ClientConfig.swift** - Stores all client Firebase configurations
   - Each client has: API Key, Project ID, Storage Bucket, etc.
   - Maps credentials to Firebase configs

2. **FirebaseManager.swift** - Manages Firebase connections
   - Dynamically creates Firebase app instances per client
   - Handles Firestore queries
   - Manages authentication state

3. **No Firebase Auth** - Uses local credential validation
   - Avoids conflicts with customer authentication
   - Each client's website uses Firebase Auth for customers
   - Admin app uses simple credential check

## 📂 Project Structure

```
MexiSItes_Admin/
├── MexiCutsAdmin/
│   ├── MexiCutsAdminApp.swift      # App entry point, handles login state
│   ├── ContentView.swift            # Main tab view (after login)
│   ├── Models/
│   │   ├── MockData.swift          # Sample data (for testing)
│   │   └── ClientConfig.swift      # Multi-tenant config store
│   ├── Services/
│   │   └── FirebaseManager.swift   # Firebase connection & data management
│   ├── Views/
│   │   ├── LoginView.swift         # Login screen
│   │   ├── CalendarView.swift      # Calendar tab
│   │   ├── HoursView.swift         # Business hours tab
│   │   ├── PaymentsView.swift      # Payments tab
│   │   └── ClientsView.swift       # Clients tab
│   ├── Styles/
│   │   └── PixelTheme.swift        # Design system (colors, fonts, components)
│   └── Assets.xcassets/            # Images, colors
├── GoogleService-Info.plist        # Firebase config (gitignored - contains sensitive keys)
└── MexiCutsAdmin.xcodeproj/        # Xcode project
```

## 🎨 Design System

### Theme: "Pixel Art" Style

- **Dark background** (#000000 or similar)
- **Sharp edges** (no rounded corners)
- **Bold, uppercase text**
- **Color scheme:**
  - Mexican Green: Primary actions
  - Mexican Red: Accents, headers
  - Gray: Secondary text, borders
  - Orange: Pending/warnings
  - Blue: Info, stats

### UI Components

- `PixelCard` - Sharp-edged cards with borders
- `PixelButton` - Bold, uppercase buttons
- `PixelTextField` - Input fields with borders
- `PixelStatCard` - Stats display cards
- `PixelBadge` - Status badges
- `PixelToggle` - Square toggle switches
- `PixelAvatar` - Square avatars with initials

## 🔌 Firebase Integration

### What It Connects To

- **Firestore Database:**
  - `bookings` collection - All appointments
  - `users` collection - Customer/client data
  - `settings/availability` document - Business hours, blocked dates, slot duration

### Key Operations

- **Fetch bookings** - Real-time listener
- **Fetch clients** - Real-time listener
- **Fetch availability** - Real-time listener
- **Save availability** - Update business hours
- **Confirm payment** - Update booking + sync to Google Sheets
- **Delete booking** - Remove from Firestore
- **Add booking** - Create new appointment

### Google Sheets Integration

- When payment is confirmed, app calls Cloud Function
- Cloud Function updates Google Sheets payment tracking
- Sheet columns: When Cut | When Paid | Who | Amount | Cash/Card
- Uses endpoint: `https://updatepaymentstatus-tktzr4t4nq-uc.a.run.app`

## 🚀 Getting Started

### Prerequisites

- Xcode 15.0+
- iOS 17.0+ deployment target
- Swift 5.9+
- Firebase account
- CocoaPods or Swift Package Manager

### Installation

1. Clone the repository:
```bash
git clone https://github.com/mxflash1/mexsitesAdminApp.git
cd MexiSItes_Admin
```

2. Open the project in Xcode:
```bash
open MexiCutsAdmin.xcodeproj
```

3. Add your `GoogleService-Info.plist` file:
   - Download from Firebase Console
   - Place in `MexiCutsAdmin/` directory
   - **Note:** This file is gitignored for security

4. Install dependencies:
   - Firebase packages are managed via Swift Package Manager
   - Xcode will automatically resolve dependencies

5. Build and run:
   - Select your target device/simulator
   - Press ⌘R to build and run

## 🔧 Adding a New Client

### Step 1: Create Their Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create new project for client
3. Set up Firestore database
4. Add iOS app to project
5. Download `GoogleService-Info.plist`
6. Extract credentials:
   - API Key
   - Project ID
   - Storage Bucket
   - Messaging Sender ID
   - App ID

### Step 2: Build Their Website

- Clone website template
- Configure for their Firebase project
- Deploy to Firebase Hosting
- Set up Cloud Functions

### Step 3: Add to iOS App

Edit `ClientConfig.swift`:

```swift
private let configs: [String: ClientConfig] = [
    "mexicuts": ClientConfig(...),
    
    // Add new client:
    "newclient": ClientConfig(
        clientId: "newclient",
        clientName: "New Client Name",
        firebaseConfig: ClientConfig.FirebaseProjectConfig(
            apiKey: "FROM_GOOGLE_SERVICE_INFO",
            projectId: "newclient-booking",
            storageBucket: "newclient-booking.firebasestorage.app",
            messagingSenderId: "FROM_GOOGLE_SERVICE_INFO",
            appId: "FROM_GOOGLE_SERVICE_INFO",
            databaseURL: nil
        )
    )
]
```

### Step 4: Add Credentials

In `validateCredentials` method:

```swift
if clientId == "newclient" && username == "newclient_admin" && password == "TheirPassword123" {
    return true
}
```

### Step 5: Distribute

- Client downloads app from App Store
- Logs in with: `newclient_admin` / `TheirPassword123`
- App connects to their Firebase
- They see their data

## 📊 Data Models

### Booking
- `id`, `name`, `phone`, `timeSlot`, `notes`, `date`
- `paymentStatus` (pending/paid)
- `paymentMethod` (cash/card)
- `userId` (if linked to user account)

### Client
- `id`, `name`, `phone`, `createdAt`, `bookingCount`
- Computed: `initials`, `formattedJoinDate`

### DayHours
- `day`, `isEnabled`, `startTime`, `endTime`

### BlockedDate
- `date`, `reason`

## 🛠️ Technical Details

### Dependencies

- **Firebase iOS SDK** (via Swift Package Manager)
  - FirebaseCore
  - FirebaseFirestore
  - FirebaseAuth (not currently used, but available)

### iOS Version

- Minimum: iOS 17.0+
- Built with: SwiftUI, Swift 5.9+

### Key SwiftUI Patterns

- `@StateObject` for FirebaseManager
- `@Published` properties for reactive updates
- `@EnvironmentObject` for dependency injection
- Real-time Firestore listeners
- Async/await for network calls

### State Management

- `FirebaseManager` is a singleton (`shared`)
- ObservableObject for SwiftUI updates
- Published properties trigger UI refreshes
- UserDefaults for session persistence

## 🔒 Security

### Current Implementation

- **Credentials:** Hardcoded in app (development phase)
- **Firebase Configs:** Stored in app code
- **API Keys:** Stored in `GoogleService-Info.plist` (gitignored)

### Production Recommendations

- Use secure backend API for credential validation
- JWT tokens for authentication
- Encrypted configs fetched from server
- Rotate API keys if exposed
- Use environment variables for sensitive data

## 🎯 Current Status

### ✅ Working Features

- Login system (local auth)
- Multi-tenant architecture
- Calendar view with bookings
- Hours management
- Payments tracking
- Client management
- Google Sheets sync
- Real-time data updates

### ⚠️ Known Limitations

- Credential validation is hardcoded (should use backend API)
- Firebase configs stored in app (should be fetched from server)
- No onboarding flow for new clients
- No way to switch between clients without logout

### 🚀 Future Improvements

- Backend API for credential validation
- Dynamic Firebase config fetching
- Client onboarding wizard
- Multi-client switching (for admin to manage multiple)
- Push notifications
- Analytics dashboard
- Export reports

## 🐛 Debugging

### Console Logs

All Firebase operations log with emojis:
- ✅ Success
- ❌ Error
- ⚠️ Warning
- 🔐 Auth
- 📝 Data operations

### Common Issues

1. **Login fails:** Check username format (`clientId_admin`)
2. **No data:** Verify Firebase project connection
3. **Sheets not updating:** Check Cloud Function endpoint
4. **Build errors:** Ensure Firebase packages are added

## 📝 Code Style

### Naming Conventions

- Views: `Pixel{Name}View` (e.g., `PixelBookingCard`)
- Components: `Pixel{Name}` (e.g., `PixelCard`, `PixelButton`)
- Functions: camelCase
- Constants: UPPER_SNAKE_CASE

### SwiftUI Patterns

- Views are structs conforming to `View`
- State managed with `@State`, `@StateObject`, `@Published`
- Environment objects for shared state
- Modifiers for styling (`.pixelCard()`, `.pixelFont()`)

## 📚 Related Projects

### Website (Separate Project)

- Customer-facing booking site
- Uses same Firebase project
- Firebase Auth for customers
- Cloud Functions for notifications

### Cloud Functions

- `updatePaymentStatus` - Updates Google Sheets
- `testPaymentSheetAdd` - Adds booking to payment sheet
- `processCompletedHaircuts` - Auto-adds past appointments

## 🎓 For New Developers

### To Understand This App

1. Start with `LoginView.swift` - Entry point
2. Read `FirebaseManager.swift` - Core logic
3. Check `ClientConfig.swift` - Multi-tenant setup
4. Browse `ContentView.swift` - Main UI structure
5. Review individual view files - Feature implementations

### To Modify

- **Add feature:** Create new view, add to ContentView tabs
- **Change design:** Edit `PixelTheme.swift`
- **Add client:** Edit `ClientConfig.swift`
- **Modify data:** Update `FirebaseManager.swift` methods

### To Test

- Use `MockData.swift` for sample data
- Test with different client configs
- Verify Firebase connections
- Check Google Sheets sync

## 📄 License

[Add your license here]

## 👥 Contributors

- **Primary Developer:** Matias
- **First Client:** MexiCuts

## 📞 Support

For issues, questions, or contributions, please open an issue on GitHub.

---

**Last Updated:** 2025-01-27

**Status:** In active development

**Version:** 1.0.0 (Development)

