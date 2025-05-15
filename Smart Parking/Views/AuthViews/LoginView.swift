import SwiftUI
import FirebaseAuth

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var showSignUp = false
    @State private var showResetPassword = false
    @StateObject private var authManager = AuthManager.shared
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            if authManager.isLoggedIn {
                TabBarView()
            } else if showSignUp {
                SignUpView()
            } else {
                ScrollView {
                    VStack(spacing: 25) {
                        Text("Kirish")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Salom! Qaytganingizdan xursandmiz")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            TextField("example@gmail.com", text: $email)
                                .padding()
                                .background(Color.gray.opacity(0.1)
                                .foregroundStyle(.gray))
                                .cornerRadius(10)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .disabled(authManager.isLoading)
                        }
                        .padding(.top, 20)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Parol")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            HStack {
                                if showPassword {
                                    TextField("********", text: $password)
                                } else {
                                    SecureField("********", text: $password)
                                }
                                
                                Button(action: {
                                    showPassword.toggle()
                                }) {
                                    Image(systemName: showPassword ? "eye.slash" : "eye")
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                            .disabled(authManager.isLoading)
                        }
                        
                        HStack {
                            Spacer()
                            Button("Parolni unutdingizmi?") {
                                showResetPassword = true
                            }
                            .font(.subheadline)
                            .foregroundColor(.purple)
                            .disabled(authManager.isLoading)
                        }
                        
                        if let errorMessage = authManager.errorMessage {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.top, 5)
                        }
                        
                        Button(action: login) {
                            if authManager.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Kirish")
                                    .fontWeight(.bold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .disabled(email.isEmpty || password.isEmpty || authManager.isLoading)
                        .opacity(email.isEmpty || password.isEmpty || authManager.isLoading ? 0.6 : 1)
                        .padding(.top, 20)
                        
                        Text("Yoki kirish")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        HStack(spacing: 20) {
                            SocialLoginButton(image: "applelogo", action: appleLogin)
                            SocialLoginButton(image: "g.circle.fill", action: googleLogin)
                            SocialLoginButton(image: "f.circle.fill", action: facebookLogin)
                        }
                        
                        HStack {
                            Text("Hisobingiz yo'qmi?")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            Button("Ro'yxatdan o'tish") {
                                showSignUp = true
                            }
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.purple)
                            .disabled(authManager.isLoading)
                        }
                        .padding(.top, 20)
                    }
                    .padding()
                }
            }
        }
        .sheet(isPresented: $showResetPassword) {
            ResetPasswordView()
        }
    }
    
    func login() {
        authManager.signIn(email: email, password: password) { success, error in
            // Kirish muvaffaqiyatli bo'lganda TabBarView ga o'tkaziladi
            // Bu authManager.isLoggedIn orqali avtomatik boshqariladi
        }
    }
    
    func appleLogin() {
        // Apple login implementation
    }
    
    func googleLogin() {
        // Google login implementation
    }
    
    func facebookLogin() {
        // Facebook login implementation
    }
}

struct ResetPasswordView: View {
    @State private var email = ""
    @State private var isSuccess = false
    @StateObject private var authManager = AuthManager.shared
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Parolni tiklash")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Email manzilingizni kiriting. Parolni tiklash uchun ko'rsatma jo'natamiz.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding()
                
                TextField("Email manzil", text: $email)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .disabled(authManager.isLoading)
                    .padding(.horizontal)
                
                if let errorMessage = authManager.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.top, 5)
                }
                
                if isSuccess {
                    Text("Parolni tiklash uchun ko'rsatmalar emailingizga jo'natildi")
                        .font(.caption)
                        .foregroundColor(.green)
                        .padding(.top, 5)
                }
                
                Button(action: resetPassword) {
                    if authManager.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Parolni tiklash")
                            .fontWeight(.bold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.purple)
                .foregroundColor(.white)
                .cornerRadius(10)
                .disabled(email.isEmpty || authManager.isLoading)
                .opacity(email.isEmpty || authManager.isLoading ? 0.6 : 1)
                .padding()
                
                Spacer()
            }
            .navigationBarTitle("", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Yopish") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    func resetPassword() {
        authManager.resetPassword(email: email) { success, error in
            if success {
                isSuccess = true
            }
        }
    }
}

struct SocialLoginButton: View {
    let image: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 24)
                .padding()
                .foregroundColor(.gray)
                .background(
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
} 
