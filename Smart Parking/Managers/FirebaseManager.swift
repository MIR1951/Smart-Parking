import SwiftUI
import FirebaseAuth
import FirebaseFirestore

class FirebaseManager {
    static let shared = FirebaseManager()
    
    var currentUserID: String? {
        return Auth.auth().currentUser?.uid
    }
    
    private init() {}
    
    // MARK: - Parkinglar bilan bog'liq metodlar
    
    func fetchParkingSlots(parkingID: String, arrivalTime: Date, exitTime: Date, completion: @escaping ([ParkingSlot], Error?) -> Void) {
        let db = Firestore.firestore()
        
        // Avval barcha slotlarni olish
        db.collection("parkingSpots").document(parkingID).collection("slots")
            .getDocuments { snapshot, error in
                if let error = error {
                    completion([], error)
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion([], nil)
                    return
                }
                
                // Barcha slotlarni olish
                var allSlots = documents.compactMap { document -> ParkingSlot? in
                    let data = document.data()
                    return ParkingSlot(
                        id: document.documentID,
                        parkingSpotID: parkingID,
                        slotNumber: data["slotNumber"] as? String ?? "",
                        isAvailable: data["isAvailable"] as? Bool ?? true,
                        type: data["type"] as? String
                    )
                }
                
                // Berilgan vaqt oralig'ida band qilingan slotlarni aniqlash
                self.checkReservations(parkingID: parkingID, arrivalTime: arrivalTime, exitTime: exitTime) { reservedSlotIDs in
                    // Band qilingan slotlarni belgilash
                    for index in 0..<allSlots.count {
                        if reservedSlotIDs.contains(allSlots[index].slotNumber ?? "") {
                            var slot = allSlots[index]
                            // To'g'ridan-to'g'ri strukturani o'zgartirolmaymiz, shuning uchun yangi qiymat yaratib qo'yamiz
                            allSlots[index] = ParkingSlot(
                                id: slot.id,
                                parkingSpotID: slot.parkingSpotID,
                                slotNumber: slot.slotNumber,
                                isAvailable: false,
                                type: slot.type
                            )
                        }
                    }
                    
                    completion(allSlots, nil)
                }
            }
    }
    
    private func checkReservations(parkingID: String, arrivalTime: Date, exitTime: Date, completion: @escaping ([String]) -> Void) {
        let db = Firestore.firestore()
        
        print("FirebaseManager - Tekshirish: Arrival: \(arrivalTime), Exit: \(exitTime)")
        
        // Tanlangan vaqt bilan to'qnashuvchi barcha bronlarni tekshirish
        db.collection("reservations")
            .whereField("parkingSpotID", isEqualTo: parkingID)
            .whereField("status", isEqualTo: "active")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Rezervatsiyalarni yuklashda xatolik: \(error.localizedDescription)")
                    completion([])
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("Hech qanday rezervatsiya topilmadi")
                    completion([])
                    return
                }
                
                print("Jami \(documents.count) rezervatsiya topildi")
                
                // To'qnashuvchilarni topish va slotIDlarni qaytarish
                var reservedSlotIDs: [String] = []
                
                for document in documents {
                    let data = document.data()
                    
                    guard let startTimestamp = data["startTime"] as? Timestamp,
                          let endTimestamp = data["endTime"] as? Timestamp,
                          let slotNumber = data["slotNumber"] as? String else {
                        print("Rezervatsiya ma'lumotlari to'liq emas: \(data)")
                        continue
                    }
                    
                    let reservationStart = startTimestamp.dateValue()
                    let reservationEnd = endTimestamp.dateValue()
                    
                    print("Rezervatsiya: \(slotNumber), Start: \(reservationStart), End: \(reservationEnd)")
                    
                    // Vaqt oralig'i to'qnashuvini tekshirish
                    if (arrivalTime < reservationEnd && exitTime > reservationStart) {
                        print("Slot \(slotNumber) band! Tanlangan vaqt: \(arrivalTime)-\(exitTime), Band vaqt: \(reservationStart)-\(reservationEnd)")
                        reservedSlotIDs.append(slotNumber)
                    } else {
                        print("Slot \(slotNumber) bo'sh chunki vaqtlar to'qnashmaydi")
                    }
                }
                
                print("Jami \(reservedSlotIDs.count) ta band joy topildi: \(reservedSlotIDs)")
                completion(reservedSlotIDs)
            }
    }
    
    // MARK: - Rezervatsiya qilish
    
    func createReservation(
        parkingSpotID: String,
        slotNumber: String,
        vehicleID: String,
        startTime: Date,
        endTime: Date,
        totalPrice: Double,
        paymentMethod: String,
        completion: @escaping (String?, Error?) -> Void
    ) {
        guard let userID = currentUserID else {
            completion(nil, NSError(domain: "FirebaseManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Foydalanuvchi topilmadi"]))
            return
        }
        
        let db = Firestore.firestore()
        
        // Avval to'lov yaratish
        let paymentRef = db.collection("payments").document()
        
        let paymentData: [String: Any] = [
            "userID": userID,
            "amount": totalPrice,
            "status": "completed",
            "paymentMethod": paymentMethod,
            "createdAt": FieldValue.serverTimestamp(),
            "transactionID": UUID().uuidString
        ]
        
        paymentRef.setData(paymentData) { error in
            if let error = error {
                completion(nil, error)
                return
            }
            
            // Keyin rezervatsiya yaratish
            let reservationRef = db.collection("reservations").document()
            
            let reservationData: [String: Any] = [
                "userID": userID,
                "parkingSpotID": parkingSpotID,
                "startTime": Timestamp(date: startTime),
                "endTime": Timestamp(date: endTime),
                "status": "active",
                "totalPrice": totalPrice,
                "vehicleID": vehicleID,
                "slotNumber": slotNumber,
                "paymentID": paymentRef.documentID,
                "createdAt": FieldValue.serverTimestamp()
            ]
            
            reservationRef.setData(reservationData) { error in
                if let error = error {
                    completion(nil, error)
                    return
                }
                
                completion(reservationRef.documentID, nil)
            }
        }
    }
    
    // MARK: - To'lov metodlarini olish
    
    func fetchPaymentMethods(completion: @escaping ([PaymentMethod], Error?) -> Void) {
        guard let userID = currentUserID else {
            completion([], NSError(domain: "FirebaseManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Foydalanuvchi topilmadi"]))
            return
        }
        
        let db = Firestore.firestore()
        
        db.collection("users").document(userID).collection("paymentMethods")
            .getDocuments { snapshot, error in
                if let error = error {
                    completion([], error)
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion([], nil)
                    return
                }
                
                let paymentMethods = documents.compactMap { document -> PaymentMethod? in
                    let data = document.data()
                    
                    return PaymentMethod(
                        id: document.documentID,
                        userID: userID,
                        type: data["type"] as? String ?? "",
                        cardNumber: data["cardNumber"] as? String,
                        expiryDate: data["expiryDate"] as? String,
                        isDefault: data["isDefault"] as? Bool ?? false,
                        cardholderName: data["cardholderName"] as? String
                    )
                }
                
                completion(paymentMethods, nil)
            }
    }
} 