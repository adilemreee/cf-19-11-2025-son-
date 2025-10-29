import SwiftUI
import Cocoa // NSStatusItem, NSMenu, NSAlert, NSTextField, NSStackView etc.
import Combine // ObservableObject, @Published, AnyCancellable
import AppKit // Required for NSAlert, NSTextField, NSStackView etc.
import UserNotifications // For notifications
import ServiceManagement // For Launch At Login (macOS 13+)

class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    var statusItem: NSStatusItem?
    var tunnelManager: TunnelManager! // Should be initialized in applicationDidFinishLaunching
    private var cancellables = Set<AnyCancellable>()

    // Window references - weak to avoid retain cycles
    weak var settingsWindow: NSWindow?
    weak var createManagedTunnelWindow: NSWindow?
    weak var createFromMampWindow: NSWindow?
    weak var quickTunnelWindow: NSWindow?
    weak var dashboardWindow: NSWindow?

    // --- MAMP Control Constants ---
    internal let mampStartScript = "start.sh"
    internal let mampStopScript = "stop.sh"
    internal var mampBinPath: String {
        let base = tunnelManager?.mampBasePath ?? "/Applications/MAMP"
        return (base as NSString).appendingPathComponent("bin")
    }
    // --- End MAMP Control Constants ---
    
    // --- Python Betik Sabitleri (GÜNCELLENDİ) ---
    // DİKKAT: Bu yolları KENDİ sisteminize ve projenize göre DÜZENLEYİN!
    internal var pythonProjectDirectoryPath: String {
        let stored = UserDefaults.standard.string(forKey: "pythonProjectPath") ?? "/Users/adilemre/Documents/PANEL-main"
        return (stored as NSString).expandingTildeInPath
    }
    private let pythonVenvName = "venv" // Sanal ortam klasörünün adı (genellikle venv)
    internal let pythonScriptPath = "app.py" // Proje DİZİNİNE GÖRE betiğin yolu VEYA TAM YOLU
    // Eski pythonInterpreterPath (/usr/bin/python3 vb.) artık doğrudan kullanılmayacak, venv içindeki kullanılacak.
    // --- BİTİŞ: Python Betik Sabitleri (GÜNCELLENDİ) ---

    // --- Çalışan Python İşlemi Takibi ---
    internal var pythonAppProcess: Process?


    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // 1. Initialize the Tunnel Manager
        tunnelManager = TunnelManager()

        // 2. Observe notifications from TunnelManager
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSendUserNotification(_:)),
            name: .sendUserNotification,
            object: tunnelManager // Only listen to notifications from our tunnelManager instance
        )

        // 3. Request Notification Permissions & Set Delegate
        requestNotificationAuthorization()
        UNUserNotificationCenter.current().delegate = self

        // 4. Create the Status Bar Item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            if let image = NSImage(systemSymbolName: "cloud.fill", accessibilityDescription: "Cloudflared Tunnels") {
                button.image = image
                button.imagePosition = .imageLeading
            } else {
                button.title = "CfT" // Fallback text
                print("⚠️ SF Symbol 'cloud.fill' bulunamadı. Metin kullanılıyor.")
            }
            button.action = #selector(statusBarButtonClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp]) // Handle both clicks
            button.target = self
        }

        // 5. Build the initial menu
        constructMenu()

        // 6. Observe changes in the TunnelManager's published properties
        observeTunnelManagerChanges()

        // Check executable status on launch
        tunnelManager.checkCloudflaredExecutable()
    }

    func applicationWillTerminate(_ notification: Notification) {
        print("Uygulama kapanıyor...")
        NotificationCenter.default.removeObserver(self) // Clean up observer
        tunnelManager?.stopMonitoringCloudflaredDirectory()
        // Stop all tunnels synchronously during shutdown
        tunnelManager?.stopAllTunnels(synchronous: true)
        print("Kapanış işlemleri tamamlandı.")
        Thread.sleep(forTimeInterval: 0.2) // Brief pause for async ops
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // If dock icon (if shown) is clicked, open settings if no other window is visible
        if !flag {
            openSettingsWindowAction()
        }
        return true
    }

    // MARK: - Observation Setup
    private func observeTunnelManagerChanges() {
        guard let tunnelManager = tunnelManager else { return }

        // Observe managed tunnels
        tunnelManager.$tunnels
            .debounce(for: .milliseconds(250), scheduler: DispatchQueue.main) // Slightly longer debounce
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.constructMenu() }
            .store(in: &cancellables)

        // Observe quick tunnels
        tunnelManager.$quickTunnels
            .debounce(for: .milliseconds(250), scheduler: DispatchQueue.main)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] quickTunnels in 
                print("🔄 QuickTunnels değişti, menü güncelleniyor. Toplam: \(quickTunnels.count)")
                for (i, tunnel) in quickTunnels.enumerated() {
                    print("   [\(i)] \(tunnel.localURL) -> URL: \(tunnel.publicURL ?? "nil")")
                }
                self?.constructMenu() 
            }
            .store(in: &cancellables)

        // Observe cloudflared path changes
        tunnelManager.$cloudflaredExecutablePath
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.constructMenu() } // Rebuild menu on path change
            .store(in: &cancellables)

        tunnelManager.$mampBasePath
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.constructMenu() }
            .store(in: &cancellables)
    }

    // MARK: - Status Bar Click
    @objc func statusBarButtonClicked(_ sender: NSStatusBarButton) {
        // Show menu for left click, right click, or ctrl-click
        statusItem?.menu = statusItem?.menu // Ensure menu is attached
        statusItem?.button?.performClick(nil) // Programmatically open the menu
    }

    // MARK: - Notification Handling (Receiving from TunnelManager)
    @objc func handleSendUserNotification(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let identifier = userInfo["identifier"] as? String,
              let title = userInfo["title"] as? String,
              let body = userInfo["body"] as? String else {
            print("⚠️ Geçersiz kullanıcı bildirimi alındı.")
            return
        }
        sendUserNotification(identifier: identifier, title: title, body: body)
    }
    
    @objc func startPythonAppAction() {
        if let existingProcess = pythonAppProcess, existingProcess.isRunning {
            // ... (zaten çalışıyor kontrolü aynı) ...
            return
        }

        // --- BAŞLANGIÇ: Venv ve Betik Yollarını Hesaplama ---
        let expandedProjectDirPath = (pythonProjectDirectoryPath as NSString).expandingTildeInPath
        let venvPath = expandedProjectDirPath.appending("/").appending(pythonVenvName)
        let venvInterpreterPath = venvPath.appending("/bin/python") // macOS/Linux için standart

        // Betik yolunu belirle: Eğer "/" içermiyorsa proje dizinine göre, içeriyorsa tam yol kabul et
        let finalScriptPath: String
        if pythonScriptPath.contains("/") { // Tam yol gibi görünüyor
             finalScriptPath = (pythonScriptPath as NSString).expandingTildeInPath
        } else { // Proje dizinine göre
             finalScriptPath = expandedProjectDirPath.appending("/").appending(pythonScriptPath)
        }

        // Gerekli dosyaların varlığını kontrol et
        guard FileManager.default.fileExists(atPath: expandedProjectDirPath) else {
            print("❌ Hata: Python proje dizini bulunamadı: \(expandedProjectDirPath)")
            showErrorAlert(message: "Python proje dizini bulunamadı:\n\(expandedProjectDirPath)")
            return
        }
         guard FileManager.default.fileExists(atPath: finalScriptPath) else {
            print("❌ Hata: Python betiği bulunamadı: \(finalScriptPath)")
            showErrorAlert(message: "Python betik dosyası bulunamadı:\n\(finalScriptPath)")
            return
        }
        // --- BİTİŞ: Venv ve Betik Yollarını Hesaplama ---


        // --- BAŞLANGIÇ: Çalıştırma Mantığını Güncelleme (Venv Öncelikli) ---
        print("🚀 Python betiği başlatılıyor: \(finalScriptPath)")
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            let process = Process()
            var interpreterToUse = "" // Kullanılacak yorumlayıcı yolu

            // Venv yorumlayıcısını kontrol et
            if FileManager.default.isExecutableFile(atPath: venvInterpreterPath) {
                print("   Sanal ortam (venv) yorumlayıcısı kullanılacak: \(venvInterpreterPath)")
                interpreterToUse = venvInterpreterPath
                process.executableURL = URL(fileURLWithPath: interpreterToUse)
                process.arguments = [finalScriptPath] // Argüman sadece betik yolu
            } else {
                // Venv bulunamadı, /usr/bin/env python3'ü fallback olarak kullan
                interpreterToUse = "/usr/bin/env" // Fallback
                print("⚠️ Uyarı: Sanal ortam yorumlayıcısı bulunamadı veya çalıştırılabilir değil: \(venvInterpreterPath). Fallback kullanılıyor: \(interpreterToUse) python3")
                process.executableURL = URL(fileURLWithPath: interpreterToUse)
                process.arguments = ["python3", finalScriptPath] // Fallback argümanları
            }

            // Çalışma dizinini ayarla (çok önemli)
            process.currentDirectoryURL = URL(fileURLWithPath: expandedProjectDirPath)

            // Termination Handler (içerik aynı, sadece log mesajını güncelleyebiliriz)
            process.terminationHandler = { terminatedProcess in
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    print("🏁 Python betiği sonlandı (\((finalScriptPath as NSString).lastPathComponent)). Yorumlayıcı: \(interpreterToUse)")
                    self.pythonAppProcess = nil
                    self.constructMenu()
                }
            }
            // --- BİTİŞ: Çalıştırma Mantığını Güncelleme ---

            do {
                try process.run()
                DispatchQueue.main.async {
                     print("✅ Python betiği başlatıldı: \(finalScriptPath), PID: \(process.processIdentifier), Yorumlayıcı: \(interpreterToUse)")
                     self.pythonAppProcess = process
                     self.constructMenu()
                     self.sendUserNotification(identifier: "python_app_started_\(UUID().uuidString)",
                                                title: "Python Uygulaması Başlatıldı",
                                                body: "\((finalScriptPath as NSString).lastPathComponent) çalıştırıldı (PID: \(process.processIdentifier)).")
                }
            } catch {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    print("❌ Python betiği çalıştırılırken hata oluştu: \(error)")
                    self.showErrorAlert(message: "Python betiği '\(finalScriptPath)' çalıştırılırken bir hata oluştu:\n\(error.localizedDescription)")
                    self.pythonAppProcess = nil
                    self.constructMenu()
                }
            }
        }
    }
    // --- BİTİŞ: Python Uygulamasını Başlatma Eylemi (Venv için Güncellenmiş) ---

    // MARK: - User Notifications (Sending & Receiving System Notifications)
    func requestNotificationAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if let error = error { print("❌ Bildirim izni hatası: \(error.localizedDescription)") }
                else { print(granted ? "✅ Bildirim izni verildi." : "🚫 Bildirim izni reddedildi.") }
            }
        }
    }

    // Sends the actual system notification
    func sendUserNotification(identifier: String = UUID().uuidString, title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title; content.body = body; content.sound = .default
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                DispatchQueue.main.async { print("❌ Bildirim gönderilemedi: \(identifier) - \(error.localizedDescription)") }
            }
        }
    }

    // UNUserNotificationCenterDelegate: Handle user interaction with notification
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let identifier = response.notification.request.identifier
        print("Bildirim yanıtı alındı: \(identifier)")
        NSApp.activate(ignoringOtherApps: true) // Bring app to front

        if identifier == "cloudflared_not_found" {
            openSettingsWindowAction()
        } else if identifier.starts(with: "quick_url_") {
            let body = response.notification.request.content.body
            if let url = extractTryCloudflareURL(from: body) {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(url, forType: .string)
                sendUserNotification(identifier: "url_copied_from_notif_\(UUID().uuidString)", title: "URL Kopyalandı", body: url)
            }
        } else if identifier.starts(with: "vhost_success_") {
            askToOpenMampConfigFolder()
        }
        // Add more handlers as needed...
        completionHandler()
    }

    // Helper to extract URL from notification body
    private func extractTryCloudflareURL(from text: String) -> String? {
        let pattern = #"(https?://[a-zA-Z0-9-]+.trycloudflare.com)"#
        if let range = text.range(of: pattern, options: .regularExpression) { return String(text[range]) }
        return nil
    }
    
    // --- NEW ACTIONS TO OPEN SPECIFIC FILES ---
    @objc func openMampVHostFileAction() { // Opens vhost FILE
        guard let path = tunnelManager?.mampVHostConfPath, FileManager.default.fileExists(atPath: path) else {
            print("⚠️ MAMP vHost dosyası bulunamadı veya yol alınamadı: \(tunnelManager?.mampVHostConfPath ?? "N/A")")
            // Optional: Show error to user if desired
            // showErrorAlert(message: "MAMP httpd-vhosts.conf dosyası bulunamadı.")
            return
        }
        NSWorkspace.shared.open(URL(fileURLWithPath: path))
    }

    @objc func openMampHttpdConfFileAction() { // Opens httpd.conf FILE
        guard let path = tunnelManager?.mampHttpdConfPath, FileManager.default.fileExists(atPath: path) else {
            print("⚠️ MAMP httpd.conf dosyası bulunamadı veya yol alınamadı: \(tunnelManager?.mampHttpdConfPath ?? "N/A")")
            // Optional: Show error to user if desired
            // showErrorAlert(message: "MAMP httpd.conf dosyası bulunamadı.")
            return
        }
        NSWorkspace.shared.open(URL(fileURLWithPath: path))
    }
    
 
    // --- END NEW ACTIONS ---
    
    // --- YENİ: Python Uygulamasını Durdurma Eylemi ---
    @objc func stopPythonAppAction() {
        guard let process = pythonAppProcess, process.isRunning else {
            print("ℹ️ Durdurulacak çalışan Python betiği bulunamadı.")
            // Eğer referans kalmış ama işlem çalışmıyorsa temizle ve menüyü güncelle
            if pythonAppProcess != nil && !pythonAppProcess!.isRunning {
                 DispatchQueue.main.async {
                     self.pythonAppProcess = nil
                     self.constructMenu()
                 }
            }
            return
        }

        print("🛑 Python betiği durduruluyor (PID: \(process.processIdentifier))...")
        process.terminate() // SIGTERM gönderir

        // Termination handler zaten pythonAppProcess'i nil yapacak ve menüyü güncelleyecek.
        // İsteğe bağlı olarak burada hemen bir bildirim gönderebiliriz:
        DispatchQueue.main.async {
             self.sendUserNotification(identifier: "python_app_stopping_\(UUID().uuidString)",
                                        title: "Python Uygulaması Durduruluyor",
                                        body: "\((self.pythonScriptPath as NSString).lastPathComponent) için durdurma sinyali gönderildi.")
             // İsteğe bağlı: Kullanıcıya daha hızlı geri bildirim için menüyü hemen güncelleyebiliriz,
             // ancak termination handler'ın çalışmasını beklemek durumu daha doğru yansıtır.
             // self.constructMenu() // İsterseniz bu satırı açabilirsiniz.
        }
    }
    // --- BİTİŞ: Python Uygulamasını Durdurma Eylemi ---

    // MARK: - Modern Menu Construction
    @objc func constructMenu() {
        constructModernMenu()
    }

    // MARK: - Menu Actions (@objc Wrappers)

    // Managed Tunnel Actions
    @objc func toggleManagedTunnelAction(_ sender: NSMenuItem) { guard let tunnel = sender.representedObject as? TunnelInfo else { return }; tunnelManager?.toggleManagedTunnel(tunnel) }
    @objc func startAllManagedTunnelsAction() { tunnelManager?.startAllManagedTunnels() }
    @objc func stopAllTunnelsAction() { tunnelManager?.stopAllTunnels(synchronous: false) } // Default async stop
    @objc func refreshManagedTunnelListAction() { tunnelManager?.findManagedTunnels() }
    @objc func openConfigFileAction(_ sender: NSMenuItem) {
        guard let tunnel = sender.representedObject as? TunnelInfo, let path = tunnel.configPath else { return }
        NSWorkspace.shared.open(URL(fileURLWithPath: path))
    }

    @objc func deleteTunnelAction(_ sender: NSMenuItem) {
        guard let tunnel = sender.representedObject as? TunnelInfo, tunnel.isManaged else { return }
        let alert = NSAlert()
        alert.messageText = "'\(tunnel.name)' Tünelini Sil"
        alert.informativeText = "Bu işlem tüneli Cloudflare'dan kalıcı olarak silecektir.\n\n⚠️ BU İŞLEM GERİ ALINAMAZ! ⚠️\n\nEmin misiniz?"
        alert.alertStyle = .critical
        alert.addButton(withTitle: "Evet, Kalıcı Olarak Sil")
        alert.addButton(withTitle: "İptal")
        if alert.buttons.count > 0 { alert.buttons[0].hasDestructiveAction = true }

        DispatchQueue.main.async {
            NSApp.activate(ignoringOtherApps: true)
            let response = alert.runModal()

            if response == .alertFirstButtonReturn {
                print("Silme işlemi başlatılıyor: \(tunnel.name)")
                self.tunnelManager?.deleteTunnel(tunnelInfo: tunnel) { result in
                    DispatchQueue.main.async {
                        switch result {
                        case .success:
                            self.sendUserNotification(identifier:"deleted_\(tunnel.id)", title: "Tünel Silindi", body: "'\(tunnel.name)' Cloudflare'dan silindi.")
                            self.askToDeleteLocalFiles(for: tunnel)
                            self.tunnelManager?.findManagedTunnels() // Refresh list
                        case .failure(let error):
                            self.showErrorAlert(message: "'\(tunnel.name)' tüneli silinirken hata:\n\(error.localizedDescription)")
                        }
                    }
                }
            } else {
                print("Silme iptal edildi.")
            }
        }
    }

    @objc func routeDnsForTunnelAction(_ sender: NSMenuItem) {
        guard let tunnel = sender.representedObject as? TunnelInfo, tunnel.isManaged, let tunnelManager = tunnelManager else { return }
        let suggestedHostname = tunnelManager.findHostname(for: tunnel.configPath ?? "") ?? "\(tunnel.name.filter { $0.isLetter || $0.isNumber || $0 == "-" }).adilemre.xyz"

        let alert = NSAlert()
        alert.messageText = "DNS Kaydı Yönlendir"
        alert.informativeText = "'\(tunnel.name)' (UUID: \(tunnel.uuidFromConfig ?? "N/A")) tüneline yönlendirilecek hostname'i girin:"
        alert.addButton(withTitle: "Yönlendir")
        alert.addButton(withTitle: "İptal")

        let inputField = NSTextField(frame: NSRect(x: 0, y: 0, width: 300, height: 24))
        inputField.stringValue = suggestedHostname
        inputField.placeholderString = "örn: app.alanadiniz.com"
        alert.accessoryView = inputField
        alert.window.initialFirstResponder = inputField

        NSApp.activate(ignoringOtherApps: true)
        let response = alert.runModal()

        if response == .alertFirstButtonReturn {
            let hostname = inputField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !hostname.isEmpty && hostname.contains(".") else {
                self.showErrorAlert(message: "Geçersiz hostname formatı.")
                return
            }
            self.tunnelManager.routeDns(tunnelInfo: tunnel, hostname: hostname) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let output):
                        self.showInfoAlert(title: "DNS Yönlendirme Başarılı", message: "'\(hostname)' için DNS kaydı başarıyla oluşturuldu veya güncellendi.\n\n\(output)")
                        self.sendUserNotification(identifier:"dns_routed_\(tunnel.id)_\(hostname)", title: "DNS Yönlendirildi", body: "\(hostname) -> \(tunnel.name)")
                    case .failure(let error):
                        self.showErrorAlert(message: "'\(hostname)' için DNS yönlendirme hatası:\n\(error.localizedDescription)")
                    }
                }
            }
        } else {
            print("DNS yönlendirme iptal edildi.")
        }
    }

    // Quick Tunnel Actions - Modern SwiftUI Interface
    @objc func startQuickTunnelAction(_ sender: Any) {
        openQuickTunnelWindow()
    }

    @objc func stopQuickTunnelAction(_ sender: NSMenuItem) {
        guard let tunnelID = sender.representedObject as? UUID, let tunnelManager = tunnelManager else { return }
        tunnelManager.stopQuickTunnel(id: tunnelID)
    }
    @objc func copyQuickTunnelURLAction(_ sender: NSMenuItem) {
        guard let tunnelData = sender.representedObject as? QuickTunnelData, let urlString = tunnelData.publicURL else {
            sendUserNotification(identifier: "copy_fail_\(UUID().uuidString)", title: "Kopyalanamadı", body: "Tünel URL'si henüz mevcut değil.")
            return
        }
        NSPasteboard.general.clearContents(); NSPasteboard.general.setString(urlString, forType: .string)
        sendUserNotification(identifier: "url_copied_\(tunnelData.id)", title: "URL Kopyalandı", body: urlString)
    }
    
    @objc func openQuickTunnelURLAction(_ sender: NSMenuItem) {
        guard let tunnelData = sender.representedObject as? QuickTunnelData, let urlString = tunnelData.publicURL else {
            sendUserNotification(identifier: "open_fail_\(UUID().uuidString)", title: "Açılamadı", body: "Tünel URL'si henüz mevcut değil.")
            return
        }
        
        guard let url = URL(string: urlString) else {
            sendUserNotification(identifier: "invalid_url_\(UUID().uuidString)", title: "Geçersiz URL", body: "URL açılamadı: \(urlString)")
            return
        }
        
        NSWorkspace.shared.open(url)
        print("🌐 Tarayıcıda açılıyor: \(urlString)")
    }

    // Folder Actions
    @objc func openCloudflaredFolderAction() { guard let path = tunnelManager?.cloudflaredDirectoryPath else { return }; NSWorkspace.shared.open(URL(fileURLWithPath: path)) }
    @objc func openMampConfigFolderAction() { guard let path = tunnelManager?.mampConfigDirectoryPath else { return }; NSWorkspace.shared.open(URL(fileURLWithPath: path)) }


    // Cloudflare Login Action
    @objc func cloudflareLoginAction() {
        tunnelManager?.cloudflareLogin { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.sendUserNotification(identifier: "login_check_complete", title: "Cloudflare Giriş Kontrolü", body: "İşlem başlatıldı veya durum kontrol edildi. Gerekirse tarayıcıyı kontrol edin.")
                case .failure(let error):
                    self?.showErrorAlert(message: "Cloudflare giriş işlemi sırasında hata:\n\(error.localizedDescription)")
                }
            }
        }
    }

    // Launch At Login Action (macOS 13+)
    @objc func toggleLaunchAtLoginAction(_ sender: NSMenuItem) {
        guard #available(macOS 13.0, *), let tunnelManager = tunnelManager else {
            showErrorAlert(message: "Bu özellik macOS 13 veya üstünü gerektirir.")
            return
        }
        tunnelManager.toggleLaunchAtLogin { result in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                switch result {
                case .success(let newStateEnabled):
                    sender.state = newStateEnabled ? .on : .off
                    self.sendUserNotification(identifier: "launch_toggle", title: "Açılışta Başlatma", body: newStateEnabled ? "Etkinleştirildi" : "Devre Dışı Bırakıldı")
                case .failure(let error):
                    self.showErrorAlert(message: "Oturum açıldığında başlatma ayarı değiştirilirken hata:\n\(error.localizedDescription)")
                    sender.state = tunnelManager.isLaunchAtLoginEnabled() ? .on : .off // Revert UI
                }
            }
        }
    }

    // Action to Open Setup PDF
     @objc func openSetupPdfAction() {
         guard let pdfURL = Bundle.main.url(forResource: "kullanım", withExtension: "pdf") else {
             print("❌ Hata: Kurulum PDF'i uygulama paketinde bulunamadı ('kullanım.pdf').")
             showErrorAlert(message: "Kurulum kılavuzu PDF dosyası bulunamadı.")
             return
         }
         print("Kurulum PDF'i açılıyor: \(pdfURL.path)")
         NSWorkspace.shared.open(pdfURL)
     }

     // --- [NEW] MAMP Control @objc Actions ---
     @objc func startMampServersAction() {
         executeMampCommand(
             scriptName: mampStartScript,
             successMessage: "MAMP sunucuları (Apache & MySQL) için başlatma komutu gönderildi.",
             failureMessage: "MAMP sunucuları başlatılırken hata oluştu."
         )
     }

     @objc func stopMampServersAction() {
         executeMampCommand(
             scriptName: mampStopScript,
             successMessage: "MAMP sunucuları (Apache & MySQL) için durdurma komutu gönderildi.",
             failureMessage: "MAMP sunucuları durdurulurken hata oluştu."
         )
     }
     // --- [END NEW] ---

    // MARK: - Window Management
    private func showWindow<Content: View>(
        _ windowPropertySetter: @escaping (NSWindow?) -> Void,
        _ existingWindowGetter: @escaping () -> NSWindow?,
        title: String,
        view: Content
    ) {
        DispatchQueue.main.async {
            guard let manager = self.tunnelManager else {
                print("❌ Hata: showWindow çağrıldı ancak TunnelManager mevcut değil.")
                self.showErrorAlert(message: "Pencere açılamadı: Tünel Yöneticisi bulunamadı.")
                return
            }
            NSApp.activate(ignoringOtherApps: true)

            if let existingWindow = existingWindowGetter(), existingWindow.isVisible {
                existingWindow.center()
                existingWindow.makeKeyAndOrderFront(nil)
                print("Mevcut pencere öne getirildi: \(title)")
                return
            }

            print("Yeni pencere oluşturuluyor: \(title)")
            let hostingController = NSHostingController(rootView: view.environmentObject(manager))
            let newWindow = NSWindow(contentViewController: hostingController)
            newWindow.title = title
            newWindow.styleMask = [.titled, .closable]
            newWindow.level = .normal
            newWindow.isReleasedWhenClosed = false
            newWindow.center()
            windowPropertySetter(newWindow)
            newWindow.makeKeyAndOrderFront(nil)
        }
    }

    @objc func openSettingsWindowAction() {
        let settingsView = SettingsView()
        showWindow(
            { newWindow in self.settingsWindow = newWindow },
            { self.settingsWindow },
            title: "Cloudflared Manager Ayarları",
            view: settingsView
        )
    }

    @objc func openCreateManagedTunnelWindow() {
        let createView = CreateManagedTunnelView()
        showWindow(
            { newWindow in self.createManagedTunnelWindow = newWindow },
            { self.createManagedTunnelWindow },
            title: "Yeni Yönetilen Tünel Oluştur",
            view: createView
        )
    }

    @objc func openCreateFromMampWindow() {
        let createView = CreateFromMampView()
        showWindow(
            { newWindow in self.createFromMampWindow = newWindow },
            { self.createFromMampWindow },
            title: "MAMP Sitesinden Tünel Oluştur",
            view: createView
        )
    }

    @objc func openQuickTunnelWindow() {
        let quickTunnelView = QuickTunnelView()
        showWindow(
            { newWindow in self.quickTunnelWindow = newWindow },
            { self.quickTunnelWindow },
            title: "Hızlı Tünel Başlat",
            view: quickTunnelView
        )
    }

    @objc func openDashboardWindowAction() {
        let dashboardView = DashboardView(
            openSettingsAction: { [weak self] in self?.openSettingsWindowAction() },
            openQuickTunnelAction: { [weak self] in self?.openQuickTunnelWindow() },
            openManagedTunnelAction: { [weak self] in self?.openCreateManagedTunnelWindow() }
        )
        showWindow(
            { newWindow in self.dashboardWindow = newWindow },
            { self.dashboardWindow },
            title: "Gösterge Paneli",
            view: dashboardView
        )
    }

    // MARK: - Alert Helpers
    private func showInfoAlert(title: String, message: String) {
        DispatchQueue.main.async {
            NSApp.activate(ignoringOtherApps: true)
            let alert = NSAlert(); alert.messageText = title; alert.informativeText = message; alert.alertStyle = .informational; alert.addButton(withTitle: "Tamam");
            alert.runModal()
        }
    }
    private func showErrorAlert(message: String) {
        DispatchQueue.main.async {
            NSApp.activate(ignoringOtherApps: true)
            let alert = NSAlert(); alert.messageText = "Hata"; alert.informativeText = message; alert.alertStyle = .critical; alert.addButton(withTitle: "Tamam");
            alert.runModal()
        }
    }

    // Ask helper for local file deletion
    func askToDeleteLocalFiles(for tunnel: TunnelInfo) {
        guard let configPath = tunnel.configPath else { return }
        let credentialPath = tunnelManager?.findCredentialPath(for: configPath)
        var filesToDelete: [String] = []
        var fileNames: [String] = []

        if FileManager.default.fileExists(atPath: configPath) {
            filesToDelete.append(configPath)
            fileNames.append((configPath as NSString).lastPathComponent)
        }
        if let credPath = credentialPath, credPath != configPath, FileManager.default.fileExists(atPath: credPath) {
            filesToDelete.append(credPath)
            fileNames.append((credPath as NSString).lastPathComponent)
        }
        guard !filesToDelete.isEmpty else { return }

        DispatchQueue.main.async {
            NSApp.activate(ignoringOtherApps: true)
            let alert = NSAlert(); alert.messageText = "Yerel Dosyaları Sil?"; alert.informativeText = "'\(tunnel.name)' tüneli Cloudflare'dan silindi.\nİlişkili yerel dosyaları da silmek ister misiniz?\n\n- \(fileNames.joined(separator: "\n- "))"; alert.alertStyle = .warning; alert.addButton(withTitle: "Evet, Yerel Dosyaları Sil"); alert.addButton(withTitle: "Hayır, Dosyaları Koruyun")
            if alert.buttons.count > 0 { alert.buttons[0].hasDestructiveAction = true }

            if alert.runModal() == .alertFirstButtonReturn {
                print("Yerel dosyalar siliniyor: \(filesToDelete)")
                var errors: [String] = []
                filesToDelete.forEach { path in
                    do { try FileManager.default.removeItem(atPath: path); print("   Silindi: \(path)") }
                    catch { print("❌ Yerel dosya silme hatası: \(path) - \(error)"); errors.append("\((path as NSString).lastPathComponent): \(error.localizedDescription)") }
                }
                if errors.isEmpty { self.sendUserNotification(identifier:"local_deleted_\(tunnel.id)", title: "Yerel Dosyalar Silindi", body: "'\(tunnel.name)' ile ilişkili dosyalar silindi.") }
                else { self.showErrorAlert(message: "Bazı yerel dosyalar silinirken hata oluştu:\n\(errors.joined(separator: "\n"))") }
                self.tunnelManager?.findManagedTunnels() // Refresh list
            } else { print("Yerel dosyalar korunuyor.") }
        }
    }

    // Ask helper for opening MAMP config
    func askToOpenMampConfigFolder() {
        guard let configPath = tunnelManager?.mampConfigDirectoryPath else { return }
        DispatchQueue.main.async {
            NSApp.activate(ignoringOtherApps: true)
            let alert = NSAlert()
            alert.messageText = "MAMP Yapılandırması Güncellendi"
            alert.informativeText = "MAMP vHost dosyası güncellendi. Ayarların etkili olması için MAMP sunucularını yeniden başlatmanız gerekir.\n\nMAMP Apache yapılandırma klasörünü açmak ister misiniz?"
            alert.addButton(withTitle: "Klasörü Aç")
            alert.addButton(withTitle: "Hayır")
            alert.alertStyle = .informational

            if alert.runModal() == .alertFirstButtonReturn {
                NSWorkspace.shared.open(URL(fileURLWithPath: configPath))
            }
        }
    }

    // --- [NEW] MAMP Command Execution Helper ---
    /// Belirtilen MAMP komut satırı betiğini çalıştırır.
    /// - Parameters:
    ///   - scriptName: Çalıştırılacak betik adı (örn: "start.sh").
    ///   - successMessage: Başarılı olursa gösterilecek bildirim mesajı.
    ///   - failureMessage: Başarısız olursa gösterilecek hata başlığı.
    private func executeMampCommand(scriptName: String, successMessage: String, failureMessage: String) {
        let scriptPath = "\(mampBinPath)/\(scriptName)"

        guard FileManager.default.isExecutableFile(atPath: scriptPath) else {
            let errorMessage = "'\(scriptName)' betiği bulunamadı veya çalıştırılabilir değil.\nYol: \(scriptPath)\nMAMP kurulumunuzu kontrol edin."
            print("❌ MAMP Betik Hatası: \(errorMessage)")
            // Ana iş parçacığında olduğundan emin olarak hata göster
            DispatchQueue.main.async {
                self.showErrorAlert(message: errorMessage)
            }
            return
        }

        // Ana iş parçacığından ayırarak UI'ın donmasını engelle
        DispatchQueue.global(qos: .userInitiated).async {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/sh") // Betiği shell ile çalıştır
            process.arguments = [scriptPath]

            // Çıktıyı yakalamak istersen (debugging için yararlı olabilir):
            // let outputPipe = Pipe()
            // let errorPipe = Pipe()
            // process.standardOutput = outputPipe
            // process.standardError = errorPipe

            do {
                print("🚀 MAMP komutu çalıştırılıyor: \(scriptPath)")
                try process.run()
                process.waitUntilExit() // İşlemin bitmesini bekle

                // Çıktıyı oku (opsiyonel)
                // let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                // let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                // let outputString = String(data: outputData, encoding: .utf8) ?? ""
                // let errorString = String(data: errorData, encoding: .utf8) ?? ""
                // if !outputString.isEmpty { print("MAMP Output [\(scriptName)]: \(outputString)") }
                // if !errorString.isEmpty { print("MAMP Error [\(scriptName)]: \(errorString)") }


                // Ana iş parçacığına dönerek UI güncellemesi yap
                DispatchQueue.main.async {
                    if process.terminationStatus == 0 {
                        print("✅ MAMP komutu başarıyla tamamlandı: \(scriptName)")
                        self.sendUserNotification(identifier: "mamp_action_\(scriptName)_\(UUID().uuidString)", title: "MAMP İşlemi", body: successMessage)
                    } else {
                        let errorDetail = "MAMP betiği '\(scriptName)' (Çıkış Kodu: \(process.terminationStatus)) ile başarısız oldu." // \nError Output: \(errorString)"
                        print("❌ MAMP Betik Hatası: \(errorDetail)")
                        self.showErrorAlert(message: "\(failureMessage)\nDetay: \(errorDetail)")
                    }
                }
            } catch {
                // Ana iş parçacığına dönerek UI güncellemesi yap
                DispatchQueue.main.async {
                    let errorDetail = "MAMP betiği '\(scriptName)' çalıştırılırken hata oluştu: \(error.localizedDescription)"
                    print("❌ MAMP Betik Hatası: \(errorDetail)")
                    self.showErrorAlert(message: "\(failureMessage)\nDetay: \(errorDetail)")
                }
            }
        }
    }
    // --- [END NEW] ---

    // End AppDelegate
}

