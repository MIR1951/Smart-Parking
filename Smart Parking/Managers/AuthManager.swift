import SwiftUI
import FirebaseAuth
import Combine

class AuthManager: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var isOnboardingCompleted: Bool = false
    @Published var currentFirebaseUser: FirebaseAuth.User?
    @Published var appUser: User?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    static let shared = AuthManager()
    
    private init() {
        checkAuthStatus()
        loadOnboardingStatus()
    }
    
    func checkAuthStatus() {
        Auth.auth().addStateDidChangeListener { [weak self] (_, user) in
            withAnimation {
                self?.isLoggedIn = user != nil
                self?.currentFirebaseUser = user
                
                if let user = user {
                    // Firebase user dan app user ga o'tkazish
                    self?.createAppUserFromFirebaseUser(user)
                } else {
                    self?.appUser = nil
                }
            }
        }
    }
    
    // Firebase User dan o'zimizning User modelimizga o'tkazish funksiyasi
    private func createAppUserFromFirebaseUser(_ firebaseUser: FirebaseAuth.User) {
        // Kamida id, email va name ni olamiz
        let user = User(
            id: firebaseUser.uid,
            name: firebaseUser.displayName ?? "Foydalanuvchi",
            email: firebaseUser.email ?? "",
            phoneNumber: firebaseUser.phoneNumber ?? "",
            profileImageURL: firebaseUser.photoURL?.absoluteString,
            createdAt: firebaseUser.metadata.creationDate ?? Date()
        )
        
        self.appUser = user
    }
    
    func loadOnboardingStatus() {
        if let onboardingCompleted = UserDefaults.standard.object(forKey: "onboardingCompleted") as? Bool {
            isOnboardingCompleted = onboardingCompleted
        }
    }
    
    func setOnboardingCompleted() {
        isOnboardingCompleted = true
        UserDefaults.standard.set(true, forKey: "onboardingCompleted")
    }
    
    func signIn(email: String, password: String, completion: @escaping (Bool, String?) -> Void) {
        isLoading = true
        errorMessage = nil
        
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] (result, error) in
            guard let self = self else { return }
            
            self.isLoading = false
            
            if let error = error {
                let errorMessage = self.handleAuthError(error)
                self.errorMessage = errorMessage
                completion(false, errorMessage)
                return
            }
            
            // Kirish muvaffaqiyatli
            self.isLoggedIn = true
            if let user = result?.user {
                self.currentFirebaseUser = user
                self.createAppUserFromFirebaseUser(user)
            }
            completion(true, nil)
        }
    }
    
    func signUp(email: String, password: String, name: String, completion: @escaping (Bool, String?) -> Void) {
        isLoading = true
        errorMessage = nil
        
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] (result, error) in
            guard let self = self else { return }
            
            if let error = error {
                self.isLoading = false
                let errorMessage = self.handleAuthError(error)
                self.errorMessage = errorMessage
                completion(false, errorMessage)
                return
            }
            
            guard let user = result?.user else {
                self.isLoading = false
                self.errorMessage = "Foydalanuvchi ma'lumotlari topilmadi"
                completion(false, "Foydalanuvchi ma'lumotlari topilmadi")
                return
            }
            
            // Foydalanuvchi profilini yangilash
            let changeRequest = user.createProfileChangeRequest()
            changeRequest.displayName = name
            
            changeRequest.commitChanges { [weak self] (error) in
                guard let self = self else { return }
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = "Profil yangilanmadi: \(error.localizedDescription)"
                    completion(false, "Profil yangilanmadi: \(error.localizedDescription)")
                    return
                }
                
                // Ro'yxatdan o'tish muvaffaqiyatli
                self.isLoggedIn = true
                self.currentFirebaseUser = user
                self.createAppUserFromFirebaseUser(user)
                completion(true, nil)
            }
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            isLoggedIn = false
            currentFirebaseUser = nil
            appUser = nil
        } catch {
            print("Chiqishda xatolik: \(error.localizedDescription)")
            errorMessage = "Chiqishda xatolik: \(error.localizedDescription)"
        }
    }
    
    func resetPassword(email: String, completion: @escaping (Bool, String?) -> Void) {
        isLoading = true
        errorMessage = nil
        
        Auth.auth().sendPasswordReset(withEmail: email) { [weak self] error in
            guard let self = self else { return }
            
            self.isLoading = false
            
            if let error = error {
                let errorMessage = self.handleAuthError(error)
                self.errorMessage = errorMessage
                completion(false, errorMessage)
                return
            }
            
            completion(true, nil)
        }
    }
    
    private func handleAuthError(_ error: Error) -> String {
        let errorCode = AuthErrorCode(_bridgedNSError: error as NSError)?.code
        
        switch errorCode {
        case .invalidEmail:
            return "Email formati noto'g'ri"
        case .wrongPassword:
            return "Parol noto'g'ri"
        case .userNotFound:
            return "Foydalanuvchi topilmadi"
        case .emailAlreadyInUse:
            return "Email allaqachon ishlatilgan"
        case .weakPassword:
            return "Parol juda sodda"
        case .networkError:
            return "Internet aloqasi mavjud emas"
        case .tooManyRequests:
            return "Juda ko'p urinishlar. Keyinroq qayta urinib ko'ring"
        default:
            return "Xatolik yuz berdi: \(error.localizedDescription)"
        }
    }
} 
