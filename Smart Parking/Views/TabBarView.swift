import SwiftUI

struct TabBarView: View {
    @State private var selectedTab = 0
    @StateObject private var viewModel = TabBarViewModel()
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Asosiy")
                }
                .tag(0)
                .onAppear {
                    viewModel.refreshIfNeeded(tab: 0)
                }
            
            ExploreView()
                .tabItem {
                    Image(systemName: "map.fill")
                    Text("Xarita")
                }
                .tag(1)
                .onAppear {
                    viewModel.refreshIfNeeded(tab: 1)
                }
            
            FavoriteView()
                .tabItem {
                    Image(systemName: "heart.fill")
                    Text("Sevimli")
                }
                .tag(2)
                .onAppear {
                    viewModel.refreshIfNeeded(tab: 2)
                }
            
            BookingsView()
                .tabItem {
                    Image(systemName: "list.bullet.clipboard")
                    Text("Buyurtma")
                }
                .tag(3)
                .onAppear {
                    viewModel.refreshIfNeeded(tab: 3)
                }
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profil")
                }
                .tag(4)
                .onAppear {
                    viewModel.refreshIfNeeded(tab: 4)
                }
        }
        .accentColor(.purple)
        .onAppear {
            // Tab o'zgarganda refresh qilish
            NotificationCenter.default.addObserver(forName: NSNotification.Name("REFRESH_FAVORITES"), object: nil, queue: .main) { _ in
                viewModel.needsRefresh = true
            }
        }
    }
}

class TabBarViewModel: ObservableObject {
    @Published var needsRefresh = false
    @Published var lastRefreshTime: [Int: Date] = [:]
    
    func refreshIfNeeded(tab: Int) {
        if needsRefresh || shouldRefresh(tab: tab) {
            // Refresh signal yuborish
            NotificationCenter.default.post(name: NSNotification.Name("REFRESH_TAB"), object: nil, userInfo: ["tab": tab])
            lastRefreshTime[tab] = Date()
            needsRefresh = false
        }
    }
    
    private func shouldRefresh(tab: Int) -> Bool {
        // Agar tab 30 soniyadan ko'p vaqt ochilmagan bo'lsa refreshlash kerak
        guard let lastTime = lastRefreshTime[tab] else {
            return true
        }
        
        return Date().timeIntervalSince(lastTime) > 30
    }
}

struct TabBarView_Previews: PreviewProvider {
    static var previews: some View {
        TabBarView()
    }
} 
