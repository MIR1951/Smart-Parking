//
//  ContentView.swift
//  Smart Parking
//
//  Created by Kenjaboy Xajiyev on 04/05/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var authManager = AuthManager.shared
    
    var body: some View {
        Group {
            if authManager.isLoggedIn && authManager.isOnboardingCompleted {
                // Foydalanuvchi tizimga kirgan va onboarding tugallangan
                TabBarView()
            } else if authManager.isOnboardingCompleted {
                // Onboarding tugallangan, ammo foydalanuvchi tizimga kirmagan
                LoginView()
            } else {
                // Onboarding ko'rsatilishi kerak
                OnboardingView()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
