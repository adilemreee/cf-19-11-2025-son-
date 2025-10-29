import SwiftUI

// MARK: - Modern Status Indicator

/// Modern durum göstergesi bileşeni
struct ModernStatusIndicator: View {
    let status: StatusType
    let title: String
    let subtitle: String?
    
    enum StatusType {
        case online, offline, warning, error, loading
        
        var color: Color {
            switch self {
            case .online: return .green
            case .offline: return .gray
            case .warning: return .orange
            case .error: return .red
            case .loading: return .blue
            }
        }
        
        var icon: String {
            switch self {
            case .online: return "checkmark.circle.fill"
            case .offline: return "xmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .error: return "exclamationmark.octagon.fill"
            case .loading: return "arrow.clockwise"
            }
        }
        
        var animation: Animation? {
            switch self {
            case .loading: return .linear(duration: 1).repeatForever(autoreverses: false)
            default: return nil
            }
        }
    }
    
    init(status: StatusType, title: String, subtitle: String? = nil) {
        self.status = status
        self.title = title
        self.subtitle = subtitle
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Status icon with pulse effect
            ZStack {
                Circle()
                    .fill(status.color.opacity(0.2))
                    .frame(width: 32, height: 32)
                    .scaleEffect(status == .loading ? 1.2 : 1.0)
                    .opacity(status == .loading ? 0.3 : 1.0)
                    .animation(status.animation, value: status == .loading)
                
                Image(systemName: status.icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(status.color)
                    .rotationEffect(.degrees(status == .loading ? 360 : 0))
                    .animation(status.animation, value: status == .loading)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(status.color.opacity(0.3), lineWidth: 1)
                }
        )
        .shadow(color: status.color.opacity(0.2), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Modern Progress Card

/// Modern ilerleme kartı bileşeni
struct ModernProgressCard: View {
    let title: String
    let progress: Double
    let color: Color
    let icon: String
    let description: String?
    
    @State private var animatedProgress: Double = 0
    
    init(title: String, progress: Double, color: Color = .blue, icon: String, description: String? = nil) {
        self.title = title
        self.progress = progress
        self.color = color
        self.icon = icon
        self.description = description
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    if let description = description {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Text("\(Int(progress * 100))%")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(color)
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                    
                    // Progress
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [color, color.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * animatedProgress, height: 8)
                        .overlay {
                            // Shimmer effect
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.clear,
                                            Color.white.opacity(0.4),
                                            Color.clear
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: 30)
                                .offset(x: animatedProgress > 0 ? (geometry.size.width * animatedProgress - 15) : -30)
                                .clipped()
                        }
                }
            }
            .frame(height: 8)
        }
        .padding(20)
        .background(
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
        )
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        .onAppear {
            withAnimation(.easeOut(duration: 1.5)) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(.easeOut(duration: 0.5)) {
                animatedProgress = newValue
            }
        }
    }
}

// MARK: - Modern Info Panel

/// Modern bilgi paneli bileşeni
struct ModernInfoPanel: View {
    let title: String
    let items: [InfoItem]
    let color: Color
    
    struct InfoItem {
        let label: String
        let value: String
        let icon: String?
        
        init(label: String, value: String, icon: String? = nil) {
            self.label = label
            self.value = value
            self.icon = icon
        }
    }
    
    init(title: String, items: [InfoItem], color: Color = .blue) {
        self.title = title
        self.items = items
        self.color = color
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                Spacer()
                
                Image(systemName: "info.circle")
                    .font(.title3)
                    .foregroundColor(color.opacity(0.7))
            }
            
            // Items
            VStack(spacing: 12) {
                ForEach(items.indices, id: \.self) { index in
                    let item = items[index]
                    
                    HStack {
                        if let icon = item.icon {
                            Image(systemName: icon)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(color)
                                .frame(width: 20)
                        }
                        
                        Text(item.label)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(item.value)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                    .slideIn(from: .right, delay: Double(index) * 0.1, duration: 0.3)
                    
                    if index < items.count - 1 {
                        Divider()
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                }
        )
        .shadow(color: color.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Modern Action Button

/// Modern aksiyon butonu bileşeni
struct ModernActionButton: View {
    let title: String
    let subtitle: String?
    let icon: String
    let color: Color
    let action: () -> Void
    
    @State private var isPressed = false
    @State private var isHovered = false
    
    init(title: String, subtitle: String? = nil, icon: String, color: Color = .blue, action: @escaping () -> Void) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 50, height: 50)
                        .overlay {
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.3), Color.clear],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        }
                    
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(color)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Arrow
                Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
                    .offset(x: isHovered ? 4 : 0)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(isHovered ? 0.4 : 0.2),
                                        Color.clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }
            )
            .shadow(
                color: .black.opacity(isHovered ? 0.15 : 0.08),
                radius: isHovered ? 12 : 6,
                x: 0,
                y: isHovered ? 6 : 3
            )
            .scaleEffect(isPressed ? 0.98 : (isHovered ? 1.02 : 1.0))
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                isHovered = hovering
            }
        }
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Modern Notification Banner

/// Modern bildirim banner bileşeni
struct ModernNotificationBanner: View {
    let type: NotificationType
    let title: String
    let message: String
    let action: (() -> Void)?
    let onDismiss: () -> Void
    
    @State private var isVisible = false
    
    enum NotificationType {
        case success, error, warning, info
        
        var color: Color {
            switch self {
            case .success: return .green
            case .error: return .red
            case .warning: return .orange
            case .info: return .blue
            }
        }
        
        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .error: return "exclamationmark.triangle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .info: return "info.circle.fill"
            }
        }
    }
    
    init(type: NotificationType, title: String, message: String, action: (() -> Void)? = nil, onDismiss: @escaping () -> Void) {
        self.type = type
        self.title = title
        self.message = message
        self.action = action
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: type.icon)
                .font(.title3)
                .foregroundColor(type.color)
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
            
            // Action button
            if let action = action {
                Button("İşlem") {
                    action()
                }
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(type.color)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            
            // Dismiss button
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(type.color.opacity(0.3), lineWidth: 1)
                }
        )
        .shadow(color: type.color.opacity(0.2), radius: 8, x: 0, y: 4)
        .offset(y: isVisible ? 0 : -100)
        .opacity(isVisible ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                isVisible = true
            }
            
            // Auto dismiss after 5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isVisible = false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    onDismiss()
                }
            }
        }
    }
}

// MARK: - Modern Toggle Switch

/// Modern toggle anahtarı bileşeni
struct ModernToggleSwitch: View {
    @Binding var isOn: Bool
    let title: String
    let subtitle: String?
    let color: Color
    
    init(title: String, subtitle: String? = nil, color: Color = .blue, isOn: Binding<Bool>) {
        self.title = title
        self.subtitle = subtitle
        self.color = color
        self._isOn = isOn
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Custom toggle
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isOn.toggle()
                }
            }) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(isOn ? color : Color.gray.opacity(0.3))
                    .frame(width: 50, height: 30)
                    .overlay {
                        Circle()
                            .fill(.white)
                            .frame(width: 26, height: 26)
                            .offset(x: isOn ? 10 : -10)
                            .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                    }
                    .shadow(color: isOn ? color.opacity(0.3) : Color.clear, radius: 4, x: 0, y: 2)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        ModernStatusIndicator(
            status: .online,
            title: "Cloudflare Bağlantısı",
            subtitle: "Tüm sistemler çalışıyor"
        )
        
        ModernProgressCard(
            title: "Tünel Kurulumu",
            progress: 0.75,
            color: .blue,
            icon: "network",
            description: "Yapılandırma tamamlanıyor..."
        )
        
        ModernActionButton(
            title: "Yeni Tünel Oluştur",
            subtitle: "Hızlı ve kolay kurulum",
            icon: "plus.circle.fill",
            color: .green
        ) {
            print("Action tapped")
        }
        
        ModernToggleSwitch(
            title: "Otomatik Başlatma",
            subtitle: "Sistem açılışında otomatik başlat",
            color: .orange,
            isOn: .constant(true)
        )
    }
    .padding()
    .frame(width: 400)
}
