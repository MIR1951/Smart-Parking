//
//  ExploreView.swift
//  Smart Parking
//
//  Created by Kenjaboy Xajiyev on 04/05/25.
//

import SwiftUI
import MapKit
import FirebaseFirestore
import FirebaseAuth

struct ExploreView: View {
    @StateObject private var viewModel = ExploreViewModel()
    @State private var searchText = ""
    @State private var showFilter = false
    @State private var selectedParkingSpot: ParkingSpot?
    @State private var navigateToDetails = false
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                // Xarita
                Map(coordinateRegion: $viewModel.region, annotationItems: viewModel.parkingSpots) { spot in
                    MapAnnotation(coordinate: CLLocationCoordinate2D(latitude: spot.location!.latitude, longitude: spot.location!.longitude)) {
                        Button(action: {
                            viewModel.selectedParking = spot
                            viewModel.showDetails = true
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.purple)
                                    .frame(width: 20, height: 20)
                                
                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
                                    .frame(width: 20, height: 20)
                            }
                        }
                    }
                }
                .ignoresSafeArea()
                
                // Qidiruv paneli
                VStack {
                    HStack {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                            
                            TextField("Parkovka qidirish", text: $searchText)
                                .onChange(of: searchText) { newValue in
                                    viewModel.searchParkingSpots(query: newValue)
                                }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(radius: 2)
                        
                        Button(action: {
                            showFilter = true
                        }) {
                            Image(systemName: "slider.horizontal.3")
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.purple)
                                .cornerRadius(10)
                        }
                    }
                    .padding()
                    
                    // Joylashuv tugmasi
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button(action: {
                                viewModel.centerOnUserLocation()
                            }) {
                                Image(systemName: "location.fill")
                                    .foregroundColor(.purple)
                                    .padding(12)
                                    .background(Color.white)
                                    .clipShape(Circle())
                                    .shadow(radius: 2)
                            }
                            .padding(.trailing, 20)
                            .padding(.bottom, viewModel.showDetails ? 240 : 20)
                        }
                    }
                    
                    Spacer()
                    
                    // Mashhur parkovkalar
                    if !viewModel.parkingSpots.isEmpty && !viewModel.showDetails {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 30) {
                                ForEach(viewModel.parkingSpots.filter { $0.rating ?? 0 >= 4.5 }) { spot in
                                    ExplorePopularCard(spot: spot, isFavorite: viewModel.favoriteSpots.contains(spot.id))
                                        .onTapGesture {
                                            viewModel.selectedParking = spot
                                            viewModel.showDetails = true
                                        }
                                        .environmentObject(viewModel)
                                }
                                Spacer()
                                    .frame(width: 20)
                            }
                        }
                        
                        .frame(height: 220)
                        .padding(.bottom, 30)
                    }
                    
                    // Parkovka kartlari
                    if viewModel.showDetails, let parking = viewModel.selectedParking {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 30) {
                                // Tanlangan parking kartasi
                                ExploreSelectedCard(parking: parking, isFavorite: viewModel.favoriteSpots.contains(parking.id))
                                    .padding(.leading)
                                    .onTapGesture {
                                        selectedParkingSpot = parking
                                        navigateToDetails = true
                                    }
                                    .environmentObject(viewModel)
                                
                                // Boshqa parkovkalar
                                ForEach(viewModel.parkingSpots.filter { $0.id != parking.id }) { otherParking in
                                    ExplorePopularCard(spot: otherParking, isFavorite: viewModel.favoriteSpots.contains(otherParking.id))
                                        .onTapGesture {
                                            viewModel.selectedParking = otherParking
                                        }
                                        .environmentObject(viewModel)
                                }
                                
                                Spacer()
                                    .frame(width: 20)
                            }
                        }
                        .frame(height: 220)
                        .padding(.bottom, 30)
                    }
                }
                
                // Pull-to-refresh (moslashtirilgan) - xaritada
                VStack {
                    RefreshControl(coordinateSpace: .named("mapRefresh"), onRefresh: {
                        viewModel.loadData()
                    })
                    Spacer()
                }
                .coordinateSpace(name: "mapRefresh")
            }
            .onAppear {
                viewModel.loadData()
                
                // NotificationCenter orqali refresh qilishni o'rnatish
                setupNotifications()
            }
            .onDisappear {
                // NotificationCenter dan chiqish
                NotificationCenter.default.removeObserver(self)
            }
            .sheet(isPresented: $showFilter) {
                FilterView(viewModel: viewModel)
                    .presentationDetents([.medium])
            }
           
        }
        .fullScreenCover(item: $selectedParkingSpot, content: { spot in
            ParkingSpotDetailsView(spot:spot)
        })
        .navigationViewStyle(.stack)
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("REFRESH_TAB"),
            object: nil,
            queue: .main
        ) { notification in
            if let userInfo = notification.userInfo,
               let tab = userInfo["tab"] as? Int,
               tab == 1 {
                viewModel.loadData()
            }
        }
        
        // ParkingSpotDetails ga o'tish uchun notifikatsiya
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("OPEN_PARKING_DETAILS"),
            object: nil,
            queue: .main
        ) { notification in
            if let userInfo = notification.userInfo,
               let spot = userInfo["parkingSpot"] as? ParkingSpot {
                selectedParkingSpot = spot
                navigateToDetails = true
            }
        }
    }
}

struct ExplorePopularCard: View {
    let spot: ParkingSpot
    let isFavorite: Bool
    @EnvironmentObject var viewModel: ExploreViewModel
    
    var body: some View {
        VStack(alignment: .leading) {
            // Rasm
            ZStack(alignment: .topTrailing) {
                if let imageUrl = spot.images?.first, !imageUrl.isEmpty {
                    AsyncImage(url: URL(string: imageUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 200, height: 120)
                            .cornerRadius(10)
                            .clipped()
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 200, height: 120)
                            .cornerRadius(10)
                    }
                } else {
                    Image(systemName: "car.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(30)
                        .frame(width: 200, height: 120)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                }
                
                // Rating va sevimli tugmasi
                HStack(spacing: 5) {
                    if let rating = spot.rating {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                            
                            Text(String(format: "%.1f", rating))
                                .font(.caption)
                                .foregroundColor(.black.opacity(0.6))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.6))
                        .cornerRadius(15)
                    }
                    Spacer()
                    Button(action: {
                        viewModel.toggleFavorite(spot)
                    }) {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .padding(8)
                            .background(Color.white)
                            .foregroundColor(isFavorite ? .red : .gray)
                            .clipShape(Circle())
                    }
                }
                .padding(8)
            }
            
            // Parkovka tipi va nomi
            Text("Avtomobil parkovkasi")
                .font(.caption)
                .foregroundColor(.purple)
            
            Text(spot.name)
                .font(.headline)
                .lineLimit(1)
            
            // Narx
            Text("\(Int(spot.pricePerHour)) so'm/soat")
                .font(.body)
                .fontWeight(.bold)
                .foregroundColor(.purple)
            
            // Vaqt va bo'sh joylar
            HStack {
                HStack(spacing: 5) {
                    Image(systemName: "clock")
                        .foregroundColor(.purple)
                        .font(.caption)
                    
                    Text("\(spot.distance) daqiqa")
                        .font(.caption)
                }
                
                Spacer()
                
                HStack(spacing: 5) {
                    Image(systemName: "car.fill")
                        .foregroundColor(.gray)
                        .font(.caption)
                    
                    Text("\(spot.spotsAvailable) joy")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(10)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.gray.opacity(0.2), radius: 5)
        .frame(width: 200)
    }
}

struct ExploreSelectedCard: View {
    let parking: ParkingSpot
    let isFavorite: Bool
    @EnvironmentObject var viewModel: ExploreViewModel
    
    var body: some View {
        VStack(alignment: .leading) {
            // Rasm
            ZStack(alignment: .topTrailing) {
                if let imageUrl = parking.images?.first, !imageUrl.isEmpty {
                    AsyncImage(url: URL(string: imageUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 200, height: 120)
                            .cornerRadius(10)
                            .clipped()
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 200, height: 120)
                            .cornerRadius(10)
                    }
                } else {
                    Image(systemName: "car.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(30)
                        .frame(width: 200, height: 120)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                }
                
                // Rating va sevimli tugmasi
                HStack(spacing: 5) {
                    if let rating = parking.rating {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                            
                            Text(String(format: "%.1f", rating))
                                .font(.caption)
                                .foregroundColor(.black.opacity(0.6))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.6))
                        .cornerRadius(15)
                    }
                    Spacer()
                    Button(action: {
                        viewModel.toggleFavorite(parking)
                    }) {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .padding(8)
                            .background(Color.white)
                            .foregroundColor(isFavorite ? .red : .gray)
                            .clipShape(Circle())
                    }
                }
                .padding(8)
            }
            
            // Parkovka tipi va nomi
            Text("Avtomobil parkovkasi")
                .font(.caption)
                .foregroundColor(.purple)
            
            Text(parking.name)
                .font(.headline)
                .lineLimit(1)
            
            // Narx
            Text("\(Int(parking.pricePerHour)) so'm/soat")
                .font(.body)
                .fontWeight(.bold)
                .foregroundColor(.purple)
            
            // Vaqt va bo'sh joylar
            HStack {
                HStack(spacing: 5) {
                    Image(systemName: "clock")
                        .foregroundColor(.purple)
                        .font(.caption)
                    
                    Text("\(parking.distance) ")
                        .font(.caption)
                }
                
                Spacer()
                
                HStack(spacing: 5) {
                    Image(systemName: "car.fill")
                        .foregroundColor(.gray)
                        .font(.caption)
                    
                    Text("\(parking.spotsAvailable) joy")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(10)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.gray.opacity(0.2), radius: 5)
        .frame(width: 200)
    }
}

struct FilterView: View {
    @ObservedObject var viewModel: ExploreViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Narx oralig'i")) {
                    HStack {
                        Text("Minimal: \(Int(viewModel.minPrice)) so'm")
                        Spacer()
                        Text("Maksimal: \(Int(viewModel.maxPrice)) so'm")
                    }
                    
                    HStack {
                        Slider(value: $viewModel.minPrice, in: 0...50000, step: 1000)
                            .accentColor(.purple)
                    }
                    
                    HStack {
                        Slider(value: $viewModel.maxPrice, in: 0...100000, step: 1000)
                            .accentColor(.purple)
                    }
                }
                
                Section(header: Text("Xususiyatlar")) {
                    ForEach(viewModel.features, id: \.self) { feature in
                        Button(action: {
                            if viewModel.selectedFeatures.contains(feature) {
                                viewModel.selectedFeatures.remove(feature)
                            } else {
                                viewModel.selectedFeatures.insert(feature)
                            }
                        }) {
                            HStack {
                                Text(feature)
                                    .foregroundColor(.primary)
                                Spacer()
                                if viewModel.selectedFeatures.contains(feature) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.purple)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Filtrlar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Bekor qilish") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Qo'llash") {
                        viewModel.applyFilters()
                        dismiss()
                    }
                    .foregroundColor(.purple)
                }
            }
        }
    }
}

class ExploreViewModel: ObservableObject {
    @Published var parkingSpots: [ParkingSpot] = []
    @Published var filteredParkingSpots: [ParkingSpot] = []
    @Published var selectedParking: ParkingSpot? = nil
    @Published var showDetails = false
    @Published var favoriteSpots: Set<String> = []
    private let dbManager = DatabaseManager()
    
    // Filtr uchun
    @Published var minPrice: Double = 0
    @Published var maxPrice: Double = 50000
    @Published var selectedFeatures: Set<String> = []
    @Published var features: [String] = ["24/7", "Soyabon", "Qo'riqlanadigan", "Video nazorat", "Tekin"]
    
    // Xarita uchun
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 41.549667, longitude: 60.630861),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    private let locationManager = CLLocationManager()
    
    init() {
        setupLocationManager()
    }
    
    func setupLocationManager() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func loadData() {
        fetchParkingSpots()
        fetchFavorites()
    }
    
    func centerOnUserLocation() {
        if let location = locationManager.location?.coordinate {
            region = MKCoordinateRegion(
                center: location,
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            )
        }
    }
    
    func fetchParkingSpots() {
        dbManager.fetchParkingSpots { [weak self] spots, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Xatolik: \(error.localizedDescription)")
               
                return
            }
            
            if let spots = spots, !spots.isEmpty {
                DispatchQueue.main.async {
                    self.parkingSpots = spots
                    self.filteredParkingSpots = spots
                }
            } else {
              
            }
        }
    }
    
    func fetchFavorites() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        dbManager.fetchFavorites(forUserID: userId) { [weak self] favorites, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Sevimlilari olishda xatolik: \(error.localizedDescription)")
                return
            }
            
            guard let favorites = favorites else { return }
            
            DispatchQueue.main.async {
                // Favoritlarni ID lari bilan saqlash
                self.favoriteSpots = Set(favorites.map { $0.parkingSpotID })
            }
        }
    }
    
    func toggleFavorite(_ parking: ParkingSpot) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // Avval UI ni yangilab olish (tezroq javob berish uchun)
        let isCurrentlyFavorite = favoriteSpots.contains(parking.id)
        
        if isCurrentlyFavorite {
            // Agar hozir sevimlilarda bo'lsa, o'chiramiz (UI ni darhol yangilash)
            favoriteSpots.remove(parking.id)
            
            // Keyin database'dan o'chiramiz
            dbManager.removeFromFavorites(userID: userId, parkingSpotID: parking.id) { [weak self] error in
                if let error = error {
                    print("Sevimlilardan o'chirishda xatolik: \(error.localizedDescription)")
                    // Xatolik yuz bergan bo'lsa, UI ni oldingi holatiga qaytaramiz
                    DispatchQueue.main.async {
                        self?.favoriteSpots.insert(parking.id)
                    }
                    return
                }
                
                // Barcha viewlarga xabar berish
                NotificationCenter.default.post(name: NSNotification.Name("REFRESH_FAVORITES"), object: nil)
            }
        } else {
            // Agar hozir sevimlilarda bo'lmasa, qo'shamiz (UI ni darhol yangilash)
            favoriteSpots.insert(parking.id)
            
            // Keyin database'ga qo'shamiz
            dbManager.addToFavorites(userID: userId, parkingSpotID: parking.id) { [weak self] error in
                if let error = error {
                    print("Sevimlilarga qo'shishda xatolik: \(error.localizedDescription)")
                    // Xatolik yuz bergan bo'lsa, UI ni oldingi holatiga qaytaramiz
                    DispatchQueue.main.async {
                        self?.favoriteSpots.remove(parking.id)
                    }
                    return
                }
                
                // Barcha viewlarga xabar berish
                NotificationCenter.default.post(name: NSNotification.Name("REFRESH_FAVORITES"), object: nil)
            }
        }
    }
    
    func searchParkingSpots(query: String) {
        if query.isEmpty {
            filteredParkingSpots = parkingSpots
            return
        }
        
        filteredParkingSpots = parkingSpots.filter { spot in
            return spot.name.lowercased().contains(query.lowercased()) ||
                  spot.address.lowercased().contains(query.lowercased())
        }
    }
    
    func applyFilters() {
        filteredParkingSpots = parkingSpots.filter { spot in
            let priceMatches = spot.pricePerHour >= minPrice && spot.pricePerHour <= maxPrice
            
            let featuresMatch: Bool
            if selectedFeatures.isEmpty {
                featuresMatch = true
            } else {
                if let spotFeatures = spot.features {
                    let spotFeatureSet = Set(spotFeatures)
                    featuresMatch = !selectedFeatures.isDisjoint(with: spotFeatureSet)
                } else {
                    featuresMatch = false
                }
            }
            
            return priceMatches && featuresMatch
        }
    }
    
    func openParkingDetails(_ parking: ParkingSpot) {
        NotificationCenter.default.post(
            name: NSNotification.Name("OPEN_PARKING_DETAILS"),
            object: nil,
            userInfo: ["parkingSpot": parking]
        )
    }
    
    }

struct ExploreView_Previews: PreviewProvider {
    static var previews: some View {
        ExploreView()
    }
}



