import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct SplashView: View {
    @State private var isActive = false
    @State private var isDataLoaded = false
    @State private var loadingProgress = 0.0
    @State private var loadingStatus = "Ma'lumotlar yuklanmoqda..."
    @StateObject private var authManager = AuthManager.shared
    @State private var retryCount = 0
    private let maxRetries = 3
    
    var body: some View {
        ZStack {
            // Background color - purple
            Color(UIColor(red: 107/255, green: 60/255, blue: 234/255, alpha: 1.0))
                .ignoresSafeArea()
            
            VStack(spacing: 25) {
                // Logo
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 70, height: 70)
                    
                    Text("P")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(Color(UIColor(red: 107/255, green: 60/255, blue: 234/255, alpha: 1.0)))
                }
                
                // App name
                Text("Avtomobil parkovkasi")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer().frame(height: 40)
                
                // Loading indicator
                if !isActive {
                    VStack(spacing: 15) {
                        // Progress indikatori
                        ZStack {
                            Circle()
                                .stroke(lineWidth: 4)
                                .opacity(0.3)
                                .foregroundColor(.white)
                                .frame(width: 50, height: 50)
                            
                            Circle()
                                .trim(from: 0.0, to: CGFloat(min(loadingProgress, 1.0)))
                                .stroke(style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                                .foregroundColor(.white)
                                .rotationEffect(Angle(degrees: 270.0))
                                .frame(width: 50, height: 50)
                                .animation(.linear, value: loadingProgress)
                            
                            if loadingProgress >= 1.0 {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        
                        // Loading status
                        Text(loadingStatus)
                            .foregroundColor(.white.opacity(0.8))
                            .font(.caption)
                    }
                }
            }
            
            // Bottom indicator (Home bar)
            VStack {
                Spacer()
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 150, height: 5)
                    .cornerRadius(2.5)
                    .padding(.bottom, 10)
            }
        }
        .onAppear {
            // Load Firebase data
            loadFirebaseData()
        }
        .fullScreenCover(isPresented: $isActive) {
            if authManager.isLoggedIn {
                if authManager.isOnboardingCompleted {
                    // User is logged in and has completed onboarding
                    TabBarView()
                } else {
                    // User is logged in but hasn't completed onboarding
                    OnboardingView()
                }
            } else {
                // User is not logged in
                if authManager.isOnboardingCompleted {
                    // Onboarding completed but not logged in
                    LoginView()
                } else {
                    // Neither logged in nor onboarding completed
                    OnboardingView()
                }
            }
        }
    }
    
    private func loadFirebaseData() {
        // Initialize FirestoreService
        let firestoreService = FirestoreService.shared
        
        // Start with some initial progress
        loadingProgress = 0.2
        loadingStatus = "Ma'lumotlarni tekshirish..."
        
        // Schedule work with a slight delay to allow UI to render
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            // Preload all app data
            loadingProgress = 0.4
            loadingStatus = "Ma'lumotlar yuklanmoqda..."
            
            firestoreService.preloadAppData { success in
                if success {
                    loadingProgress = 0.8
                    loadingStatus = "Ma'lumotlar muvaffaqiyatli yuklandi"
                    
                    // Check authentication status and complete loading
                    authManager.checkAuthStatus()
                    
                    loadingProgress = 1.0
                    loadingStatus = "Ilovaga kirish..."
                    
                    // Make sure we show splash screen for at least 2.5 seconds total
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        isDataLoaded = true
                        isActive = true
                    }
                } else {
                    // Handle data loading failure
                    if retryCount < maxRetries {
                        retryCount += 1
                        loadingStatus = "Qayta urinish \(retryCount)/\(maxRetries)..."
                        loadingProgress = 0.3
                        
                        // Retry after a delay with exponential backoff
                        let delay = Double(retryCount) * 2.0
                        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                            loadingProgress = 0.0
                            loadFirebaseData()
                        }
                    } else {
                        // Max retries reached, proceed anyway
                        loadingStatus = "Ma'lumotlarni yuklashda xatolik! Ilovani qayta ishga tushiring."
                        loadingProgress = 1.0
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            isDataLoaded = true
                            isActive = true
                        }
                    }
                }
            }
        }
    }
}

struct SplashView_Previews: PreviewProvider {
    static var previews: some View {
        SplashView()
    }
} 
