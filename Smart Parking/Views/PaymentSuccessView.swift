import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import PDFKit

struct PaymentSuccessView: View {
    let reservationID: String
    
    @Environment(\.dismiss) var dismiss
    @State private var showHomeScreen = false
    @State private var reservation: Reservation?
    @State private var spot: ParkingSpot?
    @State private var vehicle: Vehicle?
    @State private var isLoadingData = true
    @State private var errorMessage: String?
    
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
                
                Text("To'lov")
                    .font(.headline)
                    .foregroundColor(.black)
                
                Spacer()
                
                Circle()
                    .frame(width: 32, height: 32)
                    .foregroundColor(.clear)
            }
            .padding()
            
            if isLoadingData {
                Spacer()
                ProgressView("Ma'lumotlar yuklanmoqda...")
                    .progressViewStyle(CircularProgressViewStyle())
                Spacer()
            } else {
                Spacer()
                
                // Success icon
                ZStack {
                    Circle()
                        .fill(Color.purple)
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 50, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.bottom, 30)
                
                // Success message
                Text("To'lov muvaffaqiyatli!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.bottom, 10)
                
                Text("Sizning to'xtash joyingiz muvaffaqiyatli bron qilindi.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                
                Text("Bronlaringizni bosh menyuda ko'rishingiz mumkin.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 40)
                
                if let reservation = reservation, let spot = spot, let vehicle = vehicle {
                    // Reservation Details
                    VStack(spacing: 8) {
                        DetailCard(title: "Mashina", value: "\(vehicle.brand) \(vehicle.name)")
                        DetailCard(title: "To'xtash joyi", value: spot.name)
                        DetailCard(title: "Manzil", value: spot.address)
                        DetailCard(title: "Rezervatsiya ID", value: reservationID)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 15) {
                    Button(action: {
                        // Download E-Receipt functionality
                        downloadReceipt()
                    }) {
                        HStack {
                            Image(systemName: "arrow.down.doc.fill")
                                .foregroundColor(.white)
                            Text("E-Kvitansiya yuklash")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .cornerRadius(30)
                    }
                    
                    Button(action: {
                        // View E-Ticket functionality
                        viewTicket()
                    }) {
                        HStack {
                            Image(systemName: "ticket.fill")
                                .foregroundColor(.purple)
                            Text("E-Chipta ko'rish")
                                .font(.headline)
                                .foregroundColor(.purple)
                        }
                        .padding()
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
        }
        .background(Color.white)
        .edgesIgnoringSafeArea(.bottom)
        .navigationBarHidden(true)
        .alert(isPresented: .constant(errorMessage != nil)) {
            Alert(
                title: Text("Xatolik"),
                message: Text(errorMessage ?? "Noma'lum xatolik yuz berdi"),
                dismissButton: .default(Text("OK")) {
                    errorMessage = nil
                }
            )
        }
        .onAppear {
            fetchReservationData()
        }
    }
    
    private func fetchReservationData() {
        isLoadingData = true
        errorMessage = nil
        
        let db = Firestore.firestore()
        
        // 1. Bron ma'lumotlarini olish
        db.collection("reservations").document(reservationID).getDocument() { documentSnapshot, error in
            if let error = error {
                DispatchQueue.main.async {
                    errorMessage = "Ma'lumotlarni olishda xatolik: \(error.localizedDescription)"
                    isLoadingData = false
                }
                return
            }
            
            guard let document = documentSnapshot, document.exists,
                  let data = document.data() else {
                DispatchQueue.main.async {
                    errorMessage = "Rezervatsiya topilmadi"
                    isLoadingData = false
                }
                return
            }
            
            let parkingSpotID = data["parkingSpotID"] as? String ?? ""
            let vehicleID = data["vehicleID"] as? String ?? ""
            let slotID = data["slotID"] as? String ?? ""
            let userID = data["userID"] as? String ?? ""
            let slotNumber = data["slotNumber"] as? String ?? ""
            
            // Reservation ma'lumotlarini yaratish
            let startTime = (data["startTime"] as? Timestamp)?.dateValue() ?? Date()
            let endTime = (data["endTime"] as? Timestamp)?.dateValue() ?? Date()
            let status = data["status"] as? String ?? "active"
            let totalPrice = data["totalPrice"] as? Double ?? 0.0
            let paymentID = data["paymentID"] as? String
            let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
            
            let reservation = Reservation(
                id: document.documentID,
                userID: userID,
                parkingSpotID: parkingSpotID,
                slotID: slotID,
                startTime: startTime,
                endTime: endTime,
                status: status,
                totalPrice: totalPrice,
                vehicleID: vehicleID,
                slotNumber: slotNumber,
                paymentID: paymentID,
                createdAt: createdAt
            )
            
            self.reservation = reservation
            
            // 2. Parking ma'lumotlarini olish
            db.collection("parkingSpots").document(parkingSpotID).getDocument() { parkingDocument, parkingError in
                if let parkingError = parkingError {
                    DispatchQueue.main.async {
                        errorMessage = "Parking ma'lumotlarini olishda xatolik: \(parkingError.localizedDescription)"
                        isLoadingData = false
                    }
                    return
                }
                
                if let parkingDocument = parkingDocument, let parkingData = parkingDocument.data() {
                    let name = parkingData["name"] as? String ?? "Noma'lum parking"
                    let address = parkingData["address"] as? String ?? "Noma'lum manzil"
                    let pricePerHour = parkingData["pricePerHour"] as? Double ?? 0.0
                    let spotsAvailable = parkingData["spotsAvailable"] as? Int ?? 0
                    let distance = parkingData["distance"] as? String
                    let location = parkingData["location"] as? GeoPoint
                    let features = parkingData["features"] as? [String]
                    let rating = parkingData["rating"] as? Double
                    let reviewCount = parkingData["reviewCount"] as? Int
                    let category = parkingData["category"] as? String
                    let description = parkingData["description"] as? String
                    let operatedBy = parkingData["operatedBy"] as? String
                    let images = parkingData["images"] as? [String]
                    
                    let parkingSpot = ParkingSpot(
                        id: parkingDocument.documentID,
                        name: name,
                        address: address,
                        pricePerHour: pricePerHour,
                        spotsAvailable: spotsAvailable,
                        distance: distance!,
                        location: location,
                        features: features,
                        rating: rating,
                        reviewCount: reviewCount,
                        category: category,
                        description: description,
                        operatedBy: operatedBy,
                        images: images
                    )
                    
                    self.spot = parkingSpot
                }
                
                // 3. Transport ma'lumotlarini olish
                db.collection("vehicles").document(vehicleID).getDocument() { vehicleDocument, vehicleError in
                    isLoadingData = false
                    
                    if let vehicleError = vehicleError {
                        DispatchQueue.main.async {
                            errorMessage = "Transport ma'lumotlarini olishda xatolik: \(vehicleError.localizedDescription)"
                        }
                        return
                    }
                    
                    if let vehicleDocument = vehicleDocument, let vehicleData = vehicleDocument.data() {
                        let userID = vehicleData["userID"] as? String ?? ""
                        let brand = vehicleData["brand"] as? String ?? "Noma'lum"
                        let name = vehicleData["name"] as? String ?? "Noma'lum transport"
                        let type = vehicleData["type"] as? String
                        let plate = vehicleData["plate"] as? String ?? ""
                        let image = vehicleData["image"] as? String
                        
                        let vehicle = Vehicle(
                            id: vehicleDocument.documentID,
                            userID: userID,
                            brand: brand,
                            name: name,
                            type: type,
                            plate: plate,
                            image: image
                        )
                        
                        self.vehicle = vehicle
                    }
                }
            }
        }
    }
    
    private func downloadReceipt() {
        guard let reservation = reservation, let spot = spot, let vehicle = vehicle else {
            errorMessage = "Kvitansiya uchun ma'lumotlar to'liq emas"
            return
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        // PDF yaratish
        let pdfMetaData = [
            kCGPDFContextCreator: "Smart Parking",
            kCGPDFContextAuthor: "Smart Parking App",
            kCGPDFContextTitle: "Parking Kvitansiyasi: \(reservationID)"
        ]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageWidth = 8.5 * 72.0
        let pageHeight = 11 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { (context) in
            context.beginPage()
            
            // PDF ga ma'lumotlarni qo'shish
            let textFont = UIFont.systemFont(ofSize: 12.0, weight: .regular)
            let titleFont = UIFont.systemFont(ofSize: 18.0, weight: .bold)
            let headerFont = UIFont.systemFont(ofSize: 14.0, weight: .semibold)
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            paragraphStyle.lineBreakMode = .byWordWrapping
            
            // Sarlavha
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: titleFont,
                .paragraphStyle: paragraphStyle
            ]
            
            let title = "SMART PARKING - TO'LOV KVITANSIYASI"
            title.draw(in: CGRect(x: 50, y: 50, width: pageWidth - 100, height: 50), withAttributes: titleAttributes)
            
            // Ma'lumotlar uchun stil
            let leftStyle = NSMutableParagraphStyle()
            leftStyle.alignment = .left
            
            let infoAttributes: [NSAttributedString.Key: Any] = [
                .font: textFont,
                .paragraphStyle: leftStyle
            ]
            
            let headerAttributes: [NSAttributedString.Key: Any] = [
                .font: headerFont,
                .paragraphStyle: leftStyle
            ]
            
            // Rezervatsiya ma'lumotlari
            "REZERVATSIYA MA'LUMOTLARI".draw(in: CGRect(x: 50, y: 120, width: pageWidth - 100, height: 20), withAttributes: headerAttributes)
            
            let infoY = 150.0
            let lineHeight = 20.0
            
            "Rezervatsiya ID: \(reservationID)".draw(in: CGRect(x: 50, y: infoY, width: pageWidth - 100, height: lineHeight), withAttributes: infoAttributes)
            
            "Sana: \(dateFormatter.string(from: Date()))".draw(in: CGRect(x: 50, y: infoY + lineHeight, width: pageWidth - 100, height: lineHeight), withAttributes: infoAttributes)
            
            // Parking ma'lumotlari
            "PARKING MA'LUMOTLARI".draw(in: CGRect(x: 50, y: infoY + lineHeight * 3, width: pageWidth - 100, height: lineHeight), withAttributes: headerAttributes)
            
            "Parking nomi: \(spot.name)".draw(in: CGRect(x: 50, y: infoY + lineHeight * 4, width: pageWidth - 100, height: lineHeight), withAttributes: infoAttributes)
            
            "Manzil: \(spot.address)".draw(in: CGRect(x: 50, y: infoY + lineHeight * 5, width: pageWidth - 100, height: lineHeight), withAttributes: infoAttributes)
            
            "Joy raqami: \(reservation.slotNumber)".draw(in: CGRect(x: 50, y: infoY + lineHeight * 6, width: pageWidth - 100, height: lineHeight), withAttributes: infoAttributes)
            
            // Vaqt ma'lumotlari
            "VAQT MA'LUMOTLARI".draw(in: CGRect(x: 50, y: infoY + lineHeight * 8, width: pageWidth - 100, height: lineHeight), withAttributes: headerAttributes)
            
            "Kirish vaqti: \(dateFormatter.string(from: reservation.startTime))".draw(in: CGRect(x: 50, y: infoY + lineHeight * 9, width: pageWidth - 100, height: lineHeight), withAttributes: infoAttributes)
            
            "Chiqish vaqti: \(dateFormatter.string(from: reservation.endTime))".draw(in: CGRect(x: 50, y: infoY + lineHeight * 10, width: pageWidth - 100, height: lineHeight), withAttributes: infoAttributes)
            
            // Transport ma'lumotlari
            "TRANSPORT MA'LUMOTLARI".draw(in: CGRect(x: 50, y: infoY + lineHeight * 12, width: pageWidth - 100, height: lineHeight), withAttributes: headerAttributes)
            
            "Transport: \(vehicle.brand) \(vehicle.name)".draw(in: CGRect(x: 50, y: infoY + lineHeight * 13, width: pageWidth - 100, height: lineHeight), withAttributes: infoAttributes)
            
            "Davlat raqami: \(vehicle.plate)".draw(in: CGRect(x: 50, y: infoY + lineHeight * 14, width: pageWidth - 100, height: lineHeight), withAttributes: infoAttributes)
            
            // To'lov ma'lumotlari
            "TO'LOV MA'LUMOTLARI".draw(in: CGRect(x: 50, y: infoY + lineHeight * 16, width: pageWidth - 100, height: lineHeight), withAttributes: headerAttributes)
            
            "Narx: \(String(format: "%.2f so'm/soat", spot.pricePerHour))".draw(in: CGRect(x: 50, y: infoY + lineHeight * 17, width: pageWidth - 100, height: lineHeight), withAttributes: infoAttributes)
            
            "Jami to'lov: \(String(format: "%.2f so'm", reservation.totalPrice))".draw(in: CGRect(x: 50, y: infoY + lineHeight * 18, width: pageWidth - 100, height: lineHeight), withAttributes: infoAttributes)
            
            // Imzo
            let footerText = "Smart Parking © \(Calendar.current.component(.year, from: Date()))"
            let footerAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10.0),
                .paragraphStyle: paragraphStyle
            ]
            
            footerText.draw(in: CGRect(x: 50, y: pageHeight - 50, width: pageWidth - 100, height: 20), withAttributes: footerAttributes)
        }
        
        // PDF ni saqlash
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "smart_parking_receipt_\(reservationID).pdf"
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL)
            
            // PDF ni ulashish uchun
            let activityViewController = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                rootViewController.present(activityViewController, animated: true, completion: nil)
            }
        } catch {
            errorMessage = "PDF faylni saqlashda xatolik: \(error.localizedDescription)"
        }
    }
    
    private func viewTicket() {
        guard let reservation = reservation, let spot = spot, let vehicle = vehicle else {
            errorMessage = "Chipta uchun ma'lumotlar to'liq emas"
            return
        }
        
        // Ticket ni alohida ko'rsatish uchun funksionallik...
        // Bu yerda e-chipta ko'rish logikasi joylashtiriladi
        print("E-chipta ko'rsatilmoqda: \(reservationID)")
    }
}

struct DetailCard: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundColor(.black)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

struct PaymentSuccessView_Previews: PreviewProvider {
    static var previews: some View {
        PaymentSuccessView(reservationID: "reservation123")
    }
}
