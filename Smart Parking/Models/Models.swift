import Foundation
import FirebaseFirestore
import CoreLocation

// MARK: - User
struct User: Identifiable {
    let id: String
    let name: String
    let email: String
    let phoneNumber: String
    let profileImageURL: String?
    let createdAt: Date
}

// MARK: - Vehicle
struct Vehicle: Identifiable {
    let id: String
    let userID: String
    let brand: String
    let name: String
    let type: String?
    let plate: String
    let image: String?
}

// MARK: - ParkingSpot
struct ParkingSpot: Identifiable {
    let id: String
    let name: String
    let address: String
    let pricePerHour: Double
    let spotsAvailable: Int
    let distance: String
    let location: FirebaseFirestore.GeoPoint?
    let features: [String]?
    let rating: Double?
    let reviewCount: Int?
    let category: String?
    let description: String?
    let operatedBy: String?
    let images: [String]?
    
    // Convenience method to get CLLocationCoordinate2D
    var coordinate: CLLocationCoordinate2D? {
        guard let location = location else { return nil }
        return CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
    }
}

// MARK: - ParkingSlot
struct ParkingSlot: Identifiable {
    let id: String
    let parkingSpotID: String
    let slotNumber: String?
    let isAvailable: Bool
    let type: String?
    var floor: Int?
}

// MARK: - Reservation
struct Reservation: Identifiable {
    let id: String
    let userID: String
    let parkingSpotID: String
    let slotID: String
    let startTime: Date
    var endTime: Date
    var status: String
    var totalPrice: Double
    let vehicleID: String?
    let slotNumber: String?
    let paymentID: String?
    let createdAt: Date
}

// MARK: - Favorite
struct Favorite: Identifiable {
    let id: String
    let userID: String
    let parkingSpotID: String
}

// MARK: - Review
struct Review: Identifiable {
    let id: String
    let userID: String
    let parkingSpotID: String
    let rating: Double
    let comment: String?
    let createdAt: Date
}

// MARK: - Payment
struct Payment: Identifiable {
    let id: String
    let userID: String
    let reservationID: String
    let amount: Double
    let status: String
    let paymentMethod: String
    let createdAt: Date
    let transactionID: String?
}

// MARK: - Notification
struct Notification: Identifiable {
    let id: String
    let userID: String
    let title: String
    let message: String
    let type: String
    let isRead: Bool
    let createdAt: Date
    let relatedID: String?
}

// MARK: - PaymentMethod
struct PaymentMethod: Identifiable {
    let id: String
    let userID: String
    let type: String
    let cardNumber: String?
    let expiryDate: String?
    let isDefault: Bool
    let cardholderName: String?
}
