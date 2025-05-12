import SwiftUI

struct BookingConfirmationView: View {
    let spot: ParkingSpot
    let vehicle: Vehicle
    let slot: ParkingSlot
    let paymentMethod: PaymentMethod
    let arrivalTime: Date
    let exitTime: Date
    
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    @State private var reservationID: String?
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack {
            // Sarlavha
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.purple)
                }
                
                Spacer()
                
                Text("Band qilishni tasdiqlash")
                    .font(.headline)
                
                Spacer()
                
                Circle()
                    .frame(width: 30, height: 30)
                    .opacity(0) // Yashirin, lekin joyni egallaydi
            }
            .padding()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Sarlavha
                    Text("Band qilish ma'lumotlari")
                        .font(.title2)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    
                    // Parking ma'lumotlari
                    SectionView(title: "Parking") {
                        InfoRow(icon: "car.fill", title: spot.name)
                        InfoRow(icon: "mappin.and.ellipse", title: spot.address)
                        InfoRow(icon: "parkingsign", title: "Joy: \(slot.slotNumber ?? "")")
                    }
                    
                    // Vaqt ma'lumotlari
                    SectionView(title: "Vaqt") {
                   
                        
                       
                        
                        let hours = exitTime.timeIntervalSince(arrivalTime) / 3600
                        InfoRow(icon: "clock", title: "Davomiyligi", value: "\(Int(hours)) soat")
                    }
                    
                    // Mashina ma'lumotlari
                    SectionView(title: "Mashina") {
                        InfoRow(icon: "car.fill", title: vehicle.name)
                        InfoRow(icon: "number", title: "Davlat raqami", value: vehicle.plate)
                        InfoRow(icon: "car.2.fill", title: "Turi", value: vehicle.type)
                    }
                    
                    // To'lov ma'lumotlari
                    SectionView(title: "To'lov") {
                        if paymentMethod.type == "cash" {
                            InfoRow(icon: "banknote.fill", title: "To'lov usuli", value: "Naqd pul")
                        } else {
                            InfoRow(icon: "creditcard.fill", title: "To'lov usuli", value: getCardType())
                            if let cardNumber = paymentMethod.cardNumber {
                                InfoRow(icon: "creditcard", title: "Karta raqami", value: "**** **** **** \(String(cardNumber.suffix(4)))")
                            }
                        }
                        
                        let hours = exitTime.timeIntervalSince(arrivalTime) / 3600
                        let totalPrice = spot.pricePerHour * hours
                        
                        InfoRow(icon: "banknote.fill", title: "Soatlik narx", value: "\(Int(spot.pricePerHour)) so'm")
                        InfoRow(icon: "timer", title: "Davomiyligi", value: "\(Int(hours)) soat")
                        InfoRow(icon: "banknote.circle.fill", title: "Jami summa", value: "\(Int(totalPrice)) so'm", isHighlighted: true)
                    }
                }
                .padding(.bottom, 100)
            }
            
            Spacer()
            
            // Tasdiqlash tugmasi
            VStack(spacing: 15) {
                Button(action: {
                    confirmBooking()
                }) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .foregroundColor(.white)
                    } else {
                        Text("Tasdiqlash")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.purple)
                .cornerRadius(10)
                .disabled(isLoading)
                
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Bekor qilish")
                        .font(.headline)
                        .foregroundColor(.purple)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.purple, lineWidth: 1)
                )
                .disabled(isLoading)
            }
            .padding()
            .background(Color.white)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: -5)
        }
        .navigationBarHidden(true)
        .alert(isPresented: $showError) {
            Alert(
                title: Text("Xatolik"),
                message: Text(errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .fullScreenCover(isPresented: $showSuccess) {
            if let reservationID = reservationID {
                PaymentSuccessView(reservationID: reservationID)
            }
        }
    }
    
    private func confirmBooking() {
        isLoading = true
        
        let hours = exitTime.timeIntervalSince(arrivalTime) / 3600
        let totalPrice = spot.pricePerHour * hours
        
        FirebaseManager.shared.createReservation(
            parkingSpotID: spot.id,
            slotNumber: slot.slotNumber ?? "",
            vehicleID: vehicle.id,
            startTime: arrivalTime,
            endTime: exitTime,
            totalPrice: totalPrice,
            paymentMethod: paymentMethod.type
        ) { reservationID, error in
            isLoading = false
            
            if let error = error {
                errorMessage = "Band qilishda xatolik: \(error.localizedDescription)"
                showError = true
                return
            }
            
            if let reservationID = reservationID {
                self.reservationID = reservationID
                showSuccess = true
            } else {
                errorMessage = "Band qilishda noma'lum xatolik"
                showError = true
            }
        }
    }
    
    private func getCardType() -> String {
        guard let cardNumber = paymentMethod.cardNumber else { return "Karta" }
        
        if cardNumber.hasPrefix("4") {
            return "Visa"
        } else if cardNumber.hasPrefix("5") {
            return "MasterCard"
        } else if cardNumber.hasPrefix("8600") {
            return "Uzcard"
        } else if cardNumber.hasPrefix("9860") {
            return "Humo"
        } else {
            return "Karta"
        }
    }
}

// Section View
struct SectionView<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(title)
                .font(.headline)
                .foregroundColor(.gray)
            
            content
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
}

// Info Row
struct InfoRow: View {
    let icon: String
    let title: String
    let value: String?
    let isHighlighted: Bool
    
    init(icon: String, title: String, value: String? = nil, isHighlighted: Bool = false) {
        self.icon = icon
        self.title = title
        self.value = value
        self.isHighlighted = isHighlighted
    }
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.purple)
                .frame(width: 25)
            
            if let value = value {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Text(value)
                    .font(.subheadline)
                    .foregroundColor(isHighlighted ? .purple : .black)
                    .fontWeight(isHighlighted ? .bold : .regular)
            } else {
                Text(title)
                    .font(.subheadline)
            }
        }
    }
} 
