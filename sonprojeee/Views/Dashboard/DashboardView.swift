import SwiftUI
import AppKit

struct DashboardView: View {
    @EnvironmentObject var manager: TunnelManager
    let openSettingsAction: (() -> Void)?
    let openQuickTunnelAction: (() -> Void)?
    let openManagedTunnelAction: (() -> Void)?
    private let backgroundGradient = LinearGradient(
        colors: [Color(.windowBackgroundColor), Color.blue.opacity(0.05)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    init(openSettingsAction: (() -> Void)? = nil,
         openQuickTunnelAction: (() -> Void)? = nil,
         openManagedTunnelAction: (() -> Void)? = nil) {
        self.openSettingsAction = openSettingsAction
        self.openQuickTunnelAction = openQuickTunnelAction
        self.openManagedTunnelAction = openManagedTunnelAction
    }

    private var managedTunnels: [TunnelInfo] {
        manager.tunnels.filter { $0.isManaged }
    }

    private var runningManagedCount: Int {
        managedTunnels.filter { $0.status == .running }.count
    }

    private var totalManagedCount: Int {
        managedTunnels.count
    }

    private var quickTunnelCount: Int {
        manager.quickTunnels.count
    }

    private var runningQuickCount: Int {
        manager.quickTunnels.filter { $0.publicURL != nil }.count
    }

    private var cloudflaredReady: Bool {
        FileManager.default.isExecutableFile(atPath: manager.cloudflaredExecutablePath)
    }

    private var progressForManaged: Double {
        guard totalManagedCount > 0 else { return 0 }
        return Double(runningManagedCount) / Double(totalManagedCount)
    }

    private var quickTunnelProgress: Double {
        guard quickTunnelCount > 0 else { return 0 }
        return Double(runningQuickCount) / Double(max(quickTunnelCount, 1))
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(spacing: 24) {
                    statusSection
                    tunnelOverviewSection
                    environmentSection
                    actionsSection
                }
                .padding(24)
            }
        }
        .frame(width: 680, height: 520)
        .background(backgroundGradient)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Gösterge Paneli")
                .font(.largeTitle.bold())
            Text("Cloudflared ve tünel altyapınızın anlık durumu")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 0)
                .fill(Color.blue.opacity(0.08))
                .overlay(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.2), Color.clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
    }

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Durum")
                .font(.title2.bold())

            VStack(spacing: 12) {
                ModernStatusIndicator(
                    status: cloudflaredReady ? .online : .warning,
                    title: cloudflaredReady ? "cloudflared hazır" : "cloudflared bulunamadı",
                    subtitle: manager.cloudflaredExecutablePath
                )

                ModernStatusIndicator(
                    status: runningManagedCount > 0 ? .online : .offline,
                    title: "Yönetilen Tüneller",
                    subtitle: "\(runningManagedCount) / \(totalManagedCount) aktif"
                )

                ModernStatusIndicator(
                    status: runningQuickCount > 0 ? .online : .offline,
                    title: "Hızlı Tüneller",
                    subtitle: quickTunnelCount == 0 ? "Henüz başlatılmadı" : "\(runningQuickCount) / \(quickTunnelCount) aktif"
                )
            }
        }
    }

    private var tunnelOverviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Tünel Özeti")
                .font(.title2.bold())

            HStack(spacing: 16) {
                ModernProgressCard(
                    title: "Yönetilen Tüneller",
                    progress: progressForManaged,
                    color: .blue,
                    icon: "network",
                    description: totalManagedCount == 0 ? "Henüz tünel yok" : "\(runningManagedCount) / \(totalManagedCount) aktif"
                )
                .frame(maxWidth: .infinity)

                ModernProgressCard(
                    title: "Hızlı Tüneller",
                    progress: quickTunnelProgress,
                    color: .purple,
                    icon: "bolt.fill",
                    description: quickTunnelCount == 0 ? "Henüz başlatılmadı" : "\(runningQuickCount) / \(quickTunnelCount) aktif"
                )
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var environmentSection: some View {
        ModernInfoPanel(
            title: "Ortam Bilgileri",
            items: [
                .init(label: "cloudflared", value: manager.cloudflaredExecutablePath, icon: "terminal"),
                .init(label: "MAMP Dizini", value: manager.mampBasePath, icon: "folder"),
                .init(label: "Durum Kontrolü", value: "\(Int(manager.checkInterval)) sn", icon: "clock"),
                .init(label: "Quick Tunnel Sayısı", value: "\(quickTunnelCount)", icon: "bolt.circle"),
                .init(label: "Tema", value: NSApp.effectiveAppearance.name.rawValue, icon: "paintbrush")
            ],
            color: .teal
        )
    }

    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Hızlı İşlemler")
                .font(.title2.bold())

            VStack(spacing: 12) {
                ModernActionButton(
                    title: "Ayarları Aç",
                    subtitle: "Yolları ve davranışı yapılandırın",
                    icon: "gearshape.fill",
                    color: .blue
                ) {
                    openSettings()
                }

                ModernActionButton(
                    title: "Hızlı Tünel Başlat",
                    subtitle: "Yerel sunucunuzu paylaşın",
                    icon: "bolt.circle.fill",
                    color: .purple
                ) {
                    openQuickTunnel()
                }

                ModernActionButton(
                    title: "Yeni Yönetilen Tünel",
                    subtitle: "Kalıcı tünel oluşturun",
                    icon: "plus.circle.fill",
                    color: .green
                ) {
                    openManagedTunnelCreator()
                }
            }
        }
    }
}

// MARK: - Window Actions
private extension DashboardView {
    func openSettings() {
        guard let action = openSettingsAction else {
            NSSound.beep()
            print("⚠️ Ayarlar penceresi için action belirtilmedi.")
            return
        }
        action()
    }

    func openQuickTunnel() {
        guard let action = openQuickTunnelAction else {
            NSSound.beep()
            print("⚠️ Quick Tunnel penceresi için action belirtilmedi.")
            return
        }
        action()
    }

    func openManagedTunnelCreator() {
        guard let action = openManagedTunnelAction else {
            NSSound.beep()
            print("⚠️ Yönetilen tünel penceresi için action belirtilmedi.")
            return
        }
        action()
    }
}

#Preview {
    DashboardView(
        openSettingsAction: {},
        openQuickTunnelAction: {},
        openManagedTunnelAction: {}
    )
    .environmentObject(TunnelManager())
}
