import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct AddVehicleView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedBrand: String = ""
    @State private var selectedModel: String = ""
    @State private var plateNumber: String = ""
    @State private var isLoading = false
    @State private var showBrandSelector = false
    @State private var showModelSelector = false
    @State private var errorMessage: String = ""
    @State private var showError: Bool = false
    
    // Mashinalar brendlari (statik)
    let carBrands = ["Toyota", "Hyundai", "Kia", "Chevrolet", "Ford", "Honda", "Audi", "BMW", "Mercedes", "Lexus"]
    
    // Model variantlari (har bir brend uchun)
    let carModels: [String: [String]] = [
        "Toyota": ["Fortuner", "Camry", "Corolla", "Land Cruiser", "RAV4", "Innova"],
        "Hyundai": ["Tucson", "Elantra", "Sonata", "Santa Fe", "Verna", "i20"],
        "Kia": ["Sportage", "Seltos", "Sorento", "Carnival", "Rio"],
        "Chevrolet": ["Tahoe", "Spark", "Captiva", "Nexia", "Cobalt", "Malibu"],
        "Ford": ["Focus", "Explorer", "Everest", "Endeavour", "Ranger"],
        "Honda": ["Civic", "Accord", "CR-V", "HR-V", "City"],
        "Audi": ["A4", "A6", "Q3", "Q5", "Q7"],
        "BMW": ["3 Series", "5 Series", "X3", "X5", "X7"],
        "Mercedes": ["C-Class", "E-Class", "GLC", "GLE", "GLS"],
        "Lexus": ["RX", "NX", "LX", "ES", "IS"]
    ]
    
    // Mashina turi (rasmdagi kabi ko'rsatish uchun)
    private var vehicleType: String {
        let suvModels = ["Fortuner", "Land Cruiser", "RAV4", "Tucson", "Santa Fe", "Sportage", "Seltos", "Sorento", "Tahoe", "Captiva", "Explorer", "Everest", "Endeavour", "CR-V", "HR-V", "Q3", "Q5", "Q7", "X3", "X5", "X7", "GLC", "GLE", "GLS", "RX", "NX", "LX"]
        let mpvModels = ["Innova", "Carnival"]
        
        if suvModels.contains(selectedModel) {
            return "SUV"
        } else if mpvModels.contains(selectedModel) {
            return "MPV"
        } else {
            return "Sedan"
        }
    }
    
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
                    
                    Text("Transport qo'shish")
                        .font(.headline)
                        .foregroundColor(.black)
                    
                    Spacer()
                    
                    Circle()
                        .frame(width: 36, height: 36)
                        .foregroundColor(.clear)
                }
                .padding()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Brend tanlash
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Brendni tanlang")
                                .font(.headline)
                                .foregroundColor(.black)
                            
                            Button(action: {
                                showBrandSelector = true
                            }) {
                                HStack {
                                    Text(selectedBrand.isEmpty ? "Brendni tanlang" : selectedBrand)
                                        .foregroundColor(selectedBrand.isEmpty ? .gray : .black)
                                        .padding()
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.purple)
                                }
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.gray.opacity(0.1))
                                )
                            }
                        }
                        .padding(.horizontal)
                        
                        // Model tanlash
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Avtomobilni tanlang")
                                .font(.headline)
                                .foregroundColor(.black)
                            
                            Button(action: {
                                if !selectedBrand.isEmpty {
                                    showModelSelector = true
                                }
                            }) {
                                HStack {
                                    Text(selectedModel.isEmpty ? "Modelni tanlang" : selectedModel)
                                        .foregroundColor(selectedModel.isEmpty ? .gray : .black)
                                        .padding()
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(selectedBrand.isEmpty ? .gray : .purple)
                                }
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.gray.opacity(0.1))
                                )
                            }
                            .disabled(selectedBrand.isEmpty)
                        }
                        .padding(.horizontal)
                        
                        // Mashina raqami kiritish
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Avtomobil raqami")
                                .font(.headline)
                                .foregroundColor(.black)
                            
                            TextField("Misol: GR 789-IJKL", text: $plateNumber)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.gray.opacity(0.1))
                                )
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
                
                // Mashina qo'shish tugmasi
                Button(action: {
                    addVehicle()
                }) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .foregroundColor(.white)
                    } else {
                        Text("Transport qo'shish")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding()
                .background(
                    isFormValid() ? Color.purple : Color.gray.opacity(0.5)
                )
                .cornerRadius(30)
                .padding(.horizontal)
                .padding(.bottom, 20)
                .disabled(!isFormValid() || isLoading)
            }
        }
        .alert(isPresented: $showError) {
            Alert(
                title: Text("Xatolik"),
                message: Text(errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .sheet(isPresented: $showBrandSelector) {
            SelectorView(
                title: "Brendni tanlang",
                options: carBrands,
                selectedOption: $selectedBrand,
                onSelect: { brand in
                    selectedBrand = brand
                    selectedModel = ""
                }
            )
        }
        .sheet(isPresented: $showModelSelector) {
            SelectorView(
                title: "Avtomobil modelini tanlang",
                options: carModels[selectedBrand] ?? [],
                selectedOption: $selectedModel,
                onSelect: { model in
                    selectedModel = model
                }
            )
        }
    }
    
    // Ma'lumotlar to'g'ri kiritilganini tekshirish
    private func isFormValid() -> Bool {
        return !selectedBrand.isEmpty && !selectedModel.isEmpty && !plateNumber.isEmpty
    }
    
    // Firebase'ga yangi mashina qo'shish
    private func addVehicle() {
        guard let userID = Auth.auth().currentUser?.uid else {
            errorMessage = "User not authenticated"
            showError = true
            return
        }
        
        isLoading = true
        
        let vehicleData: [String: Any] = [
            "name": "\(selectedBrand) \(selectedModel)",
            "type": vehicleType,
            "plate": plateNumber,
            "created_at": Timestamp(date: Date())
        ]
        
        let db = Firestore.firestore()
        db.collection("users").document(userID).collection("vehicles")
            .addDocument(data: vehicleData) { error in
                isLoading = false
                
                if let error = error {
                    errorMessage = "Error adding vehicle: \(error.localizedDescription)"
                    showError = true
                } else {
                    dismiss()
                }
            }
    }
    
    // Tasodifiy rang qaytarish (ko'rsatish uchun)
  
}

// Tanlash oynasi (brend va model uchun)
struct SelectorView: View {
    let title: String
    let options: [String]
    @Binding var selectedOption: String
    let onSelect: (String) -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(options, id: \.self) { option in
                    Button(action: {
                        selectedOption = option
                        onSelect(option)
                        dismiss()
                    }) {
                        HStack {
                            Text(option)
                                .foregroundColor(.black)
                            
                            Spacer()
                            
                            if selectedOption == option {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.purple)
                            }
                        }
                    }
                }
            }
            .navigationTitle(title)
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

struct AddVehicleView_Previews: PreviewProvider {
    static var previews: some View {
        AddVehicleView()
    }
} 
