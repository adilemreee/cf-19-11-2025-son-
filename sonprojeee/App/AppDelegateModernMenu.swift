import Foundation
import AppKit

// Modern Menu Extension for AppDelegate
extension AppDelegate {
    
    // MARK: - Modern Menu Construction
    func constructModernMenu() {
        guard let tunnelManager = tunnelManager else {
            createErrorMenu()
            return
        }

        let menu = NSMenu()
        let isCloudflaredAvailable = FileManager.default.fileExists(atPath: tunnelManager.cloudflaredExecutablePath)
        
        // Update menu bar icon based on status
        updateMenuBarIcon(isCloudflaredAvailable: isCloudflaredAvailable, tunnels: tunnelManager.tunnels, quickTunnels: tunnelManager.quickTunnels)

        // --- Header Section ---
        createHeaderSection(menu, isCloudflaredAvailable: isCloudflaredAvailable)
        
        // --- Quick Tunnels Section ---
        createQuickTunnelsSection(menu, quickTunnels: tunnelManager.quickTunnels)
        
        // --- Managed Tunnels Section ---
        createManagedTunnelsSection(menu, managedTunnels: tunnelManager.tunnels, isCloudflaredAvailable: isCloudflaredAvailable)
        
        // --- Control Actions ---
        createControlActionsSection(menu, tunnelManager: tunnelManager, isCloudflaredAvailable: isCloudflaredAvailable)
        
        // --- Creation Tools ---
        createCreationToolsSection(menu, tunnelManager: tunnelManager, isCloudflaredAvailable: isCloudflaredAvailable)
        
        // --- Management Tools ---
        createManagementToolsSection(menu, tunnelManager: tunnelManager)
        
        // --- System Tools ---
        createSystemToolsSection(menu, tunnelManager: tunnelManager, isCloudflaredAvailable: isCloudflaredAvailable)
        
        // --- Footer Section ---
        createFooterSection(menu, tunnelManager: tunnelManager)

        // Update the status item's menu
        statusItem?.menu = menu
    }
    
    // MARK: - Modern Menu Helpers
    private func createErrorMenu() {
        let menu = NSMenu()
        createModernMenuItem(menu, title: "Yönetici Başlatılamadı", icon: "exclamationmark.triangle.fill", action: nil, color: .systemRed)
        menu.addItem(NSMenuItem.separator())
        let exitItem = NSMenuItem(title: "Çıkış", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        exitItem.target = NSApp // NSApplication'ı target olarak ayarla
        if let image = NSImage(systemSymbolName: "xmark.circle.fill", accessibilityDescription: "Çıkış") {
            let coloredImage = image.copy() as! NSImage
            coloredImage.isTemplate = true
            exitItem.image = coloredImage
        }
        menu.addItem(exitItem)
        statusItem?.menu = menu
    }
    
    private func updateMenuBarIcon(isCloudflaredAvailable: Bool, tunnels: [TunnelInfo], quickTunnels: [QuickTunnelData]) {
        guard let button = statusItem?.button else { return }
        
        let runningCount = tunnels.filter { $0.status == .running }.count + quickTunnels.filter { $0.publicURL != nil }.count
        let hasErrors = tunnels.contains { $0.status == .error } || quickTunnels.contains { $0.lastError != nil }
        
        let iconName: String
        
        if !isCloudflaredAvailable {
            iconName = "cloud.slash.fill"
        } else if hasErrors {
            iconName = "cloud.bolt.fill"
        } else if runningCount > 0 {
            iconName = "cloud.fill"
        } else {
            iconName = "cloud"
        }
        
        if let image = NSImage(systemSymbolName: iconName, accessibilityDescription: "Cloudflared Status") {
            let coloredImage = image.copy() as! NSImage
            coloredImage.isTemplate = true // Template moduna geç
            
            button.image = coloredImage
        }
        
        // Sade tooltip
        var tooltipParts: [String] = []
        if !isCloudflaredAvailable {
            tooltipParts.append("cloudflared bulunamadı")
        } else {
            tooltipParts.append("Cloudflared Manager")
            if runningCount > 0 {
                tooltipParts.append("\(runningCount) tünel aktif")
            }
            if hasErrors {
                tooltipParts.append("Hata var")
            }
            if runningCount == 0 && !hasErrors {
                tooltipParts.append("Hazır")
            }
        }
        button.toolTip = tooltipParts.joined(separator: " • ")
    }
    
    private func createHeaderSection(_ menu: NSMenu, isCloudflaredAvailable: Bool) {
        if !isCloudflaredAvailable {
            createModernMenuItem(menu, title: "cloudflared Bulunamadı", icon: "exclamationmark.triangle.fill", action: #selector(openSettingsWindowAction), color: .systemRed, tooltip: "Ayarlar'dan cloudflared yolunu düzeltin")
            menu.addItem(createStyledSeparator())
        } else {
            createModernMenuItem(menu, title: "Cloudflare Hesabı", icon: "person.crop.circle.badge.checkmark", action: #selector(cloudflareLoginAction), color: .systemBlue, tooltip: "Cloudflare hesabınıza giriş yapın")
            menu.addItem(createStyledSeparator())
        }
    }
    
    private func createQuickTunnelsSection(_ menu: NSMenu, quickTunnels: [QuickTunnelData]) {
        if !quickTunnels.isEmpty {
            let header = createSectionHeader("Hızlı Tüneller (\(quickTunnels.count))", icon: "bolt.fill", color: .systemPurple)
            menu.addItem(header)
            
            let maxItemsPerPage = 8 // Slightly less for quick tunnels since they have longer URLs
            
            if quickTunnels.count <= maxItemsPerPage {
                // Show all quick tunnels directly
                for quickTunnelData in quickTunnels {
                    let (title, icon, color, tooltip) = getQuickTunnelDisplayInfo(quickTunnelData)
                    
                    let quickItem = createModernMenuItem(menu, title: title, icon: icon, action: #selector(openQuickTunnelURLAction(_:)), color: color, tooltip: tooltip)
                    quickItem.representedObject = quickTunnelData
                    quickItem.isEnabled = (quickTunnelData.publicURL != nil)
                    
                    let subMenu = NSMenu()
                    let copyItem = createModernMenuItem(subMenu, title: "URL Kopyala", icon: "doc.on.clipboard", action: #selector(copyQuickTunnelURLAction(_:)), color: .systemBlue)
                    copyItem.representedObject = quickTunnelData
                    copyItem.isEnabled = (quickTunnelData.publicURL != nil)
                    
                    let stopItem = createModernMenuItem(subMenu, title: "Durdur", icon: "stop.circle.fill", action: #selector(stopQuickTunnelAction(_:)), color: .systemRed)
                    stopItem.representedObject = quickTunnelData.id
                    quickItem.submenu = subMenu
                }
            } else {
                // Create paginated quick tunnels
                let totalPages = (quickTunnels.count + maxItemsPerPage - 1) / maxItemsPerPage
                let quickTunnelsItem = createModernMenuItem(menu, title: "Hızlı Tüneller (\(quickTunnels.count))", icon: "bolt.fill", action: nil, color: .systemPurple)
                let quickTunnelsSubMenu = NSMenu()
                
                for pageIndex in 0..<totalPages {
                    let startIndex = pageIndex * maxItemsPerPage
                    let endIndex = min(startIndex + maxItemsPerPage, quickTunnels.count)
                    let pageTunnels = Array(quickTunnels[startIndex..<endIndex])
                    
                    let pageTitle = totalPages > 1 ? "Sayfa \(pageIndex + 1) (\(startIndex + 1)-\(endIndex))" : "Hızlı Tüneller"
                    let pageItem = createModernMenuItem(quickTunnelsSubMenu, title: pageTitle, icon: "doc.on.doc", action: nil, color: .secondaryLabelColor)
                    let pageSubMenu = NSMenu()
                    
                    for quickTunnelData in pageTunnels {
                        let (title, icon, color, tooltip) = getQuickTunnelDisplayInfo(quickTunnelData)
                        
                        let quickItem = createModernMenuItem(pageSubMenu, title: title, icon: icon, action: #selector(openQuickTunnelURLAction(_:)), color: color, tooltip: tooltip)
                        quickItem.representedObject = quickTunnelData
                        quickItem.isEnabled = (quickTunnelData.publicURL != nil)
                        
                        let subMenu = NSMenu()
                        let copyItem = createModernMenuItem(subMenu, title: "URL Kopyala", icon: "doc.on.clipboard", action: #selector(copyQuickTunnelURLAction(_:)), color: .systemBlue)
                        copyItem.representedObject = quickTunnelData
                        copyItem.isEnabled = (quickTunnelData.publicURL != nil)
                        
                        let stopItem = createModernMenuItem(subMenu, title: "Durdur", icon: "stop.circle.fill", action: #selector(stopQuickTunnelAction(_:)), color: .systemRed)
                        stopItem.representedObject = quickTunnelData.id
                        quickItem.submenu = subMenu
                    }
                    
                    pageItem.submenu = pageSubMenu
                }
                
                quickTunnelsItem.submenu = quickTunnelsSubMenu
                // Remove the header since we're showing the item with count
                menu.removeItem(header)
                menu.addItem(quickTunnelsItem)
            }
            
            menu.addItem(createStyledSeparator())
        }
    }
    
    private func createManagedTunnelsSection(_ menu: NSMenu, managedTunnels: [TunnelInfo], isCloudflaredAvailable: Bool) {
        if !managedTunnels.isEmpty {
            let header = createSectionHeader("Yönetilen Tüneller (\(managedTunnels.count))", icon: "network", color: .systemTeal)
            menu.addItem(header)
            
            // Group tunnels by status
            let runningTunnels = managedTunnels.filter { $0.status == .running }
            let stoppedTunnels = managedTunnels.filter { $0.status == .stopped }
            let errorTunnels = managedTunnels.filter { $0.status == .error }
            let otherTunnels = managedTunnels.filter { ![.running, .stopped, .error].contains($0.status) }
            
            // Create groups with pagination
            createTunnelGroup(menu, title: "Çalışan", tunnels: runningTunnels, icon: "checkmark.circle.fill", color: .systemGreen, isCloudflaredAvailable: isCloudflaredAvailable)
            createTunnelGroup(menu, title: "Durmuş", tunnels: stoppedTunnels, icon: "stop.circle.fill", color: .systemGray, isCloudflaredAvailable: isCloudflaredAvailable)
            createTunnelGroup(menu, title: "Hatalı", tunnels: errorTunnels, icon: "exclamationmark.circle.fill", color: .systemRed, isCloudflaredAvailable: isCloudflaredAvailable)
            createTunnelGroup(menu, title: "Diğer", tunnels: otherTunnels, icon: "clock.circle.fill", color: .systemOrange, isCloudflaredAvailable: isCloudflaredAvailable)
            
            menu.addItem(createStyledSeparator())
        } else if managedTunnels.isEmpty && tunnelManager.quickTunnels.isEmpty && isCloudflaredAvailable {
            createModernMenuItem(menu, title: "Henüz Tünel Yok", icon: "network.slash", action: nil, color: .secondaryLabelColor, isEnabled: false)
            menu.addItem(createStyledSeparator())
        }
    }
    
    private func createControlActionsSection(_ menu: NSMenu, tunnelManager: TunnelManager, isCloudflaredAvailable: Bool) {
        let managedTunnels = tunnelManager.tunnels
        let quickTunnels = tunnelManager.quickTunnels
        
        createModernMenuItem(menu, title: "Gösterge Paneli", icon: "rectangle.grid.2x2.fill", action: #selector(openDashboardWindowAction), color: .systemBlue)
        
        let canStartAny = isCloudflaredAvailable && managedTunnels.contains { $0.isManaged && ($0.status == .stopped || $0.status == .error) }
        let canStopAny = isCloudflaredAvailable && (managedTunnels.contains { $0.isManaged && [.running, .stopping, .starting].contains($0.status) } || !quickTunnels.isEmpty)
        
        if canStartAny {
            createModernMenuItem(menu, title: "Tümünü Başlat", icon: "play.circle.fill", action: #selector(startAllManagedTunnelsAction), color: .systemGreen, isEnabled: canStartAny)
        }
        
        if canStopAny {
            createModernMenuItem(menu, title: "Tümünü Durdur", icon: "stop.circle.fill", action: #selector(stopAllTunnelsAction), color: .systemRed, isEnabled: canStopAny)
        }
        
        if canStartAny || canStopAny {
            createModernMenuItem(menu, title: "Listeyi Yenile", icon: "arrow.clockwise", action: #selector(refreshManagedTunnelListAction), color: .systemBlue, keyEquivalent: "r")
        }
        
        menu.addItem(createStyledSeparator())
    }
    
    private func createCreationToolsSection(_ menu: NSMenu, tunnelManager: TunnelManager, isCloudflaredAvailable: Bool) {
        createModernMenuItem(menu, title: "Hızlı Tünel Başlat", icon: "bolt.circle.fill", action: #selector(startQuickTunnelAction(_:)), color: .systemPurple, isEnabled: isCloudflaredAvailable, keyEquivalent: "t")
        
        createModernMenuItem(menu, title: "Yeni Yönetilen Tünel", icon: "doc.badge.plus", action: #selector(openCreateManagedTunnelWindow), color: .systemBlue, isEnabled: isCloudflaredAvailable, keyEquivalent: "n")
        
        let mampEnabled = isCloudflaredAvailable && FileManager.default.fileExists(atPath: tunnelManager.mampSitesDirectoryPath)
        createModernMenuItem(menu, title: "MAMP Sitesinden Oluştur", icon: "server.rack", action: #selector(openCreateFromMampWindow), color: .systemOrange, isEnabled: mampEnabled, tooltip: mampEnabled ? nil : "MAMP site dizini bulunamadı")
        
        menu.addItem(createStyledSeparator())
    }
    
    private func createManagementToolsSection(_ menu: NSMenu, tunnelManager: TunnelManager) {
        let foldersMenu = NSMenu()
        createModernMenuItem(foldersMenu, title: "~/.cloudflared", icon: "folder", action: #selector(openCloudflaredFolderAction), color: .systemBlue, isEnabled: FileManager.default.fileExists(atPath: tunnelManager.cloudflaredDirectoryPath))
        createModernMenuItem(foldersMenu, title: "MAMP Apache Conf", icon: "folder.badge.gearshape", action: #selector(openMampConfigFolderAction), color: .systemOrange, isEnabled: FileManager.default.fileExists(atPath: tunnelManager.mampConfigDirectoryPath))
        
        let foldersItem = createModernMenuItem(menu, title: "Klasörler", icon: "folder.fill", action: nil, color: .systemBlue)
        foldersItem.submenu = foldersMenu
        
        let filesMenu = NSMenu()
        createModernMenuItem(filesMenu, title: "httpd-vhosts.conf", icon: "doc.text", action: #selector(openMampVHostFileAction), color: .systemGreen, isEnabled: FileManager.default.fileExists(atPath: tunnelManager.mampVHostConfPath))
        createModernMenuItem(filesMenu, title: "httpd.conf", icon: "doc.text.fill", action: #selector(openMampHttpdConfFileAction), color: .systemTeal, isEnabled: FileManager.default.fileExists(atPath: tunnelManager.mampHttpdConfPath))
        
        let filesItem = createModernMenuItem(menu, title: "Dosyalar", icon: "doc.on.doc.fill", action: nil, color: .systemGreen)
        filesItem.submenu = filesMenu
        
        menu.addItem(createStyledSeparator())
    }
    
    private func createSystemToolsSection(_ menu: NSMenu, tunnelManager: TunnelManager, isCloudflaredAvailable: Bool) {
        let mampMenu = NSMenu()
        let mampScriptsExist = FileManager.default.isExecutableFile(atPath: "\(mampBinPath)/\(mampStartScript)")
        createModernMenuItem(mampMenu, title: "MAMP Başlat", icon: "play.circle.fill", action: #selector(startMampServersAction), color: .systemGreen, isEnabled: mampScriptsExist)
        createModernMenuItem(mampMenu, title: "MAMP Durdur", icon: "stop.circle.fill", action: #selector(stopMampServersAction), color: .systemRed, isEnabled: mampScriptsExist)
        
        let mampItem = createModernMenuItem(menu, title: "MAMP Kontrol", icon: "server.rack", action: nil, color: .systemOrange)
        mampItem.submenu = mampMenu
        
        let pythonMenu = NSMenu()
        let pythonScriptFullPath = (pythonProjectDirectoryPath as NSString).appendingPathComponent(pythonScriptPath)
        let pythonExists = FileManager.default.fileExists(atPath: pythonScriptFullPath)
        let pythonRunning = pythonAppProcess?.isRunning == true
        
        createModernMenuItem(pythonMenu, title: "Python Başlat", icon: "play.circle.fill", action: #selector(startPythonAppAction), color: .systemGreen, isEnabled: pythonExists && !pythonRunning)
        createModernMenuItem(pythonMenu, title: "Python Durdur", icon: "stop.circle.fill", action: #selector(stopPythonAppAction), color: .systemRed, isEnabled: pythonRunning)
        
        let pythonItem = createModernMenuItem(menu, title: "Python Panel", icon: "terminal.fill", action: nil, color: .systemYellow)
        pythonItem.submenu = pythonMenu
        
        menu.addItem(createStyledSeparator())
    }
    
    private func createFooterSection(_ menu: NSMenu, tunnelManager: TunnelManager) {
        createModernMenuItem(menu, title: "Kurulum Kılavuzu", icon: "book.fill", action: #selector(openSetupPdfAction), color: .systemPurple)
        
        if #available(macOS 13.0, *) {
            let launchAtLogin = tunnelManager.isLaunchAtLoginEnabled()
            let launchItem = createModernMenuItem(menu, title: "Otomatik Başlatma", icon: "power", action: #selector(toggleLaunchAtLoginAction(_:)), color: launchAtLogin ? .systemGreen : .systemGray)
            launchItem.state = launchAtLogin ? .on : .off
        }
        
        menu.addItem(createStyledSeparator())
        
        createModernMenuItem(menu, title: "Ayarlar...", icon: "gear", action: #selector(openSettingsWindowAction), color: .systemBlue, keyEquivalent: ",")
        let exitItem = NSMenuItem(title: "Çıkış", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        exitItem.target = NSApp // NSApplication'ı target olarak ayarla
        if let image = NSImage(systemSymbolName: "xmark.circle.fill", accessibilityDescription: "Çıkış") {
            let coloredImage = image.copy() as! NSImage
            coloredImage.isTemplate = true
            exitItem.image = coloredImage
        }
        menu.addItem(exitItem)
    }
    
    @discardableResult
    private func createModernMenuItem(_ menu: NSMenu, title: String, icon: String?, action: Selector?, color: NSColor = .labelColor, isEnabled: Bool = true, keyEquivalent: String = "", tooltip: String? = nil) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: keyEquivalent)
        item.target = self
        item.isEnabled = isEnabled
        
        if let icon = icon, let image = NSImage(systemSymbolName: icon, accessibilityDescription: title) {
            let coloredImage = image.copy() as! NSImage
            coloredImage.isTemplate = true // Template mode için daha iyi görünürlük
            item.image = coloredImage
        }
        
        if let tooltip = tooltip {
            item.toolTip = tooltip
        }
        
        menu.addItem(item)
        return item
    }
    
    private func createSectionHeader(_ title: String, icon: String, color: NSColor) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        
        if let image = NSImage(systemSymbolName: icon, accessibilityDescription: title) {
            let coloredImage = image.copy() as! NSImage
            coloredImage.isTemplate = true
            item.image = coloredImage
        }
        
        item.attributedTitle = NSAttributedString(string: title, attributes: [
            .foregroundColor: NSColor.secondaryLabelColor,
            .font: NSFont.systemFont(ofSize: 12, weight: .medium)
        ])
        
        return item
    }
    
    private func createStyledSeparator() -> NSMenuItem {
        return NSMenuItem.separator()
    }
    
    private func getQuickTunnelDisplayInfo(_ quickTunnelData: QuickTunnelData) -> (title: String, icon: String, color: NSColor, tooltip: String) {
        var tooltip = "Yerel: \(quickTunnelData.localURL)"
        
        if let url = quickTunnelData.publicURL {
            let displayURL = url.replacingOccurrences(of: "https://", with: "")
            tooltip += "\nGenel: \(url)\nTarayıcıda açmak için tıkla"
            if let pid = quickTunnelData.processIdentifier { tooltip += "\nPID: \(pid)" }
            return (displayURL, "link.circle.fill", .systemGreen, tooltip)
        } else if let error = quickTunnelData.lastError {
            tooltip += "\nHata: \(error)"
            return ("\(quickTunnelData.localURL) (Hata)", "exclamationmark.circle.fill", .systemRed, tooltip)
        } else {
            tooltip += "\nURL bekleniyor..."
            return ("\(quickTunnelData.localURL) (Başlatılıyor)", "clock.circle.fill", .systemOrange, tooltip)
        }
    }
    
    private func getManagedTunnelDisplayInfo(_ tunnel: TunnelInfo) -> (title: String, icon: String, color: NSColor, tooltip: String) {
        var tooltipParts = ["Durum: \(tunnel.status.displayName)"]
        if let uuid = tunnel.uuidFromConfig { tooltipParts.append("UUID: \(uuid)") }
        if let path = tunnel.configPath { tooltipParts.append("Config: \((path as NSString).abbreviatingWithTildeInPath)") }
        if let pid = tunnel.processIdentifier { tooltipParts.append("PID: \(pid)") }
        if let error = tunnel.lastError, !error.isEmpty { tooltipParts.append("Hata: \(error.split(separator: "\n").first ?? "")") }
        
        let tooltip = tooltipParts.joined(separator: "\n")
        
        switch tunnel.status {
        case .running:
            return (tunnel.name, "checkmark.circle.fill", .systemGreen, tooltip)
        case .stopped:
            return (tunnel.name, "stop.circle.fill", .systemGray, tooltip)
        case .starting:
            return ("\(tunnel.name) (Başlatılıyor)", "arrow.clockwise.circle", .systemOrange, tooltip)
        case .stopping:
            return ("\(tunnel.name) (Durduruluyor)", "stop.circle", .systemOrange, tooltip)
        case .error:
            return ("\(tunnel.name) (Hata)", "exclamationmark.circle.fill", .systemRed, tooltip)
        }
    }
    
    // MARK: - Compact Tunnel Group Management
    private func createTunnelGroup(_ menu: NSMenu, title: String, tunnels: [TunnelInfo], icon: String, color: NSColor, isCloudflaredAvailable: Bool) {
        guard !tunnels.isEmpty else { return }
        
        let maxItemsPerPage = 10
        let totalTunnels = tunnels.count
        
        if totalTunnels <= maxItemsPerPage {
            // Show all tunnels directly in a submenu
            let groupItem = createModernMenuItem(menu, title: "\(title) (\(totalTunnels))", icon: icon, action: nil, color: color)
            let groupSubMenu = NSMenu()
            
            for tunnel in tunnels {
                let (tunnelTitle, tunnelIcon, tunnelColor, tooltip) = getManagedTunnelDisplayInfo(tunnel)
                let tunnelItem = createModernMenuItem(groupSubMenu, title: tunnelTitle, icon: tunnelIcon, action: nil, color: tunnelColor, tooltip: tooltip)
                
                let tunnelSubMenu = NSMenu()
                createTunnelSubmenu(tunnelSubMenu, tunnel: tunnel, isCloudflaredAvailable: isCloudflaredAvailable)
                tunnelItem.submenu = tunnelSubMenu
            }
            
            groupItem.submenu = groupSubMenu
        } else {
            // Paginate tunnels
            let groupItem = createModernMenuItem(menu, title: "\(title) (\(totalTunnels))", icon: icon, action: nil, color: color)
            let groupSubMenu = NSMenu()
            
            let totalPages = (totalTunnels + maxItemsPerPage - 1) / maxItemsPerPage
            
            for pageIndex in 0..<totalPages {
                let startIndex = pageIndex * maxItemsPerPage
                let endIndex = min(startIndex + maxItemsPerPage, totalTunnels)
                let pageTunnels = Array(tunnels[startIndex..<endIndex])
                
                let pageTitle = totalPages > 1 ? "\(title) (\(startIndex + 1)-\(endIndex))" : title
                let pageItem = createModernMenuItem(groupSubMenu, title: pageTitle, icon: "doc.on.doc", action: nil, color: .secondaryLabelColor)
                let pageSubMenu = NSMenu()
                
                for tunnel in pageTunnels {
                    let (tunnelTitle, tunnelIcon, tunnelColor, tooltip) = getManagedTunnelDisplayInfo(tunnel)
                    let tunnelItem = createModernMenuItem(pageSubMenu, title: tunnelTitle, icon: tunnelIcon, action: nil, color: tunnelColor, tooltip: tooltip)
                    
                    let tunnelSubMenu = NSMenu()
                    createTunnelSubmenu(tunnelSubMenu, tunnel: tunnel, isCloudflaredAvailable: isCloudflaredAvailable)
                    tunnelItem.submenu = tunnelSubMenu
                }
                
                pageItem.submenu = pageSubMenu
            }
            
            groupItem.submenu = groupSubMenu
        }
    }
    
    private func createTunnelSubmenu(_ subMenu: NSMenu, tunnel: TunnelInfo, isCloudflaredAvailable: Bool) {
        let canToggle = tunnel.isManaged && tunnel.status != .starting && tunnel.status != .stopping && isCloudflaredAvailable
        let toggleTitle = (tunnel.status == .running) ? "Durdur" : "Başlat"
        let toggleColor: NSColor = (tunnel.status == .running) ? .systemRed : .systemGreen
        let toggleIcon = tunnel.status == .running ? "stop.circle.fill" : "play.circle.fill"
        
        createModernMenuItem(subMenu, title: toggleTitle, icon: toggleIcon, action: #selector(toggleManagedTunnelAction(_:)), color: toggleColor, isEnabled: canToggle).representedObject = tunnel
        
        subMenu.addItem(NSMenuItem.separator())
        
        let canOpenConfig = tunnel.configPath != nil && FileManager.default.fileExists(atPath: tunnel.configPath!)
        createModernMenuItem(subMenu, title: "Config Aç", icon: "doc.text", action: #selector(openConfigFileAction(_:)), color: .systemBlue, isEnabled: canOpenConfig).representedObject = tunnel
        
        createModernMenuItem(subMenu, title: "DNS Yönlendir", icon: "arrow.triangle.branch", action: #selector(routeDnsForTunnelAction(_:)), color: .systemPurple, isEnabled: tunnel.isManaged && isCloudflaredAvailable).representedObject = tunnel
        
        subMenu.addItem(NSMenuItem.separator())
        
        let canDelete = tunnel.isManaged && tunnel.status != .stopping && tunnel.status != .starting && isCloudflaredAvailable
        let deleteItem = createModernMenuItem(subMenu, title: "Sil...", icon: "trash.fill", action: #selector(deleteTunnelAction(_:)), color: .systemRed, isEnabled: canDelete, tooltip: "Cloudflare'dan kalıcı olarak siler!")
        deleteItem.representedObject = tunnel
    }
}
