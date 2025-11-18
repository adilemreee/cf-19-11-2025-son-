import Foundation
import SwiftUI

// MARK: - Backup Models

/// Represents a complete backup of the application state
struct BackupData: Codable {
    let version: String
    let timestamp: Date
    let tunnels: [BackupTunnel]
    let settings: BackupSettings
    let metadata: BackupMetadata
    
    struct BackupMetadata: Codable {
        let appVersion: String
        let systemVersion: String
        let deviceName: String
    }
}

/// Tunnel information for backup
struct BackupTunnel: Codable, Identifiable {
    let id: UUID
    let name: String
    let configPath: String?
    let configContent: String? // The actual YAML content
    let uuidFromConfig: String?
    let isManaged: Bool
    
    init(from tunnel: TunnelInfo, configContent: String? = nil) {
        self.id = tunnel.id
        self.name = tunnel.name
        self.configPath = tunnel.configPath
        self.configContent = configContent
        self.uuidFromConfig = tunnel.uuidFromConfig
        self.isManaged = tunnel.isManaged
    }
}

/// Settings information for backup
struct BackupSettings: Codable {
    let cloudflaredExecutablePath: String
    let cloudflaredDirectoryPath: String
    let checkInterval: TimeInterval
    let mampBasePath: String
    let customMampSitesPath: String?
    let customMampApacheConfigPath: String?
    let customMampVHostConfPath: String?
    let customMampHttpdConfPath: String?
    
    // UI Preferences
    let darkModeEnabled: Bool
    let notificationsEnabled: Bool
    let autoStartTunnels: Bool
    let minimizeToTray: Bool
    let showStatusInMenuBar: Bool
    let accentColor: String
}

/// Represents a saved backup file
struct BackupFile: Identifiable, Codable {
    let id: UUID
    let filename: String
    let timestamp: Date
    let size: Int64
    let tunnelCount: Int
    
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: timestamp)
    }
}

// MARK: - Backup Manager

class BackupManager: ObservableObject {
    static let shared = BackupManager()
    
    @Published var availableBackups: [BackupFile] = []
    @Published var isCreatingBackup = false
    @Published var isRestoringBackup = false
    @Published var lastBackupDate: Date?
    @Published var autoBackupEnabled = false
    @Published var autoBackupInterval: TimeInterval = 86400 // 24 hours
    
    private let backupDirectory: URL
    private let fileManager = FileManager.default
    private var autoBackupTimer: Timer?
    
    private init() {
        // Create backups directory in Application Support
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        self.backupDirectory = appSupport.appendingPathComponent("CloudflaredManager/Backups", isDirectory: true)
        
        createBackupDirectoryIfNeeded()
        loadAvailableBackups()
        loadBackupPreferences()
        setupAutoBackup()
    }
    
    // MARK: - Directory Management
    
    private func createBackupDirectoryIfNeeded() {
        if !fileManager.fileExists(atPath: backupDirectory.path) {
            try? fileManager.createDirectory(at: backupDirectory, withIntermediateDirectories: true)
            print("📁 Backup dizini oluşturuldu: \(backupDirectory.path)")
        }
    }
    
    // MARK: - Backup Creation
    
    func createBackup(manager: TunnelManager) async throws -> BackupFile {
        await MainActor.run {
            isCreatingBackup = true
        }
        
        defer {
            Task { @MainActor in
                isCreatingBackup = false
            }
        }
        
        // Collect tunnel data with config contents
        let backupTunnels = try await collectTunnelData(manager: manager)
        
        // Collect settings
        let settings = collectSettings(manager: manager)
        
        // Create metadata
        let metadata = BackupData.BackupMetadata(
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
            systemVersion: ProcessInfo.processInfo.operatingSystemVersionString,
            deviceName: Host.current().localizedName ?? "Unknown"
        )
        
        // Create backup data
        let backupData = BackupData(
            version: "1.0",
            timestamp: Date(),
            tunnels: backupTunnels,
            settings: settings,
            metadata: metadata
        )
        
        // Encode to JSON
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let jsonData = try encoder.encode(backupData)
        
        // Create filename with timestamp
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = dateFormatter.string(from: Date())
        let filename = "backup_\(timestamp).json"
        
        // Save to file
        let backupURL = backupDirectory.appendingPathComponent(filename)
        try jsonData.write(to: backupURL)
        
        // Create backup file info
        let attributes = try fileManager.attributesOfItem(atPath: backupURL.path)
        let fileSize = attributes[.size] as? Int64 ?? 0
        
        let backupFile = BackupFile(
            id: UUID(),
            filename: filename,
            timestamp: Date(),
            size: fileSize,
            tunnelCount: backupTunnels.count
        )
        
        // Update state
        await MainActor.run {
            availableBackups.insert(backupFile, at: 0)
            lastBackupDate = Date()
            saveBackupPreferences()
        }
        
        print("✅ Backup oluşturuldu: \(filename)")
        sendNotification(title: "Backup Oluşturuldu", message: "\(backupTunnels.count) tünel yedeklendi")
        
        return backupFile
    }
    
    private func collectTunnelData(manager: TunnelManager) async throws -> [BackupTunnel] {
        var backupTunnels: [BackupTunnel] = []
        
        for tunnel in manager.tunnels {
            var configContent: String?
            
            // Read config file content if exists
            if let configPath = tunnel.configPath {
                let configURL = URL(fileURLWithPath: configPath)
                if fileManager.fileExists(atPath: configPath) {
                    configContent = try? String(contentsOf: configURL, encoding: .utf8)
                }
            }
            
            let backupTunnel = BackupTunnel(from: tunnel, configContent: configContent)
            backupTunnels.append(backupTunnel)
        }
        
        return backupTunnels
    }
    
    private func collectSettings(manager: TunnelManager) -> BackupSettings {
        return BackupSettings(
            cloudflaredExecutablePath: manager.cloudflaredExecutablePath,
            cloudflaredDirectoryPath: manager.cloudflaredDirectoryPath,
            checkInterval: manager.checkInterval,
            mampBasePath: manager.mampBasePath,
            customMampSitesPath: manager.customMampSitesPath,
            customMampApacheConfigPath: manager.customMampApacheConfigPath,
            customMampVHostConfPath: manager.customMampVHostConfPath,
            customMampHttpdConfPath: manager.customMampHttpdConfPath,
            darkModeEnabled: UserDefaults.standard.bool(forKey: "darkModeEnabled"),
            notificationsEnabled: UserDefaults.standard.bool(forKey: "notificationsEnabled"),
            autoStartTunnels: UserDefaults.standard.bool(forKey: "autoStartTunnels"),
            minimizeToTray: UserDefaults.standard.bool(forKey: "minimizeToTray"),
            showStatusInMenuBar: UserDefaults.standard.bool(forKey: "showStatusInMenuBar"),
            accentColor: UserDefaults.standard.string(forKey: "accentColor") ?? "blue"
        )
    }
    
    // MARK: - Backup Restoration
    
    func restoreBackup(backupFile: BackupFile, manager: TunnelManager, restoreSettings: Bool = true, restoreTunnels: Bool = true) async throws {
        await MainActor.run {
            isRestoringBackup = true
        }
        
        defer {
            Task { @MainActor in
                isRestoringBackup = false
            }
        }
        
        // Read backup file
        let backupURL = backupDirectory.appendingPathComponent(backupFile.filename)
        let jsonData = try Data(contentsOf: backupURL)
        
        // Decode backup data
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let backupData = try decoder.decode(BackupData.self, from: jsonData)
        
        // Restore settings if requested
        if restoreSettings {
            try await restoreSettingsFromBackup(backupData.settings, manager: manager)
        }
        
        // Restore tunnels if requested
        if restoreTunnels {
            try await restoreTunnelsFromBackup(backupData.tunnels, manager: manager)
        }
        
        print("✅ Backup geri yüklendi: \(backupFile.filename)")
        sendNotification(title: "Backup Geri Yüklendi", message: "Ayarlarınız başarıyla geri yüklendi")
    }
    
    private func restoreSettingsFromBackup(_ settings: BackupSettings, manager: TunnelManager) async throws {
        await MainActor.run {
            // Update manager settings
            manager.cloudflaredExecutablePath = settings.cloudflaredExecutablePath
            manager.cloudflaredDirectoryPath = settings.cloudflaredDirectoryPath
            manager.checkInterval = settings.checkInterval
            manager.mampBasePath = settings.mampBasePath
            manager.customMampSitesPath = settings.customMampSitesPath
            manager.customMampApacheConfigPath = settings.customMampApacheConfigPath
            manager.customMampVHostConfPath = settings.customMampVHostConfPath
            manager.customMampHttpdConfPath = settings.customMampHttpdConfPath
            
            // Update UserDefaults
            UserDefaults.standard.set(settings.darkModeEnabled, forKey: "darkModeEnabled")
            UserDefaults.standard.set(settings.notificationsEnabled, forKey: "notificationsEnabled")
            UserDefaults.standard.set(settings.autoStartTunnels, forKey: "autoStartTunnels")
            UserDefaults.standard.set(settings.minimizeToTray, forKey: "minimizeToTray")
            UserDefaults.standard.set(settings.showStatusInMenuBar, forKey: "showStatusInMenuBar")
            UserDefaults.standard.set(settings.accentColor, forKey: "accentColor")
        }
    }
    
    private func restoreTunnelsFromBackup(_ tunnels: [BackupTunnel], manager: TunnelManager) async throws {
        for backupTunnel in tunnels {
            // Restore config file if content exists
            if let configContent = backupTunnel.configContent,
               let configPath = backupTunnel.configPath {
                let configURL = URL(fileURLWithPath: configPath)
                
                // Create directory if needed
                let configDir = configURL.deletingLastPathComponent()
                if !fileManager.fileExists(atPath: configDir.path) {
                    try fileManager.createDirectory(at: configDir, withIntermediateDirectories: true)
                }
                
                // Write config file
                try configContent.write(to: configURL, atomically: true, encoding: .utf8)
                print("📝 Config dosyası geri yüklendi: \(configPath)")
            }
        }
        
        // Refresh tunnel list
        await MainActor.run {
            manager.findManagedTunnels()
        }
    }
    
    // MARK: - Backup Management
    
    func loadAvailableBackups() {
        guard fileManager.fileExists(atPath: backupDirectory.path) else { return }
        
        do {
            let files = try fileManager.contentsOfDirectory(at: backupDirectory, includingPropertiesForKeys: [.fileSizeKey, .creationDateKey])
            
            var backups: [BackupFile] = []
            
            for fileURL in files where fileURL.pathExtension == "json" {
                let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
                let fileSize = attributes[.size] as? Int64 ?? 0
                let creationDate = attributes[.creationDate] as? Date ?? Date()
                
                // Try to read tunnel count from file
                var tunnelCount = 0
                if let jsonData = try? Data(contentsOf: fileURL),
                   let backupData = try? JSONDecoder().decode(BackupData.self, from: jsonData) {
                    tunnelCount = backupData.tunnels.count
                }
                
                let backup = BackupFile(
                    id: UUID(),
                    filename: fileURL.lastPathComponent,
                    timestamp: creationDate,
                    size: fileSize,
                    tunnelCount: tunnelCount
                )
                backups.append(backup)
            }
            
            // Sort by date (newest first)
            backups.sort { $0.timestamp > $1.timestamp }
            
            DispatchQueue.main.async {
                self.availableBackups = backups
            }
            
        } catch {
            print("❌ Backup listesi yüklenemedi: \(error.localizedDescription)")
        }
    }
    
    func deleteBackup(_ backup: BackupFile) throws {
        let backupURL = backupDirectory.appendingPathComponent(backup.filename)
        try fileManager.removeItem(at: backupURL)
        
        DispatchQueue.main.async {
            self.availableBackups.removeAll { $0.id == backup.id }
        }
        
        print("🗑️ Backup silindi: \(backup.filename)")
    }
    
    func exportBackup(_ backup: BackupFile) throws -> URL {
        let backupURL = backupDirectory.appendingPathComponent(backup.filename)
        return backupURL
    }
    
    func importBackup(from sourceURL: URL) throws -> BackupFile {
        let filename = sourceURL.lastPathComponent
        let destinationURL = backupDirectory.appendingPathComponent(filename)
        
        // Check if file already exists
        if fileManager.fileExists(atPath: destinationURL.path) {
            // Create unique filename
            let timestamp = Int(Date().timeIntervalSince1970)
            let nameWithoutExt = (filename as NSString).deletingPathExtension
            let ext = (filename as NSString).pathExtension
            let newFilename = "\(nameWithoutExt)_imported_\(timestamp).\(ext)"
            let newDestination = backupDirectory.appendingPathComponent(newFilename)
            try fileManager.copyItem(at: sourceURL, to: newDestination)
        } else {
            try fileManager.copyItem(at: sourceURL, to: destinationURL)
        }
        
        loadAvailableBackups()
        
        let attributes = try fileManager.attributesOfItem(atPath: destinationURL.path)
        let fileSize = attributes[.size] as? Int64 ?? 0
        
        // Read tunnel count
        var tunnelCount = 0
        if let jsonData = try? Data(contentsOf: destinationURL),
           let backupData = try? JSONDecoder().decode(BackupData.self, from: jsonData) {
            tunnelCount = backupData.tunnels.count
        }
        
        return BackupFile(
            id: UUID(),
            filename: destinationURL.lastPathComponent,
            timestamp: Date(),
            size: fileSize,
            tunnelCount: tunnelCount
        )
    }
    
    // MARK: - Auto Backup
    
    private func setupAutoBackup() {
        autoBackupTimer?.invalidate()
        
        guard autoBackupEnabled else { return }
        
        autoBackupTimer = Timer.scheduledTimer(withTimeInterval: autoBackupInterval, repeats: true) { [weak self] _ in
            Task {
                // Auto backup will be triggered from the app
                self?.sendNotification(title: "Otomatik Backup", message: "Otomatik yedekleme zamanı geldi")
            }
        }
    }
    
    func toggleAutoBackup(enabled: Bool) {
        autoBackupEnabled = enabled
        saveBackupPreferences()
        setupAutoBackup()
    }
    
    func setAutoBackupInterval(_ interval: TimeInterval) {
        autoBackupInterval = max(3600, interval) // Minimum 1 hour
        saveBackupPreferences()
        setupAutoBackup()
    }
    
    // MARK: - Preferences
    
    private func loadBackupPreferences() {
        autoBackupEnabled = UserDefaults.standard.bool(forKey: "autoBackupEnabled")
        if let interval = UserDefaults.standard.object(forKey: "autoBackupInterval") as? TimeInterval {
            autoBackupInterval = interval
        }
        if let date = UserDefaults.standard.object(forKey: "lastBackupDate") as? Date {
            lastBackupDate = date
        }
    }
    
    private func saveBackupPreferences() {
        UserDefaults.standard.set(autoBackupEnabled, forKey: "autoBackupEnabled")
        UserDefaults.standard.set(autoBackupInterval, forKey: "autoBackupInterval")
        if let date = lastBackupDate {
            UserDefaults.standard.set(date, forKey: "lastBackupDate")
        }
    }
    
    // MARK: - Utilities
    
    private func sendNotification(title: String, message: String) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: .sendUserNotification,
                object: nil,
                userInfo: ["title": title, "message": message]
            )
        }
    }
}
