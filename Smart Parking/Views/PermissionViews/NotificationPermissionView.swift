import SwiftUI
import UserNotifications

struct NotificationPermissionView: View {
    @State private var isPermissionGranted = false
    
    var body: some View {
        ZStack {
            if isPermissionGranted {
                TabBarView()
            } else {
                VStack(spacing: 20) {
                    Spacer()
                    
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 120, height: 120)
                        .overlay(
                            Image(systemName: "bell.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 40, height: 40)
                                .foregroundColor(.purple)
                        )
                    
                    Text("Bildirishnomalar")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Real vaqtdagi yangilanishlarni olish uchun bildirishnomalarga ruxsat bering.")
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Spacer()
                    
                    Button(action: requestNotificationPermission) {
                        Text("Bildirishnomalarga ruxsat berish")
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .cornerRadius(25)
                            .padding(.horizontal, 40)
                    }
                    
                    Button("Keyinroq") {
                        isPermissionGranted = true
                    }
                    .foregroundColor(.purple)
                    .padding(.bottom, 30)
                }
            }
        }
    }
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            DispatchQueue.main.async {
                isPermissionGranted = true
            }
        }
    }
}

struct NotificationPermissionView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationPermissionView()
    }
} 