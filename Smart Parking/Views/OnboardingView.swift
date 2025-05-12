import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    @StateObject private var authManager = AuthManager.shared
    
    var body: some View {
        VStack {
            TabView(selection: $currentPage) {
                // Birinchi sahifa
                OnboardingPageView(
                    image: "car.fill",
                    title: "Eng yaxshi parkovka joyini toping",
                    description: "Har doim, har qanday vaqtda eng qulay parkovka joyini toping.",
                    buttonText: "Boshlaylik",
                    showSkip: true,
                    page: 0,
                    currentPage: $currentPage,
                    onComplete: completeOnboarding
                )
                .tag(0)
                
                // Ikkinchi sahifa
                OnboardingPageView(
                    image: "location.fill",
                    title: "Yaqin atrofdagi parkovkalarni toping",
                    description: "Atrofingizda joylashgan barcha parkovka joylarini oson toping.",
                    buttonText: "Davom etish",
                    showSkip: true,
                    page: 1,
                    currentPage: $currentPage,
                    onComplete: completeOnboarding
                )
                .tag(1)
                
                // Uchinchi sahifa
                OnboardingPageView(
                    image: "heart.fill",
                    title: "Sevimli parkovkalarni saqlang",
                    description: "Keyinchalik foydalanish uchun sevimli parkovka joylaringizni saqlang.",
                    buttonText: "Davom etish",
                    showSkip: true,
                    page: 2,
                    currentPage: $currentPage,
                    onComplete: completeOnboarding
                )
                .tag(2)
                
                // To'rtinchi sahifa
                OnboardingPageView(
                    image: "list.bullet.clipboard",
                    title: "Parkovka band qilishlarni kuzating",
                    description: "Barcha parkovka band qilishlaringizni oson kuzating va boshqaring.",
                    buttonText: "Boshlash",
                    showSkip: false,
                    page: 3,
                    currentPage: $currentPage,
                    onComplete: completeOnboarding
                )
                .tag(3)
            }
            .tabViewStyle(PageTabViewStyle())
            .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
        }
    }
    
    func completeOnboarding() {
        // Onboarding tugallandi deb belgilash
        authManager.setOnboardingCompleted()
    }
}

struct OnboardingPageView: View {
    let image: String
    let title: String
    let description: String
    let buttonText: String
    let showSkip: Bool
    let page: Int
    @Binding var currentPage: Int
    let onComplete: () -> Void
    
    var body: some View {
        VStack {
            Spacer()
            if image.contains("car") || image.contains("location") {
                // Agar bu birinchi yoki ikkinchi sahifa bo'lsa, telefon ichida ko'rsatiladi
                Image(systemName: "iphone")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 220, height: 220)
                    .overlay(
                        ZStack {
                            Color.purple.opacity(0.2)
                            VStack {
                                Text("Joylashuv")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .padding(.leading, -45)
                                
                                Image(systemName: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 100, height: 100)
                                    .foregroundColor(.purple)
                                
                                Text(title)
                                    .font(.headline)
                                    .foregroundColor(.purple)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                                    .padding(.top, 5)
                            }
                            .padding(.horizontal)
                        }
                        .mask(
                            RoundedRectangle(cornerRadius: 20)
                                .padding()
                        )
                    )
            } else {
                Image(systemName: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 120)
                    .foregroundColor(.purple)
                    .padding(.bottom, 20)
            }
            
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top, 20)
            
            Text(description)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.top, 10)
                .foregroundColor(.gray)
            
            Spacer()
            
            HStack {
                if showSkip {
                    Button("O'tkazib yuborish") {
                        onComplete()
                    }
                    .foregroundColor(.purple)
                    .padding()
                    .padding(.leading)
                }
                
                Spacer()
                
                if page == 3 {
                    Button(action: {
                        onComplete()
                    }) {
                        Text(buttonText)
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 30)
                            .background(Color.purple)
                            .cornerRadius(25)
                    }
                    .padding(.trailing, 30)
                } else {
                    Button(action: {
                        withAnimation {
                            currentPage += 1
                        }
                    }) {
                        Image(systemName: "arrow.right")
                            .foregroundColor(.white)
                            .padding()
                            .background(Circle().fill(Color.purple))
                    }
                    .padding(.trailing, 30)
                }
            }
            .padding(.bottom, 30)
        }
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
    }
} 