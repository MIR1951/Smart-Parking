import Foundation
import FirebaseFirestore

class DatabaseManager {
    private let db = Firestore.firestore()
    
    // MARK: - Parkovka joylarini olish
    func fetchParkingSpots(completion: @escaping ([ParkingSpot]?, Error?) -> Void) {
        db.collection("parkingSpots").getDocuments { snapshot, error in
            if let error = error {
                completion(nil, error)
                return
            }
            
            guard let documents = snapshot?.documents, !documents.isEmpty else {
                completion([], nil)
                return
            }
            
            let spots = documents.compactMap { document -> ParkingSpot? in
                let data = document.data()
                guard let name = data["name"] as? String,
                      let address = data["address"] as? String,
                      let pricePerHour = data["pricePerHour"] as? Double,
                      let spotsAvailable = data["spotsAvailable"] as? Int,
                      let location = data["location"] as? GeoPoint,
                      let features = data["features"] as? [String] else {
                    return nil
                }
                
                return ParkingSpot(
                    id: document.documentID,
                    name: name,
                    address: address,
                    pricePerHour: pricePerHour,
                    spotsAvailable: spotsAvailable,
                    distance: data["distance"] as? String ?? "0 km",
                    location: location,
                    features: features,
                    rating: data["rating"] as? Double,
                    reviewCount: data["reviewCount"] as? Int,
                    category: data["category"] as? String,
                    description: data["description"] as? String,
                    operatedBy: data["operatedBy"] as? String,
                    images: data["images"] as? [String]
                )
            }
            
            completion(spots, nil)
        }
    }
    
    // MARK: - Parkovka joyini ID bo'yicha olish
    func fetchParkingSpot(withID id: String, completion: @escaping (ParkingSpot?, Error?) -> Void) {
        db.collection("parkingSpots").document(id).getDocument { document, error in
            if let error = error {
                completion(nil, error)
                return
            }
            
            guard let document = document, document.exists,
                  let data = document.data(),
                  let name = data["name"] as? String,
                  let address = data["address"] as? String,
                  let pricePerHour = data["pricePerHour"] as? Double,
                  let spotsAvailable = data["spotsAvailable"] as? Int,
                  let location = data["location"] as? GeoPoint,
                  let features = data["features"] as? [String] else {
                completion(nil, nil)
                return
            }
            
            let spot = ParkingSpot(
                id: document.documentID,
                name: name,
                address: address,
                pricePerHour: pricePerHour,
                spotsAvailable: spotsAvailable,
                distance: data["distance"] as? String ?? "0 km",
                location: location,
                features: features,
                rating: data["rating"] as? Double,
                reviewCount: data["reviewCount"] as? Int,
                category: data["category"] as? String,
                description: data["description"] as? String,
                operatedBy: data["operatedBy"] as? String,
                images: data["images"] as? [String]
            )
            
            completion(spot, nil)
        }
    }
    
    // MARK: - Foydalanuvchi transportlarini olish
    func fetchUserVehicles(forUserID userID: String, completion: @escaping ([Vehicle]?, Error?) -> Void) {
        db.collection("vehicles")
            .whereField("userID", isEqualTo: userID)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(nil, error)
                    return
                }
                
                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    completion([], nil)
                    return
                }
                
                let vehicles = documents.compactMap { document -> Vehicle? in
                    let data = document.data()
                    guard let userID = data["userID"] as? String,
                          let brand = data["brand"] as? String,
                          let name = data["name"] as? String,
                          let type = data["type"] as? String,
                          let plate = data["plate"] as? String else {
                        return nil
                    }
                    
                    return Vehicle(
                        id: document.documentID,
                        userID: userID,
                        brand: brand,
                        name: name,
                        type: type,
                        plate: plate,
                        image: data["image"] as? String
                    )
                }
                
                completion(vehicles, nil)
            }
    }
    
    // MARK: - Transport qo'shish
    func addVehicle(_ vehicle: Vehicle, completion: @escaping (Error?) -> Void) {
        var data: [String: Any] = [
            "userID": vehicle.userID,
            "name": vehicle.name,
            "type": vehicle.type,
            "plate": vehicle.plate
        ]
        
        
        if let image = vehicle.image {
            data["image"] = image
        }
        
        db.collection("vehicles").document(vehicle.id).setData(data) { error in
            completion(error)
        }
    }
    
    // MARK: - Sevimlilar ro'yxatini olish
    func fetchFavorites(forUserID userID: String, completion: @escaping ([Favorite]?, Error?) -> Void) {
        db.collection("users").document(userID).collection("favorites").getDocuments { snapshot, error in
            if let error = error {
                completion(nil, error)
                return
            }
            
            guard let documents = snapshot?.documents, !documents.isEmpty else {
                completion([], nil)
                return
            }
            
            let favorites = documents.compactMap { document -> Favorite? in
                return Favorite(
                    id: document.documentID,
                    userID: userID,
                    parkingSpotID: document.documentID
                )
            }
            
            completion(favorites, nil)
        }
    }
    
    // MARK: - Sevimliga qo'shish
    func addToFavorites(userID: String, parkingSpotID: String, completion: @escaping (Error?) -> Void) {
        let data: [String: Any] = [
            "addedAt": FieldValue.serverTimestamp()
        ]
        
        db.collection("users").document(userID).collection("favorites").document(parkingSpotID).setData(data) { error in
            completion(error)
        }
    }
    
    // MARK: - Sevimlilardan o'chirish
    func removeFromFavorites(userID: String, parkingSpotID: String, completion: @escaping (Error?) -> Void) {
        db.collection("users").document(userID).collection("favorites").document(parkingSpotID).delete { error in
            completion(error)
        }
    }
    
    // MARK: - Sevimlilarda mavjudligini tekshirish
    func checkIfFavorite(userID: String, parkingSpotID: String, completion: @escaping (Bool, Error?) -> Void) {
        db.collection("users").document(userID).collection("favorites").document(parkingSpotID).getDocument { document, error in
            if let error = error {
                completion(false, error)
                return
            }
            
            completion(document?.exists ?? false, nil)
        }
    }
    
    // MARK: - Band qilishlarni olish
    func fetchReservations(forUserID userID: String, completion: @escaping ([Reservation]?, Error?) -> Void) {
        db.collection("reservations")
            .whereField("userID", isEqualTo: userID)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(nil, error)
                    return
                }
                
                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    completion([], nil)
                    return
                }
                
                let reservations = documents.compactMap { document -> Reservation? in
                    let data = document.data()
                    guard let userID = data["userID"] as? String,
                          let parkingSpotID = data["parkingSpotID"] as? String,
                          let startTime = data["startTime"] as? Timestamp,
                          let endTime = data["endTime"] as? Timestamp,
                          let status = data["status"] as? String,
                          let totalPrice = data["totalPrice"] as? Double else {
                        return nil
                    }
                    
                    return Reservation(
                        id: document.documentID,
                        userID: userID,
                        parkingSpotID: parkingSpotID,
                        slotID : data["slotID"] as? String ?? "",
                        startTime: startTime.dateValue(),
                        endTime: endTime.dateValue(),
                        status: status,
                        totalPrice: totalPrice,
                        vehicleID: data["vehicleID"] as? String ,
                        slotNumber: data["slotNumber"] as? String,
                        paymentID: data["paymentID"] as? String,
                        createdAt: Date()
                    )
                }
                
                completion(reservations, nil)
            }
    }
    
    // MARK: - Band qilish yaratish
    func createReservation(_ reservation: Reservation, completion: @escaping (Error?) -> Void) {
        var data: [String: Any] = [
            "userID": reservation.userID,
            "parkingSpotID": reservation.parkingSpotID,
            "startTime": Timestamp(date: reservation.startTime),
            "endTime": Timestamp(date: reservation.endTime),
            "status": reservation.status,
            "totalPrice": reservation.totalPrice
        ]
        
        if let vehicleID = reservation.vehicleID {
            data["vehicleID"] = vehicleID
        }
        
        if let slotNumber = reservation.slotNumber {
            data["slotNumber"] = slotNumber
        }
        
        if let paymentID = reservation.paymentID {
            data["paymentID"] = paymentID
        }
        
        db.collection("reservations").document(reservation.id).setData(data) { error in
            completion(error)
        }
    }
    
    // MARK: - Band qilish statusini yangilash
    func updateReservationStatus(reservationID: String, status: String, completion: @escaping (Error?) -> Void) {
        db.collection("reservations").document(reservationID).updateData([
            "status": status
        ]) { error in
            completion(error)
        }
    }
    
    // MARK: - To'lovni yaratish
    func createPayment(_ payment: Payment, completion: @escaping (Error?) -> Void) {
        var data: [String: Any] = [
            "userID": payment.userID,
            "reservationID": payment.reservationID,
            "amount": payment.amount,
            "status": payment.status,
            "paymentMethod": payment.paymentMethod,
            "createdAt": Timestamp(date: payment.createdAt)
        ]
        
        if let transactionID = payment.transactionID {
            data["transactionID"] = transactionID
        }
        
        db.collection("payments").document(payment.id).setData(data) { error in
            completion(error)
        }
    }
    
    // MARK: - Sharhlarni olish
    func fetchReviews(forParkingSpotID spotID: String, completion: @escaping ([Review]?, Error?) -> Void) {
        db.collection("reviews")
            .whereField("parkingSpotID", isEqualTo: spotID)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(nil, error)
                    return
                }
                
                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    completion([], nil)
                    return
                }
                
                let reviews = documents.compactMap { document -> Review? in
                    let data = document.data()
                    guard let userID = data["userID"] as? String,
                          let parkingSpotID = data["parkingSpotID"] as? String,
                          let rating = data["rating"] as? Double,
                          let createdAt = data["createdAt"] as? Timestamp else {
                        return nil
                    }
                    
                    return Review(
                        id: document.documentID,
                        userID: userID,
                        parkingSpotID: parkingSpotID,
                        rating: rating,
                        comment: data["comment"] as? String,
                        createdAt: createdAt.dateValue()
                    )
                }
                
                completion(reviews, nil)
            }
    }
    
    // MARK: - Sharh qo'shish
    func addReview(_ review: Review, completion: @escaping (Error?) -> Void) {
        var data: [String: Any] = [
            "userID": review.userID,
            "parkingSpotID": review.parkingSpotID,
            "rating": review.rating,
            "createdAt": Timestamp(date: review.createdAt)
        ]
        
        if let comment = review.comment {
            data["comment"] = comment
        }
        
        db.collection("reviews").document(review.id).setData(data) { error in
            completion(error)
        }
    }
} 
