import SwiftUI

@main
struct CloudflaredManagerApp: App {
    // Use AppDelegateAdaptor to connect AppDelegate lifecycle
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    // Theme Manager'ı global olarak oluştur
    @StateObject private var themeManager = ThemeManager()

    var body: some Scene {
        // Menu bar uygulaması için hiç scene tanımlamıyoruz
        // Tüm pencereler AppDelegate tarafından manuel olarak yönetiliyor
        Settings {
            EmptyView()
        }
        .environmentObject(themeManager)
    }
}
