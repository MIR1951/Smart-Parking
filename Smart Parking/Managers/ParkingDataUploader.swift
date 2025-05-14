import FirebaseFirestore
import Firebase

class ParkingDataUploader {
    private let db = Firestore.firestore()
    
    func uploadParkingData() {
        let parkingData: [[String: Any]] = [
            // TATU Parking Spot
            [
                "name": "TATU Avtoturargohi",
                "address": "TATU, Urganch shahri",
                "pricePerHour": 5000.0,
                "spotsAvailable": 30,
                "distance": "1.5 km",
                "location": GeoPoint(latitude: 41.5500, longitude: 60.6250),
                "features": ["Kamera nazorati", "24/7 ishlash"],
                "rating": 4.5,
                "reviewCount": 20,
                "category": "Ta'lim",
                "description": "TATU hududidagi avtoturargoh. Keng joylar va zamonaviy xizmatlar.",
                "operatedBy": "TATU Parking",
                "images": ["https://example.com/image1.jpg", "https://example.com/image2.jpg"]
            ],
            
            // URDU Parking Spot
            [
                "name": "URDU Avtoturargohi",
                "address": "URDU, Urganch shahri",
                "pricePerHour": 4000.0,
                "spotsAvailable": 30,
                "distance": "2.0 km",
                "location": GeoPoint(latitude: 41.5525, longitude: 60.6255),
                "features": ["Kamera nazorati", "Qo'riqlash"],
                "rating": 4.3,
                "reviewCount": 18,
                "category": "Ta'lim",
                "description": "URDU hududida joylashgan maxsus avtoturargoh. Xavfsiz va qulay.",
                "operatedBy": "URDU Parking",
                "images": ["https://example.com/image3.jpg", "https://example.com/image4.jpg"]
            ],
            
            // GIPER Parking Spot
            [
                "name": "GIPER Avtoturargohi",
                "address": "GIPER, Urganch shahri",
                "pricePerHour": 6000.0,
                "spotsAvailable": 30,
                "distance": "3.0 km",
                "location": GeoPoint(latitude: 41.5550, longitude: 60.6200),
                "features": ["Kamera nazorati", "24/7 ishlash", "To'lov terminali"],
                "rating": 4.7,
                "reviewCount": 25,
                "category": "Savdo markazi",
                "description": "GIPER hududida zamonaviy avtoturargoh. Xavfsiz va qulay joylar.",
                "operatedBy": "GIPER Parking",
                "images": ["https://example.com/image5.jpg", "https://example.com/image6.jpg"]
            ],
            
            // SUM Parking Spot
            [
                "name": "SUM Avtoturargohi",
                "address": "SUM, Urganch shahri",
                "pricePerHour": 5500.0,
                "spotsAvailable": 30,
                "distance": "1.2 km",
                "location": GeoPoint(latitude: 41.5400, longitude: 60.6150),
                "features": ["Kamera nazorati", "Qo'riqlash", "Yopiq avtoturargoh"],
                "rating": 4.6,
                "reviewCount": 30,
                "category": "Savdo markazi",
                "description": "SUM hududidagi keng va xavfsiz avtoturargoh.",
                "operatedBy": "SUM Parking",
                "images": ["https://example.com/image7.jpg", "https://example.com/image8.jpg"]
            ],
            
            // DARITAL Parking Spot
            [
                "name": "DARITAL Avtoturargohi",
                "address": "DARITAL, Urganch shahri",
                "pricePerHour": 4000.0,
                "spotsAvailable": 30,
                "distance": "4.5 km",
                "location": GeoPoint(latitude: 41.5600, longitude: 60.6180),
                "features": ["Kamera nazorati", "Qo'riqlash", "Talabalar uchun chegirma"],
                "rating": 4.4,
                "reviewCount": 15,
                "category": "Ta'lim",
                "description": "DARITAL hududidagi keng va qulay avtoturargoh.",
                "operatedBy": "DARITAL Parking",
                "images": ["https://example.com/image9.jpg", "https://example.com/image10.jpg"]
            ]
        ]
        
        // Har bir parking spotni Firestore'ga qo‘shish
        for (index, parking) in parkingData.enumerated() {
            let parkingID = ["TATU", "URDU", "GIPER", "SUM", "DARITAL"][index]
            
            db.collection("parkingSpots").document(parkingID).setData(parking) { error in
                if let error = error {
                    print("Parking spot qo‘shishda xatolik: \(error)")
                } else {
                    print("\(parkingID) muvaffaqiyatli qo‘shildi!")
                    self.createParkingSlots(parkingID: parkingID)
                }
            }
        }
    }
    
    // Parking slotlarni yaratish
    private func createParkingSlots(parkingID: String) {
        let levels = [1, 2, 3] // Qavatlar 1, 2, 3 bo‘ladi
        let levelNames = ["A", "B", "C"] // Harflar A, B, C bo‘ladi
        
        // Har bir qavatda 10 ta slot yaratish
        for (index, level) in levels.enumerated() {
            for slotNumber in 1...10 {
                let slotID = "\(levelNames[index])\(slotNumber)" // Slot ID-si: A1, A2, ..., A10, B1, B2, ..., C1, C2, ...
                
                let slotData: [String: Any] = [
                    "id": slotID,
                    "parkingSpotID": parkingID,
                    "slotNumber": slotID,
                    "isAvailable": true,
                    "type": "Standard", // Slot turi, o‘zgartirish mumkin
                    "floor": level
                ]
                
                db.collection("parkingSpots").document(parkingID).collection("slots").document(slotID).setData(slotData) { error in
                    if let error = error {
                        print("Slot \(slotID) yaratishda xatolik: \(error)")
                    } else {
                        print("Slot \(slotID) muvaffaqiyatli yaratildi!")
                    }
                }
            }
        }
    }
}

// Firebase’ga ma'lumotlarni yuborish uchun quyidagi kodni ishga tushirishingiz mumkin

