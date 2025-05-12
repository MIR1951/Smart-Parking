import SwiftUI
import FirebaseFirestore
import Firebase

struct BookingTimeSelectionView: View {
    let spot: ParkingSpot
    
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(3600) // 1 soat keyingi
    @State private var showDatePicker = false
    @State private var pickerType: DatePickerType = .start
    
    enum DatePickerType {
        case start, end
    }
    
    @Environment(\.dismiss) var dismiss
    @State private var showVehicleSelection = false
    @State private var isLoading = false
    
    init(spot: ParkingSpot) {
        self.spot = spot
    }
    
    var body: some View {
        // ScrollView o'rniga ZStack va GeometryReader ishlatamiz
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                VStack(spacing: 0) {
                    // Sarlavha va orqaga tugma - fiksirlangan qism
                    VStack(spacing: 20) {
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
                            
                            Text("Band qilish")
                                .font(.title3)
                                .fontWeight(.bold)
                            
                            Spacer()
                        }
                        .padding(.horizontal)
                        
                        // Parking ma'lumotlari kartochkasi - fiksirlangan
                        VStack(alignment: .leading, spacing: 10) {
                            if let imageUrl = spot.images?.first, !imageUrl.isEmpty {
                                AsyncImage(url: URL(string: imageUrl)) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(height: 120)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                } placeholder: {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(height: 120)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Avtomobil parkingi")
                                    .font(.caption)
                                    .foregroundColor(.purple)
                                
                                Text(spot.name)
                                    .font(.headline)
                                    .fontWeight(.bold)
                                
                                HStack {
                                    Image(systemName: "location.circle.fill")
                                        .foregroundColor(.gray)
                                        .font(.caption)
                                    
                                    Text(spot.address)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                
                                HStack {
                                    if let rating = spot.rating {
                                        HStack {
                                            Image(systemName: "star.fill")
                                                .foregroundColor(.yellow)
                                                .font(.caption)
                                            
                                            Text(String(format: "%.1f", rating))
                                                .font(.caption)
                                                .fontWeight(.bold)
                                        }
                                    }
                                    
                                    if let reviewCount = spot.reviewCount {
                                        Text("(\(reviewCount) sharhlar)")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    
                                    Spacer()
                                    
                                    Text("\(formatPrice(spot.pricePerHour))/soat")
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.purple)
                                }
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 5)
                        .padding(.horizontal)
                    }
                    
                    // Vaqt tanlash qismi - fiksirlangan
                    VStack(spacing: 15) {
                        // Kirish vaqti
                        HStack {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Boshlash vaqti")
                                    .font(.headline)
                                
                                Text(formatDateTime(startDate))
                                    .font(.title3)
                                    .fontWeight(.semibold)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                pickerType = .start
                                showDatePicker = true
                            }) {
                                Text("O'zgartirish")
                                    .font(.subheadline)
                                    .foregroundColor(.purple)
                                    .padding(.horizontal, 15)
                                    .padding(.vertical, 8)
                                    .background(Color.purple.opacity(0.1))
                                    .cornerRadius(20)
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(color: Color.black.opacity(0.05), radius: 2)
                        .padding(.horizontal)
                        
                        // Chiqish vaqti
                        HStack {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Tugash vaqti")
                                    .font(.headline)
                                
                                Text(formatDateTime(endDate))
                                    .font(.title3)
                                    .fontWeight(.semibold)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                pickerType = .end
                                showDatePicker = true
                            }) {
                                Text("O'zgartirish")
                                    .font(.subheadline)
                                    .foregroundColor(.purple)
                                    .padding(.horizontal, 15)
                                    .padding(.vertical, 8)
                                    .background(Color.purple.opacity(0.1))
                                    .cornerRadius(20)
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(color: Color.black.opacity(0.05), radius: 2)
                        .padding(.horizontal)
                    }
                    
                    // Narx ma'lumotlari - fiksirlangan 
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "clock")
                                .foregroundColor(.purple)
                                .frame(width: 24)
                            Text("Band qilish vaqti:")
                                .foregroundColor(.gray)
                            Spacer()
                            Text(formatDuration(endDate.timeIntervalSince(startDate)))
                                .fontWeight(.medium)
                        }
                        
                        Divider()
                        
                        HStack {
                            Image(systemName: "banknote")
                                .foregroundColor(.purple)
                                .frame(width: 24)
                            Text("Soatlik narx:")
                                .foregroundColor(.gray)
                            Spacer()
                            Text(formatPrice(spot.pricePerHour))
                                .fontWeight(.medium)
                        }
                        
                        Divider()
                        
                        HStack {
                            Image(systemName: "creditcard")
                                .foregroundColor(.purple)
                                .frame(width: 24)
                            Text("Jami narx:")
                                .font(.headline)
                            Spacer()
                            Text(formatPrice(calculateTotalPrice()))
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.purple)
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(color: Color.black.opacity(0.05), radius: 2)
                    .padding(.horizontal)
                    
                    Spacer()
                }
                
                // Davom etish tugmasi - har doim pastki qismda ko'rinib turadigan
                VStack {
                    Button(action: {
                        continueToVehicleSelection()
                    }) {
                        Text("Davom etish")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .cornerRadius(30)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? 20 : 30)
                }
                .padding(.top, 10)
                .background(
                    Color.white
                        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: -5)
                )
            }
            .edgesIgnoringSafeArea(.bottom)
        }
        .background(Color.gray.opacity(0.05).ignoresSafeArea())
        .onAppear {
            setupInitialDates()
        }
        .sheet(isPresented: $showDatePicker) {
            DatePickerSheet(
                startDate: $startDate,
                endDate: $endDate, 
                pickerType: pickerType,
                minimumDate: Date(),
                isPresented: $showDatePicker
            )
        }
        .fullScreenCover(isPresented: $showVehicleSelection) {
            VehicleSelectionView(
                spot: spot, 
                arrivalTime: startDate, 
                exitTime: endDate
            )
        }
    }
    
    // Dastlabki sana va vaqtlarni o'rnatish
    private func setupInitialDates() {
        // Joriy vaqt (hozir)
        let currentDate = Date()
        
        // Joriy vaqtni eng yaqin kelayotgan 30 daqiqalik intervalga yaxlitlash
        // Va 30 daqiqa qo'shish (band qilish hech bo'lmaganda joriy vaqtdan 30 daqiqa keyindan boshlanishi kerak)
        startDate = roundToThirtyMinutes(currentDate.addingTimeInterval(1800), roundingType: .down)
        
        // Tugash vaqti boshlang'ich vaqtdan kamida 1 soat keyin
        endDate = startDate.addingTimeInterval(3600)
    }
    
    // Vaqtni 30 daqiqalik intervalga yaxlitlash
    private func roundToThirtyMinutes(_ date: Date, roundingType: RoundingType) -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        
        let minutes = components.minute ?? 0
        
        switch roundingType {
        case .down:
            // Pastga yaxlitlash (kelish vaqti uchun)
            components.minute = minutes < 30 ? 0 : 30
        case .up:
            // Yuqoriga yaxlitlash (chiqish vaqti uchun)
            components.minute = minutes <= 30 ? 30 : 0
            if minutes > 30 {
                components.hour = (components.hour ?? 0) + 1
            }
        }
        
        components.second = 0
        
        return calendar.date(from: components) ?? date
    }
    
    enum RoundingType {
        case up   // Yuqoriga yaxlitlash (chiqish vaqti uchun)
        case down // Pastga yaxlitlash (kelish vaqti uchun)
    }
    
    // Narx formatini UZS (so'm) ko'rinishiga o'zgartirish
    private func formatPrice(_ price: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        
        if let formattedString = formatter.string(from: NSNumber(value: price)) {
            return "\(formattedString) so'm"
        }
        
        return "\(Int(price)) so'm"
    }
    
    private func calculateTotalPrice() -> Double {
        let hours = ceil(endDate.timeIntervalSince(startDate) / 3600)
        return hours * spot.pricePerHour
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        let days = hours / 24
        let remainingHours = hours % 24
        
        if days > 0 {
            return "\(days) kun \(remainingHours) soat"
        } else if minutes > 0 && hours > 0 {
            return "\(hours) soat \(minutes) daqiqa"
        } else if hours > 0 {
            return "\(hours) soat"
        } else {
            return "\(minutes) daqiqa"
        }
    }
    
    // Vaqt va sanani birlashtiradigan funksiya
    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "uz_UZ")
        formatter.dateFormat = "d-MMMM, HH:mm"
        return formatter.string(from: date)
    }
    
    // Keyingi qadam
    private func continueToVehicleSelection() {
        // Transport vositasi tanlashga o'tish
        showVehicleSelection = true
    }
}

struct DatePickerSheet: View {
    @Binding var startDate: Date
    @Binding var endDate: Date
    let pickerType: BookingTimeSelectionView.DatePickerType
    let minimumDate: Date
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            VStack {
                DatePicker(
                    "Sana va vaqtni tanlang",
                    selection: pickerType == .start ? $startDate : $endDate,
                    in: pickerType == .start ? minimumDate... : startDate.addingTimeInterval(1800)...,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(GraphicalDatePickerStyle())
                .labelsHidden()
                .padding()
                .environment(\.locale, Locale(identifier: "uz_UZ"))
                
                Button("Tasdiqlash") {
                    // Minimal vaqt farqi yarim soat (1800 sekund)
                    if endDate.timeIntervalSince(startDate) < 1800 {
                        endDate = startDate.addingTimeInterval(1800)
                    }
                    
                    // 30 daqiqalik intervallarga yaxlitlash
                    if pickerType == .start {
                        // Kelish vaqtini pastga yaxlitlash
                        startDate = roundToThirtyMinutes(startDate, roundingType: .down)
                        // Agar endDate ham mos kelmasa, uni ham yangilash
                        if endDate.timeIntervalSince(startDate) < 1800 {
                            endDate = startDate.addingTimeInterval(1800)
                        }
                    } else {
                        // Chiqish vaqtini yuqoriga yaxlitlash
                        endDate = roundToThirtyMinutes(endDate, roundingType: .up)
                    }
                    
                    isPresented = false
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.purple)
                .cornerRadius(10)
                .padding(.horizontal)
            }
            .navigationTitle(pickerType == .start ? "Boshlash vaqti" : "Tugash vaqti")
            .navigationBarItems(trailing: Button("Yopish") {
                isPresented = false
            })
        }
    }
    
    // Vaqtni 30 daqiqalik intervalga yaxlitlash
    private func roundToThirtyMinutes(_ date: Date, roundingType: BookingTimeSelectionView.RoundingType) -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        
        let minutes = components.minute ?? 0
        
        switch roundingType {
        case .down:
            // Pastga yaxlitlash (kelish vaqti uchun)
            components.minute = minutes < 30 ? 0 : 30
        case .up:
            // Yuqoriga yaxlitlash (chiqish vaqti uchun)
            components.minute = minutes <= 30 ? 30 : 0
            if minutes > 30 {
                components.hour = (components.hour ?? 0) + 1
            }
        }
        
        components.second = 0
        
        return calendar.date(from: components) ?? date
    }
} 