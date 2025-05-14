//
//  ProfileView.swift
//  Smart Parking
//
//  Created by Kenjaboy Xajiyev on 04/05/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseStorage
import UIKit

struct ProfileView: View {
    @StateObject private var authManager = AuthManager.shared
    @State private var userName = "Foydalanuvchi"
    @State private var userPhoto: UIImage?
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage? = nil
    @State private var profileImage: UIImage? = nil
    @State private var isUploading = false
    
    // userID parametrini olib tashlaymiz va uni AuthManager'dan olamiz
    private var userID: String {
        return Auth.auth().currentUser?.uid ?? ""
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    // Profil rasmi
                    ZStack {
                        if let profileImage = profileImage {
                            Image(uiImage: profileImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                        } else {
                            // Firebase Storage'dan yuklash
                            StorageImageView(
                                path: "profile_images/\(userID).jpg",
                                placeholder: Image(systemName: "person.circle.fill"),
                                contentMode: .fill
                            )
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                        }
                        
                        // Rasm tanlash tugmasi
                        Button(action: {
                            showImagePicker = true
                        }) {
                            Image(systemName: "camera.fill")
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Circle().fill(Color.purple))
                        }
                        .offset(x: 40, y: 40)
                    }
                    .padding(.top, 30)
                    
                    // Foydalanuvchi nomi
                    Text(userName)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    // Profil sozlamalari
                    VStack(spacing: 5) {
                        MenuItemView(icon: "person.fill", title: "Profil ma'lumotlari") {
                            // Profil ma'lumotlarini o'zgartirish
                        }
                        
                        Divider()
                        
                        MenuItemView(icon: "creditcard.fill", title: "To'lov usullari") {
                            // To'lov usullarini o'zgartirish
                        }
                        
                        Divider()
                        
                        MenuItemView(icon: "wallet.pass.fill", title: "Mening hamyonim") {
                            // Hamyon ma'lumotlari
                        }
                        
                        Divider()
                        
                        MenuItemView(icon: "gearshape.fill", title: "Sozlamalar") {
                            // Sozlamalar
                        }
                        
                        Divider()
                        
                        MenuItemView(icon: "questionmark.circle.fill", title: "Yordam markazi") {
                            // Yordam markazi
                        }
                        
                        Divider()
                        
                        MenuItemView(icon: "lock.shield.fill", title: "Maxfiylik siyosati") {
                            // Maxfiylik siyosati
                        }
                        
                        Divider()
                        
                        MenuItemView(icon: "person.badge.plus.fill", title: "Do'stlarni taklif qilish") {
                            // Do'stlarni taklif qilish
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 5)
                    
                    // Chiqish tugmasi
                    Button(action: {
                        authManager.signOut()
                    }) {
                        HStack {
                            Image(systemName: "arrow.right.square")
                            Text("Chiqish")
                        }
                        .foregroundColor(.red)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(10)
                    }
                }
                .padding()
            }
            .navigationTitle("Profil")
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(selectedImage: $selectedImage)
            }
        }
        .onChange(of: selectedImage) { newImage in
            if let image = newImage {
                uploadProfileImage(image)
            }
        }
        .onAppear(perform: loadProfileImage)
    }
    
    // Firebase Storage'dan profil rasmini yuklash
    private func loadProfileImage() {
        // Agar userID bo'sh bo'lsa, yuklashni to'xtatamiz
        guard !userID.isEmpty else {
            print("Foydalanuvchi ID si topilmadi, rasm yuklanmaydi")
            return
        }
        
        print("Profil rasmini yuklash boshlandi: \(userID)")
        
        let storage = Storage.storage()
        let storageRef = storage.reference().child("profile_images/\(userID).jpg")
        
        storageRef.getData(maxSize: 5 * 1024 * 1024) { data, error in
            if let error = error {
                print("Profil rasmini yuklashda xatolik: \(error.localizedDescription)")
                return
            }
            
            guard let imageData = data, let uiImage = UIImage(data: imageData) else {
                print("Olingan ma'lumotlardan rasm yaratib bo'lmaydi")
                return
            }
            
            print("Profil rasmi muvaffaqiyatli olindi")
            DispatchQueue.main.async {
                self.profileImage = uiImage
            }
        }
    }
    
    // Firebase Storage'ga profil rasmini yuklash
    private func uploadProfileImage(_ image: UIImage) {
        isUploading = true
        
        guard let imageData = image.jpegData(compressionQuality: 0.6) else {
            print("Rasm siqishda xatolik")
            isUploading = false
            return
        }
        
        // Agar userID bo'sh bo'lsa, yuklashni to'xtatamiz
        guard !userID.isEmpty else {
            print("Foydalanuvchi ID si topilmadi")
            isUploading = false
            return
        }
        
        print("Profil rasmini yuklash boshlandi: \(userID)")
        
        let storage = Storage.storage()
        let storageRef = storage.reference().child("profile_images/\(userID).jpg")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        // Yuklanish jarayonini kuzatish uchun uploadTask ishlatamiz
        let uploadTask = storageRef.putData(imageData, metadata: metadata) { metadata, error in
            if let error = error {
                print("Rasmni yuklashda xatolik: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.isUploading = false
                }
                return
            }
            
            // Yuklash muvaffaqiyatli bo'lganda, yuklab olib ko'rsatamiz
            storageRef.downloadURL { url, error in
                DispatchQueue.main.async {
                    self.isUploading = false
                    
                    if let error = error {
                        print("Yuklangan rasm URL'ini olishda xatolik: \(error.localizedDescription)")
                        return
                    }
                    
                    if let url = url {
                        print("Rasm muvaffaqiyatli yuklandi: \(url.absoluteString)")
                        // URL olindi va rasm ko'rsatilishi mumkin
                        self.profileImage = image
                    }
                }
            }
        }
        
        // Upload progress'ni kuzatish
        uploadTask.observe(.progress) { snapshot in
            guard let progress = snapshot.progress else { return }
            let percentComplete = Double(progress.completedUnitCount) / Double(progress.totalUnitCount) * 100
            print("Yuklash jarayoni: \(percentComplete)%")
        }
    }
}

struct MenuItemView: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.purple)
                    .frame(width: 30)
                
                Text(title)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 10)
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}

// Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.selectedImage = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.selectedImage = originalImage
            }
            
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
