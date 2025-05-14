//
//  StorageManager.swift
//  Smart Parking
//
//  Created by Kenjaboy Xajiyev on 13/05/25.
//




import SwiftUI
import FirebaseStorage

class StorageManager {
    // Singleton pattern
    static let shared = StorageManager()
    private let storage = Storage.storage()
    private let cache = NSCache<NSString, UIImage>()
    
    private init() { }
    
    // MARK: - Kesh bilan ishlash
    
    // Rasmni keshdan olish
    func getImageFromCache(forKey key: String) -> UIImage? {
        return cache.object(forKey: key as NSString)
    }
    
    // Rasmni keshga saqlash
    func saveImageToCache(_ image: UIImage, forKey key: String) {
        cache.setObject(image, forKey: key as NSString)
    }
    
    // MARK: - Rasmlarni olish
    
    // Path bo'yicha rasmni olish
    func fetchImage(fromPath path: String, completion: @escaping (UIImage?) -> Void) {
        // Avval keshdan tekshirish
        if let cachedImage = getImageFromCache(forKey: path) {
            print("Rasm keshdan olindi: \(path)")
            completion(cachedImage)
            return
        }
        
        // Firebase Storage'dan olish
        let storageRef = storage.reference().child(path)
        
        storageRef.getData(maxSize: 5 * 1024 * 1024) { data, error in
            if let error = error {
                print("Rasmni olishda xatolik: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let imageData = data, let image = UIImage(data: imageData) else {
                print("Rasm ma'lumotlari noto'g'ri")
                completion(nil)
                return
            }
            
            // Rasmni keshga saqlash
            self.saveImageToCache(image, forKey: path)
            print("Rasm muvaffaqiyatli yuklandi: \(path)")
            completion(image)
        }
    }
    
    // URL bo'yicha rasmni olish
    func fetchImage(fromURL urlString: String, completion: @escaping (UIImage?) -> Void) {
        // Avval keshdan tekshirish
        if let cachedImage = getImageFromCache(forKey: urlString) {
            print("Rasm keshdan olindi (URL): \(urlString)")
            completion(cachedImage)
            return
        }
        
        // URL to'g'riligini tekshirish
        guard let url = URL(string: urlString) else {
            print("Noto'g'ri URL: \(urlString)")
            completion(nil)
            return
        }
        
        // URLSession orqali rasmni olish
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Rasmni yuklashda xatolik: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let imageData = data, let image = UIImage(data: imageData) else {
                print("Rasm ma'lumotlari noto'g'ri (URL)")
                completion(nil)
                return
            }
            
            // Rasmni keshga saqlash
            self.saveImageToCache(image, forKey: urlString)
            print("Rasm muvaffaqiyatli yuklandi (URL): \(urlString)")
            completion(image)
        }.resume()
    }
    
    // MARK: - Rasmlarni yuklash
    
    // Rasmni Storage'ga yuklash
    func uploadImage(_ image: UIImage, path: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.6) else {
            let error = NSError(domain: "StorageManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "Rasm siqishda xatolik"])
            completion(.failure(error))
            return
        }
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        let storageRef = storage.reference().child(path)
        
        // Firebase Storage'ga yuklash
        storageRef.putData(imageData, metadata: metadata) { metadata, error in
            if let error = error {
                print("Rasmni yuklashda xatolik: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            // Download URL olish
            storageRef.downloadURL { url, error in
                if let error = error {
                    print("URL olishda xatolik: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                
                guard let downloadURL = url else {
                    let error = NSError(domain: "StorageManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "URL topilmadi"])
                    completion(.failure(error))
                    return
                }
                
                print("Rasm muvaffaqiyatli yuklandi: \(downloadURL.absoluteString)")
                completion(.success(downloadURL.absoluteString))
            }
        }
    }
    
    // Profil rasmini yuklash
    func uploadProfileImage(_ image: UIImage, forUserID userID: String, completion: @escaping (Result<String, Error>) -> Void) {
        let path = "profile_images/\(userID).jpg"
        uploadImage(image, path: path, completion: completion)
    }
    
    // Parkovka rasmini yuklash
    func uploadParkingImage(_ image: UIImage, forParkingID parkingID: String, completion: @escaping (Result<String, Error>) -> Void) {
        let timestamp = Int(Date().timeIntervalSince1970)
        let path = "parking_images/\(parkingID)/\(timestamp).jpg"
        uploadImage(image, path: path, completion: completion)
    }
    
    // Transport vositasi rasmini yuklash
    func uploadVehicleImage(_ image: UIImage, forUserID userID: String, vehicleID: String, completion: @escaping (Result<String, Error>) -> Void) {
        let path = "vehicle_images/\(userID)/\(vehicleID).jpg"
        uploadImage(image, path: path, completion: completion)
    }
    
    // MARK: - Rasmlarni o'chirish
    
    // Rasmni Storage'dan o'chirish
    func deleteImage(atPath path: String, completion: @escaping (Bool) -> Void) {
        let storageRef = storage.reference().child(path)
        
        storageRef.delete { error in
            if let error = error {
                print("Rasmni o'chirishda xatolik: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            // Keshdan ham o'chirish
            self.cache.removeObject(forKey: path as NSString)
            
            print("Rasm muvaffaqiyatli o'chirildi: \(path)")
            completion(true)
        }
    }
    
    // URL bo'yicha rasmni o'chirish
    func deleteImage(atURL urlString: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: urlString),
              url.host?.contains("firebasestorage.googleapis.com") == true else {
            print("Firebase Storage URL emas: \(urlString)")
            completion(false)
            return
        }
        
        // URL dan path ajratib olish
        let storageRef = storage.reference(forURL: urlString)
        
        storageRef.delete { error in
            if let error = error {
                print("Rasmni o'chirishda xatolik: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            // Keshdan ham o'chirish
            self.cache.removeObject(forKey: urlString as NSString)
            
            print("Rasm muvaffaqiyatli o'chirildi: \(urlString)")
            completion(true)
        }
    }
}

// MARK: - Firebase Storage Image View
//struct StorageImageView: View {
//    let path: String
//    var placeholder: Image = Image(systemName: "photo")
//    var contentMode: ContentMode = .fill
//    
//    @State private var image: UIImage? = nil
//    @State private var isLoading = true
//    
//    var body: some View {
//        Group {
//            if let image = image {
//                Image(uiImage: image)
//                    .resizable()
//                    .aspectRatio(contentMode: contentMode)
//            } else if isLoading {
//                placeholder
//                    .resizable()
//                    .aspectRatio(contentMode: contentMode)
//                    .overlay(
//                        ProgressView()
//                            .progressViewStyle(CircularProgressViewStyle())
//                    )
//            } else {
//                placeholder
//                    .resizable()
//                    .aspectRatio(contentMode: contentMode)
//            }
//        }
//        .onAppear(perform: loadImage)
//    }
//    
//    private func loadImage() {
//        isLoading = true
//        
//        StorageManager.shared.fetchImage(fromPath: path) { fetchedImage in
//            DispatchQueue.main.async {
//                isLoading = false
//                image = fetchedImage
//            }
//        }
//    }
//}

// MARK: - Firebase Storage URL Image View
struct StorageURLImageView: View {
    let url: String
    var placeholder: Image = Image(systemName: "photo")
    var contentMode: ContentMode = .fill
    
    @State private var image: UIImage? = nil
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else if isLoading {
                placeholder
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
                    .overlay(
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    )
            } else {
                placeholder
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            }
        }
        .onAppear(perform: loadImage)
    }
    
    private func loadImage() {
        isLoading = true
        
        StorageManager.shared.fetchImage(fromURL: url) { fetchedImage in
            DispatchQueue.main.async {
                isLoading = false
                image = fetchedImage
            }
        }
    }
}
