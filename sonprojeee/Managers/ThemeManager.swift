import SwiftUI
import Combine
import AppKit

// MARK: - Theme Manager

class ThemeManager: ObservableObject {
    @Published var currentTheme: AppTheme = .system
    @Published var accentColor: AccentColor = .blue
    @Published var isDarkMode: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadThemeSettings()
        observeSystemThemeChanges()
    }
    
    private func loadThemeSettings() {
        // UserDefaults'tan tema ayarlarını yükle
        if let themeRawValue = UserDefaults.standard.object(forKey: "selectedTheme") as? String,
           let theme = AppTheme(rawValue: themeRawValue) {
            currentTheme = theme
        }
        
        if let accentRawValue = UserDefaults.standard.object(forKey: "selectedAccentColor") as? String,
           let accent = AccentColor(rawValue: accentRawValue) {
            accentColor = accent
        }
        
        updateDarkModeStatus()
    }
    
    private func observeSystemThemeChanges() {
        // Sistem tema değişikliklerini gözlemle
        DistributedNotificationCenter.default.publisher(for: Notification.Name("AppleInterfaceThemeChangedNotification"))
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.updateDarkModeStatus()
                }
            }
            .store(in: &cancellables)
        
        // NSApp appearance değişikliklerini de gözlemle
        NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.updateDarkModeStatus()
                }
            }
            .store(in: &cancellables)
    }
    
    private func updateDarkModeStatus() {
        DispatchQueue.main.async {
            switch self.currentTheme {
            case .system:
                // Sistem tema durumunu kontrol et
                if let appearance = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) {
                    self.isDarkMode = appearance == .darkAqua
                } else {
                    // Fallback: UserDefaults üzerinden sistem temasını kontrol et
                    let appleInterfaceStyle = UserDefaults.standard.string(forKey: "AppleInterfaceStyle")
                    self.isDarkMode = appleInterfaceStyle?.lowercased() == "dark"
                }
            case .light:
                self.isDarkMode = false
            case .dark:
                self.isDarkMode = true
            }
        }
    }
    
    func setTheme(_ theme: AppTheme) {
        currentTheme = theme
        UserDefaults.standard.set(theme.rawValue, forKey: "selectedTheme")
        
        // NSApp appearance'ını güncelle
        DispatchQueue.main.async {
            switch theme {
            case .system:
                NSApp.appearance = nil
            case .light:
                NSApp.appearance = NSAppearance(named: .aqua)
            case .dark:
                NSApp.appearance = NSAppearance(named: .darkAqua)
            }
        }
        
        updateDarkModeStatus()
    }
    
    func setAccentColor(_ color: AccentColor) {
        accentColor = color
        UserDefaults.standard.set(color.rawValue, forKey: "selectedAccentColor")
    }
    
    // Tema-aware renkler
    var primaryColor: Color {
        accentColor.color
    }
    
    var backgroundColor: Color {
        isDarkMode ? Color(.windowBackgroundColor) : Color(.windowBackgroundColor)
    }
    
    var cardBackgroundColor: Color {
        isDarkMode ? Color(.controlBackgroundColor) : Color(.controlBackgroundColor)
    }
    
    var textColor: Color {
        isDarkMode ? Color.white : Color.primary
    }
    
    var secondaryTextColor: Color {
        isDarkMode ? Color.secondary : Color.secondary
    }
    
    var shadowColor: Color {
        isDarkMode ? Color.black.opacity(0.3) : Color.black.opacity(0.1)
    }
    
    var glassmorphismOverlay: Color {
        isDarkMode ? Color.white.opacity(0.05) : Color.white.opacity(0.1)
    }
    
    var glassmorphismBorder: Color {
        isDarkMode ? Color.white.opacity(0.1) : Color.white.opacity(0.2)
    }
}

// MARK: - Theme Types

enum AppTheme: String, CaseIterable {
    case system = "system"
    case light = "light"
    case dark = "dark"
    
    var displayName: String {
        switch self {
        case .system: return "Sistem"
        case .light: return "Açık"
        case .dark: return "Koyu"
        }
    }
    
    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max"
        case .dark: return "moon"
        }
    }
}

enum AccentColor: String, CaseIterable {
    case blue = "blue"
    case purple = "purple"
    case pink = "pink"
    case red = "red"
    case orange = "orange"
    case yellow = "yellow"
    case green = "green"
    case mint = "mint"
    case teal = "teal"
    case cyan = "cyan"
    case indigo = "indigo"
    
    var color: Color {
        switch self {
        case .blue: return .blue
        case .purple: return .purple
        case .pink: return .pink
        case .red: return .red
        case .orange: return .orange
        case .yellow: return .yellow
        case .green: return .green
        case .mint: return .mint
        case .teal: return .teal
        case .cyan: return .cyan
        case .indigo: return .indigo
        }
    }
    
    var displayName: String {
        switch self {
        case .blue: return "Mavi"
        case .purple: return "Mor"
        case .pink: return "Pembe"
        case .red: return "Kırmızı"
        case .orange: return "Turuncu"
        case .yellow: return "Sarı"
        case .green: return "Yeşil"
        case .mint: return "Nane"
        case .teal: return "Deniz Yeşili"
        case .cyan: return "Cyan"
        case .indigo: return "İndigo"
        }
    }
}

// MARK: - Theme-Aware View Modifiers

struct ThemedGlassmorphismModifier: ViewModifier {
    @EnvironmentObject var themeManager: ThemeManager
    let cornerRadius: CGFloat
    
    init(cornerRadius: CGFloat = 12) {
        self.cornerRadius = cornerRadius
    }
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        themeManager.glassmorphismBorder,
                                        Color.clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }
            )
    }
}

struct ThemedShadowModifier: ViewModifier {
    @EnvironmentObject var themeManager: ThemeManager
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
    
    init(radius: CGFloat = 8, x: CGFloat = 0, y: CGFloat = 4) {
        self.radius = radius
        self.x = x
        self.y = y
    }
    
    func body(content: Content) -> some View {
        content
            .shadow(color: themeManager.shadowColor, radius: radius, x: x, y: y)
    }
}

// MARK: - Theme Extensions

extension View {
    func themedGlassmorphism(cornerRadius: CGFloat = 12) -> some View {
        self.modifier(ThemedGlassmorphismModifier(cornerRadius: cornerRadius))
    }
    
    func themedShadow(radius: CGFloat = 8, x: CGFloat = 0, y: CGFloat = 4) -> some View {
        self.modifier(ThemedShadowModifier(radius: radius, x: x, y: y))
    }
    
    func themedCard(padding: CGFloat = 20) -> some View {
        self
            .padding(padding)
            .themedGlassmorphism()
            .themedShadow()
            .hoverEffect()
    }
}

// MARK: - Theme Selection View

struct ThemeSelectionView: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Theme Selection
            VStack(alignment: .leading, spacing: 12) {
                Text("Tema")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                HStack(spacing: 12) {
                    ForEach(AppTheme.allCases, id: \.self) { theme in
                        ThemeButton(theme: theme)
                    }
                }
            }
            
            // Accent Color Selection
            VStack(alignment: .leading, spacing: 12) {
                Text("Vurgu Rengi")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                    ForEach(AccentColor.allCases, id: \.self) { color in
                        AccentColorButton(accentColor: color)
                    }
                }
            }
        }
        .themedCard()
    }
}

struct ThemeButton: View {
    @EnvironmentObject var themeManager: ThemeManager
    let theme: AppTheme
    
    var isSelected: Bool {
        themeManager.currentTheme == theme
    }
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                themeManager.setTheme(theme)
            }
        }) {
            VStack(spacing: 8) {
                Image(systemName: theme.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : themeManager.primaryColor)
                
                Text(theme.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(width: 70, height: 60)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? themeManager.primaryColor : Color.clear)
                    .overlay {
                        if !isSelected {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(themeManager.primaryColor.opacity(0.3), lineWidth: 1)
                        }
                    }
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
        }
        .buttonStyle(.plain)
        .hoverEffect(scaleEffect: 1.02)
    }
}

struct AccentColorButton: View {
    @EnvironmentObject var themeManager: ThemeManager
    let accentColor: AccentColor
    
    var isSelected: Bool {
        themeManager.accentColor == accentColor
    }
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                themeManager.setAccentColor(accentColor)
            }
        }) {
            Circle()
                .fill(accentColor.color)
                .frame(width: 32, height: 32)
                .overlay {
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .scaleEffect(isSelected ? 1.2 : 1.0)
                .shadow(color: accentColor.color.opacity(0.4), radius: isSelected ? 6 : 2)
        }
        .buttonStyle(.plain)
        .hoverEffect(scaleEffect: 1.1)
    }
}

// MARK: - Environment Integration

struct ThemeManagerKey: EnvironmentKey {
    static let defaultValue = ThemeManager()
}

extension EnvironmentValues {
    var themeManager: ThemeManager {
        get { self[ThemeManagerKey.self] }
        set { self[ThemeManagerKey.self] = newValue }
    }
}

// MARK: - SwiftUI Integration

/// SwiftUI view'lar için tema-aware modifier
struct ThemeAwareModifier: ViewModifier {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) var systemColorScheme
    
    func body(content: Content) -> some View {
        content
            .preferredColorScheme(colorScheme)
            .onChange(of: systemColorScheme) { _, newScheme in
                if themeManager.currentTheme == .system {
                    DispatchQueue.main.async {
                        themeManager.isDarkMode = newScheme == .dark
                    }
                }
            }
    }
    
    private var colorScheme: ColorScheme? {
        switch themeManager.currentTheme {
        case .system: return nil // Sistem temasını kullan
        case .light: return .light
        case .dark: return .dark
        }
    }
}

extension View {
    /// View'a tema desteği ekler
    func themeAware() -> some View {
        self.modifier(ThemeAwareModifier())
    }
}

// MARK: - Theme Preview

#Preview {
    ThemeSelectionView()
        .environmentObject(ThemeManager())
        .frame(width: 400, height: 300)
}
