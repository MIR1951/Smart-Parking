import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct SplashView: View {
    @State private var isActive = false
    @State private var size = 0.8
    @State private var opacity = 0.5
    @State private var isLoading = true
    @State private var dataLoaded = false
    
    @AppStorage("onboardingCompleted") private var onboardingCompleted = false
    @State private var isUserLoggedIn = false
    
    // Ma'lumotlarni saqlash uchun hech qanday o'zgarishsiz
    @State private var parkingSpots: [ParkingSpot] = []
    
    var body: some View {
        ZStack {
            // Fon rangi
            LinearGradient(gradient: Gradient(colors: [Color.purple, Color.purple.opacity(0.8)]), 
                           startPoint: .top, 
                           endPoint: .bottom)
                .edgesIgnoringSafeArea(.all)
            
            if isActive {
                // Keyingi ekranga o'tish
                Group {
                    if !onboardingCompleted {
                        OnboardingView()
                    } else if !isUserLoggedIn {
                        LoginView()
                    } else {
                        TabBarView()
                    }
                }
                .transition(.opacity)
            } else {
                // Splash ekrani ko'rsatish
                VStack {
                    Spacer()
                    
                    VStack {
                        Image("app_logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 150, height: 150)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.white, lineWidth: 2)
                            )
                            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                        
                        Text("Smart Parking")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.top, 20)
                        
                        Text("Qulay parkovka tizimi")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.top, 5)
                        
                        // Yuklash indikatori
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .padding(.top, 20)
                        }
                    }
                    .scaleEffect(size)
                    .opacity(opacity)
                    .onAppear {
                        withAnimation(.easeIn(duration: 1.2)) {
                            self.size = 1.0
                            self.opacity = 1.0
                        }
                    }
                    
                    Spacer()
                    
                    Text("v 1.0.0")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.bottom, 20)
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        withAnimation {
                            self.isLoading = false
                            self.isActive = true
                        }
                        
                    }
                    // Ilovaning ma'lumotlarini yuklash
                    
                    loadData()
                }
            }
        }
    }
    
    // Ma'lumotlarni yuklash, lekin hech narsa yaratimasdan
    private func loadData() {
        // Foydalanuvchi holati
        checkAuthState()
        
        // Firebase-dan parkovka joylarini olish
        fetchParkingSpots { spots in
            self.parkingSpots = spots
            print("Yuklangan parkovka joylari soni: \(spots.count)")
            
            // Keyingi ekranga o'tish, malumotlar yuklangandan so'ng
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation {
                    self.isLoading = false
                    self.isActive = true
                }
            }
        }
    }
    
    // Foydalanuvchi holati
    private func checkAuthState() {
        if let user = Auth.auth().currentUser {
            print("Foydalanuvchi tizimga kirgan: \(user.uid)")
            self.isUserLoggedIn = true
        } else {
            print("Foydalanuvchi tizimga kirmagan")
            self.isUserLoggedIn = false
        }
    }
    
    // Firebase-dan ma'lumotlarni faqat O'QISH (yozish emas)
    private func fetchParkingSpots(completion: @escaping ([ParkingSpot]) -> Void) {
        let db = Firestore.firestore()
        
        db.collection("parkingSpots").getDocuments { snapshot, error in
            if let error = error {
                print("Parkovka joylarini olishda xatolik: \(error.localizedDescription)")
                completion([])
                return
            }
            
            guard let documents = snapshot?.documents else {
                print("Hech qanday parkovka joyi topilmadi")
                completion([])
                return
            }
            
            let spots = documents.compactMap { document -> ParkingSpot? in
                let data = document.data()
                
                guard let name = data["name"] as? String,
                      let address = data["address"] as? String,
                      let pricePerHour = data["pricePerHour"] as? Double else {
                    return nil
                }
                
                return ParkingSpot(
                    id: document.documentID,
                    name: name,
                    address: address,
                    pricePerHour: pricePerHour,
                    spotsAvailable: data["spotsAvailable"] as? Int ?? 0,
                    distance: data["distance"] as? String ?? "",
                    location: data["location"] as? GeoPoint,
                    features: data["features"] as? [String],
                    rating: data["rating"] as? Double,
                    reviewCount: data["reviewCount"] as? Int,
                    category: data["category"] as? String,
                    description: data["description"] as? String,
                    operatedBy: data["operatedBy"] as? String,
                    images: data["images"] as? [String]
                )
            }
            
            completion(spots)
        }
    }
}

struct SplashScreenView: View {
    var body: some View {
        SplashView()
    }
}

struct SplashScreenView_Previews: PreviewProvider {
    static var previews: some View {
        SplashScreenView()
    }
} 
