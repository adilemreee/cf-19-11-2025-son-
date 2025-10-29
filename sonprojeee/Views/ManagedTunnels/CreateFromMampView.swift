import SwiftUI
import AppKit // For FileManager, NSWorkspace

// Modern Alert View for MAMP View
struct MampAlertView: View {
    let title: String
    let message: String
    let type: AlertType
    let action: () -> Void
    
    @State private var isAnimating = false
    
    enum AlertType {
        case success, error, info
        
        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .error: return "exclamationmark.triangle.fill"
            case .info: return "info.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .success: return .green
            case .error: return .red
            case .info: return .blue
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: type.icon)
                .font(.system(size: 40))
                .foregroundColor(type.color)
                .symbolEffect(.bounce, options: .repeating, value: isAnimating)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Button(action: action) {
                Text("Tamam")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 120, height: 36)
                    .background(type.color)
                    .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(24)
        .frame(width: 320)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.windowBackgroundColor))
                .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

struct CreateFromMampView: View {
    @EnvironmentObject var tunnelManager: TunnelManager
    @Environment(\.dismiss) var dismiss

    // Form State
    @State private var mampSites: [String] = []
    @State private var selectedSite: String = ""
    @State private var tunnelName: String = ""
    @State private var configName: String = ""
    @State private var hostname: String = ""
    @State private var portString: String = ""

    // UI State
    @State private var isCreating: Bool = false
    @State private var creationStatus: String = ""
    @State private var showErrorAlert: Bool = false
    @State private var errorMessage: String = ""
    @State private var showSuccessAlert: Bool = false
    @State private var successMessage: String = ""

    // Modern alert state
    @State private var showCustomAlert: Bool = false
    @State private var customAlertTitle: String = ""
    @State private var customAlertMessage: String = ""
    @State private var customAlertType: MampAlertView.AlertType = .info
    @State private var customAlertAction: (() -> Void)?
    
    // Animation states
    @State private var headerOffset: CGFloat = -50
    @State private var contentOpacity: Double = 0
    @State private var buttonScale: CGFloat = 0.8

    // Computed Properties
    var documentRoot: String {
        guard !selectedSite.isEmpty else { return "" }
        let sitesPath = tunnelManager.mampSitesDirectoryPath.hasSuffix("/") ? String(tunnelManager.mampSitesDirectoryPath.dropLast()) : tunnelManager.mampSitesDirectoryPath
        return sitesPath.appending("/").appending(selectedSite)
    }
    var mampPortString: String { "\(tunnelManager.defaultMampPort)" }
    var documentRootExists: Bool { !documentRoot.isEmpty && FileManager.default.fileExists(atPath: documentRoot) }

    var isFormValid: Bool {
         !selectedSite.isEmpty &&
         !tunnelName.isEmpty && tunnelName.rangeOfCharacter(from: .whitespacesAndNewlines) == nil &&
         !configName.isEmpty && configName.rangeOfCharacter(from: CharacterSet(charactersIn: "/\\:")) == nil &&
         !hostname.isEmpty && hostname.contains(".") && hostname.rangeOfCharacter(from: .whitespacesAndNewlines) == nil &&
         documentRootExists &&
         !portString.isEmpty && Int(portString) != nil && (1...65535).contains(Int(portString)!)
    }

    var body: some View {
        ZStack {
            // Background with subtle gradient
            LinearGradient(
                colors: [
                    Color(.windowBackgroundColor),
                    Color(.windowBackgroundColor).opacity(0.95)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Modern Header
                modernHeader
                    .offset(y: headerOffset)
                    .opacity(contentOpacity)

                // Main Content
                ScrollView {
                    VStack(spacing: 24) {
                        if mampSites.isEmpty {
                            modernEmptyStateCard
                        } else {
                            // Site Selection Card
                            modernSiteSelectionCard
                            
                            // Tunnel Configuration Card
                            modernTunnelConfigCard
                            
                            // Info Card
                            modernInfoCard
                            
                            // Status Card (when creating)
                            if isCreating {
                                modernStatusCard
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                }
                .opacity(contentOpacity)

                // Modern Action Bar
                modernActionBar
                    .scaleEffect(buttonScale)
                    .opacity(contentOpacity)
            }
        }
        .frame(width: 580, height: 520)
        .onAppear {
            setupInitialValues()
            animateEntry()
        }
        .overlay {
            if showCustomAlert {
                modernAlertOverlay
            }
        }
    }

    // MARK: - Modern UI Components
    
    private var modernHeader: some View {
        VStack(spacing: 12) {
            HStack {
                // Icon with gradient background
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [.orange, .red],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "server.rack")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("MAMP Sitesinden Tünel")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Mevcut MAMP projelerinizden tünel oluşturun")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Progress indicator
            if isCreating {
                ProgressView(value: 0.5)
                    .progressViewStyle(LinearProgressViewStyle(tint: .orange))
                    .scaleEffect(y: 0.5)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.controlBackgroundColor))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .padding(.horizontal, 24)
        .padding(.top, 16)
    }
    
    private var modernEmptyStateCard: some View {
        MampCard(title: "MAMP Siteleri Bulunamadı", icon: "exclamationmark.triangle.fill") {
            VStack(spacing: 16) {
                Image(systemName: "folder.badge.questionmark")
                    .font(.system(size: 48))
                    .foregroundColor(.orange)
                
                VStack(spacing: 8) {
                    Text("MAMP site dizininde proje bulunamadı")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                    
                    Text(tunnelManager.mampSitesDirectoryPath)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                Button(action: {
                    NSWorkspace.shared.open(URL(fileURLWithPath: tunnelManager.mampSitesDirectoryPath))
                }) {
                    HStack {
                        Image(systemName: "folder")
                        Text("MAMP Dizinini Aç")
                    }
                }
                .buttonStyle(MampPrimaryButtonStyle())
            }
        }
    }
    
    private var modernSiteSelectionCard: some View {
        MampCard(title: "Site Seçimi", icon: "list.bullet") {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("MAMP Sitesi")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Picker("", selection: $selectedSite) {
                        Text("Site seçiniz").tag("")
                        ForEach(mampSites, id: \.self) { site in
                            Text(site).tag(site)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: selectedSite) { _, newSite in autoFillDetails(for: newSite) }
                }
                
                if !selectedSite.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Proje Kök Dizini")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        HStack {
                            HStack {
                                Image(systemName: documentRootExists ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                    .foregroundColor(documentRootExists ? .green : .red)
                                
                                Text((documentRoot as NSString).abbreviatingWithTildeInPath)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(documentRootExists ? .primary : .red)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            }
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color(.textBackgroundColor))
                                    .stroke(documentRootExists ? Color.green.opacity(0.3) : Color.red.opacity(0.3), lineWidth: 1)
                            )
                            
                            Spacer()
                        }
                    }
                }
            }
        }
    }
    
    private var modernTunnelConfigCard: some View {
        MampCard(title: "Tünel Yapılandırması", icon: "network") {
            VStack(spacing: 16) {
                MampTextField(
                    title: "Tünel Adı",
                    text: $tunnelName,
                    placeholder: "Cloudflare'deki benzersiz ad",
                    icon: "tag.fill"
                )
                
                MampTextField(
                    title: "Config Dosya Adı",
                    text: $configName,
                    placeholder: "Yerel .yml dosya adı",
                    icon: "doc.text.fill"
                )
                
                MampTextField(
                    title: "Hostname",
                    text: $hostname,
                    placeholder: "example.com",
                    icon: "globe"
                )
                
                HStack(spacing: 12) {
                    Image(systemName: "network")
                        .foregroundColor(.blue)
                        .frame(width: 20)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Yerel Port")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        TextField("Port numarası", text: $portString)
                            .textFieldStyle(MampTextFieldStyle())
                            .frame(maxWidth: 120)
                            .onChange(of: portString) { _, newValue in
                                let filtered = newValue.filter { "0123456789".contains($0) }
                                let clamped = String(filtered.prefix(5))
                                if clamped != newValue {
                                    DispatchQueue.main.async { portString = clamped }
                                }
                            }
                    }
                    
                    Spacer()
                }
            }
        }
    }
    
    private var modernInfoCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "info.circle.fill")
                .foregroundColor(.blue)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Önemli Not")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text("Bu işlem MAMP vHost dosyasını otomatik günceller. Değişikliklerin etkili olması için MAMP sunucularını yeniden başlatmanız gerekir.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.blue.opacity(0.1))
                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var modernStatusCard: some View {
        MampCard(title: "Oluşturma Durumu", icon: "gearshape.fill") {
            HStack(spacing: 12) {
                ProgressView()
                    .scaleEffect(0.8)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(creationStatus)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("Lütfen bekleyiniz...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
    }
    
    private var modernActionBar: some View {
        HStack(spacing: 16) {
            Button("İptal") {
                if !isCreating {
                    withAnimation(.easeOut(duration: 0.3)) {
                        dismiss()
                    }
                }
            }
            .buttonStyle(MampSecondaryButtonStyle())
            .keyboardShortcut(.cancelAction)
            
            Spacer()
            
            Button(action: startMampCreationProcess) {
                HStack(spacing: 8) {
                    if isCreating {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "plus.circle.fill")
                    }
                    Text("Tünel Oluştur")
                }
            }
            .buttonStyle(MampPrimaryButtonStyle())
            .disabled(isCreating || !isFormValid || mampSites.isEmpty)
            .keyboardShortcut(.defaultAction)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .background(
            Rectangle()
                .fill(Color(.controlBackgroundColor))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: -2)
        )
    }
    
    private var modernAlertOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeOut(duration: 0.2)) {
                        showCustomAlert = false
                    }
                }
            
            MampAlertView(
                title: customAlertTitle,
                message: customAlertMessage,
                type: customAlertType
            ) {
                withAnimation(.easeOut(duration: 0.2)) {
                    showCustomAlert = false
                }
                customAlertAction?()
            }
        }
        .transition(.opacity.combined(with: .scale))
    }

    // MARK: - Helper Functions
    
    private func setupInitialValues() {
        loadMampSites()
        portString = "\(tunnelManager.defaultMampPort)"
    }
    
    private func animateEntry() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            headerOffset = 0
            contentOpacity = 1
            buttonScale = 1
        }
    }

    // Helper Views
    private struct FormField: View {
        let label: String
        @Binding var text: String
        let placeholder: String
        
        var body: some View {
            HStack {
                Text(label)
                    .frame(width: 100, alignment: .trailing)
                TextField(placeholder, text: $text)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }

    private struct EmptyStateView: View {
        let mampSitesDirectoryPath: String
        
        var body: some View {
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.orange)
                
                Text("MAMP site dizininde proje klasörü bulunamadı")
                    .font(.headline)
                    .foregroundColor(.orange)
                
                Text("Dizin: \(mampSitesDirectoryPath)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Button(action: { NSWorkspace.shared.open(URL(fileURLWithPath: mampSitesDirectoryPath)) }) {
                    Label("MAMP Site Dizinini Aç", systemImage: "folder")
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity)
            .padding()
        }
    }

    private func loadMampSites() {
        mampSites = tunnelManager.scanMampSitesFolder()
        selectedSite = ""
        autoFillDetails(for: "")
    }

    private func autoFillDetails(for siteName: String) {
        if !siteName.isEmpty {
            let safeName = siteName.lowercased().filter { "abcdefghijklmnopqrstuvwxyz0123456789-_".contains($0) }
            if tunnelName.isEmpty || configName.isEmpty || hostname.hasSuffix(".adilemre.xyz") || tunnelName == configName {
                tunnelName = safeName
                configName = safeName
                hostname = "\(safeName).adilemre.xyz"
            }
        } else {
            tunnelName = ""
            configName = ""
            hostname = ""
        }
    }

    private func startMampCreationProcess() {
        guard isFormValid else {
            customAlertTitle = "Hata"
            customAlertMessage = "Lütfen geçerli bir MAMP sitesi seçin ve tüm alanları doğru doldurun."
            if !documentRootExists && !selectedSite.isEmpty {
                customAlertMessage += "\n\nSeçilen site için proje kökü bulunamadı: \(documentRoot)"
            }
            customAlertType = .error
            showCustomAlert = true
            return
        }

        isCreating = true
        creationStatus = "'\(tunnelName)' tüneli Cloudflare'da oluşturuluyor..."

        tunnelManager.createTunnel(name: tunnelName) { createResult in
            DispatchQueue.main.async {
                switch createResult {
                case .success(let tunnelData):
                    creationStatus = "Yapılandırma dosyası '\(configName).yml' oluşturuluyor..."

                    tunnelManager.createConfigFile(configName: self.configName, tunnelUUID: tunnelData.uuid, credentialsPath: tunnelData.jsonPath, hostname: self.hostname, port: self.portString, documentRoot: self.documentRoot) { configResult in
                        DispatchQueue.main.async {
                            switch configResult {
                            case .success(let configPath):
                                isCreating = false
                                customAlertTitle = "Başarılı"
                                customAlertMessage = """
                                    MAMP sitesi '\(selectedSite)' için tünel '\(tunnelName)' ve yapılandırma '\((configPath as NSString).lastPathComponent)' başarıyla oluşturuldu.

                                    MAMP Apache yapılandırma dosyaları (vhost ve httpd.conf) güncellenmeye çalışıldı.

                                    ⚠️ Ayarların etkili olması için MAMP sunucularını yeniden başlatmanız GEREKİR!
                                    """
                                customAlertType = .success
                                customAlertAction = { dismiss() }
                                showCustomAlert = true

                            case .failure(let configError):
                                customAlertTitle = "Hata"
                                customAlertMessage = "Tünel oluşturuldu ancak yapılandırma/MAMP hatası:\n\(configError.localizedDescription)"
                                if configError.localizedDescription.contains("Yazma izni hatası") {
                                    customAlertMessage += "\n\nLütfen vHost dosyası için yazma izinlerini kontrol edin."
                                }
                                customAlertType = .error
                                showCustomAlert = true
                                isCreating = false
                                creationStatus = "Hata."
                            }
                        }
                    }
                case .failure(let createError):
                    customAlertTitle = "Hata"
                    customAlertMessage = "Cloudflare'da tünel oluşturma hatası:\n\(createError.localizedDescription)"
                    customAlertType = .error
                    showCustomAlert = true
                    isCreating = false
                    creationStatus = "Hata."
                }
            }
        }
    }
} // End CreateFromMampView

// MARK: - Modern UI Components for MAMP

struct MampCard<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(.orange)
                    .font(.system(size: 16, weight: .medium))
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            content
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.controlBackgroundColor))
                .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
        )
    }
}

struct MampTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.orange)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                TextField(placeholder, text: $text)
                    .textFieldStyle(MampTextFieldStyle())
            }
        }
    }
}

// MARK: - MAMP Specific Styles

struct MampTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(.textBackgroundColor))
                    .stroke(Color(.separatorColor), lineWidth: 1)
            )
    }
}

struct MampPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(LinearGradient(
                        colors: [.orange, .orange.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .shadow(color: .orange.opacity(0.3), radius: 4, x: 0, y: 2)
            )
            .foregroundColor(.white)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct MampSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.controlBackgroundColor))
                    .stroke(Color(.separatorColor), lineWidth: 1)
            )
            .foregroundColor(.primary)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

