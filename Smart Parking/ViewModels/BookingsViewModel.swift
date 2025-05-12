import SwiftUI
import FirebaseFirestore
import FirebaseAuth

class BookingsViewModel: ObservableObject {
    @Published var reservations: [Reservation] = []
    @Published var isLoading = false
    @Published var parkingSpots: [String: ParkingSpot] = [:]
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    
    enum ReservationStatus: String, CaseIterable {
        case ongoing = "active"
        case completed = "completed"
        case cancelled = "cancelled"
        
        var localizedTitle: String {
            switch self {
            case .ongoing: return "Faol"
            case .completed: return "Yakunlangan"
            case .cancelled: return "Bekor qilingan"
            }
        }
    }
    
    func fetchReservations() {
        guard let userID = Auth.auth().currentUser?.uid else {
            return
        }
        
        isLoading = true
        
        // Rezervatsiyalarni birinchi umumiy kolleksiyadan olish
        db.collection("reservations")
            .whereField("userID", isEqualTo: userID)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Rezervatsiyalarni olishda xatolik: \(error.localizedDescription)")
                    self.errorMessage = "Rezervatsiyalarni olishda xatolik"
                    self.isLoading = false
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self.reservations = []
                    self.isLoading = false
                    return
                }
                
                // Rezervatsiyalarni qayta ishlash
                self.reservations = documents.compactMap { document -> Reservation? in
                    let data = document.data()
                    
                    guard let parkingSpotID = data["parkingSpotID"] as? String,
                          let startTimestamp = data["startTime"] as? Timestamp,
                          let endTimestamp = data["endTime"] as? Timestamp,
                          let status = data["status"] as? String,
                          let totalPrice = data["totalPrice"] as? Double else {
                        return nil
                    }
                    
                    let reservation = Reservation(
                        id: document.documentID,
                        userID: userID,
                        parkingSpotID: parkingSpotID,
                        slotID: data["slotID"] as? String ?? "",
                        startTime: startTimestamp.dateValue(),
                        endTime: endTimestamp.dateValue(),
                        status: status,
                        totalPrice: totalPrice,
                        vehicleID: data["vehicleID"] as? String,
                        slotNumber: data["slotNumber"] as? String,
                        paymentID: data["paymentID"] as? String,
                        createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                    )
                    
                    // Parking ma'lumotlarini olish
                    self.fetchParkingSpot(id: parkingSpotID)
                    
                    return reservation
                }
                
                // Rezervatsiyalarni tartibga solish (yangilaridan eskiklariga)
                self.reservations.sort { $0.startTime > $1.startTime }
                
                self.isLoading = false
            }
    }
    
    // Parking ma'lumotlarini olish
    private func fetchParkingSpot(id: String) {
        // Agar parkingSpots lug'atida allaqachon bo'lsa, qayta so'rov yubormaslik
        if self.parkingSpots[id] != nil {
            return
        }
        
        db.collection("parkingSpots").document(id).getDocument { [weak self] document, error in
            guard let self = self, let document = document, document.exists,
                  let data = document.data() else {
                return
            }
            
            let features = data["features"] as? [String] ?? []
            let images = data["images"] as? [String] ?? []
            
            let parkingSpot = ParkingSpot(
                id: document.documentID,
                name: data["name"] as? String ?? "Nomsiz",
                address: data["address"] as? String ?? "Manzil ko'rsatilmagan",
                pricePerHour: data["pricePerHour"] as? Double ?? 0.0,
                spotsAvailable: data["spotsAvailable"] as? Int ?? 0,
                distance: "",
                location: data["location"] as? GeoPoint,
                features: features,
                rating: data["rating"] as? Double,
                reviewCount: data["reviewCount"] as? Int,
                category: data["category"] as? String,
                description: data["description"] as? String,
                operatedBy: data["operatedBy"] as? String,
                images: images
            )
            
            DispatchQueue.main.async {
                self.parkingSpots[id] = parkingSpot
                self.objectWillChange.send()
            }
        }
    }
    
    // Filtrga qarab rezervatsiyalarni olish
    func filteredReservations(for tabIndex: Int) -> [Reservation] {
        let status: String
        switch tabIndex {
        case 0:
            status = "active"
        case 1:
            status = "completed"
        case 2:
            status = "cancelled"
        default:
            status = "active"
        }
        
        return reservations.filter { $0.status == status }
    }
    
    // Parking spotni rezervatsiya ID bo'yicha olish
    func getParkingSpot(for reservation: Reservation) -> ParkingSpot? {
        return parkingSpots[reservation.parkingSpotID]
    }
    
    // Rezervatsiyani bekor qilish
    func cancelReservation(reservationID: String, completion: @escaping (Bool, String?) -> Void) {
        db.collection("reservations").document(reservationID).updateData([
            "status": "cancelled"
        ]) { error in
            if let error = error {
                completion(false, "Rezervatsiyani bekor qilishda xatolik: \(error.localizedDescription)")
            } else {
                // Muvaffaqiyatli
                if let index = self.reservations.firstIndex(where: { $0.id == reservationID }) {
                    DispatchQueue.main.async {
                        // Status yangilash
                        var updatedReservation = self.reservations[index]
                        updatedReservation.status = "cancelled"
                        self.reservations[index] = updatedReservation
                    }
                }
                completion(true, nil)
            }
        }
    }
    
    // Rezervatsiyani sabab bilan bekor qilish
    func cancelReservation(reservationID: String, reason: String, completion: @escaping (Bool, String?) -> Void) {
        db.collection("reservations").document(reservationID).updateData([
            "status": "cancelled",
            "cancellationReason": reason,
            "cancelledAt": FieldValue.serverTimestamp()
        ]) { error in
            if let error = error {
                completion(false, "Rezervatsiyani bekor qilishda xatolik: \(error.localizedDescription)")
            } else {
                // Muvaffaqiyatli
                if let index = self.reservations.firstIndex(where: { $0.id == reservationID }) {
                    DispatchQueue.main.async {
                        // Status yangilash
                        var updatedReservation = self.reservations[index]
                        updatedReservation.status = "cancelled"
                        self.reservations[index] = updatedReservation
                    }
                }
                completion(true, nil)
            }
        }
    }
    
    // Rezervatsiya vaqtini uzaytirish
    func extendReservationTime(reservationID: String, newEndTime: Date, additionalPrice: Double, completion: @escaping (Bool, String?) -> Void) {
        // Mavjud rezervatsiyani olish
        if let index = self.reservations.firstIndex(where: { $0.id == reservationID }) {
            let reservation = self.reservations[index]
            
            // Firebase'da vaqtni uzaytirish
            db.collection("reservations").document(reservationID).updateData([
                "endTime": Timestamp(date: newEndTime),
                "totalPrice": FieldValue.increment(additionalPrice),
                "lastExtendedAt": FieldValue.serverTimestamp(),
                "additionalPayment": additionalPrice
            ]) { error in
                if let error = error {
                    completion(false, "Vaqtni uzaytirishda xatolik: \(error.localizedDescription)")
                } else {
                    // Muvaffaqiyatli
                    DispatchQueue.main.async {
                        // Mahalliy ma'lumotlarni yangilash
                        var updatedReservation = self.reservations[index]
                        updatedReservation.endTime = newEndTime
                        updatedReservation.totalPrice += additionalPrice
                        self.reservations[index] = updatedReservation
                    }
                    completion(true, nil)
                }
            }
            
            // To'lov tarixi yozuvini qo'shish (ixtiyoriy)
            if let userID = Auth.auth().currentUser?.uid {
                let paymentRef = db.collection("payments").document()
                let paymentData: [String: Any] = [
                    "userID": userID,
                    "reservationID": reservationID,
                    "amount": additionalPrice,
                    "status": "completed",
                    "paymentMethod": "card", // Yoki boshqa metod
                    "createdAt": FieldValue.serverTimestamp(),
                    "type": "extension",
                    "description": "Band qilish vaqtini uzaytirish"
                ]
                
                paymentRef.setData(paymentData)
            }
        } else {
            completion(false, "Rezervatsiya topilmadi")
        }
    }
    
    // Rezervatsiyalarni foydalanuvchi ma'lumotlariga saqlash
    func saveReservationToUserDocument(reservation: Reservation, completion: @escaping (Bool, String?) -> Void) {
        guard let userID = Auth.auth().currentUser?.uid else {
            completion(false, "Foydalanuvchi tizimga kirmagan")
            return
        }
        
        let reservationData: [String: Any] = [
            "parkingSpotID": reservation.parkingSpotID,
            "slotID": reservation.slotID,
            "startTime": Timestamp(date: reservation.startTime),
            "endTime": Timestamp(date: reservation.endTime),
            "status": reservation.status,
            "totalPrice": reservation.totalPrice,
            "slotNumber": reservation.slotNumber ?? "",
            "vehicleID": reservation.vehicleID ?? "",
            "paymentID": reservation.paymentID ?? "",
            "createdAt": FieldValue.serverTimestamp()
        ]
        
        db.collection("users").document(userID).collection("reservations").document(reservation.id)
            .setData(reservationData) { error in
                if let error = error {
                    completion(false, "Foydalanuvchi ma'lumotlarini saqlashda xatolik: \(error.localizedDescription)")
                } else {
                    completion(true, nil)
                }
            }
    }
    
    // Sana formati
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, HH:mm"
        return formatter.string(from: date)
    }
} 