//
//  ProfileView.swift
//  Smart Parking
//
//  Created by Kenjaboy Xajiyev on 04/05/25.
//

import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @StateObject private var authManager = AuthManager.shared
    @State private var userName = "Foydalanuvchi"
    @State private var userPhoto: UIImage?
    @State private var showImagePicker = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    // Profil rasmi
                    ZStack(alignment: .bottomTrailing) {
                        if let userPhoto = userPhoto {
                            Image(uiImage: userPhoto)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                                .padding(4)
                                .background(Circle().stroke(Color.purple, lineWidth: 2))
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .foregroundColor(.purple)
                        }
                        
                        Button(action: {
                            showImagePicker = true
                        }) {
                            Image(systemName: "pencil")
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Circle().fill(Color.purple))
                        }
                    }
                    
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
                // Image picker
                Text("Rasm tanlash")
            }
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
