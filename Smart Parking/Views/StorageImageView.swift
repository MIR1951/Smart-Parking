import SwiftUI
import FirebaseStorage

/// Firebase Storage'dan rasmlarni yuklab ko'rsatuvchi SwiftUI komponenti
struct StorageImageView: View {
    let path: String
    let placeholder: Image
    let contentMode: ContentMode
    
    @State private var image: UIImage?
    @State private var isLoading = false
    @State private var loadError = false
    
    init(path: String, placeholder: Image, contentMode: ContentMode = .fit) {
        self.path = path
        self.placeholder = placeholder
        self.contentMode = contentMode
    }
    
    var body: some View {
        ZStack {
            if let uiImage = image {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: contentMode == .fill ? .fill : .fit)
            } else if isLoading {
                ProgressView()
            } else if loadError {
                placeholder
                    .resizable()
                    .aspectRatio(contentMode: contentMode == .fill ? .fill : .fit)
                    .foregroundColor(.gray)
            } else {
                placeholder
                    .resizable()
                    .aspectRatio(contentMode: contentMode == .fill ? .fill : .fit)
                    .foregroundColor(.gray)
            }
        }
        .onAppear(perform: loadImage)
    }
    
    private func loadImage() {
        isLoading = true
        loadError = false
        
        // Agar path bo'sh bo'lsa yuklashni to'xtatamiz
        guard !path.isEmpty else {
            isLoading = false
            loadError = true
            return
        }
        
        // Rasmning to'liq yo'lini aniqlash
        // Agar path "parking_images/" bilan boshlanmasa, qo'shib qo'yamiz
        let fullPath = path.hasPrefix("parking_images/") ? path : "parking_images/\(path)"
        
        print("Rasm yuklanmoqda: \(fullPath)")
        
        let storage = Storage.storage()
        let storageRef = storage.reference().child(fullPath)
        
        // 5MB maksimal rasm hajmi
        storageRef.getData(maxSize: 5 * 1024 * 1024) { data, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    print("Rasmni yuklashda xatolik: \(error.localizedDescription)")
                    loadError = true
                    return
                }
                
                guard let imageData = data, let uiImage = UIImage(data: imageData) else {
                    print("Olingan ma'lumotlardan rasm yaratib bo'lmaydi")
                    loadError = true
                    return
                }
                
                print("Rasm muvaffaqiyatli olindi: \(path)")
                self.image = uiImage
            }
        }
    }
}

// Preview Provider
struct StorageImageView_Previews: PreviewProvider {
    static var previews: some View {
        StorageImageView(
            path: "test/example.jpg",
            placeholder: Image(systemName: "photo"),
            contentMode: .fit
        )
        .frame(width: 200, height: 200)
    }
} 