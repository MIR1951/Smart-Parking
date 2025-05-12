import SwiftUI
import MapKit
import FirebaseFirestore
import UIKit
import FirebaseAuth

struct ParkingSpotDetailsView: View {
    let spot: ParkingSpot
    @State private var selectedTab = "About"
    @State private var isFavorite = false
    @State private var showBookingView = false
    @Environment(\.dismiss) var dismiss
    @Environment(\.presentationMode) var presentationMode
    @State private var reviews: [ReviewItem] = []
    @State private var isLoading = true
    @State private var showShareSheet = false
    
    var body: some View {
        ZStack {
            Color.white.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
        ScrollView {
            VStack(alignment: .leading, spacing: 15) {
                        // Asosiy rasm qismi
                        ZStack(alignment: .top) {
                            // Asosiy rasm
                            if let imageUrl = spot.images?.first, !imageUrl.isEmpty {
                                AsyncImage(url: URL(string: imageUrl)) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(height: 250)
                                        .clipped()
                                } placeholder: {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(height: 250)
                                }
                            } else {
                                Image("parking1")
                                .resizable()
                                .scaledToFill()
                                .frame(height: 250)
                                .clipped()
                        }
                            
                            // Yuqoridagi tugmalar
                            HStack {
                                Button(action: {
                                    presentationMode.wrappedValue.dismiss()
                                }) {
                                    Image(systemName: "chevron.left")
                                        .foregroundColor(.black)
                                        .padding(12)
                                        .background(Circle().fill(Color.white))
                                        .shadow(color: Color.black.opacity(0.1), radius: 3)
                                }
                                
                                Spacer()
                                
                                Button(action: {
                                    showShareSheet = true
                                }) {
                                    Image(systemName: "square.and.arrow.up")
                                        .foregroundColor(.black)
                                        .padding(12)
                                        .background(Circle().fill(Color.white))
                                        .shadow(color: Color.black.opacity(0.1), radius: 3)
                                }
                                
                                Button(action: {
                                    isFavorite.toggle()
                                }) {
                                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                                        .foregroundColor(isFavorite ? .red : .black)
                                        .padding(12)
                                        .background(Circle().fill(Color.white))
                                        .shadow(color: Color.black.opacity(0.1), radius: 3)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top, 20)
                            
                            // Rasm thumbnaillar
                            VStack {
                                Spacer()
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 5) {
                                        if let images = spot.images {
                                            ForEach(0..<min(5, images.count), id: \.self) { index in
                                                if !images[index].isEmpty {
                                                    AsyncImage(url: URL(string: images[index])) { image in
                                                        image
                                                            .resizable()
                                                            .scaledToFill()
                                                            .frame(width: 60, height: 60)
                                                            .cornerRadius(8)
                                                    } placeholder: {
                                                        Rectangle()
                                                            .fill(Color.gray.opacity(0.2))
                                                            .frame(width: 60, height: 60)
                                                            .cornerRadius(8)
                                                    }
                                                } else {
                                                    Image("parking1")
                                                        .resizable()
                                                        .scaledToFill()
                                                        .frame(width: 60, height: 60)
                                                        .cornerRadius(8)
                                                }
                                            }
                                            
                                            if images.count > 5 {
                                                ZStack {
                                                    Rectangle()
                                                        .fill(Color.black.opacity(0.5))
                                                        .frame(width: 60, height: 60)
                                                        .cornerRadius(8)
                                                    
                                                    Text("+\(images.count - 5)")
                                                        .foregroundColor(.white)
                                                        .font(.system(size: 18, weight: .bold))
                                                }
                                            }
                                        } else {
                                            // Default image if no images available
                                            ForEach(0..<3, id: \.self) { _ in
                                                Image("parking1")
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 60, height: 60)
                                                    .cornerRadius(8)
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                    .padding(.bottom, 5)
                                }
                            }
                        }
                        
                        // Asosiy ma'lumotlar
                        VStack(alignment: .leading, spacing: 15) {
                            // Kategoriya va reyting
                            HStack {
                                Text(spot.category ?? "Avtomobil parkovkasi")
                                    .foregroundColor(.purple)
                                    .font(.headline)
                                
                                Spacer()
                                
                                if let rating = spot.rating {
                        HStack(spacing: 5) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                            
                            Text(String(format: "%.1f", rating))
                                            .fontWeight(.bold)
                                        
                                        if let reviewCount = spot.reviewCount {
                                            Text("(\(reviewCount) sharhlar)")
                                                .foregroundColor(.gray)
                                        }
                                    }
                                }
                            }
                            .padding(.top, 15)
                            
                            // Nom va manzil
                            HStack {
                                VStack(alignment: .leading) {
                                    // Nom
                    Text(spot.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    // Manzil
                        Text(spot.address)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    
                                Spacer()
                                
                                // Yo'nalish tugmasi
                                Button(action: {}) {
                                    Image(systemName: "paperplane.fill")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                        .padding(12)
                                        .background(Circle().fill(Color.purple))
                                }
                            }
                            
                            // Tab bar
                            HStack {
                                TabButton(text: "Haqida", isSelected: selectedTab == "About") {
                                    selectedTab = "About"
                                }
                                
                                TabButton(text: "Galereya", isSelected: selectedTab == "Gallery") {
                                    selectedTab = "Gallery"
                                }
                                
                                TabButton(text: "Sharhlar", isSelected: selectedTab == "Review") {
                                    selectedTab = "Review"
                                }
                            }
                            .overlay(
                        VStack {
                                    Spacer()
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(height: 1)
                                }
                            )
                            .overlay(
                                GeometryReader { geometry in
                                    Rectangle()
                                        .fill(Color.purple)
                                        .frame(width: geometry.size.width / 3, height: 3)
                                        .offset(x: CGFloat(
                                            selectedTab == "About" ? 0 :
                                            selectedTab == "Gallery" ? geometry.size.width / 3 :
                                            2 * geometry.size.width / 3
                                        ))
                                }
                                .frame(height: 3)
                                .offset(y: 20),
                                alignment: .bottom
                            )
                            
                            // Tab tarkibi
                            if selectedTab == "About" {
                                AboutTabContent(spot: spot)
                            } else if selectedTab == "Gallery" {
                                GalleryTabContent(images: spot.images ?? [])
                            } else {
                                ReviewTabContent(spotID: spot.id, reviews: $reviews, isLoading: $isLoading)
                                    .onAppear {
                                        fetchReviews(for: spot.id)
                                    }
                            }
                        }
                        .padding(.horizontal)
                        
                        Spacer(minLength: 80)
                    }
                }
                
                // Pastki qism
                        VStack {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Umumiy narx")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Text("\(Int(spot.pricePerHour)) so'm/soat")
                                .font(.headline)
                                .foregroundColor(.purple)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            showBookingView = true
                        }) {
                            Text("Joy band qilish")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 40)
                                .padding(.vertical, 12)
                                .background(Color.purple)
                                .cornerRadius(25)
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: -5)
                }
            }
        }
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $showBookingView) {
            BookingTimeSelectionView(spot: spot)
        }
        .sheet(isPresented: $showShareSheet) {
            ActivityView(activityItems: [spot.name, spot.address])
        }
        .onAppear {
            // Check if the spot is in favorites when view appears
            checkFavoriteStatus()
        }
    }
    
    private func checkFavoriteStatus() {
        // Firebase'dan sevimlilarni tekshirish
        let db = Firestore.firestore()
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        db.collection("favorites")
            .whereField("userID", isEqualTo: userID)
            .whereField("parkingSpotID", isEqualTo: spot.id)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error checking favorite status: \(error.localizedDescription)")
                    return
                }
                
                if let snapshot = snapshot, !snapshot.documents.isEmpty {
                    self.isFavorite = true
                }
            }
    }
    
    private func fetchReviews(for spotID: String) {
        isLoading = true
        
        let db = Firestore.firestore()
        db.collection("reviews")
            .whereField("spotId", isEqualTo: spotID)
            .order(by: "date", descending: true)
            .limit(to: 10)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching reviews: \(error.localizedDescription)")
                    isLoading = false
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    isLoading = false
                    return
                }
                
                self.reviews = documents.compactMap { document in
                    let data = document.data()
                    
                    guard let id = document.documentID as String?,
                          let userId = data["userId"] as? String,
                          let spotId = data["spotId"] as? String,
                          let rating = data["rating"] as? Double,
                          let timestamp = data["date"] as? Timestamp else {
                        return nil
                    }
                    
                    let comment = data["comment"] as? String
                    let date = timestamp.dateValue()
                    
                    return ReviewItem(
                        id: id,
                        userId: userId,
                        spotId: spotId,
                        rating: rating,
                        comment: comment,
                        date: date
                    )
                }
                
                isLoading = false
            }
    }
}

// Tab tugmasi
struct TabButton: View {
    let text: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .purple : .gray)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
        }
    }
}

// About tab
struct AboutTabContent: View {
    let spot: ParkingSpot
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            // Qo'shimcha ma'lumotlar
            HStack(spacing: 40) {
                HStack(spacing: 5) {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.purple)
                        .font(.subheadline)
                    Text("\(spot.distance) uzoqlikda")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    
                HStack(spacing: 5) {
                    Image(systemName: "car.fill")
                        .foregroundColor(.purple)
                        .font(.subheadline)
                    Text("\(spot.spotsAvailable) bo'sh joy")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
                        .padding(.top, 10)
                    
            // Tavsif
            Text("Tavsif")
                .font(.headline)
                .padding(.top, 5)
            
            Text(spot.description ?? "Tavsif mavjud emas")
                .font(.subheadline)
                .foregroundColor(.gray)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(3)
            
            if (spot.description?.count ?? 0) > 100 {
                Button(action: {}) {
                    Text("Ko'proq o'qish")
                        .foregroundColor(.purple)
                }
            }
            
            // Operator
            Text("Operatorlar")
                            .font(.headline)
                            .padding(.top, 10)
                        
                            HStack {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(String((spot.operatedBy?.first ?? "J").uppercased()))
                            .foregroundColor(.gray)
                    )
                
                Text(spot.operatedBy ?? "John Doe")
                                    .font(.subheadline)
                                
                                Spacer()
                                
                Button(action: {}) {
                    Image(systemName: "bubble.left.fill")
                        .foregroundColor(.purple)
                        .padding(8)
                        .background(Color.purple.opacity(0.2))
                        .cornerRadius(8)
                }
                
                Button(action: {}) {
                    Image(systemName: "phone.fill")
                                    .foregroundColor(.purple)
                        .padding(8)
                        .background(Color.purple.opacity(0.2))
                        .cornerRadius(8)
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 20)
    }
}

// Gallery tab
struct GalleryTabContent: View {
    let images: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Galereya (\(images.count))")
                    .font(.headline)
                                
                                Spacer()
                                
                Button(action: {}) {
                    HStack {
                        Image(systemName: "plus")
                        Text("rasm qo'shish")
                            .foregroundColor(.purple)
                    }
                }
            }
            .padding(.top, 10)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 10) {
                ForEach(images.indices, id: \.self) { index in
                    if !images[index].isEmpty {
                        AsyncImage(url: URL(string: images[index])) { image in
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(height: 120)
                                .cornerRadius(12)
                                .clipped()
                        } placeholder: {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 120)
                                .cornerRadius(12)
                        }
                    } else {
                        Image("parking1")
                            .resizable()
                            .scaledToFill()
                            .frame(height: 120)
                        .cornerRadius(12)
                            .clipped()
                    }
                }
            }
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.bottom, 20)
    }
}

// Review tab
struct ReviewTabContent: View {
    let spotID: String
    @Binding var reviews: [ReviewItem]
    @Binding var isLoading: Bool
    @State private var searchText = ""
    @State private var showingAddReview = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
                    HStack {
                Text("Sharhlar")
                            .font(.headline)
                        
                        Spacer()
                        
                Button(action: {
                    showingAddReview = true
                }) {
                    HStack {
                        Image(systemName: "pencil")
                        Text("sharh qo'shish")
                            .foregroundColor(.purple)
                    }
                }
            }
            .padding(.top, 10)
            
            // Qidiruv
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Sharhlarda qidirish", text: $searchText)
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color.gray.opacity(0.2))
            .cornerRadius(20)
            
            // Filter tugmalari
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    HStack {
                        Image(systemName: "line.3.horizontal.decrease")
                        Text("Filtr")
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(20)
                    
                    Text("Tasdiqlangan")
                        .padding(.horizontal, 15)
                        .padding(.vertical, 8)
                        .background(Color.purple)
                            .foregroundColor(.white)
                        .cornerRadius(20)
                    
                    Text("So'nggi")
                        .padding(.horizontal, 15)
                        .padding(.vertical, 8)
                            .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(20)
                    
                    Text("Rasmli")
                        .padding(.horizontal, 15)
                        .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(20)
                }
            }
            
            if isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .padding(.top, 20)
            } else if reviews.isEmpty {
                VStack(spacing: 15) {
                    Image(systemName: "star")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                    
                    Text("Hali sharhlar yo'q")
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 30)
            } else {
                // Izohlar ro'yxati
                ForEach(reviews) { review in
                    ReviewRow(review: review)
                    .padding(.top, 10)
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 20)
        .sheet(isPresented: $showingAddReview) {
            Text("Add Review")
            // AddReviewView(spotID: spotID)
        }
    }
}

struct ReviewRow: View {
    let review: ReviewItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                // Foydalanuvchi rasmi
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text("D")
                            .foregroundColor(.gray)
                    )
                
                VStack(alignment: .leading) {
                    HStack {
                        Text("Dale Thiel")
                            .font(.headline)
                        
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.purple)
                            .font(.caption)
                    }
                    
                    Text("\(timeAgo(date: review.date))")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
            }
            
            // Reyting
            HStack {
                ForEach(1...5, id: \.self) { i in
                    Image(systemName: i <= Int(review.rating) ? "star.fill" : "star")
                        .foregroundColor(.yellow)
                        .font(.caption)
                }
            }
            
            // Izoh
            if let comment = review.comment {
                Text(comment)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // Vaqtni chiroyli formatlash
    private func timeAgo(date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.month, .day, .hour, .minute], from: date, to: now)
        
        if let month = components.month, month > 0 {
            return "\(month) oy oldin"
        } else if let day = components.day, day > 0 {
            return "\(day) kun oldin"
        } else if let hour = components.hour, hour > 0 {
            return "\(hour) soat oldin"
        } else if let minute = components.minute, minute > 0 {
            return "\(minute) daqiqa oldin"
        } else {
            return "Hozirgina"
        }
    }
}

// ReviewItem modeli
struct ReviewItem: Identifiable {
    let id: String
    let userId: String
    let spotId: String
    let rating: Double
    let comment: String?
    let date: Date
}

// Share functionality
struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
 
