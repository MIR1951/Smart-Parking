import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var searchText = ""
    @State private var selectedLocation = "Urganch, O'zbekiston"
    @State private var showLocationPicker = false
    @State private var showNotifications = false
    @State private var selectedSpot: ParkingSpot?
    @State private var showSpotDetails = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.white.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Joylashuv va bildirishnomalar
                    VStack{
                        HStack {
                            Button(action: {
                                showLocationPicker = true
                            }) {
                                VStack(alignment: .leading) {
                                    Text("Joylashuv")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                    
                                    HStack {
                                        Image(systemName: "location.fill")
                                            .font(.caption)
                                            .foregroundColor(.white)
                                        
                                        Text(selectedLocation)
                                            .font(.subheadline)
                                            .foregroundColor(.white)
                                        
                                        Image(systemName: "chevron.down")
                                            .font(.caption)
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                showNotifications = true
                            }) {
                                Image(systemName: "bell")
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(Circle().stroke(Color.white.opacity(0.5), lineWidth: 1))
                            }
                        }
                        .padding()
                        .background(Color.purple)
                        
                        // Qidiruv qutisi
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                                .padding(.leading, 10)
                            
                            TextField("Parkovka qidirish", text: $searchText)
                                .padding(.vertical, 10)
                            
                            Button(action: {
                                // Filtr ko'rsatish
                            }) {
                                Image(systemName: "slider.horizontal.3")
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(Color.purple)
                                    .cornerRadius(8)
                            }
                        }
                        .padding(.vertical, 5)
                        .padding(.horizontal, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.white)
                                .shadow(color: Color.gray.opacity(0.2), radius: 2)
                        )
                        .padding(.horizontal)
                        .padding(.top, -15)
                    }
                    .padding(.bottom)
                    .background(Color.purple)
                    
                    ScrollView(showsIndicators: false) {
                        // Pull-to-refresh
                        RefreshControl(coordinateSpace: .named("pullToRefresh"), onRefresh: {
                            viewModel.fetchData()
                        })
                        
                        VStack(alignment: .leading, spacing: 15) {
                            // Mashhur parkovkalar
                            HStack {
                                Text("Mashhur parkovkalar")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                
                                Spacer()
                                
                                Button("Hammasi") {
                                    // Hamma mashhur parkovkalarni ko'rsatish
                                }
                                .font(.subheadline)
                                .foregroundColor(.purple)
                            }
                            .padding(.horizontal)
                            .padding(.top, 15)
                            
                            // Mashhur parkovkalar ro'yxati
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 30) {
                                    ForEach(viewModel.popularParkingSpots) { spot in
                                        PopularParkingCard(spot: spot, isFavorite: viewModel.isSpotFavorite(spot))
                                            .onTapGesture {
                                                selectedSpot = spot
                                                showSpotDetails = true
                                            }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .padding()
                            }
                            .padding(.bottom, 10)
                            
                            // Yaqin atrofdagi parkovkalar
                            HStack {
                                Text("Yaqin atrofdagi parkovkalar")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                
                                Spacer()
                                
                                Button("Hammasi") {
                                    // Hamma yaqin parkovkalarni ko'rsatish
                                }
                                .font(.subheadline)
                                .foregroundColor(.purple)
                            }
                            .padding(.horizontal)
                            .padding(.top, 5)
                            
                            // Yaqin atrofdagi parkovkalar ro'yxati
                            VStack(spacing: 15) {
                                ForEach(viewModel.nearbyParkingSpots) { spot in
                                    NearbyParkingCard(spot: spot, isFavorite: viewModel.isSpotFavorite(spot))
                                        .onTapGesture {
                                            selectedSpot = spot
                                            showSpotDetails = true
                                        }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .coordinateSpace(name: "pullToRefresh")
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                viewModel.fetchData()
                setupNotifications()
            }
            .onDisappear {
                NotificationCenter.default.removeObserver(self)
            }
            .sheet(isPresented: $showLocationPicker) {
                LocationPickerView(selectedLocation: $selectedLocation)
            }
        }
        .fullScreenCover(item: $selectedSpot, content: { spot in
            ParkingSpotDetailsView(spot: spot)
        })
        .fullScreenCover(item: $selectedSpot, content: { spot in
            NearbyParkingCard(spot: spot, isFavorite: viewModel.isSpotFavorite(spot))
        })
        .navigationViewStyle(.stack)
        .environmentObject(viewModel)
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("REFRESH_TAB"),
            object: nil,
            queue: .main
        ) { notification in
            if let userInfo = notification.userInfo,
               let tab = userInfo["tab"] as? Int,
               tab == 0 {
                viewModel.fetchData()
            }
        }
    }
}

struct PopularParkingCard: View {
    let spot: ParkingSpot
    let isFavorite: Bool
    @EnvironmentObject var viewModel: HomeViewModel
    
    var body: some View {
        VStack(alignment: .leading) {
            // Rasm
            ZStack(alignment: .topTrailing) {
                if let imageUrl = spot.images?.first, !imageUrl.isEmpty {
                    StorageImageView(
                        path: imageUrl,
                        placeholder: Image(systemName: "car.fill"),
                        contentMode: .fill
                    )
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 200, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    Image(systemName: "car.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(30)
                        .frame(width: 200, height: 120)
                       
                        .foregroundColor(.gray)
                        .background(Color.gray.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
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
                    
                    Text("\(spot.distance)")
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

struct NearbyParkingCard: View {
    let spot: ParkingSpot
    let isFavorite: Bool
    @EnvironmentObject var viewModel: HomeViewModel
    
    var body: some View {
        HStack(spacing: 15) {
            // Rasm
            ZStack(alignment: .topTrailing) {
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
            
            // Ma'lumotlar
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Avtomobil parkovkasi")
                        .font(.caption)
                        .foregroundColor(.purple)
                    
                    Spacer()
                    
                    if let rating = spot.rating {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                            
                            Text(String(format: "%.1f", rating))
                                .font(.caption)
                                .foregroundStyle(.black.opacity(0.6))
                        }
                    }
                }
                
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
                    .font(.body)
                    .fontWeight(.bold)
                    .foregroundColor(.purple)
            }
        }
        .padding(10)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.gray.opacity(0.2), radius: 5)
    }
}

struct LocationPickerView: View {
    @Binding var selectedLocation: String
    @Environment(\.dismiss) var dismiss
    
    let locations = [
        "Urganch, O'zbekiston",
        "Toshkent, O'zbekiston",
        "Samarqand, O'zbekiston",
        "Buxoro, O'zbekiston",
        "Namangan, O'zbekiston",
        "Andijon, O'zbekiston"
    ]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(locations, id: \.self) { location in
                    Button(action: {
                        selectedLocation = location
                        dismiss()
                    }) {
                        HStack {
                            Text(location)
                            Spacer()
                            if location == selectedLocation {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.purple)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Joylashuv tanlang")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Yopish") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// RefreshControl komponenti
struct RefreshControl: View {
    var coordinateSpace: CoordinateSpace
    var onRefresh: () -> Void
    
    @State private var isRefreshing = false
    
    var body: some View {
        GeometryReader { geo in
            if geo.frame(in: coordinateSpace).midY > 50 {
                Spacer()
                    .onAppear {
                        if !isRefreshing {
                            isRefreshing = true
                            onRefresh()
                        }
                    }
            } else if geo.frame(in: coordinateSpace).maxY < 1 {
                Spacer()
                    .onAppear {
                        isRefreshing = false
                    }
            }
            
            HStack {
                Spacer()
                if isRefreshing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                }
                Spacer()
            }
            .padding(.top, -50)
        }
        .padding(.top, -50)
        .frame(height: 0)
    }
}

class HomeViewModel: ObservableObject {
    @Published var popularParkingSpots: [ParkingSpot] = []
    @Published var nearbyParkingSpots: [ParkingSpot] = []
    @Published var favoriteSpots: Set<String> = []
    
    private let dbManager = DatabaseManager()
    
    func fetchData() {
        fetchParkingSpots()
        fetchFavorites()
    }
    
    func fetchParkingSpots() {
        dbManager.fetchParkingSpots { [weak self] spots, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Xatolik: \(error.localizedDescription)")
                return
            }
            
            guard let spots = spots, !spots.isEmpty else {
                print("Parkovka joylari topilmadi")
                return
            }
            
            DispatchQueue.main.async {
                // Mashhur parkovka joylarini rating bo'yicha saralash
                self.popularParkingSpots = spots
                    .filter { $0.rating != nil }
                    .sorted { ($0.rating ?? 0) > ($1.rating ?? 0) }
                
                // Yaqin joylashgan parkovka joylarini masofa bo'yicha saralash
                self.nearbyParkingSpots = spots
                    .sorted { Int($0.distance) ?? 100 < Int($1.distance) ?? 100 }
            }
        }
    }
    
    func fetchFavorites() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        dbManager.fetchFavorites(forUserID: userId) { [weak self] favorites, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Sevimlilarni olishda xatolik: \(error.localizedDescription)")
                return
            }
            
            guard let favorites = favorites else { return }
            
            DispatchQueue.main.async {
                // Favoritlarni ID lari bilan saqlash
                self.favoriteSpots = Set(favorites.map { $0.parkingSpotID })
            }
        }
    }
    
    func isSpotFavorite(_ spot: ParkingSpot) -> Bool {
        return favoriteSpots.contains(spot.id)
    }
    
    func toggleFavorite(_ spot: ParkingSpot) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // Avval UI ni yangilab olish (tezroq javob berish uchun)
        let isCurrentlyFavorite = favoriteSpots.contains(spot.id)
        
        if isCurrentlyFavorite {
            // Agar hozir sevimlilarda bo'lsa, o'chiramiz (UI ni darhol yangilash)
            favoriteSpots.remove(spot.id)
            
            // Keyin database'dan o'chiramiz
            dbManager.removeFromFavorites(userID: userId, parkingSpotID: spot.id) { [weak self] error in
                if let error = error {
                    print("Sevimlilardan o'chirishda xatolik: \(error.localizedDescription)")
                    // Xatolik yuz bergan bo'lsa, UI ni oldingi holatiga qaytaramiz
                    DispatchQueue.main.async {
                        self?.favoriteSpots.insert(spot.id)
                    }
                    return
                }
                
                // Barcha viewlarga xabar berish
                NotificationCenter.default.post(name: NSNotification.Name("REFRESH_FAVORITES"), object: nil)
            }
        } else {
            // Agar hozir sevimlilarda bo'lmasa, qo'shamiz (UI ni darhol yangilash)
            favoriteSpots.insert(spot.id)
            
            // Keyin database'ga qo'shamiz
            dbManager.addToFavorites(userID: userId, parkingSpotID: spot.id) { [weak self] error in
                if let error = error {
                    print("Sevimlilarga qo'shishda xatolik: \(error.localizedDescription)")
                    // Xatolik yuz bergan bo'lsa, UI ni oldingi holatiga qaytaramiz
                    DispatchQueue.main.async {
                        self?.favoriteSpots.remove(spot.id)
                    }
                    return
                }
                
                // Barcha viewlarga xabar berish
                NotificationCenter.default.post(name: NSNotification.Name("REFRESH_FAVORITES"), object: nil)
            }
        }
    }
}
// Xabarlar
enum AlertItem: Identifiable {
    var id: String {
        switch self {
        case .error(let message): return message
        }
    }
    
    case error(String)
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}

