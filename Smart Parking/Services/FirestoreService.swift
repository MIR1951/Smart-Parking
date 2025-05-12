import Foundation
import FirebaseFirestore
import FirebaseAuth
import CoreLocation

class FirestoreService {
    static let shared = FirestoreService()
    private let db = Firestore.firestore()
    private var setupCompleted = false
    private var isPreloading = false
    
    // Ilovani ishga tushganda barcha parkinglarga slotlarni qo'shish
    func preloadAppData(completion: @escaping (Bool) -> Void) {
        // Agar yuklash jarayoni allaqachon davom etayotgan bo'lsa, yangi so'rovni qaytarish
        guard !isPreloading else {
            completion(false)
            return
        }
        
        isPreloading = true
        
        // Agar sozlamalar allaqachon tugallangan bo'lsa, darhol muvaffaqiyatli qaytarish
        if setupCompleted {
            isPreloading = false
            completion(true)
            return
        }
        
        // Avval mavjud ma'lumotlarni o'chirish
        deleteAllParkingData { [weak self] success in
            guard let self = self else {
                completion(false)
                return
            }
            
            if !success {
                print("Mavjud ma'lumotlarni o'chirishda xatolik")
                self.isPreloading = false
                completion(false)
                return
            }
            
            // Yangi ma'lumotlarni qo'shish
            self.addDefaultParkingSpots { success in
                self.isPreloading = false
                self.setupCompleted = success
                completion(success)
            }
        }
    }
    
    // Barcha parking ma'lumotlarini o'chirish
    private func deleteAllParkingData(completion: @escaping (Bool) -> Void) {
        let group = DispatchGroup()
        var deleteSuccess = true
        
        group.enter()
        db.collection("parkingSpots").getDocuments { [weak self] snapshot, error in
            guard let self = self else {
                deleteSuccess = false
                group.leave()
                return
            }
            
            if let error = error {
                print("Parking joylarni olishda xatolik: \(error.localizedDescription)")
                deleteSuccess = false
                group.leave()
                return
            }
            
            guard let documents = snapshot?.documents else {
                group.leave()
                return
            }
            
            let deleteGroup = DispatchGroup()
            
            for document in documents {
                let parkingID = document.documentID
                
                // Avval slotlarni o'chirish
                deleteGroup.enter()
                self.deleteSlotsForParking(parkingID: parkingID) { success in
                    if !success {
                        print("Parking joy \(parkingID) uchun slotlarni o'chirishda xatolik")
                        deleteSuccess = false
                    }
                    deleteGroup.leave()
                }
                
                // Keyin parking joyni o'chirish
                deleteGroup.enter()
                self.db.collection("parkingSpots").document(parkingID).delete { error in
                    if let error = error {
                        print("Parking joy \(parkingID) ni o'chirishda xatolik: \(error.localizedDescription)")
                        deleteSuccess = false
                    }
                    deleteGroup.leave()
                }
            }
            
            deleteGroup.notify(queue: .main) {
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            completion(deleteSuccess)
        }
    }
    
    // Parking joy uchun slotlarni o'chirish
    private func deleteSlotsForParking(parkingID: String, completion: @escaping (Bool) -> Void) {
        let slotsRef = db.collection("parkingSpots").document(parkingID).collection("slots")
        
        slotsRef.getDocuments { snapshot, error in
            if let error = error {
                print("Slotlarni olishda xatolik: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            guard let documents = snapshot?.documents else {
                completion(true)
                return
            }
            
            let batch = self.db.batch()
            
            for document in documents {
                batch.deleteDocument(document.reference)
            }
            
            batch.commit { error in
                if let error = error {
                    print("Slotlarni o'chirishda xatolik: \(error.localizedDescription)")
                    completion(false)
                    return
                }
                
                completion(true)
            }
        }
    }
    
    // Standart parking joylarni qo'shish
    private func addDefaultParkingSpots(completion: @escaping (Bool) -> Void) {
        let batch = db.batch()
        
        // Standart parking joylar
        let defaultParkingSpots: [[String: Any]] = [
            [
                "name": "Urganch Markaziy Parkovka",
                "address": "Urganch shahri, Al-Xorazmiy ko'chasi, 45",
                "pricePerHour": 5000.0,
                "spotsAvailable": 50,
                "location": GeoPoint(latitude: 41.5503, longitude: 60.6333),
                "features": ["24/7", "Xavfsizlik", "Kamera", "Yoritish", "Tozalash"],
                "rating": 4.5,
                "reviewCount": 128,
                "category": "Markaziy",
                "description": "Urganch shahri markazida joylashgan zamonaviy parkovka. 24 soat xizmat ko'rsatadi.",
                "operatedBy": "Urganch Shahar Hokimligi",
                "images": [
                    "https://example.com/parking1.jpg",
                    "https://example.com/parking1_2.jpg"
                ],
                "distance": "0.5 km",
                "createdAt": Timestamp(date: Date())
            ],
            [
                "name": "Urganch Savdo Markazi Parkovka",
                "address": "Urganch shahri, Ibn Sino ko'chasi, 12",
                "pricePerHour": 4000.0,
                "spotsAvailable": 30,
                "location": GeoPoint(latitude: 41.5521, longitude: 60.6315),
                "features": ["Xavfsizlik", "Kamera", "Yoritish"],
                "rating": 4.2,
                "reviewCount": 85,
                "category": "Savdo Markazi",
                "description": "Urganch Savdo Markazi yonida joylashgan qulay parkovka.",
                "operatedBy": "Urganch Savdo Markazi",
                "images": [
                    "https://example.com/parking2.jpg"
                ],
                "distance": "1.2 km",
                "createdAt": Timestamp(date: Date())
            ],
            [
                "name": "Urganch Universitet Parkovka",
                "address": "Urganch shahri, Al-Beruniy ko'chasi, 110",
                "pricePerHour": 3000.0,
                "spotsAvailable": 40,
                "location": GeoPoint(latitude: 41.5489, longitude: 60.6357),
                "features": ["Xavfsizlik", "Yoritish"],
                "rating": 4.0,
                "reviewCount": 64,
                "category": "Oliy O'quv Yurti",
                "description": "Urganch Davlat Universiteti talabalari va xodimlari uchun maxsus parkovka.",
                "operatedBy": "Urganch Davlat Universiteti",
                "images": [
                    "https://example.com/parking3.jpg"
                ],
                "distance": "2.1 km",
                "createdAt": Timestamp(date: Date())
            ]
        ]
        
        // Har bir parking joyni qo'shish
        for parkingData in defaultParkingSpots {
            let parkingRef = db.collection("parkingSpots").document()
            batch.setData(parkingData, forDocument: parkingRef)
        }
        
        // Batch ni yuborish
        batch.commit { error in
            if let error = error {
                print("Standart parking joylarni qo'shishda xatolik: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            // Muvaffaqiyatli qo'shilgandan so'ng, slotlarni qo'shish
            self.addDefaultSlotsForAllParkingSpots { success in
                completion(success)
            }
        }
    }
    
    // Barcha parking joylarga standart slotlarni qo'shish
    private func addDefaultSlotsForAllParkingSpots(completion: @escaping (Bool) -> Void) {
        let group = DispatchGroup()
        var setupSuccess = true
        
        group.enter()
        db.collection("parkingSpots").getDocuments { [weak self] snapshot, error in
            guard let self = self else {
                setupSuccess = false
                group.leave()
                return
            }
            
            if let error = error {
                print("Parking joylarni olishda xatolik: \(error.localizedDescription)")
                setupSuccess = false
                group.leave()
                return
            }
            
            guard let documents = snapshot?.documents else {
                setupSuccess = false
                group.leave()
                return
            }
            
            let setupGroup = DispatchGroup()
            
            for document in documents {
                let parkingID = document.documentID
                setupGroup.enter()
                
                self.addDefaultSlots(parkingID: parkingID) { success in
                    if !success {
                        print("Parking joy \(parkingID) uchun slotlarni qo'shishda xatolik")
                        setupSuccess = false
                    }
                    setupGroup.leave()
                }
            }
            
            setupGroup.notify(queue: .main) {
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            completion(setupSuccess)
        }
    }
    
    // Slotlar mavjud emasligini tekshirish va qo'shish
    private func checkAndAddSlots(parkingID: String, completion: @escaping (Bool) -> Void) {
        let slotsRef = db.collection("parkingSpots").document(parkingID).collection("slots")
        
        slotsRef.getDocuments { snapshot, error in
            if let error = error {
                print("Slotlarni tekshirishda xatolik: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            // Agar slotlar mavjud bo'lsa, muvaffaqiyatli qaytarish
            if let snapshot = snapshot, !snapshot.documents.isEmpty {
                completion(true)
                return
            }
            
            // Agar slotlar mavjud bo'lmasa, yangi slotlar qo'shish
            self.addDefaultSlots(parkingID: parkingID, completion: completion)
        }
    }
    
    // Standart slotlarni qo'shish
    private func addDefaultSlots(parkingID: String, completion: @escaping (Bool) -> Void) {
        let slotsRef = db.collection("parkingSpots").document(parkingID).collection("slots")
        let batch = db.batch()
        
        // 10 ta standart slot qo'shish
        for i in 1...10 {
            let slotData: [String: Any] = [
                "number": i,
                "isAvailable": true,
                "type": "standard",
                "createdAt": Timestamp(date: Date())
            ]
            
            let slotRef = slotsRef.document()
            batch.setData(slotData, forDocument: slotRef)
        }
        
        batch.commit { error in
            if let error = error {
                print("Slotlarni qo'shishda xatolik: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            completion(true)
        }
    }
} 