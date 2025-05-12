import SwiftUI
import FirebaseFirestore
import FirebaseAuth

class ParkingViewModel: ObservableObject {
    @Published var popularSpots: [ParkingSpot] = []
    @Published var nearbySpots: [ParkingSpot] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    
    private let dbManager = DatabaseManager()
    
    // Barcha parking joylarini olish
    func fetchSpots() {
        isLoading = true
        errorMessage = nil
        
        dbManager.fetchParkingSpots { [weak self] spots, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    
                    #if DEBUG
                    // Debug rejimida test ma'lumotlari bilan ishlash
                    self.createSampleData()
                    #endif
                    return
                }
                
                guard let spots = spots, !spots.isEmpty else {
                    self.errorMessage = "Parking joylar topilmadi"
                    
                    #if DEBUG
                    // Debug rejimida test ma'lumotlari bilan ishlash
                    self.createSampleData()
                    #endif
                    return
                }
                
                // Parking joylarini ikkiga bo'lib, popular va nearby qilib ko'rsatamiz
                let middleIndex = spots.count / 2
                self.popularSpots = Array(spots[0..<min(middleIndex, spots.count)])
                self.nearbySpots = Array(spots[middleIndex..<spots.count])
            }
        }
    }
    
    #if DEBUG
    // Test uchun sample ma'lumotlarni yaratish - faqat DEBUG rejimida mavjud
    private func createSampleData() {
        let location1 = GeoPoint(latitude: 41.549667, longitude: 60.630861)
        let location2 = GeoPoint(latitude: 41.555123, longitude: 60.639234)
        
        let spot1 = ParkingSpot(
            id: "sample1",
            name: "Markaziy Parkovka",
            address: "Al-Xorazmiy ko'chasi, 25",
            pricePerHour: 5000,
            spotsAvailable: 15,
            distance: "1.2 km",
            location: location1,
            features: ["Qo'riqlanadigan", "24/7", "Soyabon"],
            rating: 4.5,
            reviewCount: 120,
            category: "Markaziy",
            description: "Markazdagi qulay joylashgan parkovka",
            operatedBy: "Premium Parking",
            images: ["parking1", "parking2"]
        )
        
        let spot2 = ParkingSpot(
            id: "sample2",
            name: "Shovot Parkovkasi",
            address: "Shovot kanali, 12",
            pricePerHour: 3000,
            spotsAvailable: 8,
            distance: "0.5 km",
            location: location2,
            features: ["Qo'riqlanadigan", "Kamera"],
            rating: 4.2,
            reviewCount: 85,
            category: "Ekonom",
            description: "Arzon narxlardagi parkovka",
            operatedBy: "City Parking",
            images: ["parking3", "parking4"]
        )
        
        self.popularSpots = [spot1, spot2]
        self.nearbySpots = [spot2, spot1]
    }
    #endif
} 
