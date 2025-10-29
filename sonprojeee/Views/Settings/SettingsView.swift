import SwiftUI
import AppKit

struct SettingsView: View {
    @EnvironmentObject var manager: TunnelManager
    
    @AppStorage("darkModeEnabled") private var darkModeEnabled = false
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("autoStartTunnels") private var autoStartTunnels = false
    @AppStorage("minimizeToTray") private var minimizeToTray = true
    @AppStorage("showStatusInMenuBar") private var showStatusInMenuBar = true
    @AppStorage("accentColor") private var accentColorName = "blue"
    @AppStorage("pythonProjectPath") private var storedPythonProjectPath: String = ""
    
    @State private var tempCloudflaredPath: String = ""
    @State private var tempMampPath: String = "/Applications/MAMP"
    @State private var tempPythonProjectPath: String = ""
    @State private var intervalString: String = ""
    @State private var isWorking: Bool = false
    @State private var launchAtLogin: Bool = false
    @State private var launchAtLoginLoading: Bool = false
    @State private var selectedTab: SettingsTab = .general
    @State private var hoveredButton: String? = nil
    
    enum SettingsTab: String, CaseIterable {
        case general = "Genel"
        case paths = "Yollar"
        case appearance = "Görünüm"
        case notifications = "Bildirimler"
        case advanced = "Gelişmiş"
        case about = "Hakkında"
        
        var icon: String {
            switch self {
            case .general: return "gear"
            case .paths: return "folder.badge.gearshape"
            case .appearance: return "paintbrush"
            case .notifications: return "bell"
            case .advanced: return "wrench.and.screwdriver"
            case .about: return "info.circle"
            }
        }
    }
    
    private let accentColors: [(name: String, color: Color)] = [
        ("blue", .blue),
        ("purple", .purple),
        ("pink", .pink),
        ("red", .red),
        ("orange", .orange),
        ("yellow", .yellow),
        ("green", .green),
        ("mint", .mint),
        ("teal", .teal),
        ("cyan", .cyan)
    ]
    
    var currentAccentColor: Color {
        accentColors.first(where: { $0.name == accentColorName })?.color ?? .blue
    }
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // Sidebar
                sidebarView
                    .frame(width: 200)
                
                // Main Content
                mainContentView
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(width: 800, height: 600)
        .background(modernBackground)
        .onAppear {
            setupInitialValues()
        }
    }
    
    // MARK: - Modern Background
    private var modernBackground: some View {
        ZStack {
            // Base background
            Color(.windowBackgroundColor)
            
            // Gradient overlay
            LinearGradient(
                colors: [
                    currentAccentColor.opacity(0.1),
                    Color.clear,
                    currentAccentColor.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Subtle noise texture effect
            Rectangle()
                .fill(Color.white.opacity(0.02))
                .blendMode(.overlay)
        }
    }
    
    // MARK: - Sidebar
    private var sidebarView: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                // App icon placeholder
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [currentAccentColor, currentAccentColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                    .overlay {
                        Image(systemName: "cloud.fill")
                            .font(.title)
                            .foregroundColor(.white)
                    }
                    .shadow(color: currentAccentColor.opacity(0.3), radius: 8, x: 0, y: 4)
                
                VStack(spacing: 4) {
                    Text("Cloudflared Manager")
                        .font(.headline.bold())
                    Text("v1.0.0")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.top, 30)
            .padding(.bottom, 20)
            
            // Tab buttons
            VStack(spacing: 4) {
                ForEach(SettingsTab.allCases, id: \.self) { tab in
                    sidebarButton(for: tab)
                }
            }
            .padding(.horizontal, 12)
            
            Spacer()
            
            // Status indicator
            statusIndicatorView
                .padding(.horizontal, 12)
                .padding(.bottom, 20)
        }
        .background {
            // Sidebar background with glassmorphism
            RoundedRectangle(cornerRadius: 0)
                .fill(.ultraThinMaterial)
                .overlay {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.1),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
        }
    }
    
    private func sidebarButton(for tab: SettingsTab) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                selectedTab = tab
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: tab.icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(selectedTab == tab ? .white : .primary)
                    .frame(width: 20)
                
                Text(tab.rawValue)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(selectedTab == tab ? .white : .primary)
                
                Spacer()
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background {
                if selectedTab == tab {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                colors: [currentAccentColor, currentAccentColor.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: currentAccentColor.opacity(0.3), radius: 4, x: 0, y: 2)
                } else {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.clear)
                }
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(selectedTab == tab ? 1.02 : 1.0)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedTab)
    }
    
    private var statusIndicatorView: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Circle()
                    .fill(FileManager.default.fileExists(atPath: tempCloudflaredPath) ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
                    .shadow(color: FileManager.default.fileExists(atPath: tempCloudflaredPath) ? .green : .red, radius: 4)
                
                Text(FileManager.default.fileExists(atPath: tempCloudflaredPath) ? "Hazır" : "Yapılandırma Gerekli")
                    .font(.caption.bold())
                    .foregroundColor(FileManager.default.fileExists(atPath: tempCloudflaredPath) ? .green : .red)
            }
            
            Button(action: { manager.checkCloudflaredExecutable() }) {
                Text("Durumu Kontrol Et")
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial)
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                }
        }
    }
    
    // MARK: - Main Content
    private var mainContentView: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(selectedTab.rawValue)
                        .font(.largeTitle.bold())
                        .foregroundColor(.primary)
                    
                    Text(headerSubtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.horizontal, 30)
            .padding(.top, 30)
            .padding(.bottom, 20)
            
            // Content
            ScrollView {
                contentForSelectedTab
                    .padding(.horizontal, 30)
                    .padding(.bottom, 30)
            }
        }
    }
    
    private var headerSubtitle: String {
        switch selectedTab {
        case .general: return "Temel uygulama ayarları ve yapılandırma"
        case .paths: return "Dosya yolları ve dizin ayarları"
        case .appearance: return "Görünüm ve tema tercihleri"
        case .notifications: return "Bildirim ayarları ve tercihler"
        case .advanced: return "Gelişmiş özellikler ve araçlar"
        case .about: return "Uygulama hakkında bilgiler"
        }
    }
    
    @ViewBuilder
    private var contentForSelectedTab: some View {
        switch selectedTab {
        case .general: generalTabContent
        case .paths: pathsTabContent
        case .appearance: appearanceTabContent
        case .notifications: notificationsTabContent
        case .advanced: advancedTabContent
        case .about: aboutTabContent
        }
    }
    
    // MARK: - Tab Contents
    private var generalTabContent: some View {
        LazyVStack(spacing: 24) {
            // Cloudflared Configuration
            modernCard("Cloudflared Yapılandırması", icon: "terminal") {
                VStack(spacing: 16) {
                    modernFormField("Yürütülebilir Dosya Yolu", value: $tempCloudflaredPath) {
                        HStack(spacing: 8) {
                            Button("Gözat") { chooseCloudflared() }
                                .buttonStyle(ModernButtonStyle(color: .blue, size: .small))
                            
                            Button("Kaydet") { saveCloudflaredPath() }
                                .buttonStyle(ModernButtonStyle(color: currentAccentColor, size: .small))
                                .disabled(tempCloudflaredPath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                    
                    modernFormField("Durum Kontrol Aralığı", value: .constant("\(Int(manager.checkInterval)) saniye")) {
                        VStack(spacing: 8) {
                            HStack {
                                Slider(value: Binding(
                                    get: { Double(Int(intervalString) ?? Int(manager.checkInterval)) },
                                    set: { newVal in intervalString = String(Int(newVal)) }
                                ), in: 5...300, step: 1) {
                                    Text("Aralık")
                                }
                                .accentColor(currentAccentColor)
                                
                                Text("\(Int(intervalString) ?? Int(manager.checkInterval))s")
                                    .font(.caption.monospacedDigit())
                                    .foregroundColor(.secondary)
                                    .frame(width: 40, alignment: .trailing)
                            }
                            
                            Button("Uygula") { applyInterval() }
                                .buttonStyle(ModernButtonStyle(color: currentAccentColor, size: .small))
                        }
                    }
                }
            }
            
            // System Behavior
            modernCard("Sistem Davranışı", icon: "gearshape") {
                VStack(spacing: 16) {
                    modernToggle("Otomatik Tünel Başlatma", isOn: $autoStartTunnels, description: "Uygulama açıldığında tünelleri otomatik başlat")
                    
                    modernToggle("Sistem Tepsisine Küçült", isOn: $minimizeToTray, description: "Pencere kapatıldığında uygulamayı gizle")
                    
                    modernToggle("Durum Çubuğunda Göster", isOn: $showStatusInMenuBar, description: "Menü çubuğunda tünel durumunu göster")
                    
                    if #available(macOS 13.0, *) {
                        modernToggle("Oturum Açıldığında Başlat", 
                                   isOn: Binding(get: { launchAtLogin }, set: { setLaunchAtLogin($0) }),
                                   description: "Sisteme giriş yapıldığında otomatik başlat")
                            .disabled(launchAtLoginLoading)
                    }
                }
            }
        }
    }
    
    private var pathsTabContent: some View {
        LazyVStack(spacing: 24) {
            // MAMP Paths
            modernCard("MAMP Yapılandırması", icon: "server.rack") {
                VStack(spacing: 16) {
                    modernFormField("MAMP Ana Dizini", value: $tempMampPath) {
                        HStack(spacing: 8) {
                            Button("Gözat") { chooseMampPath() }
                                .buttonStyle(ModernButtonStyle(color: .blue, size: .small))
                            
                            Button("Kaydet") { saveMampPath() }
                                .buttonStyle(ModernButtonStyle(color: currentAccentColor, size: .small))
                                .disabled(tempMampPath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                    
                    pathDisplayCard("Apache Config", path: manager.mampConfigDirectoryPath, icon: "folder.badge.gearshape")
                    pathDisplayCard("Sites Directory", path: manager.mampSitesDirectoryPath, icon: "folder")
                    pathDisplayCard("vHost Config", path: manager.mampVHostConfPath, icon: "doc.text")
                    pathDisplayCard("httpd.conf", path: manager.mampHttpdConfPath, icon: "doc.text.fill")
                }
            }
            
            // Python Project Paths
            modernCard("Python Proje Ayarları", icon: "terminal") {
                VStack(spacing: 16) {
                    modernFormField("Python Proje Dizini", value: $tempPythonProjectPath) {
                        HStack(spacing: 8) {
                            Button("Gözat") { choosePythonProjectPath() }
                                .buttonStyle(ModernButtonStyle(color: .green, size: .small))
                            
                            Button("Kaydet") { savePythonProjectPath() }
                                .buttonStyle(ModernButtonStyle(color: currentAccentColor, size: .small))
                                .disabled(tempPythonProjectPath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                    
                    Text("Python uygulamanızın bulunduğu ana dizin")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Quick Access
            modernCard("Hızlı Erişim", icon: "bolt.fill") {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    quickAccessButton("~/.cloudflared", icon: "folder", path: manager.cloudflaredDirectoryPath)
                    quickAccessButton("MAMP Config", icon: "folder.badge.gearshape", path: manager.mampConfigDirectoryPath)
                    quickAccessButton("vHost File", icon: "doc.text", path: manager.mampVHostConfPath)
                    quickAccessButton("httpd.conf", icon: "doc.text.fill", path: manager.mampHttpdConfPath)
                }
            }
        }
    }
    
    private var appearanceTabContent: some View {
        LazyVStack(spacing: 24) {
            // Theme Settings
            modernCard("Tema Ayarları", icon: "paintbrush") {
                VStack(spacing: 20) {
                    modernToggle("Koyu Mod", isOn: $darkModeEnabled, description: "Karanlık tema kullan")
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Vurgu Rengi")
                            .font(.headline)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                            ForEach(accentColors, id: \.name) { colorOption in
                                colorPickerButton(colorOption)
                            }
                        }
                    }
                }
            }
            
            // Interface Options
            modernCard("Arayüz Seçenekleri", icon: "rectangle.3.group") {
                VStack(spacing: 16) {
                    Text("Gelecek güncellemelerde daha fazla özelleştirme seçeneği eklenecek...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 20)
                }
            }
        }
    }
    
    private var notificationsTabContent: some View {
        LazyVStack(spacing: 24) {
            modernCard("Bildirim Ayarları", icon: "bell") {
                VStack(spacing: 16) {
                    modernToggle("Bildirimleri Etkinleştir", isOn: $notificationsEnabled, description: "Sistem bildirimlerini göster")
                    
                    if notificationsEnabled {
                        VStack(spacing: 12) {
                            modernToggle("Tünel Durumu Bildirimleri", isOn: .constant(true), description: "Tünel başlatma/durdurma bildirimleri")
                            modernToggle("Hata Bildirimleri", isOn: .constant(true), description: "Hata ve uyarı bildirimleri")
                            modernToggle("Başarı Bildirimleri", isOn: .constant(true), description: "İşlem tamamlama bildirimleri")
                        }
                        .padding(.leading, 20)
                    }
                }
            }
        }
    }
    
    private var advancedTabContent: some View {
        LazyVStack(spacing: 24) {
            // Cloudflare Operations
            modernCard("Cloudflare İşlemleri", icon: "cloud") {
                VStack(spacing: 12) {
                    actionButton("Cloudflare Hesabı Girişi", icon: "person.crop.circle.badge.checkmark", color: .blue) {
                        manager.cloudflareLogin { _ in }
                    }
                    
                    actionButton("Tünel Durumlarını Kontrol Et", icon: "clock.arrow.circlepath", color: .orange) {
                        manager.checkAllManagedTunnelStatuses(forceCheck: true)
                    }
                }
            }
            
            // Bulk Operations
            modernCard("Toplu İşlemler", icon: "square.3.layers.3d") {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    actionButton("Tümünü Tara", icon: "arrow.clockwise", color: .blue) {
                        manager.findManagedTunnels()
                    }
                    
                    actionButton("Tümünü Başlat", icon: "play.circle.fill", color: .green) {
                        manager.startAllManagedTunnels()
                    }
                    
                    actionButton("Tümünü Durdur", icon: "stop.circle.fill", color: .red) {
                        manager.stopAllTunnels()
                    }
                    
                    actionButton("Ayarları Sıfırla", icon: "arrow.counterclockwise", color: .purple) {
                        resetSettings()
                    }
                }
            }
        }
    }
    
    private var aboutTabContent: some View {
        LazyVStack(spacing: 24) {
            modernCard("Uygulama Bilgileri", icon: "info.circle") {
                VStack(spacing: 20) {
                    // App Icon
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [currentAccentColor, currentAccentColor.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                        .overlay {
                            Image(systemName: "cloud.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.white)
                        }
                        .shadow(color: currentAccentColor.opacity(0.3), radius: 12, x: 0, y: 6)
                    
                    VStack(spacing: 8) {
                        Text("Cloudflared Manager")
                            .font(.title.bold())
                        
                        Text("Version 1.0.0")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("Modern cloudflared tünel yönetim aracı")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    Divider()
                    
                    VStack(spacing: 12) {
                        infoRow("Geliştirici", value: "Adil Emre Karayürek")
                        infoRow("Platform", value: "macOS 12.0+")
                        infoRow("Framework", value: "SwiftUI")
                        infoRow("Son Güncelleme", value: "2024")
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Views
    private func modernCard<Content: View>(_ title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(currentAccentColor)
                    .frame(width: 24, height: 24)
                
                Text(title)
                    .font(.title2.bold())
                
                Spacer()
            }
            
            content()
        }
        .padding(24)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.3), Color.clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
    }
    
    private func modernFormField<Content: View>(_ label: String, value: Binding<String>, @ViewBuilder actions: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.headline)
            
            HStack(spacing: 12) {
                TextField(label, text: value)
                    .textFieldStyle(ModernTextFieldStyle())
                
                actions()
            }
        }
    }
    
    private func modernToggle(_ title: String, isOn: Binding<Bool>, description: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: isOn)
                .toggleStyle(ModernToggleStyle(accentColor: currentAccentColor))
        }
    }
    
    private func pathDisplayCard(_ title: String, path: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(currentAccentColor)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                Text((path as NSString).abbreviatingWithTildeInPath)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: {
                NSWorkspace.shared.open(URL(fileURLWithPath: path))
            }) {
                Image(systemName: "arrow.up.right.square")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .disabled(!FileManager.default.fileExists(atPath: path))
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .cornerRadius(10)
    }
    
    private func quickAccessButton(_ title: String, icon: String, path: String) -> some View {
        Button(action: {
            NSWorkspace.shared.open(URL(fileURLWithPath: path))
        }) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(currentAccentColor)
                
                Text(title)
                    .font(.caption.bold())
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(.ultraThinMaterial)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .disabled(!FileManager.default.fileExists(atPath: path))
    }
    
    private func colorPickerButton(_ colorOption: (name: String, color: Color)) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                accentColorName = colorOption.name
            }
        }) {
            Circle()
                .fill(colorOption.color)
                .frame(width: 32, height: 32)
                .overlay {
                    if accentColorName == colorOption.name {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .scaleEffect(accentColorName == colorOption.name ? 1.2 : 1.0)
                .shadow(color: colorOption.color.opacity(0.4), radius: accentColorName == colorOption.name ? 6 : 2)
        }
        .buttonStyle(.plain)
    }
    
    private func actionButton(_ title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.subheadline.bold())
                Spacer()
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(.ultraThinMaterial)
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
    
    private func infoRow(_ title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.bold())
        }
    }
    
    // MARK: - Helper Functions
    private func setupInitialValues() {
        tempCloudflaredPath = manager.cloudflaredExecutablePath
        tempMampPath = manager.mampBasePath
        intervalString = String(Int(manager.checkInterval))
        if let appDelegate = NSApp.delegate as? AppDelegate {
            let resolvedPythonPath = appDelegate.pythonProjectDirectoryPath
            storedPythonProjectPath = resolvedPythonPath
            tempPythonProjectPath = resolvedPythonPath
        } else {
            let fallback = storedPythonProjectPath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "/Users/adilemre/Documents/PANEL-main" : storedPythonProjectPath
            storedPythonProjectPath = fallback
            tempPythonProjectPath = fallback
        }
        if #available(macOS 13.0, *) {
            launchAtLogin = manager.isLaunchAtLoginEnabled()
        }
    }
    
    private func chooseCloudflared() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.title = "cloudflared Yürütülebilir Dosyasını Seçin"
        
        if panel.runModal() == .OK, let url = panel.url {
            tempCloudflaredPath = url.path
        }
    }
    
    private func chooseMampPath() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.title = "MAMP Ana Dizinini Seçin"
        
        if panel.runModal() == .OK, let url = panel.url {
            tempMampPath = url.path
        }
    }
    
    private func choosePythonProjectPath() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.title = "Python Proje Dizinini Seçin"
        
        if panel.runModal() == .OK, let url = panel.url {
            tempPythonProjectPath = url.path
        }
    }
    
    private func saveMampPath() {
        let trimmed = tempMampPath.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        manager.mampBasePath = trimmed
        tempMampPath = manager.mampBasePath
    }
    
    private func savePythonProjectPath() {
        let trimmed = tempPythonProjectPath.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let expanded = (trimmed as NSString).expandingTildeInPath
        storedPythonProjectPath = expanded
        tempPythonProjectPath = expanded
        if let delegate = NSApp.delegate as? AppDelegate {
            delegate.constructMenu()
        }
    }
    
    private func saveCloudflaredPath() {
        let path = tempCloudflaredPath.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !path.isEmpty else { return }
        manager.cloudflaredExecutablePath = path
    }
    
    private func applyInterval() {
        let val = Int(intervalString) ?? Int(manager.checkInterval)
        let clamped = max(5, min(300, val))
        intervalString = String(clamped)
        manager.checkInterval = TimeInterval(clamped)
    }
    
    private func setLaunchAtLogin(_ newValue: Bool) {
        guard #available(macOS 13.0, *) else { return }
        launchAtLoginLoading = true
        manager.toggleLaunchAtLogin { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let enabled):
                    launchAtLogin = enabled
                case .failure(_):
                    launchAtLogin = manager.isLaunchAtLoginEnabled()
                }
                launchAtLoginLoading = false
            }
        }
    }
    
    private func resetSettings() {
        // Reset to defaults
        darkModeEnabled = false
        notificationsEnabled = true
        autoStartTunnels = false
        minimizeToTray = true
        showStatusInMenuBar = true
        accentColorName = "blue"
    }
}

// MARK: - Custom Styles
struct ModernButtonStyle: ButtonStyle {
    let color: Color
    let size: ButtonSize
    
    enum ButtonSize {
        case small, medium, large
        
        var padding: EdgeInsets {
            switch self {
            case .small: return EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)
            case .medium: return EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16)
            case .large: return EdgeInsets(top: 14, leading: 20, bottom: 14, trailing: 20)
            }
        }
        
        var font: Font {
            switch self {
            case .small: return .caption.bold()
            case .medium: return .subheadline.bold()
            case .large: return .headline.bold()
            }
        }
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(size.font)
            .foregroundColor(.white)
            .padding(size.padding)
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [color, color.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: color.opacity(0.3), radius: configuration.isPressed ? 2 : 4, x: 0, y: configuration.isPressed ? 1 : 2)
            }
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct ModernTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
            .cornerRadius(10)
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            }
    }
}

struct ModernToggleStyle: ToggleStyle {
    let accentColor: Color
    
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            
            Spacer()
            
            RoundedRectangle(cornerRadius: 16)
                .fill(configuration.isOn ? accentColor : Color.gray.opacity(0.3))
                .frame(width: 50, height: 30)
                .overlay {
                    Circle()
                        .fill(.white)
                        .frame(width: 26, height: 26)
                        .offset(x: configuration.isOn ? 10 : -10)
                        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                }
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        configuration.isOn.toggle()
                    }
                }
        }
    }
}

#Preview {
    SettingsView().environmentObject(TunnelManager())
}
