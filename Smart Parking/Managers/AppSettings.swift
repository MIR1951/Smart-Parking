import Foundation

/// Ilova sozlamalari uchun yordamchi klass
class AppSettings {
    static let shared = AppSettings()
    
    private let defaults = UserDefaults.standard
    
    private enum Keys {
        static let dataUploaded = "parking_data_uploaded"
    }
    
    private init() {}
    
    /// Parking ma'lumotlari yuklanganligi holatini tekshirish
    var isDataUploaded: Bool {
        get {
            defaults.bool(forKey: Keys.dataUploaded)
        }
        set {
            defaults.set(newValue, forKey: Keys.dataUploaded)
        }
    }
    
    /// Barcha sozlamalarni tozalash (ilovani qayta o'rnatgandagi holat)
    func resetAllSettings() {
        let domain = Bundle.main.bundleIdentifier!
        defaults.removePersistentDomain(forName: domain)
        defaults.synchronize()
    }
} 