import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

@main
struct Smart_ParkingApp: App {
    @State private var dataLoadingError: String? = nil
    
    init() {
        // Firebase-ni sozlash
        FirebaseApp.configure()
        
        // Logging sozlamalari
        setupLogging()
        
        // Firebase xatoliklarini kuzatish
        Auth.auth().addStateDidChangeListener { (auth, user) in
            if let error = auth.currentUser?.uid {
                print("Firebase Auth Error: \(error)")
            }
        }
        
        // Parking ma'lumotlarini FirebasegaDataga yuklash uchun funksiya
        // Bu kod birinchi marta ishga tushganda yoki debug rejimida ishlaydi
        #if DEBUG
        // Debug rejimida ma'lumotlarni yuklash
       
        #endif
       
    }
    
    var body: some Scene {
        WindowGroup {
            SplashView()
                .alert("Xatolik", isPresented: .constant(dataLoadingError != nil)) {
                    Button("OK", role: .cancel) {
                        dataLoadingError = nil
                    }
                } message: {
                    if let error = dataLoadingError {
                        Text(error)
                    }
                }
        }
    }
    
    // Logging tizimini sozlash
    private func setupLogging() {
        #if DEBUG
        // Debug rejimida ko'proq ma'lumot
        FirebaseConfiguration.shared.setLoggerLevel(.debug)
        #else
        // Release rejimida faqat xatoliklar
        FirebaseConfiguration.shared.setLoggerLevel(.error)
        #endif
    }
}



