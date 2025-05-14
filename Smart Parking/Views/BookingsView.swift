//
//  BookingsView.swift
//  Smart Parking
//
//  Created by Kenjaboy Xajiyev on 04/05/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct BookingsView: View {
    @StateObject private var viewModel = BookingsViewModel()
    @State private var selectedTab = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Sarlavha va orqaga tugma
            HStack {
                Button(action: {
                    // Orqaga tugmasi
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.black)
                        .padding(10)
                        .background(Circle().fill(Color.white))
                        .shadow(color: Color.black.opacity(0.1), radius: 2)
                }
                
                Spacer()
                
                Text("Mening bandlarim")
                    .font(.title3)
                    .fontWeight(.bold)
                
                Spacer()
                
                Circle()
                    .frame(width: 36, height: 36)
                    .foregroundColor(.clear)
            }
            .padding()
            
            // Tab tugmalar
            HStack(spacing: 0) {
                ForEach(BookingsViewModel.ReservationStatus.allCases, id: \.self) { status in
                    let index = BookingsViewModel.ReservationStatus.allCases.firstIndex(of: status) ?? 0
                    
                    Button(action: {
                        selectedTab = index
                    }) {
                        Text(status.localizedTitle)
                            .fontWeight(selectedTab == index ? .bold : .regular)
                            .foregroundColor(selectedTab == index ? .purple : .gray)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                }
            }
            .overlay(alignment: .bottom) {
                VStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 1)
                    
                    Rectangle()
                        .fill(Color.purple)
                        .frame(width: UIScreen.main.bounds.width / 3, height: 3)
                        .offset(x: CGFloat(selectedTab - 1) * UIScreen.main.bounds.width / 3)
                }
            }
            
            if viewModel.isLoading {
                Spacer()
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                Spacer()
            } else if viewModel.filteredReservations(for: selectedTab).isEmpty {
                Spacer()
                VStack(spacing: 20) {
                    Image(systemName: "calendar.badge.clock")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.gray)
                    
                    Text("Bandlar mavjud emas")
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    Text("Hozircha hech qanday bandlar yo'q")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(viewModel.filteredReservations(for: selectedTab)) { reservation in
                            ParkingReservationCard(reservation: reservation, viewModel: viewModel)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
                .refreshable {
                    viewModel.fetchReservations()
                }
            }
        }
        .onAppear {
            viewModel.fetchReservations()
        }
    }
}

struct ParkingReservationCard: View {
    let reservation: Reservation
    @ObservedObject var viewModel: BookingsViewModel
    @State private var remainingTime: TimeInterval = 0
    @State private var timer: Timer? = nil
    @State private var showCancelReasons = false
    @State private var showAddTimeSheet = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Parking Spot ma'lumotlari
            HStack(alignment: .top, spacing: 12) {
                // Rasm
                if let parkingSpot = viewModel.getParkingSpot(for: reservation),
                   let imageUrl = parkingSpot.images?.first,
                   !imageUrl.isEmpty {
                    StorageImageView(
                        path: imageUrl,
                        placeholder: Image(systemName: "car.fill"),
                        contentMode: .fill
                    )
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                } else {
                    Image(systemName: "car.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                        .padding()
                        .foregroundColor(.gray)
                        .background(Color.gray.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    if let parkingSpot = viewModel.getParkingSpot(for: reservation) {
                        Text("Avtomobil parkovkasi")
                            .font(.caption)
                            .foregroundColor(.purple)
                        
                        Text(parkingSpot.name)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .lineLimit(1)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "location.circle.fill")
                                .foregroundColor(.gray)
                                .font(.caption)
                            
                            Text(parkingSpot.address)
                                .font(.caption)
                                .foregroundColor(.gray)
                                .lineLimit(1)
                        }
                    } else {
                        Text("Yuklanyapti...")
                            .font(.subheadline)
                    }
                }
                
                Spacer()
                
                // Reyting
                if let parkingSpot = viewModel.getParkingSpot(for: reservation), 
                   let rating = parkingSpot.rating {
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                        
                        Text(String(format: "%.1f", rating))
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                    }
                }
            }
            .padding()
            .background(Color.white)
            
            Divider()
            
            // Narx
            if let parkingSpot = viewModel.getParkingSpot(for: reservation) {
                HStack {
                    Text("\(String(format: "%.0f", parkingSpot.pricePerHour)) so'm")
                        .fontWeight(.semibold)
                        .foregroundColor(.purple)
                    
                    Text("/soat")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    // Qolgan vaqt timer uchun
                    if reservation.status == "active" && isCurrentlyActive() {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .foregroundColor(.orange)
                            
                            Text(formatRemainingTime())
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.orange)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.white)
            }
            
            // Amallar
            HStack {
                if reservation.status == "active" {
                    if isCurrentlyActive() {
                        // Agar hozir aktivlashgan bo'lsa (startTime < now < endTime)
                        Button(action: {
                            showAddTimeSheet = true
                        }) {
                            Text("Vaqt qo'shish")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.white)
                                .foregroundColor(.purple)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                        }
                    } else {
                        // Hali boshlanmagan rezervatsiya
                        Button(action: {
                            showCancelReasons = true
                        }) {
                            Text("Bekor qilish")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.white)
                                .foregroundColor(.red)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                )
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        // E-Ticket amalini bajarish
                    }) {
                        Text("E-Ticket")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
            }
            .padding()
            .background(Color.white)
        }
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 3)
        .sheet(isPresented: $showCancelReasons) {
            CancelReasonView(reservation: reservation, viewModel: viewModel)
        }
        .sheet(isPresented: $showAddTimeSheet) {
            AddTimeView(reservation: reservation, viewModel: viewModel)
        }
        .onAppear {
            setupTimer()
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
    }
    
    private func setupTimer() {
        if reservation.status == "active" && isCurrentlyActive() {
            calculateRemainingTime()
            
            timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
                calculateRemainingTime()
            }
        }
    }
    
    private func calculateRemainingTime() {
        let now = Date()
        if now < reservation.endTime {
            remainingTime = reservation.endTime.timeIntervalSince(now)
        } else {
            remainingTime = 0
            timer?.invalidate()
            timer = nil
        }
    }
    
    private func formatRemainingTime() -> String {
        if remainingTime <= 0 {
            return "Vaqt tugadi"
        }
        
        let hours = Int(remainingTime) / 3600
        let minutes = (Int(remainingTime) % 3600) / 60
        
        if hours > 0 {
            return "\(hours) soat \(minutes) daqiqa"
        } else {
            return "\(minutes) daqiqa"
        }
    }
    
    private func isCurrentlyActive() -> Bool {
        let now = Date()
        return now >= reservation.startTime && now <= reservation.endTime
    }
}

struct CancelReasonView: View {
    let reservation: Reservation
    @ObservedObject var viewModel: BookingsViewModel
    @Environment(\.dismiss) var dismiss
    @State private var selectedReason = ""
    
    let reasons = [
        "Rejalarim o'zgardi",
        "Boshqa parkovka joyi topdim",
        "Narxi qimmat",
        "Boshqa sabab"
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Spacer()
                
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.gray)
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal)
            
            Text("Band qilishni bekor qilish")
                .font(.title3)
                .fontWeight(.bold)
                
            Text("Iltimos, bekor qilish sababini tanlang")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            VStack(spacing: 15) {
                ForEach(reasons, id: \.self) { reason in
                    ReasonButton(text: reason, isSelected: selectedReason == reason) {
                        selectedReason = reason
                    }
                }
            }
            .padding()
            
            if !selectedReason.isEmpty {
                Button(action: {
                    viewModel.cancelReservation(reservationID: reservation.id, reason: selectedReason) { success, message in
                        dismiss()
                        // Bunda notifikatsiya yoki alert ko'rsatish mumkin
                    }
                }) {
                    Text("Tasdiqlash")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            
            Spacer()
        }
        .padding(.top)
    }
}

struct ReasonButton: View {
    let text: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(text)
                    .font(.subheadline)
                    .foregroundColor(isSelected ? .purple : .black)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.purple)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.purple : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
            )
        }
    }
}

struct AddTimeView: View {
    let reservation: Reservation
    @ObservedObject var viewModel: BookingsViewModel
    @Environment(\.dismiss) var dismiss
    @State private var additionalTime: Int = 30
    
    let timeOptions = [30, 60, 90, 120]
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Spacer()
                
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.gray)
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal)
            
            Text("Vaqt qo'shish")
                .font(.title3)
                .fontWeight(.bold)
            
            if let parkingSpot = viewModel.getParkingSpot(for: reservation) {
                Text("Joriy tugash vaqti: \(viewModel.formatDate(reservation.endTime))")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                VStack(spacing: 15) {
                    Text("Qo'shimcha vaqt tanlang")
                        .font(.headline)
                    
                    HStack {
                        ForEach(timeOptions, id: \.self) { minutes in
                            TimeButton(
                                minutes: minutes,
                                isSelected: additionalTime == minutes
                            ) {
                                additionalTime = minutes
                            }
                        }
                    }
                }
                .padding()
                
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Qo'shimcha to'lov:")
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Text("\(String(format: "%.0f", calculateAdditionalPrice(parkingSpot))) so'm")
                            .font(.headline)
                            .foregroundColor(.purple)
                    }
                    
                    HStack {
                        Text("Yangi tugash vaqti:")
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Text(viewModel.formatDate(calculateNewEndTime()))
                            .font(.headline)
                            .foregroundColor(.purple)
                    }
                }
                .padding()
                .background(Color.purple.opacity(0.05))
                .cornerRadius(10)
                .padding(.horizontal)
                
                Button(action: {
                    viewModel.extendReservationTime(
                        reservationID: reservation.id,
                        newEndTime: calculateNewEndTime(),
                        additionalPrice: calculateAdditionalPrice(parkingSpot)
                    ) { success, message in
                        dismiss()
                        // Bunda notifikatsiya yoki alert ko'rsatish mumkin
                    }
                }) {
                    Text("To'lash va vaqtni qo'shish")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            
            Spacer()
        }
        .padding(.top)
    }
    
    private func calculateNewEndTime() -> Date {
        let minutesToAdd = Double(additionalTime * 60)
        return reservation.endTime.addingTimeInterval(minutesToAdd)
    }
    
    private func calculateAdditionalPrice(_ parkingSpot: ParkingSpot) -> Double {
        let hoursToAdd = Double(additionalTime) / 60.0
        return parkingSpot.pricePerHour * hoursToAdd
    }
}

struct TimeButton: View {
    let minutes: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Text("\(minutes)")
                    .font(.headline)
                    .foregroundColor(isSelected ? .white : .black)
                
                Text("daqiqa")
                    .font(.caption)
                    .foregroundColor(isSelected ? .white : .gray)
            }
            .frame(width: 70, height: 70)
            .background(isSelected ? Color.purple : Color.white)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.purple : Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

struct ReservationDetailsView: View {
    let reservation: Reservation
    @StateObject private var viewModel = ReservationDetailsViewModel()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Holat banneri
                HStack {
                    Circle()
                        .fill(statusColor(reservation.status))
                        .frame(width: 8, height: 8)
                    
                    Text(formatStatus(reservation.status))
                        .font(.subheadline)
                        .foregroundColor(statusColor(reservation.status))
                    
                    Spacer()
                    
                    Text(formatReservationID(reservation.id))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding()
                .background(statusColor(reservation.status).opacity(0.1))
                .cornerRadius(10)
                
                // Parkovka ma'lumotlari
                if let spot = viewModel.parkingSpot {
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Parkovka ma'lumotlari")
                            .font(.headline)
                        
                        HStack {
                            if let imageUrl = spot.images?.first, !imageUrl.isEmpty {
                                StorageImageView(
                                    path: imageUrl,
                                    placeholder: Image(systemName: "car.fill"),
                                    contentMode: .fill
                                )
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            } else {
                                Image(systemName: "car.fill")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 80, height: 80)
                                    .padding()
                                    .foregroundColor(.gray)
                                    .background(Color.gray.opacity(0.2))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(spot.name)
                                    .font(.headline)
                                
                                Text(spot.address)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                
                                HStack {
                                    // Reyting
                                    if let rating = spot.rating {
                                        HStack(spacing: 2) {
                                            Image(systemName: "star.fill")
                                                .foregroundColor(.yellow)
                                                .font(.caption)
                                            
                                            Text(String(format: "%.1f", rating))
                                                .font(.caption)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    // Masofa
                                    Text(spot.distance)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(.leading, 5)
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(color: Color.black.opacity(0.05), radius: 5)
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                }
                
                // Band qilish tafsilotlari
                VStack(alignment: .leading, spacing: 15) {
                    Text("Band qilish tafsilotlari")
                        .font(.headline)
                    
                    // Vaqt
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.purple)
                            
                            Text("Kirish vaqti")
                                .foregroundColor(.gray)
                            
                            Spacer()
                            
                            Text(formatDateTime(reservation.startTime))
                        }
                        
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.purple)
                            
                            Text("Chiqish vaqti")
                                .foregroundColor(.gray)
                            
                            Spacer()
                            
                            Text(formatDateTime(reservation.endTime))
                        }
                        
                        if let slot = reservation.slotNumber {
                            HStack {
                                Image(systemName: "parkingsign")
                                    .foregroundColor(.purple)
                                
                                Text("Parkovka slot")
                                    .foregroundColor(.gray)
                                
                                Spacer()
                                
                                Text(slot)
                            }
                        }
                        
                        if let vehicleID = reservation.vehicleID, let vehicle = viewModel.vehicle {
                            HStack {
                                Image(systemName: "car")
                                    .foregroundColor(.purple)
                                
                                Text("Transport vositasi")
                                    .foregroundColor(.gray)
                                
                                Spacer()
                                
                                Text("\(vehicle.name) (\(vehicle.plate))")
                            }
                        }
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.05), radius: 5)
                
                // To'lov ma'lumotlari
                VStack(alignment: .leading, spacing: 15) {
                    Text("To'lov tafsilotlari")
                        .font(.headline)
                    
                    VStack(spacing: 12) {
                        HStack {
                            Text("Band qilish narxi")
                                .foregroundColor(.gray)
                            
                            Spacer()
                            
                            Text("\(Int(reservation.totalPrice)) so'm")
                        }
                        
                        if let payment = viewModel.payment {
                            HStack {
                                Text("To'lov usuli")
                                    .foregroundColor(.gray)
                                
                                Spacer()
                                
                                Text(payment.paymentMethod)
                            }
                            
                            HStack {
                                Text("To'lov holati")
                                    .foregroundColor(.gray)
                                
                                Spacer()
                                
                                Text(formatPaymentStatus(payment.status))
                                    .foregroundColor(paymentStatusColor(payment.status))
                            }
                        }
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.05), radius: 5)
                
                // Tugmalar
                if reservation.status == "Ongoing" {
                    VStack(spacing: 10) {
                        Button(action: {
                            // Show QR code for e-ticket
                        }) {
                            HStack {
                                Image(systemName: "qrcode")
                                Text("E-Chiptani ko'rsatish")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        
                        Button(action: {
                            // Cancel reservation
                            viewModel.cancelReservation(reservation)
                        }) {
                            HStack {
                                Image(systemName: "xmark.circle")
                                Text("Band qilishni bekor qilish")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .foregroundColor(.red)
                            .cornerRadius(10)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Band qilish tafsilotlari")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.fetchReservationDetails(reservation)
        }
    }
    
    private func formatStatus(_ status: String) -> String {
        switch status {
        case "Ongoing":
            return "Faol band qilish"
        case "Completed":
            return "Tugallangan band qilish"
        case "Cancelled":
            return "Bekor qilingan band qilish"
        default:
            return status
        }
    }
    
    private func statusColor(_ status: String) -> Color {
        switch status {
        case "Ongoing":
            return .green
        case "Completed":
            return .blue
        case "Cancelled":
            return .red
        default:
            return .gray
        }
    }
    
    private func formatReservationID(_ id: String) -> String {
        return "ID: \(id.prefix(8).uppercased())"
    }
    
    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy, HH:mm"
        return formatter.string(from: date)
    }
    
    private func formatPaymentStatus(_ status: String) -> String {
        switch status {
        case "Completed":
            return "To'langan"
        case "Pending":
            return "Kutilmoqda"
        case "Failed":
            return "Muvaffaqiyatsiz"
        default:
            return status
        }
    }
    
    private func paymentStatusColor(_ status: String) -> Color {
        switch status {
        case "Completed":
            return .green
        case "Pending":
            return .orange
        case "Failed":
            return .red
        default:
            return .gray
        }
    }
}

class ReservationDetailsViewModel: ObservableObject {
    @Published var parkingSpot: ParkingSpot?
    @Published var vehicle: Vehicle?
    @Published var payment: Payment?
    
    private let dbManager = DatabaseManager()
    
    func fetchReservationDetails(_ reservation: Reservation) {
        // Parkovka joyini olish
        dbManager.fetchParkingSpot(withID: reservation.parkingSpotID) { [weak self] spot, error in
            guard let self = self else { return }
            
            if let spot = spot {
                DispatchQueue.main.async {
                    self.parkingSpot = spot
                }
            }
        }
        
        // Transport vositasini olish
        if let vehicleID = reservation.vehicleID {
            fetchVehicle(vehicleID)
        }
        
        // To'lovni olish
        if let paymentID = reservation.paymentID {
            fetchPayment(paymentID)
        }
    }
    
    private func fetchVehicle(_ vehicleID: String) {
        // Oddiy namuna uchun
        let vehicle = Vehicle(
            id: vehicleID,
            userID: "user123",
            brand: "Toyota",
            name: "Toyota Camry",
            type: "Sedan",
            plate: "01A777BC",
            image: nil
        )
        
        DispatchQueue.main.async {
            self.vehicle = vehicle
        }
    }
    
    private func fetchPayment(_ paymentID: String) {
        // Oddiy namuna uchun
        let payment = Payment(
            id: paymentID,
            userID: "user123",
            reservationID: "reservation1",
            amount: 15000,
            status: "Completed",
            paymentMethod: "Payme",
            createdAt: Date(),
            transactionID: "tx123456"
        )
        
        DispatchQueue.main.async {
            self.payment = payment
        }
    }
    
    func cancelReservation(_ reservation: Reservation) {
        dbManager.updateReservationStatus(reservationID: reservation.id, status: "Cancelled") { error in
            if let error = error {
                print("Band qilishni bekor qilishda xatolik: \(error.localizedDescription)")
                return
            }
            
            // Muvaffaqiyatli bekor qilingan
        }
    }
}

struct BookingsView_Previews: PreviewProvider {
    static var previews: some View {
        BookingsView()
    }
}
