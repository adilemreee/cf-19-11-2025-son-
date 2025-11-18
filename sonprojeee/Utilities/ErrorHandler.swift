import Foundation
import AppKit

// MARK: - Enhanced Error Types

enum TunnelError: LocalizedError {
    case cloudflaredNotFound(path: String)
    case configFileNotFound(path: String)
    case portConflict(port: Int, conflictingProcess: String?)
    case mampPermissionDenied(file: String)
    case mampFileNotFound(path: String)
    case tunnelAlreadyRunning(name: String)
    case tunnelCreationFailed(reason: String)
    case processStartFailed(reason: String)
    case invalidConfiguration(reason: String)
    case networkError(reason: String)
    
    var errorDescription: String? {
        switch self {
        case .cloudflaredNotFound(let path):
            return "cloudflared bulunamadı: \(path)"
        case .configFileNotFound(let path):
            return "Yapılandırma dosyası bulunamadı: \(path)"
        case .portConflict(let port, let process):
            if let process = process {
                return "Port \(port) zaten kullanımda: \(process)"
            }
            return "Port \(port) zaten kullanımda"
        case .mampPermissionDenied(let file):
            return "MAMP dosyasına yazma izni yok: \(file)"
        case .mampFileNotFound(let path):
            return "MAMP dosyası bulunamadı: \(path)"
        case .tunnelAlreadyRunning(let name):
            return "Tünel '\(name)' zaten çalışıyor"
        case .tunnelCreationFailed(let reason):
            return "Tünel oluşturulamadı: \(reason)"
        case .processStartFailed(let reason):
            return "İşlem başlatılamadı: \(reason)"
        case .invalidConfiguration(let reason):
            return "Geçersiz yapılandırma: \(reason)"
        case .networkError(let reason):
            return "Ağ hatası: \(reason)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .cloudflaredNotFound(let path):
            return """
            Çözüm Adımları:
            1. cloudflared'i indirin: https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/installation/
            2. Settings → Paths bölümünden doğru yolu ayarlayın
            3. Veya Terminal'de: brew install cloudflare/cloudflare/cloudflared
            
            Beklenen konum: \(path)
            """
        case .configFileNotFound:
            return "Yapılandırma dosyasının mevcut olduğundan emin olun."
        case .portConflict(let port, let process):
            var suggestion = """
            Çözüm Seçenekleri:
            1. Farklı bir port kullanın (örn: \(port + 1))
            2. Çakışan servisi durdurun
            """
            if process != nil {
                suggestion += "\n3. Terminal'de: lsof -ti:\(port) | xargs kill -9"
            }
            return suggestion
        case .mampPermissionDenied(let file):
            return """
            Çözüm Adımları:
            1. Terminal'i açın
            2. Komutu çalıştırın:
               sudo chmod 644 '\(file)'
            3. Admin şifrenizi girin
            4. Uygulamayı tekrar deneyin
            
            Alternatif: 'Manuel Yapılandırma' seçeneğini kullanın
            """
        case .mampFileNotFound(let path):
            return """
            MAMP düzgün kurulmamış olabilir.
            
            Kontrol Edilecekler:
            1. MAMP yüklü mü? → /Applications/MAMP
            2. Settings → Paths → MAMP yolunu kontrol edin
            3. Dosya mevcut mu? → \(path)
            """
        case .tunnelAlreadyRunning:
            return "Tüneli durdurup tekrar başlatmayı deneyin."
        case .tunnelCreationFailed(let reason):
            return "Hata detayı: \(reason)\nCloudflare hesabınızı ve ağ bağlantınızı kontrol edin."
        case .processStartFailed:
            return "Sistem kaynaklarını kontrol edin ve tekrar deneyin."
        case .invalidConfiguration:
            return "Yapılandırma dosyasını kontrol edin veya yeniden oluşturun."
        case .networkError:
            return "İnternet bağlantınızı kontrol edin ve tekrar deneyin."
        }
    }
}

// MARK: - Error Handler

class ErrorHandler {
    static let shared = ErrorHandler()
    
    private init() {}
    
    // Enhanced error presentation
    func handle(_ error: Error, context: String = "", showAlert: Bool = true) {
        let errorMessage = formatError(error, context: context)
        print("❌ \(context): \(errorMessage)")
        
        if showAlert {
            DispatchQueue.main.async {
                self.showErrorAlert(message: errorMessage)
            }
        }
        
        // Send notification
        NotificationCenter.default.post(
            name: .sendUserNotification,
            object: nil,
            userInfo: [
                "title": "Hata",
                "message": errorMessage
            ]
        )
    }
    
    private func formatError(_ error: Error, context: String) -> String {
        var message = ""
        
        if !context.isEmpty {
            message += "📍 \(context)\n\n"
        }
        
        if let tunnelError = error as? TunnelError {
            message += "❌ \(tunnelError.localizedDescription)\n\n"
            if let suggestion = tunnelError.recoverySuggestion {
                message += "💡 \(suggestion)"
            }
        } else {
            message += "❌ \(error.localizedDescription)"
        }
        
        return message
    }
    
    func showErrorAlert(message: String) {
        let alert = NSAlert()
        alert.messageText = "Hata Oluştu"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Tamam")
        
        // Check if there's a key window
        if let window = NSApp.keyWindow {
            alert.beginSheetModal(for: window)
        } else {
            alert.runModal()
        }
    }
    
    func showInfoAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Tamam")
        
        if let window = NSApp.keyWindow {
            alert.beginSheetModal(for: window)
        } else {
            alert.runModal()
        }
    }
}

// MARK: - Port Conflict Detection

class PortChecker {
    static let shared = PortChecker()
    
    private init() {}
    
    /// Check if a port is available
    func isPortAvailable(_ port: Int) -> Bool {
        let socketFD = socket(AF_INET, SOCK_STREAM, 0)
        guard socketFD != -1 else { return false }
        
        defer { close(socketFD) }
        
        var addr = sockaddr_in()
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port = in_port_t(port).bigEndian
        addr.sin_addr.s_addr = INADDR_ANY
        
        let bindResult = withUnsafePointer(to: &addr) { ptr -> Int32 in
            ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockaddrPtr in
                bind(socketFD, sockaddrPtr, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }
        
        return bindResult == 0
    }
    
    /// Find process using a port
    func findProcessUsingPort(_ port: Int) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/lsof")
        process.arguments = ["-i", ":\(port)", "-sTCP:LISTEN"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8), !output.isEmpty {
                // Parse lsof output to get process name
                let lines = output.components(separatedBy: "\n")
                if lines.count > 1 {
                    let fields = lines[1].components(separatedBy: .whitespaces).filter { !$0.isEmpty }
                    if fields.count > 0 {
                        return fields[0] // Process name
                    }
                }
            }
        } catch {
            print("⚠️ Port kontrolü yapılamadı: \(error.localizedDescription)")
        }
        
        return nil
    }
    
    /// Check port and return detailed result
    func checkPort(_ port: Int) -> Result<Void, TunnelError> {
        if isPortAvailable(port) {
            return .success(())
        } else {
            let conflictingProcess = findProcessUsingPort(port)
            return .failure(.portConflict(port: port, conflictingProcess: conflictingProcess))
        }
    }
    
    /// Find next available port starting from given port
    func findAvailablePort(startingFrom port: Int, maxAttempts: Int = 100) -> Int? {
        for testPort in port..<(port + maxAttempts) {
            if isPortAvailable(testPort) {
                return testPort
            }
        }
        return nil
    }
}

// MARK: - MAMP Permission Handler

class MAMPPermissionHandler {
    static let shared = MAMPPermissionHandler()
    
    private init() {}
    
    /// Check if MAMP files are writable
    func checkMAMPPermissions(vhostPath: String, httpdPath: String) -> (canWrite: Bool, errors: [TunnelError]) {
        var errors: [TunnelError] = []
        let fileManager = FileManager.default
        
        // Check vhost file
        if !fileManager.fileExists(atPath: vhostPath) {
            errors.append(.mampFileNotFound(path: vhostPath))
        } else if !fileManager.isWritableFile(atPath: vhostPath) {
            errors.append(.mampPermissionDenied(file: vhostPath))
        }
        
        // Check httpd.conf
        if !fileManager.fileExists(atPath: httpdPath) {
            errors.append(.mampFileNotFound(path: httpdPath))
        } else if !fileManager.isWritableFile(atPath: httpdPath) {
            errors.append(.mampPermissionDenied(file: httpdPath))
        }
        
        return (errors.isEmpty, errors)
    }
    
    /// Request admin privileges to fix MAMP file permissions
    func requestAdminPrivileges(for filePaths: [String]) -> Bool {
        let filePathsString = filePaths.map { "'\($0)'" }.joined(separator: " ")
        let script = """
        do shell script "chmod 644 \(filePathsString)" with administrator privileges
        """
        
        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: script) {
            scriptObject.executeAndReturnError(&error)
            return error == nil
        }
        return false
    }
    
    /// Show manual configuration instructions
    func showManualConfigInstructions(config: String, filePath: String) {
        let alert = NSAlert()
        alert.messageText = "Manuel Yapılandırma Gerekli"
        alert.informativeText = """
        MAMP dosyalarına otomatik yazma başarısız oldu.
        
        Yapılandırma panoya kopyalandı.
        
        Manuel Adımlar:
        1. Terminal'i açın
        2. Şu komutu çalıştırın:
           sudo nano \(filePath)
        3. Dosya sonuna gidin (Ctrl+End)
        4. Panodaki içeriği yapıştırın (Cmd+V)
        5. Kaydedin (Ctrl+O, Enter, Ctrl+X)
        6. MAMP'ı yeniden başlatın
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Kopyalandı, Tamam")
        alert.addButton(withTitle: "Terminal'i Aç")
        
        let response = alert.runModal()
        
        // Copy to clipboard
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(config, forType: .string)
        
        // Open Terminal if requested
        if response == .alertSecondButtonReturn {
            let terminalURL = URL(fileURLWithPath: "/Applications/Utilities/Terminal.app")
            NSWorkspace.shared.open(terminalURL)
        }
    }
}
