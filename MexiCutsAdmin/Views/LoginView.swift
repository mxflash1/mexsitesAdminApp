import SwiftUI

struct LoginView: View {
    @EnvironmentObject var firebase: FirebaseManager
    @State private var username = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var showPassword = false
    
    var body: some View {
        ZStack {
            PixelTheme.darkBackground.ignoresSafeArea()
                .onTapGesture {
                    hideKeyboard()
                }
            
            VStack(spacing: 0) {
                Spacer()
                
                // Logo/Title Section
                VStack(spacing: 16) {
                    if firebase.currentClientName.isEmpty {
                        Text("BOOKING")
                            .pixelFont(size: 32, weight: .bold)
                            .foregroundColor(PixelTheme.mexicanGreen)
                    } else {
                        Text(firebase.currentClientName.uppercased())
                            .pixelFont(size: 28, weight: .bold)
                            .foregroundColor(PixelTheme.mexicanGreen)
                    }
                    
                    Text("ADMIN PANEL")
                        .pixelFont(size: 16, weight: .bold)
                        .foregroundColor(PixelTheme.mexicanRed)
                }
                .padding(.bottom, 60)
                
                // Login Form
                VStack(spacing: 20) {
                    // Username Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("USERNAME")
                            .pixelFont(size: 11, weight: .regular)
                            .foregroundColor(PixelTheme.textGray)
                        
                        TextField("", text: $username)
                            .pixelFont(size: 14, weight: .regular)
                            .foregroundColor(.white)
                            .padding(14)
                            .background(PixelTheme.darkBackground)
                            .overlay(
                                Rectangle()
                                    .stroke(PixelTheme.borderGray, lineWidth: 2)
                            )
                            .autocapitalization(.none)
                            .textContentType(.username)
                            .submitLabel(.next)
                            .onSubmit {
                                // Move focus to password field (handled automatically)
                            }
                    }
                    
                    // Password Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("PASSWORD")
                            .pixelFont(size: 11, weight: .regular)
                            .foregroundColor(PixelTheme.textGray)
                        
                        ZStack(alignment: .trailing) {
                            Group {
                                if showPassword {
                                    TextField("", text: $password)
                                } else {
                                    SecureField("", text: $password)
                                }
                            }
                            .pixelFont(size: 14, weight: .regular)
                            .foregroundColor(.white)
                            .padding(14)
                            .padding(.trailing, 40) // Make space for eye button
                            .background(PixelTheme.darkBackground)
                            .overlay(
                                Rectangle()
                                    .stroke(PixelTheme.borderGray, lineWidth: 2)
                            )
                            .textContentType(.password)
                            .submitLabel(.go)
                            .onSubmit {
                                if !username.isEmpty && !password.isEmpty {
                                    handleLogin()
                                }
                            }
                            
                            // Show/Hide Password Button
                            Button(action: { showPassword.toggle() }) {
                                Text(showPassword ? "👁️" : "👁️‍🗨️")
                                    .font(.system(size: 20))
                                    .foregroundColor(PixelTheme.textGray)
                                    .frame(width: 40, height: 40)
                            }
                            .padding(.trailing, 8)
                        }
                    }
                    
                    // Error Message
                    if showError {
                        HStack(spacing: 8) {
                            Text("⚠️")
                            Text(errorMessage)
                                .pixelFont(size: 11, weight: .regular)
                                .foregroundColor(PixelTheme.mexicanRed)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(PixelTheme.mexicanRed.opacity(0.1))
                        .overlay(
                            Rectangle()
                                .stroke(PixelTheme.mexicanRed, lineWidth: 2)
                        )
                    }
                    
                    // Login Button
                    Button(action: handleLogin) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("🔐")
                                Text("LOGIN")
                                    .pixelFont(size: 14, weight: .bold)
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(username.isEmpty || password.isEmpty ? PixelTheme.borderGray : PixelTheme.mexicanGreen)
                    }
                    .disabled(username.isEmpty || password.isEmpty || isLoading)
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 32)
                .pixelCard(borderColor: PixelTheme.mexicanRed.opacity(0.5))
                .padding(.horizontal, 24)
                
                Spacer()
                
                // Footer
                Text("MEXICUTS ADMIN v1.0")
                    .pixelFont(size: 9, weight: .regular)
                    .foregroundColor(PixelTheme.textGray)
                    .padding(.bottom, 24)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("DONE") {
                    hideKeyboard()
                }
                .pixelFont(size: 12, weight: .bold)
                .foregroundColor(PixelTheme.mexicanGreen)
            }
        }
    }
    
    private func handleLogin() {
        hideKeyboard()
        showError = false
        isLoading = true
        
        print("👤 Attempting login with username: '\(username)'")
        print("🔑 Password length: \(password.count)")
        
        Task {
            do {
                try await firebase.login(username: username.trimmingCharacters(in: .whitespaces), 
                                        password: password)
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    isLoading = false
                    print("❌ Login failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    LoginView()
        .environmentObject(FirebaseManager.shared)
}

