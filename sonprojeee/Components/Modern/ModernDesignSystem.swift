import SwiftUI

// MARK: - Modern Design System

/// Modern tasarım sistemi için temel renkler ve stillar
struct ModernDesignSystem {
    
    // MARK: - Colors
    struct Colors {
        static let primary = Color.blue
        static let secondary = Color.purple
        static let accent = Color.orange
        static let success = Color.green
        static let warning = Color.yellow
        static let error = Color.red
        static let info = Color.cyan
        
        // Glassmorphism colors
        static let glassBackground = Color.white.opacity(0.1)
        static let glassBorder = Color.white.opacity(0.2)
        static let glassOverlay = Color.white.opacity(0.05)
    }
    
    // MARK: - Typography
    struct Typography {
        static let largeTitle = Font.largeTitle.weight(.bold)
        static let title = Font.title.weight(.semibold)
        static let title2 = Font.title2.weight(.semibold)
        static let headline = Font.headline.weight(.medium)
        static let body = Font.body
        static let caption = Font.caption
        static let callout = Font.callout.weight(.medium)
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }
    
    // MARK: - Corner Radius
    struct CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let extraLarge: CGFloat = 20
        static let circle: CGFloat = 50
    }
    
    // MARK: - Shadows
    struct Shadows {
        static let light = Shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        static let medium = Shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        static let heavy = Shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
        static let colored = Shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
    }
    
    struct Shadow {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
    }
}

// MARK: - Modern View Modifiers

/// Glassmorphism efekti için modifier
struct GlassmorphismModifier: ViewModifier {
    let cornerRadius: CGFloat
    let opacity: Double
    let blur: CGFloat
    
    init(cornerRadius: CGFloat = ModernDesignSystem.CornerRadius.medium, 
         opacity: Double = 0.1, 
         blur: CGFloat = 10) {
        self.cornerRadius = cornerRadius
        self.opacity = opacity
        self.blur = blur
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
                                        Color.white.opacity(0.3),
                                        Color.white.opacity(0.1),
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

/// Hover efekti için modifier
struct HoverEffectModifier: ViewModifier {
    @State private var isHovered = false
    let scaleEffect: CGFloat
    let shadowIntensity: Double
    
    init(scaleEffect: CGFloat = 1.02, shadowIntensity: Double = 0.15) {
        self.scaleEffect = scaleEffect
        self.shadowIntensity = shadowIntensity
    }
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isHovered ? scaleEffect : 1.0)
            .shadow(
                color: .black.opacity(isHovered ? shadowIntensity : 0.08),
                radius: isHovered ? 12 : 6,
                x: 0,
                y: isHovered ? 6 : 3
            )
            .onHover { hovering in
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    isHovered = hovering
                }
            }
    }
}

/// Gradient border modifier
struct GradientBorderModifier: ViewModifier {
    let colors: [Color]
    let lineWidth: CGFloat
    let cornerRadius: CGFloat
    
    init(colors: [Color] = [.white.opacity(0.3), .clear], 
         lineWidth: CGFloat = 1, 
         cornerRadius: CGFloat = ModernDesignSystem.CornerRadius.medium) {
        self.colors = colors
        self.lineWidth = lineWidth
        self.cornerRadius = cornerRadius
    }
    
    func body(content: Content) -> some View {
        content
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: colors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: lineWidth
                    )
            }
    }
}

/// Animated gradient background modifier
struct AnimatedGradientModifier: ViewModifier {
    let colors: [Color]
    @State private var animateGradient = false
    
    init(colors: [Color]) {
        self.colors = colors
    }
    
    func body(content: Content) -> some View {
        content
            .background(
                LinearGradient(
                    colors: colors,
                    startPoint: animateGradient ? .topTrailing : .topLeading,
                    endPoint: animateGradient ? .bottomLeading : .bottomTrailing
                )
                .ignoresSafeArea()
                .onAppear {
                    withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                        animateGradient = true
                    }
                }
            )
    }
}

// MARK: - View Extensions

extension View {
    /// Glassmorphism efekti ekler
    func glassmorphism(cornerRadius: CGFloat = ModernDesignSystem.CornerRadius.medium,
                      opacity: Double = 0.1,
                      blur: CGFloat = 10) -> some View {
        self.modifier(GlassmorphismModifier(cornerRadius: cornerRadius, opacity: opacity, blur: blur))
    }
    
    /// Hover efekti ekler
    func hoverEffect(scaleEffect: CGFloat = 1.02, shadowIntensity: Double = 0.15) -> some View {
        self.modifier(HoverEffectModifier(scaleEffect: scaleEffect, shadowIntensity: shadowIntensity))
    }
    
    /// Gradient border ekler
    func gradientBorder(colors: [Color] = [.white.opacity(0.3), .clear],
                       lineWidth: CGFloat = 1,
                       cornerRadius: CGFloat = ModernDesignSystem.CornerRadius.medium) -> some View {
        self.modifier(GradientBorderModifier(colors: colors, lineWidth: lineWidth, cornerRadius: cornerRadius))
    }
    
    /// Animated gradient background ekler
    func animatedGradient(colors: [Color]) -> some View {
        self.modifier(AnimatedGradientModifier(colors: colors))
    }
    
    /// Modern card style
    func modernCard(padding: CGFloat = ModernDesignSystem.Spacing.lg) -> some View {
        self
            .padding(padding)
            .glassmorphism()
            .hoverEffect()
    }
    
    /// Modern button style
    func modernButton(color: Color = ModernDesignSystem.Colors.primary) -> some View {
        self
            .padding(.horizontal, ModernDesignSystem.Spacing.lg)
            .padding(.vertical, ModernDesignSystem.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.medium)
                    .fill(
                        LinearGradient(
                            colors: [color, color.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .foregroundColor(.white)
            .shadow(color: color.opacity(0.3), radius: 4, x: 0, y: 2)
            .hoverEffect(scaleEffect: 1.05)
    }
}

// MARK: - Design System Components

/// Temel kart bileşeni (ModernComponents.swift'teki detaylı versiyonlar için)
struct BaseCard<Content: View>: View {
    let content: Content
    let padding: CGFloat
    let cornerRadius: CGFloat
    
    init(padding: CGFloat = ModernDesignSystem.Spacing.lg,
         cornerRadius: CGFloat = ModernDesignSystem.CornerRadius.large,
         @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .glassmorphism(cornerRadius: cornerRadius)
            .hoverEffect()
    }
}

/// Modern buton bileşeni
struct ModernButton: View {
    let title: String
    let icon: String?
    let color: Color
    let action: () -> Void
    
    @State private var isPressed = false
    
    init(_ title: String, icon: String? = nil, color: Color = ModernDesignSystem.Colors.primary, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.color = color
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: ModernDesignSystem.Spacing.sm) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                }
                
                Text(title)
                    .font(ModernDesignSystem.Typography.callout)
            }
        }
        .modernButton(color: color)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

/// Modern badge bileşeni
struct ModernBadge: View {
    let text: String
    let color: Color
    
    init(_ text: String, color: Color = ModernDesignSystem.Colors.primary) {
        self.text = text
        self.color = color
    }
    
    var body: some View {
        Text(text)
            .font(ModernDesignSystem.Typography.caption)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, ModernDesignSystem.Spacing.md)
            .padding(.vertical, ModernDesignSystem.Spacing.xs)
            .background(
                Capsule()
                    .fill(color)
                    .shadow(color: color.opacity(0.3), radius: 2, x: 0, y: 1)
            )
    }
}

/// Modern progress indicator
struct ModernProgressIndicator: View {
    let progress: Double
    let color: Color
    let height: CGFloat
    
    init(progress: Double, color: Color = ModernDesignSystem.Colors.primary, height: CGFloat = 4) {
        self.progress = progress
        self.color = color
        self.height = height
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: height)
                
                // Progress
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(
                        LinearGradient(
                            colors: [color, color.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * progress, height: height)
                    .shadow(color: color.opacity(0.3), radius: 2, x: 0, y: 1)
            }
        }
        .frame(height: height)
    }
}

// MARK: - Animated Components

/// Shimmer loading efekti
struct ShimmerModifier: ViewModifier {
    @State private var isAnimating = false
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color.white.opacity(0.3),
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .rotationEffect(.degrees(30))
                    .offset(x: isAnimating ? 200 : -200)
                    .clipped()
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    isAnimating = true
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        self.modifier(ShimmerModifier())
    }
}
