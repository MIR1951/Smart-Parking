//
//  FavoriteView.swift
//  Smart Parking
//
//  Created by Kenjaboy Xajiyev on 04/05/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct FavoriteView: View {
    @StateObject private var viewModel = FavoriteViewModel()
    @State private var showRemoveAlert = false
    @State private var parkingToRemove: ParkingSpot? = nil
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                } else if viewModel.favorites.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "heart.slash")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .foregroundColor(.gray)
                        
                        Text("Sevimli parkovkalar yo'q")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Sizga yoqqan parkovkalarni sevimlilar ro'yxatiga qo'shing")
                            .font(.body)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        NavigationLink(destination: ExploreView()) {
                            Text("Parkovka izlash")
                                .fontWeight(.semibold)
                                .padding(.horizontal, 30)
                                .padding(.vertical, 12)
                                .background(Color.purple)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    .padding()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 15) {
                            ForEach(viewModel.favorites) { spot in
                                NavigationLink(destination: ParkingSpotDetailsView(spot: spot)) {
                                    FavoriteCard(spot: spot, onRemove: {
                                        // Tasdiqlovchi sheet ko'rsatish
                                        parkingToRemove = spot
                                        showRemoveAlert = true
                                    })
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal)
                    }
                    .refreshable {
                        viewModel.fetchFavorites()
                    }
                }
            }
            .navigationTitle("Sevimlilar")
        }
        .onAppear {
            viewModel.fetchFavorites()
            
            // NotificationCenter orqali refresh qilishni o'rnatish
            setupNotifications()
        }
        .onDisappear {
            // NotificationCenter dan chiqish
            NotificationCenter.default.removeObserver(self)
        }
        .sheet(isPresented: $showRemoveAlert) {
            if let parking = parkingToRemove {
                RemoveConfirmationView(
                    parking: parking,
                    onConfirm: {
                        viewModel.removeFromFavorites(spot: parking)
                        showRemoveAlert = false
                        parkingToRemove = nil
                    },
                    onCancel: {
                        showRemoveAlert = false
                        parkingToRemove = nil
                    }
                )
                .presentationDetents([.height(280)])
            }
        }
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("REFRESH_TAB"),
            object: nil,
            queue: .main
        ) { notification in
            if let userInfo = notification.userInfo,
               let tab = userInfo["tab"] as? Int,
               tab == 2 {
                viewModel.fetchFavorites()
            }
        }
    }
}

struct FavoriteCard: View {
    let spot: ParkingSpot
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 15) {
            // Rasm
            if let imageUrl = spot.images?.first, !imageUrl.isEmpty {
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 100, height: 100)
                        .cornerRadius(10)
                        .clipped()
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 100, height: 100)
                        .cornerRadius(10)
                }
            } else {
                Image(systemName: "car.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(15)
                    .frame(width: 100, height: 100)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
            }
            
            VStack(alignment: .leading, spacing: 5) {
                Text("Avtomobil parkovkasi")
                    .font(.caption)
                    .foregroundColor(.purple)
                
                Text(spot.name)
                    .font(.headline)
                    .lineLimit(1)
                
                HStack {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundColor(.gray)
                        .font(.caption)
                    
                    Text(spot.address)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
                
                Text("\(Int(spot.pricePerHour)) so'm/soat")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.purple)
                
                HStack {
                    HStack(spacing: 3) {
                        Image(systemName: "clock")
                            .foregroundColor(.purple)
                            .font(.caption)
                        
                        Text(spot.distance ?? "5km")
                            .font(.caption)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 3) {
                        Image(systemName: "car.fill")
                            .foregroundColor(.gray)
                            .font(.caption)
                        
                        Text("\(spot.spotsAvailable) joy")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            
            Spacer()
            
            VStack {
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
                
                Button(action: onRemove) {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                        .padding(8)
                        .background(Circle().stroke(Color.gray.opacity(0.3), lineWidth: 1))
                }
            }
        }
        .padding(10)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.gray.opacity(0.2), radius: 5)
    }
}

struct RemoveConfirmationView: View {
    let parking: ParkingSpot
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Sevimlilardan o'chirish?")
                .font(.headline)
                .padding(.top, 20)
            
            HStack(spacing: 15) {
                // Parking rasmi
                if let imageUrl = parking.images?.first, !imageUrl.isEmpty {
                    AsyncImage(url: URL(string: imageUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 80, height: 80)
                            .cornerRadius(10)
                            .clipped()
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 80, height: 80)
                            .cornerRadius(10)
                    }
                } else {
                    Image(systemName: "car.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(15)
                        .frame(width: 80, height: 80)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Avtomobil parkovkasi")
                            .font(.caption)
                            .foregroundColor(.purple)
                        
                        Spacer()
                        
                        if let rating = parking.rating {
                            HStack(spacing: 2) {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                    .font(.caption)
                                
                                Text(String(format: "%.1f", rating))
                                    .font(.caption)
                            }
                        }
                    }
                    
                    Text(parking.name)
                        .font(.headline)
                        .lineLimit(1)
                    
                    HStack {
                        Image(systemName: "mappin.and.ellipse")
                            .foregroundColor(.gray)
                            .font(.caption)
                        
                        Text(parking.address)
                            .font(.caption)
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                    
                    Text("\(Int(parking.pricePerHour)) so'm/soat")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.purple)
                }
            }
            .padding(.horizontal)
            .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 10) {
                Button(action: onCancel) {
                    Text("Bekor qilish")
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.gray.opacity(0.1))
                        .foregroundColor(.purple)
                        .cornerRadius(10)
                }
                
                Button(action: onConfirm) {
                    Text("Ha, o'chirish")
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .padding(.horizontal)
            
            Spacer()
        }
    }
}

class FavoriteViewModel: ObservableObject {
    @Published var favorites: [ParkingSpot] = []
    @Published var isLoading = false
    private let dbManager = DatabaseManager()
    
    func fetchFavorites() {
        guard let userID = Auth.auth().currentUser?.uid else {
            // Test ma'lumotlarini ko'rsatish
            createSampleData()
            return
        }
        
        isLoading = true
        
        dbManager.fetchFavorites(forUserID: userID) { [weak self] favorites, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Sevimlilarni olishda xatolik: \(error.localizedDescription)")
                self.isLoading = false
                return
            }
            
            guard let favorites = favorites, !favorites.isEmpty else {
                // Sevimlilar bo'sh bo'lsa
                DispatchQueue.main.async {
                    self.favorites = []
                    self.isLoading = false
                }
                return
            }
            
            // Har bir sevimli parkovka joyini olish
            var spotList: [ParkingSpot] = []
            let group = DispatchGroup()
            
            for favorite in favorites {
                group.enter()
                self.dbManager.fetchParkingSpot(withID: favorite.parkingSpotID) { spot, error in
                    if let spot = spot {
                        spotList.append(spot)
                    }
                    group.leave()
                }
            }
            
            group.notify(queue: .main) {
                self.favorites = spotList
                self.isLoading = false
            }
        }
    }
    
    func removeFromFavorites(spot: ParkingSpot) {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        isLoading = true
        
        // UI darhol yangilash
        DispatchQueue.main.async {
            self.favorites.removeAll { $0.id == spot.id }
        }
        
        // Firebase dan o'chirish
        dbManager.removeFromFavorites(userID: userID, parkingSpotID: spot.id) { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                print("Sevimlilardan o'chirishda xatolik: \(error.localizedDescription)")
                self.isLoading = false
                
                // Xatolik bo'lsa, qayta sevimlilarni olib kelamiz
                self.fetchFavorites()
                return
            }
            
            self.isLoading = false
            
            // Barcha viewlarga xabar berish
            NotificationCenter.default.post(name: NSNotification.Name("REFRESH_FAVORITES"), object: nil)
        }
    }
    
    // Test uchun ma'lumotlar
    func createSampleData() {
        DispatchQueue.main.async {
            self.isLoading = false
            let location1 = GeoPoint(latitude: 41.549667, longitude: 60.630861)
            let location2 = GeoPoint(latitude: 41.557123, longitude: 60.641234)
            
            let spot1 = ParkingSpot(
                id: "sample1",
                name: "Markaziy Parkovka",
                address: "Al-Xorazmiy ko'chasi, 17",
                pricePerHour: 5000,
                spotsAvailable: 15,
                distance: "1.2 km",
                location: location1,
                features: ["Qo'riqlanadigan", "24/7", "Soyabon"],
                rating: 4.5,
                reviewCount: 120,
                category: "Markaziy",
                description: "Markazdagi qulay joylashgan parkovka",
                operatedBy: "Premium Parking",
                images: ["parking1", "parking2"]
            )
            
            let spot2 = ParkingSpot(
                id: "sample2",
                name: "Yoshlik Parkovkasi",
                address: "Darital ko'chasi, 22",
                pricePerHour: 3000,
                spotsAvailable: 8,
                distance: "0.5 km",
                location: location2,
                features: ["Qo'riqlanadigan", "Kamera"],
                rating: 4.2,
                reviewCount: 85,
                category: "Ekonom",
                description: "Arzon narxlardagi parkovka",
                operatedBy: "City Parking",
                images: ["parking3", "parking4"]
            )
            
            self.favorites = [spot1, spot2]
        }
    }
}

struct FavoriteView_Previews: PreviewProvider {
    static var previews: some View {
        FavoriteView()
    }
}
