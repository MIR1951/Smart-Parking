import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct PaymentReviewView: View {
    let spot: ParkingSpot
    let vehicle: Vehicle
    let slot: ParkingSlot
    let arrivalTime: Date
    let exitTime: Date
    let paymentOption: PaymentOption
    
    @State private var showConfirmation = false
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var reservationID: String?
    @Environment(\.dismiss) var dismiss
    
    // To'lov ma'lumotlari
    private var parkingDuration: Double {
        return exitTime.timeIntervalSince(arrivalTime) / 3600.0 // Soatlarda
    }
    
    private var parkingFee: Double {
        return spot.pricePerHour * parkingDuration
    }
    
    private var serviceFee: Double {
        return 2.00 // Fixed service fee
    }
    
    private var totalAmount: Double {
        return parkingFee + serviceFee
    }
    
    private var totalHours: String {
        let hours = Int(parkingDuration)
        let minutes = Int((parkingDuration - Double(hours)) * 60)
        return String(format: "%02d:%02d", hours, minutes)
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM dd | HH:mm"
        return formatter
    }()
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.black)
                        .padding(10)
                        .background(Circle().fill(Color.white))
                        .shadow(color: Color.black.opacity(0.1), radius: 2)
                }
                
                Spacer()
                
                Text("To'lovni ko'rib chiqish")
                    .font(.headline)
                    .foregroundColor(.black)
                
                Spacer()
                
                Circle()
                    .frame(width: 32, height: 32)
                    .foregroundColor(.clear)
            }
            .padding()
            .background(Color.white)
            
            ScrollView {
                VStack(spacing: 24) {
                    // Parking spot card
                    HStack(alignment: .top, spacing: 12) {
                        // Parking image
                        if let imageUrl = spot.images?.first, !imageUrl.isEmpty {
                                if let url = URL(string: imageUrl) {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .empty:
                                        ProgressView()
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    case .failure(let error):
                                        Text("Rasm yuklanmadi: \(error.localizedDescription)")
                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Avtomobil to'xtash joyi")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Text(spot.name)
                                .font(.headline)
                                .foregroundColor(.black)
                            
                            HStack(spacing: 4) {
                                Image(systemName: "location.circle.fill")
                                    .foregroundColor(.gray)
                                    .font(.caption)
                                
                                Text(spot.address)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        Spacer()
                        
                        // Rating
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                            
                            Text(String(format: "%.1f", spot.rating ?? 4.8))
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    .padding(.horizontal)
                    
                    // Booking details
                    VStack(spacing: 16) {
                        DetailRow(title: "Kelish vaqti", value: dateFormatter.string(from: arrivalTime))
                        
                        DetailRow(title: "Chiqish vaqti", value: dateFormatter.string(from: exitTime))
                        
                        DetailRow(title: "Transport", value: "\(vehicle.brand) \(vehicle.name) (\(vehicle.type ?? ""))")
                        
                        DetailRow(title: "Joy", value: "\(slot.slotNumber ?? "") (\(slot.floor == 0 ? "1" : slot.floor == 1 ? "2" : "3")-qavat)")
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    .padding(.horizontal)
                    
                    // Payment details
                    VStack(spacing: 16) {
                        DetailRow(title: "Narx", value: String(format: "%.0f so'm/soat", spot.pricePerHour))
                        
                        DetailRow(title: "Jami vaqt", value: totalHours)
                        
                        DetailRow(title: "Xizmat haqi", value: String(format: "%.0f so'm", serviceFee))
                        
                        Divider()
                        
                        DetailRow(title: "Jami", value: String(format: "%.0f so'm", totalAmount), isTotal: true)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    .padding(.horizontal)
                    
                    // Payment method
                    HStack {
                        // Payment method icon
                        Image(systemName: getPaymentIcon())
                            .foregroundColor(.purple)
                            .frame(width: 40, height: 40)
                            .background(Color.purple.opacity(0.1))
                            .cornerRadius(8)
                        
                        Text(paymentOption.rawValue)
                            .foregroundColor(.black)
                        
                        Spacer()
                        
                        Button(action: {
                            // Return to payment method selection
                            dismiss()
                        }) {
                            Text("O'zgartirish")
                                .font(.subheadline)
                                .foregroundColor(.purple)
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    .padding(.horizontal)
                }
                .padding(.top, 16)
            }
            
            // Continue button
            Button(action: {
                processPayment()
            }) {
                if isProcessing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .cornerRadius(30)
                } else {
                    Text("Davom etish")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .cornerRadius(30)
                }
            }
            .padding()
            .shadow(color: Color.purple.opacity(0.3), radius: 5, x: 0, y: 3)
            .disabled(isProcessing)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .edgesIgnoringSafeArea(.bottom)
        .alert(isPresented: .constant(errorMessage != nil)) {
            Alert(
                title: Text("Xatolik"),
                message: Text(errorMessage ?? "Noma'lum xatolik yuz berdi"),
                dismissButton: .default(Text("OK")) {
                    errorMessage = nil
                }
            )
        }
        .fullScreenCover(isPresented: $showConfirmation) {
            if let reservationID = reservationID {
                PaymentSuccessView(reservationID: reservationID)
            }
        }
    }
    
    private func getPaymentIcon() -> String {
        switch paymentOption {
        case .wallet:
            return "wallet.pass.fill"
        case .cash:
            return "banknote.fill"
        case .creditCard:
            return "creditcard.fill"
        case .paypal:
            return "p.circle.fill"
        case .applePay:
            return "applelogo"
        case .googlePay:
            return "g.circle.fill"
        }
    }
    
    private func processPayment() {
        isProcessing = true
        errorMessage = nil
        
        // To'lovni va bron qilishni yaratish
        createReservation { reservationID, error in
            isProcessing = false
            
            if let error = error {
                errorMessage = "To'lov qilishda xatolik: \(error.localizedDescription)"
                return
            }
            
            guard let reservationID = reservationID else {
                errorMessage = "Rezervatsiya yaratilmadi"
                return
            }
            
            self.reservationID = reservationID
            self.showConfirmation = true
        }
    }
    
    private func createReservation(completion: @escaping (String?, Error?) -> Void) {
        guard let userID = Auth.auth().currentUser?.uid else {
            completion(nil, NSError(domain: "PaymentReviewView", code: 1, userInfo: [NSLocalizedDescriptionKey: "Foydalanuvchi tizimga kirmagan"]))
            return
        }
        
        let db = Firestore.firestore()
        print("Rezervatsiya yaratilyapti: Slot \(slot.slotNumber ?? ""), Arrival: \(arrivalTime), Exit: \(exitTime)")
        
        // 1. To'lov yaratish
        let paymentRef = db.collection("payments").document()
        
        let paymentData: [String: Any] = [
            "userID": userID,
            "amount": totalAmount,
            "status": "completed",
            "paymentMethod": paymentOption.rawValue,
            "createdAt": FieldValue.serverTimestamp(),
            "transactionID": UUID().uuidString
        ]
        
        paymentRef.setData(paymentData) { error in
            if let error = error {
                completion(nil, error)
                return
            }
            
            // 2. Rezervatsiya yaratish
            let reservationRef = db.collection("reservations").document()
            let startTimestamp = Timestamp(date: self.arrivalTime)
            let endTimestamp = Timestamp(date: self.exitTime)
            
            let reservationData: [String: Any] = [
                "userID": userID,
                "parkingSpotID": self.spot.id,
                "slotID": self.slot.id,
                "vehicleID": self.vehicle.id,
                "startTime": startTimestamp,
                "endTime": endTimestamp,
                "status": "active",
                "totalPrice": self.totalAmount,
                "slotNumber": self.slot.slotNumber ?? "",
                "paymentID": paymentRef.documentID,
                "createdAt": FieldValue.serverTimestamp()
            ]
            
            print("Rezervatsiya ma'lumotlari: \(reservationData)")
            
            reservationRef.setData(reservationData) { error in
                if let error = error {
                    print("Rezervatsiya saqlashda xatolik: \(error.localizedDescription)")
                    completion(nil, error)
                    return
                }
                
                print("Rezervatsiya muvaffaqiyatli yaratildi: \(reservationRef.documentID)")
                
                // 3. Foydalanuvchi ma'lumotlariga ham rezervatsiyani saqlash
                db.collection("users").document(userID).collection("reservations").document(reservationRef.documentID)
                    .setData(reservationData) { error in
                        if let error = error {
                            print("Foydalanuvchi ma'lumotlariga saqlashda xatolik: \(error.localizedDescription)")
                            // Xatolikni qaytarmang, faqat log qiling - asosiy rezervatsiya allaqachon saqlangan
                        }
                        
                        print("Rezervatsiya foydalanuvchi ma'lumotlariga ham saqlandi")
                        completion(reservationRef.documentID, nil)
                    }
            }
        }
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    var isTotal: Bool = false
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: isTotal ? 17 : 15))
                .foregroundColor(.gray)
                .fontWeight(isTotal ? .semibold : .regular)
            
            Spacer()
            
            Text(value)
                .font(.system(size: isTotal ? 17 : 15))
                .foregroundColor(isTotal ? .black : .gray)
                .fontWeight(isTotal ? .semibold : .regular)
        }
    }
} 
