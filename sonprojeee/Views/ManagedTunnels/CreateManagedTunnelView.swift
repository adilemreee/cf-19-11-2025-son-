import SwiftUI
import AppKit

struct CreateManagedTunnelView: View {
    @EnvironmentObject var tunnelManager: TunnelManager
    @Environment(\.dismiss) var dismiss

    // Form State
    @State private var tunnelName: String = ""
    @State private var configName: String = ""
    @State private var hostname: String = ""
    @State private var portString: String = "80"
    @State private var documentRoot: String = ""
    @State private var updateVHost: Bool = false

    // UI State
    @State private var isCreating: Bool = false
    @State private var creationStatus: String = ""
    @State private var showAlert: Bool = false
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""
    @State private var alertType: ModernAlertType = .info
    @State private var alertAction: (() -> Void)?

    // Animation States
    @State private var headerOffset: CGFloat = -50
    @State private var contentOpacity: Double = 0
    @State private var buttonScale: CGFloat = 0.8

    // Validation computed property
    var isFormValid: Bool {
        !tunnelName.isEmpty && tunnelName.rangeOfCharacter(from: .whitespacesAndNewlines) == nil &&
        !configName.isEmpty && configName.rangeOfCharacter(from: CharacterSet(charactersIn: "/\\:")) == nil &&
        !hostname.isEmpty && hostname.contains(".") && hostname.rangeOfCharacter(from: .whitespacesAndNewlines) == nil &&
        !portString.isEmpty && Int(portString) != nil && (1...65535).contains(Int(portString)!) &&
        (!updateVHost || (!documentRoot.isEmpty && FileManager.default.fileExists(atPath: documentRoot)))
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
                        // Tunnel Configuration Card
                        modernTunnelConfigCard
                        
                        // MAMP Integration Card
                        modernMampIntegrationCard
                        
                        // Status Card (when creating)
                        if isCreating {
                            modernStatusCard
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
            if showAlert {
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
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "plus.app.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Yeni Yönetilen Tünel")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Cloudflare üzerinde yönetilen tünel oluşturun")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Progress indicator
            if isCreating {
                ProgressView(value: 0.5)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
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

    private var modernTunnelConfigCard: some View {
        TunnelCard(title: "Tünel Yapılandırması", icon: "network") {
            VStack(spacing: 16) {
                ModernTextField(
                    title: "Tünel Adı",
                    text: $tunnelName,
                    placeholder: "Cloudflare'deki benzersiz ad",
                    icon: "tag.fill"
                )
                .onChange(of: tunnelName) { _, _ in syncConfigName() }
                
                ModernTextField(
                    title: "Config Dosya Adı",
                    text: $configName,
                    placeholder: "Yerel .yml dosya adı",
                    icon: "doc.text.fill"
                )
                
                ModernTextField(
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
                    .textFieldStyle(TunnelTextFieldStyle())
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

    private var modernMampIntegrationCard: some View {
        TunnelCard(title: "MAMP Entegrasyonu", icon: "server.rack") {
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    Image(systemName: "folder.fill")
                        .foregroundColor(.orange)
                        .frame(width: 20)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Proje Kök Dizini")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        HStack {
                            TextField("MAMP site klasörü seçin", text: $documentRoot)
                                .textFieldStyle(ModernTextFieldStyle())
                            
                            Button(action: browseForDocumentRoot) {
                                Image(systemName: "folder.badge.plus")
                                    .foregroundColor(.blue)
                            }
                            .buttonStyle(TunnelIconButtonStyle())
                        }
                    }
                }
                
                ModernToggle(
                    title: "MAMP vHost Dosyasını Güncelle",
                    subtitle: "httpd-vhosts.conf dosyasına otomatik giriş ekler",
                    isOn: $updateVHost
                )
                .disabled(documentRoot.isEmpty || !FileManager.default.fileExists(atPath: documentRoot))
                
                if updateVHost {
                    ModernInfoBox(
                        message: "Değişikliklerin etkili olması için MAMP sunucularını yeniden başlatmanız gerekecek.",
                        type: .info
                    )
                }
            }
        }
    }

    private var modernStatusCard: some View {
        TunnelCard(title: "Oluşturma Durumu", icon: "gearshape.fill") {
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
            .buttonStyle(TunnelSecondaryButtonStyle())
            .keyboardShortcut(.cancelAction)
            
            Spacer()
            
            Button(action: startCreationProcess) {
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
            .buttonStyle(TunnelPrimaryButtonStyle())
            .disabled(isCreating || !isFormValid)
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
                        showAlert = false
                    }
                }
            
            ModernAlert(
                title: alertTitle,
                message: alertMessage,
                type: alertType
            ) {
                withAnimation(.easeOut(duration: 0.2)) {
                    showAlert = false
                }
                alertAction?()
            }
        }
        .transition(.opacity.combined(with: .scale))
    }

    // MARK: - Helper Functions

    private func setupInitialValues() {
        portString = "\(tunnelManager.defaultMampPort)"
    }

    private func animateEntry() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            headerOffset = 0
            contentOpacity = 1
            buttonScale = 1
        }
    }

    private func syncConfigName() {
        if configName.isEmpty && !tunnelName.isEmpty {
            var safeName = tunnelName.replacingOccurrences(of: " ", with: "-").lowercased()
            safeName = safeName.filter { "abcdefghijklmnopqrstuvwxyz0123456789-_".contains($0) }
            configName = safeName
        }
    }

    func browseForDocumentRoot() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "MAMP Proje Kök Dizinini Seçin"
        
        if !documentRoot.isEmpty && FileManager.default.fileExists(atPath: documentRoot) {
            panel.directoryURL = URL(fileURLWithPath: documentRoot)
        } else if FileManager.default.fileExists(atPath: tunnelManager.mampSitesDirectoryPath) {
            panel.directoryURL = URL(fileURLWithPath: tunnelManager.mampSitesDirectoryPath)
        }

        panel.begin { response in
            if response == .OK, let url = panel.url {
                DispatchQueue.main.async {
                    self.documentRoot = url.path
                }
            }
        }
    }

    private func startCreationProcess() {
        guard isFormValid else {
            showModernAlert(
                title: "Form Hatası",
                message: "Lütfen tüm gerekli alanları doğru şekilde doldurun.",
                type: .error
            )
            return
        }
        
        guard let portIntValue = Int(portString), (1...65535).contains(portIntValue) else {
            showModernAlert(
                title: "Port Hatası",
                message: "Geçersiz port numarası. 1-65535 arasında bir değer girin.",
                type: .error
            )
            return
        }

        isCreating = true
        creationStatus = "'\(tunnelName)' tüneli Cloudflare'da oluşturuluyor..."

        tunnelManager.createTunnel(name: tunnelName) { createResult in
            DispatchQueue.main.async {
                switch createResult {
                case .success(let tunnelData):
                    creationStatus = "Yapılandırma dosyası '\(configName).yml' oluşturuluyor..."
                    let finalDocRoot = (self.updateVHost && !self.documentRoot.isEmpty && FileManager.default.fileExists(atPath: self.documentRoot)) ? self.documentRoot : nil

                    tunnelManager.createConfigFile(
                        configName: self.configName,
                        tunnelUUID: tunnelData.uuid,
                        credentialsPath: tunnelData.jsonPath,
                        hostname: self.hostname,
                        port: self.portString,
                        documentRoot: finalDocRoot
                    ) { configResult in
                        DispatchQueue.main.async {
                            self.isCreating = false
                            
                            switch configResult {
                            case .success(let configPath):
                                var message = "Tünel '\(self.tunnelName)' ve yapılandırma '\((configPath as NSString).lastPathComponent)' başarıyla oluşturuldu."
                                if finalDocRoot != nil {
                                    message += "\n\nMAMP vHost dosyası güncellenmeye çalışıldı. MAMP sunucularını yeniden başlatmanız gerekebilir."
                                }
                                
                                self.showModernAlert(
                                    title: "Tünel Oluşturuldu",
                                    message: message,
                                    type: .success
                                ) {
                                    dismiss()
                                }

                            case .failure(let configError):
                                self.showModernAlert(
                                    title: "Yapılandırma Hatası",
                                    message: "Tünel oluşturuldu ancak yapılandırma/MAMP hatası:\n\(configError.localizedDescription)",
                                    type: .error
                                )
                            }
                        }
                    }
                    
                case .failure(let createError):
                    self.isCreating = false
                    self.showModernAlert(
                        title: "Oluşturma Hatası",
                        message: "Cloudflare'da tünel oluşturma hatası:\n\(createError.localizedDescription)",
                        type: .error
                    )
                }
            }
        }
    }

    private func showModernAlert(title: String, message: String, type: ModernAlertType, action: (() -> Void)? = nil) {
        alertTitle = title
        alertMessage = message
        alertType = type
        alertAction = action
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            showAlert = true
        }
    }
}

// MARK: - Modern UI Components

struct TunnelCard<Content: View>: View {
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
                    .foregroundColor(.blue)
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

struct ModernTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                TextField(placeholder, text: $text)
                    .textFieldStyle(TunnelTextFieldStyle())
            }
        }
    }
}

struct ModernToggle: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: .blue))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct ModernInfoBox: View {
    let message: String
    let type: InfoType
    
    enum InfoType {
        case info, warning, success
        
        var color: Color {
            switch self {
            case .info: return .blue
            case .warning: return .orange
            case .success: return .green
            }
        }
        
        var icon: String {
            switch self {
            case .info: return "info.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .success: return "checkmark.circle.fill"
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: type.icon)
                .foregroundColor(type.color)
                .font(.caption)
            
            Text(message)
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(type.color.opacity(0.1))
        )
    }
}

// MARK: - Modern Styles for CreateManagedTunnelView

struct TunnelTextFieldStyle: TextFieldStyle {
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

struct TunnelPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(LinearGradient(
                        colors: [.blue, .blue.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .shadow(color: .blue.opacity(0.3), radius: 4, x: 0, y: 2)
            )
            .foregroundColor(.white)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct TunnelSecondaryButtonStyle: ButtonStyle {
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

struct TunnelIconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: 32, height: 32)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(.controlBackgroundColor))
                    .stroke(Color(.separatorColor), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Modern Alert System

enum ModernAlertType {
    case success, error, info, warning
    
    var color: Color {
        switch self {
        case .success: return .green
        case .error: return .red
        case .info: return .blue
        case .warning: return .orange
        }
    }
    
    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        }
    }
}

struct ModernAlert: View {
    let title: String
    let message: String
    let type: ModernAlertType
    let action: () -> Void
    
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Icon
            Image(systemName: type.icon)
                .font(.system(size: 40))
                .foregroundColor(type.color)
                .symbolEffect(.bounce, options: .repeating, value: isAnimating)
            
            // Content
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
            
            // Button
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