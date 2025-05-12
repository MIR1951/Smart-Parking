import SwiftUI
import CoreLocation

struct LocationPermissionView: View {
    @State private var isPermissionGranted = false
    @StateObject private var locationManager = LocationManager()
    
    var body: some View {
        ZStack {
            if isPermissionGranted || locationManager.authorizationStatus == .authorizedWhenInUse {
                NotificationPermissionView()
            } else {
                VStack(spacing: 20) {
                    Spacer()
                    
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 120, height: 120)
                        .overlay(
                            Image(systemName: "location.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 40, height: 40)
                                .foregroundColor(.purple)
                        )
                    
                    Text("Joylashuvingiz qayerda?")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Eng yaqin xizmatlarni tavsiya etish uchun joylashuvingizni bilishimiz kerak.")
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Spacer()
                    
                    Button(action: requestLocationPermission) {
                        Text("Joylashuvga ruxsat berish")
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .cornerRadius(25)
                            .padding(.horizontal, 40)
                    }
                    
                    Button("Joylashuvni qo'lda kiritish") {
                        isPermissionGranted = true
                    }
                    .foregroundColor(.purple)
                    .padding(.bottom, 30)
                }
            }
        }
        .onAppear {
            checkLocationPermission()
        }
    }
    
    func checkLocationPermission() {
        if locationManager.authorizationStatus == .authorizedWhenInUse {
            isPermissionGranted = true
        }
    }
    
    func requestLocationPermission() {
        locationManager.requestLocation()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            if locationManager.authorizationStatus == .authorizedWhenInUse {
                isPermissionGranted = true
            }
        }
    }
}

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    override init() {
        super.init()
        locationManager.delegate = self
    }
    
    func requestLocation() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {}
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {}
}

struct LocationPermissionView_Previews: PreviewProvider {
    static var previews: some View {
        LocationPermissionView()
    }
} 