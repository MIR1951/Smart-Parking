import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct VehicleSelectionView: View {
    let spot: ParkingSpot
    let arrivalTime: Date
    let exitTime: Date
    
    @State private var vehicles: [Vehicle] = []
    @State private var isLoading = true
    @State private var selectedVehicle: Vehicle?
    @State private var showParkingSlotSelection = false
    @State private var showAddVehicle = false
    @Environment(\.dismiss) var dismiss
    
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
                    
                    Text("Transport vositasini tanlash")
                        .font(.headline)
                        .foregroundColor(.black)
                    
                    Spacer()
                    
                    Button(action: {
                        showAddVehicle = true
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(.black)
                            .padding(10)
                            .background(Circle().fill(Color.white))
                            .shadow(color: Color.black.opacity(0.1), radius: 2)
                    }
                }
                .padding()
                
                if isLoading {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                    Spacer()
                } else if vehicles.isEmpty {
                    Spacer()
                    VStack(spacing: 20) {
                        Image(systemName: "car.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        
                        Text("Transport vositalari mavjud emas")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Button(action: {
                            showAddVehicle = true
                        }) {
                            Text("Transport qo'shish")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 30)
                                .padding(.vertical, 12)
                                .background(Color.purple)
                                .cornerRadius(25)
                        }
                    }
                    Spacer()
                } else {
                    // Vehicle list
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(vehicles) { vehicle in
                                VehicleCardView(
                                    vehicle: vehicle,
                                    isSelected: selectedVehicle?.id == vehicle.id,
                                    action: {
                                        selectedVehicle = vehicle
                                    }
                                )
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                }
                
                // Continue button
                Button(action: {
                    if selectedVehicle != nil {
                        showParkingSlotSelection = true
                    }
                }) {
                    HStack {
                        Spacer()
                        Text("Davom etish")
                            .font(.headline)
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding()
                    .background(selectedVehicle == nil ? Color.gray.opacity(0.5) : Color.purple)
                    .cornerRadius(30)
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
                .disabled(selectedVehicle == nil)
            }
        }
        .onAppear {
            loadVehicles()
        }
        .fullScreenCover(isPresented: $showParkingSlotSelection) {
            if let vehicle = selectedVehicle {
                ParkingSlotSelectionView(
                    spot: spot,
                    vehicle: vehicle,
                    arrivalTime: arrivalTime,
                    exitTime: exitTime
                )
            }
        }
        .fullScreenCover(isPresented: $showAddVehicle) {
            AddVehicleView()
                .onDisappear {
                    loadVehicles()
                }
        }
    }
    
    private func loadVehicles() {
        isLoading = true
        guard let userID = Auth.auth().currentUser?.uid else {
            isLoading = false
            return
        }
        
        let db = Firestore.firestore()
        db.collection("users").document(userID).collection("vehicles")
            .getDocuments { snapshot, error in
                isLoading = false
                
                if let error = error {
                    print("Transport vositalarini yuklashda xatolik: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    return
                }
                
                self.vehicles = documents.compactMap { document in
                    let data = document.data()
                    
                    return Vehicle(
                        id: document.documentID,
                        userID: userID,
                        brand: data["brand"] as? String ?? "",
                        name: data["name"] as? String ?? "",
                        type: data["type"] as? String ?? "",
                        plate: data["plate"] as? String ?? "",

                        image: data["image"] as? String
                    )
                }
            }
    }
}

struct VehicleCardView: View {
    let vehicle: Vehicle
    let isSelected: Bool
    let action: () -> Void
  
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 15) {
                // Car icon with color
                Image(systemName: "car.top.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(.black)
                    .frame(width: 40, height: 25)
                    .padding(10)
                
                // Vehicle details
                VStack(alignment: .leading, spacing: 4) {
                    Text(vehicle.name)
                        .font(.headline)
                        .foregroundColor(.black)
                    
                    HStack {
                        Text(vehicle.type ?? "sedan")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Text(vehicle.plate)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(Color.purple, lineWidth: 1.5)
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Circle()
                            .fill(Color.purple)
                            .frame(width: 16, height: 16)
                    }
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: isSelected ? Color.purple.opacity(0.2) : Color.gray.opacity(0.1), radius: 4)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.purple : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
} 
