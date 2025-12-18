# Multi-Tenant Admin App Architecture

This iOS admin app supports **multiple clients** with separate Firebase projects.

## How It Works

### 1. One App, Multiple Backends
- Single iOS app codebase
- Each client has their own Firebase project
- Dynamic Firebase configuration based on login credentials
- Completely isolated data per client

### 2. Login Flow
```
User enters credentials
  ↓
App validates with ClientConfigStore
  ↓
Retrieves client's Firebase configuration
  ↓
Dynamically configures Firebase connection
  ↓
User sees THEIR bookings/clients/data
```

### 3. Current Clients

#### MexiCuts (First Client)
- **Username:** `mexicuts_admin`
- **Password:** `Martina2016.`
- **Firebase Project:** `mexicuts-booking`

## Adding New Clients

### Step 1: Create Firebase Project
1. Go to https://console.firebase.google.com/
2. Create new project for the client
3. Add iOS app to project
4. Download `GoogleService-Info.plist`
5. Extract these values:
   - API Key
   - Project ID
   - Storage Bucket
   - Messaging Sender ID
   - App ID

### Step 2: Add Client to App

Edit `ios-app/MexiCutsAdmin/Models/ClientConfig.swift`:

```swift
private let configs: [String: ClientConfig] = [
    "mexicuts": ClientConfig(...),
    
    // Add new client here:
    "newclient": ClientConfig(
        clientId: "newclient",
        clientName: "New Client Name",
        firebaseConfig: ClientConfig.FirebaseProjectConfig(
            apiKey: "FROM_GOOGLE_SERVICE_INFO",
            projectId: "newclient-booking",
            storageBucket: "newclient-booking.appspot.com",
            messagingSenderId: "FROM_GOOGLE_SERVICE_INFO",
            appId: "FROM_GOOGLE_SERVICE_INFO",
            databaseURL: nil
        )
    )
]
```

### Step 3: Add Credentials

Update the `validateCredentials` method:

```swift
private func validateCredentials(clientId: String, username: String, password: String) async -> Bool {
    // Add validation for new client
    if clientId == "newclient" && username == "newclient_admin" && password == "TheirPassword123" {
        return true
    }
    
    return false
}
```

### Step 4: Test
1. Rebuild app
2. Login with: `newclient_admin` / `TheirPassword123`
3. App connects to their Firebase project
4. They see only THEIR data

## Username Format

**Format:** `{clientId}_admin`

Examples:
- `mexicuts_admin` → MexiCuts client
- `salon_admin` → Salon client  
- `barber_admin` → Barber client

The clientId (part before `_`) determines which Firebase project to connect to.

## Future Improvements

### Option A: Central Authentication Server (Recommended)
Create a backend API that:
- Stores all client credentials securely
- Validates login requests
- Returns Firebase configuration for authenticated clients
- Supports adding new clients without app updates

```swift
// Replace validateCredentials with API call
func validateCredentials(...) async -> Bool {
    let response = try await apiClient.post("/auth/validate", body: [
        "username": username,
        "password": password
    ])
    return response.isValid
}
```

### Option B: Firebase Auth per Client
Use each client's own Firebase Auth for authentication:
```swift
// Login to their Firebase Auth first
auth.signIn(email, password)
// Then connect to their Firestore
```

### Option C: Master Firebase Project
Create one "master" Firebase project that stores:
- All client credentials
- All client Firebase configurations  
- App queries master, gets config, switches to client's Firebase

## Security Notes

⚠️ **Current Implementation:**
- Credentials are hardcoded in app
- Safe for small number of trusted clients
- Not ideal for scaling

✅ **Production Recommendations:**
1. Move credentials to secure backend
2. Use JWT tokens for session management
3. Implement refresh tokens
4. Add rate limiting
5. Enable 2FA for client admins
6. Encrypt Firebase configs at rest

## Testing Multiple Clients

1. Create test Firebase project
2. Add test client config
3. Login with test credentials
4. Verify data isolation
5. Switch between clients
6. Confirm no data leakage

## Distribution

### App Store
- Publish once
- All clients download same app
- Each logs in with their credentials

### TestFlight
- Share one TestFlight build
- Provide credentials to each client
- They test with their data

### Enterprise Distribution
- Sign with enterprise certificate
- Distribute directly to clients
- Each gets same .ipa file

