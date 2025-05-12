import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct SignUpView: View {
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var isAccepted = false
    @State private var isRegistered = false
    @State private var showLogin = false
    @State private var errorMessage = ""
    @State private var showError = false
    
    var body: some View {
        ZStack {
            if isRegistered {
                LocationPermissionView()
            } else if showLogin {
                LoginView()
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        Text("Ro'yxatdan o'tish")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Ma'lumotlaringizni kiriting yoki ijtimoiy tarmoq hisobingiz orqali ro'yxatdan o'ting")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Ism")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            TextField("Komiljon Toshmatov", text: $name)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(10)
                        }
                        .padding(.top, 20)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            TextField("example@gmail.com", text: $email)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(10)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                        }
                        
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
                        }
                        
                        HStack {
                            Button(action: {
                                isAccepted.toggle()
                            }) {
                                ZStack {
                                    Rectangle()
                                        .fill(isAccepted ? Color.purple : Color.white)
                                        .frame(width: 20, height: 20)
                                        .cornerRadius(5)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 5)
                                                .stroke(Color.purple, lineWidth: 1)
                                        )
                                    
                                    if isAccepted {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.white)
                                            .font(.system(size: 12))
                                    }
                                }
                            }
                            
                            Text("Foydalanish shartlari va qoidalariga roziman")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            Spacer()
                        }
                        
                        Button(action: signUp) {
                            Text("Ro'yxatdan o'tish")
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.purple)
                                .cornerRadius(10)
                        }
                        
                        Text("Yoki ro'yxatdan o'tish")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        HStack(spacing: 20) {
                            SocialSignUpButton(image: "applelogo", action: appleSignUp)
                            SocialSignUpButton(image: "g.circle.fill", action: googleSignUp)
                            SocialSignUpButton(image: "f.circle.fill", action: facebookSignUp)
                        }
                        
                        HStack {
                            Text("Hisobingiz bormi?")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            Button("Kirish") {
                                showLogin = true
                            }
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.purple)
                        }
                        .padding(.top, 20)
                    }
                    .padding()
                }
                .alert(isPresented: $showError) {
                    Alert(title: Text("Xatolik"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
                }
            }
        }
    }
    
    func signUp() {
        guard isAccepted else {
            errorMessage = "Foydalanish shartlari va qoidalarini qabul qilishingiz kerak"
            showError = true
            return
        }
        
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                errorMessage = error.localizedDescription
                showError = true
                return
            }
            
            guard let user = result?.user else { return }
            
            // User ma'lumotlarini Firestore'ga saqlash
            let db = Firestore.firestore()
            let userData: [String: Any] = [
                "name": name,
                "email": email,
                "createdAt": Date()
            ]
            
            db.collection("users").document(user.uid).setData(userData) { error in
                if let error = error {
                    errorMessage = error.localizedDescription
                    showError = true
                    return
                }
                
                isRegistered = true
            }
        }
    }
    
    func appleSignUp() {
        // Apple sign up implementation
    }
    
    func googleSignUp() {
        // Google sign up implementation
    }
    
    func facebookSignUp() {
        // Facebook sign up implementation
    }
}

struct SocialSignUpButton: View {
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

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView()
    }
} 