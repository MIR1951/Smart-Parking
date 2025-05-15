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
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                VStack(spacing: 0) {
                    // 1. Sarlavha va parking kartochkasi (fiksirlangan)
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
                        .padding(.top)
                        .padding(.horizontal)
                        
                        // Parking ma'lumotlari kartochkasi - fiksirlangan
                        VStack(alignment: .leading, spacing: 10) {
                            if let imageUrl = spot.images?.first, !imageUrl.isEmpty {
                                StorageImageView(
                                    path: imageUrl,
                                    placeholder: Image(systemName: "car.fill"),
                                    contentMode: .fill
                                )
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 180)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            } else {
                                Image(systemName: "car.fill")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(height: 180)
                                    .padding()
                                    .foregroundColor(.gray)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
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

                    // 2. ScrollView faqat asosiy content uchun
                    ScrollView {
                        VStack(spacing: 15) {
                            // Vaqt tanlash qismi
                            HStack {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text("Boshlash vaqti")
                                        .font(.subheadline)
                                    
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
                                        .font(.subheadline)
                                    
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
                    }
                    .padding(.bottom, 20)
                }
                // 3. Pastki tugma (fiksirlangan)
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
        startDate = roundToThirtyMinutes(currentDate.addingTimeInterval(1800))
        
        // Tugash vaqti boshlang'ich vaqtdan kamida 1 soat keyin
        endDate = startDate.addingTimeInterval(3600)
    }
    
    // Vaqtni 30 daqiqalik intervalga yaxlitlash - yangilangan
    private func roundToThirtyMinutes(_ date: Date) -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        
        let minutes = components.minute ?? 0
        
        // 30 daqiqalik intervallarga yaxlitlash
        if minutes < 30 {
            components.minute = 30
        } else {
            components.minute = 0
            components.hour = (components.hour ?? 0) + 1
        }
        
        components.second = 0
        
        return calendar.date(from: components) ?? date
    }
    
    // To'g'rilangan narx formatini UZS (so'm) ko'rinishiga o'zgartirish
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
    
    // To'g'rilangan narx hisoblash funksiyasi
    private func calculateTotalPrice() -> Double {
        let durationInSeconds = endDate.timeIntervalSince(startDate)
        let durationInHours = durationInSeconds / 3600
        
        // 30 daqiqalik intervallarga bo'lingan narx hisoblash
        let halfHoursDouble = ceil(durationInSeconds / 1800)
        let halfHours = Int(halfHoursDouble)
        let finalHours = Double(halfHours) / 2.0
        let hasHalfHour = halfHours % 2 == 1
        
        // Asosiy narx (to'liq soatlar uchun)
        var price = finalHours * spot.pricePerHour
        
        // Agar yarim soat qo'shimcha bo'lsa
        if hasHalfHour {
            price += spot.pricePerHour / 2
        }
        
        // Minimal narx 30 daqiqa uchun (yarim soatlik narx)
        if price == 0 {
            price = spot.pricePerHour / 2
        }
        
        return price
    }
    
    // To'g'rilangan vaqt formatini ko'rsatish
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let totalMinutes = Int(seconds) / 60
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
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
    
    @State private var selectedDate: Date
    @State private var selectedHour: Int
    @State private var selectedMinute: Int
    
    init(startDate: Binding<Date>, endDate: Binding<Date>, pickerType: BookingTimeSelectionView.DatePickerType, minimumDate: Date, isPresented: Binding<Bool>) {
        self._startDate = startDate
        self._endDate = endDate
        self.pickerType = pickerType
        self.minimumDate = minimumDate
        self._isPresented = isPresented
        
        let date = pickerType == .start ? startDate.wrappedValue : endDate.wrappedValue
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        
        self._selectedDate = State(initialValue: date)
        self._selectedHour = State(initialValue: hour)
        self._selectedMinute = State(initialValue: minute)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Sana tanlash qismi (kichikroq, kamroq e'tibor)
                VStack(alignment: .leading, spacing: 10) {
                    Text("Sana:")
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    DatePicker("", selection: $selectedDate, in: pickerType == .start ? minimumDate... : startDate.addingTimeInterval(1800)..., displayedComponents: [.date])
                        .datePickerStyle(CompactDatePickerStyle())
                        .labelsHidden()
                        .environment(\.locale, Locale(identifier: "uz_UZ"))
                }
                .padding(.horizontal)
                
                // Soat va minut tanlagichlar (asosiy e'tibor)
                VStack(spacing: 30) {
                    Text("Vaqtni tanlang")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    HStack(spacing: 20) {
                        // Soat tanlagich
                        VStack {
                            Text("Soat")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Picker("Soat", selection: $selectedHour) {
                                ForEach(0..<24, id: \.self) { hour in
                                    Text("\(hour)").tag(hour)
                                }
                            }
                            .pickerStyle(WheelPickerStyle())
                            .frame(width: 80, height: 120)
                            .clipped()
                        }
                        
                        Text(":")
                            .font(.title)
                            .fontWeight(.bold)
                            .padding(.top, 20)
                        
                        // Minut tanlagich
                        VStack {
                            Text("Daqiqa")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Picker("Daqiqa", selection: $selectedMinute) {
                                ForEach([0, 30], id: \.self) { minute in
                                    Text("\(minute)").tag(minute)
                                }
                            }
                            .pickerStyle(WheelPickerStyle())
                            .frame(width: 80, height: 120)
                            .clipped()
                        }
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 15).fill(Color.white).shadow(color: Color.black.opacity(0.1), radius: 5))
                    
                    // Tanlangan vaqt
                    VStack {
                        Text("Tanlangan vaqt:")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Text("\(formatTime(hour: selectedHour, minute: selectedMinute))")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.purple)
                    }
                    .padding()
                }
                .padding(.top)
                
                Spacer()
                
                // Tasdiqlash tugmasi
                Button("Tasdiqlash") {
                    applySelectedTimeAndDismiss()
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.purple)
                .cornerRadius(10)
                .padding(.horizontal)
            }
            .padding(.vertical)
            .navigationTitle(pickerType == .start ? "Boshlash vaqti" : "Tugash vaqti")
            .navigationBarItems(trailing: Button("Yopish") {
                isPresented = false
            })
        }
    }
    
    // Soat va minutlarni formatlash
    private func formatTime(hour: Int, minute: Int) -> String {
        return String(format: "%02d:%02d", hour, minute)
    }
    
    // Tanlangan vaqtni qo'llash
    private func applySelectedTimeAndDismiss() {
        // Tanlangan sana va vaqtdan yangi sana yaratish
        var components = Calendar.current.dateComponents([.year, .month, .day], from: selectedDate)
        components.hour = selectedHour
        components.minute = selectedMinute
        components.second = 0
        
        guard let newDate = Calendar.current.date(from: components) else { return }
        
        // Sana minimal chegaralarini tekshirish
        let validDate = max(newDate, minimumDate)
        
        // Tanlangan vaqtga qarab start yoki end date'ni yangilash
        if pickerType == .start {
            startDate = validDate
            
            // Agar endDate ham mos kelmasa, uni ham yangilash
            if endDate.timeIntervalSince(startDate) < 1800 {
                endDate = startDate.addingTimeInterval(1800)
            }
        } else {
            // Eng kamida startDate dan 30 daqiqa keyin bo'lishi kerak
            let minimumEndDate = startDate.addingTimeInterval(1800)
            endDate = max(validDate, minimumEndDate)
        }
        
        isPresented = false
    }
} 
