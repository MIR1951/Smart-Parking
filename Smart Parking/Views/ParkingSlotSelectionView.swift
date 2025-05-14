import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ParkingSlotSelectionView: View {
    let spot: ParkingSpot
    let vehicle: Vehicle
    let arrivalTime: Date
    let exitTime: Date
    
    @State private var slots: [ParkingSlot] = []
    @State private var isLoading = true
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var selectedSlot: ParkingSlot?
    @State private var showPaymentMethodSelection = false
    @State private var selectedFloor = 0
    @Environment(\.dismiss) var dismiss
    
    private let floors = ["1-qavat", "2-qavat", "3-qavat"]
    
    var body: some View {
        ZStack {
            Color.white.edgesIgnoringSafeArea(.all)
            
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
                    
                    Text("Joy tanlash")
                        .font(.headline)
                        .foregroundColor(.black)
                    
                    Spacer()
                    
                    Circle()
                        .frame(width: 36, height: 36)
                        .foregroundColor(.clear)
                }
                .padding()
                
                // Floor selection tabs
                HStack(spacing: 0) {
                    ForEach(0..<floors.count , id: \.self) { index in
                        Button(action: {
                            selectedFloor = index
                        }) {
                            Text(floors[index])
                                .font(.subheadline)
                                .fontWeight(selectedFloor == index ? .semibold : .regular)
                                .foregroundColor(selectedFloor == index ? .white : .gray)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(selectedFloor == index ? Color.purple : Color.clear)
                        }
                    }
                }
                .background(Color.gray.opacity(0.1))
                
                if isLoading {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                    Spacer()
                } else if filteredSlots.isEmpty {
                    Spacer()
                    VStack(spacing: 15) {
                        Image(systemName: "car.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        
                        Text("Bo'sh joylar mavjud emas")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            // Joylar to'rtburchagi
                            ParkingGridView(
                                slots: filteredSlots,
                                selectedfloor: selectedFloor,
                                selectedSlot: $selectedSlot,
                                toggleSelection: toggleSlotSelection
                            )
                            .padding()
                        }
                    }
                }
                
                // Footer with continue button
                Button(action: {
                    if selectedSlot != nil {
                        showPaymentMethodSelection = true
                    } else {
                        errorMessage = "Iltimos, to'xtash joyini tanlang"
                        showError = true
                    }
                }) {
                    Text("Davom etish")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedSlot == nil ? Color.gray.opacity(0.5) : Color.purple)
                        .cornerRadius(30)
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                }
                .disabled(selectedSlot == nil)
            }
        }
        .onAppear(perform: loadParkingSlots)
        .alert(isPresented: $showError) {
            Alert(
                title: Text("Xatolik"),
                message: Text(errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .fullScreenCover(isPresented: $showPaymentMethodSelection) {
            if let slot = selectedSlot {
                PaymentMethodSelectionView(
                    spot: spot,
                    vehicle: vehicle,
                    slot: slot,
                    arrivalTime: arrivalTime,
                    exitTime: exitTime
                )
            }
        }
    }
    
    // Tanlangan qavatdagi slotlarni filtrlash
    private var filteredSlots: [ParkingSlot] {
        slots.filter { $0.floor == selectedFloor + 1 }
    }
    
    private func loadParkingSlots() {
        isLoading = true
        
        let db = Firestore.firestore()
        
        // Avval barcha slotlarni olish
        db.collection("parkingSpots").document(spot.id).collection("slots")
            .getDocuments { snapshot, error in
                if let error = error {
                    self.isLoading = false
                    self.errorMessage = "Joylarni yuklashda xatolik: \(error.localizedDescription)"
                    self.showError = true
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self.isLoading = false
                    return
                }
                
                // Barcha slotlarni olish
                var allSlots = documents.compactMap { document -> ParkingSlot? in
                    let data = document.data()
                    return ParkingSlot(
                        id: document.documentID,
                        parkingSpotID: spot.id,
                        slotNumber: data["slotNumber"] as? String ?? "",
                        isAvailable: data["isAvailable"] as? Bool ?? true,
                        type: data["type"] as? String,
                        floor: data["floor"] as? Int ?? 0
                    )
                }
                
                // Berilgan vaqt oralig'ida band qilingan slotlarni aniqlash
                self.checkReservations(parkingID: self.spot.id, arrivalTime: self.arrivalTime, exitTime: self.exitTime) { reservedSlotIDs in
                    // Band qilingan slotlarni belgilash
                    for index in 0..<allSlots.count {
                        if reservedSlotIDs.contains(allSlots[index].slotNumber ?? "") {
                            let slot = allSlots[index]
                            // To'g'ridan-to'g'ri strukturani o'zgartirolmaymiz, shuning uchun yangi qiymat yaratib qo'yamiz
                            allSlots[index] = ParkingSlot(
                                id: slot.id,
                                parkingSpotID: slot.parkingSpotID,
                                slotNumber: slot.slotNumber,
                                isAvailable: false,
                                type: slot.type,
                                floor: slot.floor
                            )
                        }
                    }
                    
                    self.slots = allSlots
                    self.isLoading = false
                }
            }
    }
    
    private func checkReservations(parkingID: String, arrivalTime: Date, exitTime: Date, completion: @escaping ([String]) -> Void) {
        let db = Firestore.firestore()
        
        print("Tekshirish: Arrival: \(arrivalTime), Exit: \(exitTime)")
        
        // Tanlangan vaqt bilan to'qnashuvchi barcha bronlarni tekshirish
        db.collection("reservations")
            .whereField("parkingSpotID", isEqualTo: parkingID)
            .whereField("status", isEqualTo: "active")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Bronlarni yuklashda xatolik: \(error.localizedDescription)")
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
                    
                    // Aniq to'qnashuv formulasi:
                    // Agar ikki vaqt oralig'i to'qnashsa, ular orasidagi maksimal boshlanish vaqti
                    // ularning minimal tugash vaqtidan kichik bo'ladi
                    if max(arrivalTime, reservationStart) < min(exitTime, reservationEnd) {
                        // Bu joy band - uni ro'yxatga qo'shish
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
    
    // Slot tanlash/bekor qilish
    private func toggleSlotSelection(_ slotNumber: String?) {
        guard let slotNumber = slotNumber else { return }
        
        if !isSlotAvailable(slotNumber) {
            return
        }
        
        if let existingSlot = selectedSlot, existingSlot.slotNumber == slotNumber {
            selectedSlot = nil
        } else if let slot = slots.first(where: { $0.slotNumber == slotNumber }) {
            selectedSlot = slot
        }
    }
    
    // Slot mavjudligini tekshirish
    private func isSlotAvailable(_ slotNumber: String?) -> Bool {
        guard let slotNumber = slotNumber else { return false }
        return !slots.contains(where: { $0.slotNumber == slotNumber && !$0.isAvailable })
    }
}

// Parking Grid View - Joylar tarmog'i
struct ParkingGridView: View {
    let slots: [ParkingSlot]
    var selectedfloor: Int
    @Binding var selectedSlot: ParkingSlot?
    let toggleSelection: (String?) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // To'xatash joyi sxemasi
            Text("To'xtash joyi sxemasi")
                .font(.headline)
                .padding(.bottom, 5)
            
            // Progress bar
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white)
                            .frame(width: 16, height: 16)
                            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.gray.opacity(0.5), lineWidth: 1))
                        
                        Text("Bo'sh")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 16, height: 16)
                        
                        Text("Band")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 8) {
                    HStack {
                        Text("Tanlangan")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.purple)
                            .frame(width: 16, height: 16)
                    }
                    
                    HStack {
                        Text("Kompakt")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white)
                            .frame(width: 16, height: 16)
                            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.blue.opacity(0.7), lineWidth: 1))
                    }
                }
            }
            
            // Soddalashtirilgan tashkil etilgan joylar
            VStack(spacing: 15) {
                // Kirish
                HStack {
                    Text("Kirish")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Spacer()
                }
                
                // Joylarni 5x2 tarzda ko'rsatish
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 10) {
                    // Avtomatik tarzda qavatga mos joylarni topish
                    let currentFloorSlots = filteredAndSortedSlots()
                    
                    ForEach(currentFloorSlots, id: \.id) { slot in
                        ParkingSlotCell(
                            slotNumber: slot.slotNumber,
                            isAvailable: slot.isAvailable,
                            isSelected: selectedSlot?.slotNumber == slot.slotNumber,
                            isCompact: slot.type == "compact",
                            onTap: {
                                toggleSelection(slot.slotNumber)
                            }
                        )
                    }
                }
            }
        }
    }
    
    // Joriy qavatning slotlarini filtrlash va saralash
    private func filteredAndSortedSlots() -> [ParkingSlot] {
        // Qavat prefixini aniqlash (1-qavatda "A", 2-qavatda "B", 3-qavatda "C")
//        let prefixes = ["A", "B", "C"]
//        guard slots.first?.floor != nil, let selectedFloor = slots.first?.floor else {
//            return []
//        }
//        
//        let prefix = selectedFloor < prefixes.count ? prefixes[selectedFloor] : "A"
//        
//        // Qavatga mos joylarni filtrlash
//        let filteredSlots = slots.filter { slot in
//            guard let slotNumber = slot.slotNumber else { return false }
//            return slotNumber.hasPrefix(prefix)
//        }
//        
//        // Joylarni raqamiga ko'ra saralash
//        return filteredSlots.sorted { slot1, slot2 in
//            guard let num1 = extractNumber(from: slot1.slotNumber ?? ""),
//                  let num2 = extractNumber(from: slot2.slotNumber ?? "") else {
//                return false
//            }
//            return num1 < num2
//        }
//    }
//    
//    // Slot raqamini ajratib olish (masalan: "A03" dan "3" ni)
//    private func extractNumber(from slotNumber: String) -> Int? {
//        guard slotNumber.count > 1 else { return nil }
//        let numberPart = slotNumber.dropFirst()
//        return Int(numberPart)
        slots
    }
}

// Individual slot cell
struct ParkingSlotCell: View {
    let slotNumber: String?
    let isAvailable: Bool
    let isSelected: Bool
    let isCompact: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(backgroundColor)
                    .frame(width: 60, height: 45)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isCompact ? Color.blue.opacity(0.7) : Color.gray.opacity(0.3), lineWidth: 1)
                    )
                
                if !isAvailable {
                    Image(systemName: "car.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 25, height: 25)
                        .foregroundColor(.gray)
                }
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .bold))
                }
            }
            
            Text(slotNumber ?? "")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(textColor)
        }
        .onTapGesture {
            if isAvailable {
                onTap()
            }
        }
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return Color.purple
        } else if isAvailable {
            return Color.white
        } else {
            return Color.gray.opacity(0.1)
        }
    }
    
    private var textColor: Color {
        if isSelected {
            return Color.purple
        } else if !isAvailable {
            return Color.gray
        } else {
            return Color.black
        }
    }
} 
