import SwiftUI

// MARK: - Animation Library

/// Önceden tanımlanmış animasyon setleri
struct AnimationPresets {
    
    // MARK: - Basic Animations
    static let quickSpring = Animation.spring(response: 0.3, dampingFraction: 0.7)
    static let smoothSpring = Animation.spring(response: 0.5, dampingFraction: 0.8)
    static let bouncySpring = Animation.spring(response: 0.4, dampingFraction: 0.6)
    static let gentleSpring = Animation.spring(response: 0.8, dampingFraction: 0.9)
    
    static let quickEase = Animation.easeInOut(duration: 0.2)
    static let smoothEase = Animation.easeInOut(duration: 0.4)
    static let slowEase = Animation.easeInOut(duration: 0.6)
    
    // MARK: - Complex Animations
    static let cardFlip = Animation.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0.2)
    static let slideIn = Animation.spring(response: 0.5, dampingFraction: 0.75)
    static let fadeInOut = Animation.easeInOut(duration: 0.3)
    static let scaleEffect = Animation.spring(response: 0.3, dampingFraction: 0.6)
    
    // MARK: - Loading Animations
    static let pulse = Animation.easeInOut(duration: 1).repeatForever(autoreverses: true)
    static let rotate = Animation.linear(duration: 2).repeatForever(autoreverses: false)
    static let breathe = Animation.easeInOut(duration: 2).repeatForever(autoreverses: true)
    
    // MARK: - Interaction Animations
    static let buttonPress = Animation.easeInOut(duration: 0.1)
    static let hoverEffect = Animation.spring(response: 0.4, dampingFraction: 0.7)
    static let tapFeedback = Animation.easeOut(duration: 0.15)
}

// MARK: - Custom Animation Modifiers

/// Fade in animasyonu
struct FadeInModifier: ViewModifier {
    @State private var opacity: Double = 0
    let delay: Double
    let duration: Double
    
    init(delay: Double = 0, duration: Double = 0.5) {
        self.delay = delay
        self.duration = duration
    }
    
    func body(content: Content) -> some View {
        content
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeIn(duration: duration).delay(delay)) {
                    opacity = 1
                }
            }
    }
}

/// Slide in animasyonu
struct SlideInModifier: ViewModifier {
    @State private var offset: CGFloat = 50
    let direction: SlideDirection
    let delay: Double
    let duration: Double
    
    enum SlideDirection {
        case top, bottom, left, right
        
        func initialOffset(value: CGFloat) -> (x: CGFloat, y: CGFloat) {
            switch self {
            case .top: return (0, -value)
            case .bottom: return (0, value)
            case .left: return (-value, 0)
            case .right: return (value, 0)
            }
        }
    }
    
    init(from direction: SlideDirection = .bottom, delay: Double = 0, duration: Double = 0.5) {
        self.direction = direction
        self.delay = delay
        self.duration = duration
    }
    
    func body(content: Content) -> some View {
        let initialOffset = direction.initialOffset(value: offset)
        
        content
            .offset(x: offset == 0 ? 0 : initialOffset.x, y: offset == 0 ? 0 : initialOffset.y)
            .opacity(offset == 0 ? 1 : 0)
            .onAppear {
                withAnimation(.spring(response: duration, dampingFraction: 0.8).delay(delay)) {
                    offset = 0
                }
            }
    }
}

/// Scale in animasyonu
struct ScaleInModifier: ViewModifier {
    @State private var scale: CGFloat = 0.8
    let delay: Double
    let duration: Double
    
    init(delay: Double = 0, duration: Double = 0.5) {
        self.delay = delay
        self.duration = duration
    }
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .opacity(scale == 1 ? 1 : 0)
            .onAppear {
                withAnimation(.spring(response: duration, dampingFraction: 0.7).delay(delay)) {
                    scale = 1
                }
            }
    }
}

/// Rotation animasyonu
struct RotationModifier: ViewModifier {
    @State private var rotation: Double = 0
    let duration: Double
    let repeats: Bool
    
    init(duration: Double = 2, repeats: Bool = true) {
        self.duration = duration
        self.repeats = repeats
    }
    
    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(rotation))
            .onAppear {
                let animation = repeats ? 
                    Animation.linear(duration: duration).repeatForever(autoreverses: false) :
                    Animation.linear(duration: duration)
                
                withAnimation(animation) {
                    rotation = 360
                }
            }
    }
}

/// Pulse animasyonu
struct PulseModifier: ViewModifier {
    @State private var scale: CGFloat = 1
    let minScale: CGFloat
    let maxScale: CGFloat
    let duration: Double
    
    init(minScale: CGFloat = 0.95, maxScale: CGFloat = 1.05, duration: Double = 1) {
        self.minScale = minScale
        self.maxScale = maxScale
        self.duration = duration
    }
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .onAppear {
                withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
                    scale = scale == minScale ? maxScale : minScale
                }
            }
    }
}

/// Shake animasyonu
struct ShakeModifier: ViewModifier {
    @State private var offset: CGFloat = 0
    let intensity: CGFloat
    let duration: Double
    
    init(intensity: CGFloat = 10, duration: Double = 0.5) {
        self.intensity = intensity
        self.duration = duration
    }
    
    func body(content: Content) -> some View {
        content
            .offset(x: offset)
            .onAppear {
                let animation = Animation.easeInOut(duration: duration / 8).repeatCount(8, autoreverses: true)
                withAnimation(animation) {
                    offset = intensity
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                    offset = 0
                }
            }
    }
}

/// Typewriter efekti
struct TypewriterModifier: ViewModifier {
    @State private var displayedText: String = ""
    let fullText: String
    let speed: Double
    
    init(text: String, speed: Double = 0.1) {
        self.fullText = text
        self.speed = speed
    }
    
    func body(content: Content) -> some View {
        Text(displayedText)
            .onAppear {
                startTypewriting()
            }
    }
    
    private func startTypewriting() {
        displayedText = ""
        for (index, character) in fullText.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * speed) {
                displayedText += String(character)
            }
        }
    }
}

// MARK: - Particle Effects

/// Konfeti efekti
struct ConfettiModifier: ViewModifier {
    @State private var particles: [ConfettiParticle] = []
    let colors: [Color]
    let particleCount: Int
    
    init(colors: [Color] = [.red, .blue, .green, .yellow, .purple], particleCount: Int = 50) {
        self.colors = colors
        self.particleCount = particleCount
    }
    
    func body(content: Content) -> some View {
        content
            .overlay {
                ZStack {
                    ForEach(particles, id: \.id) { particle in
                        Circle()
                            .fill(particle.color)
                            .frame(width: particle.size, height: particle.size)
                            .position(x: particle.x, y: particle.y)
                            .opacity(particle.opacity)
                    }
                }
                .allowsHitTesting(false)
            }
            .onAppear {
                createParticles()
                animateParticles()
            }
    }
    
    private func createParticles() {
        particles = (0..<particleCount).map { _ in
            ConfettiParticle(
                id: UUID(),
                x: CGFloat.random(in: 0...400),
                y: -50,
                color: colors.randomElement() ?? .blue,
                size: CGFloat.random(in: 4...12),
                opacity: 1.0
            )
        }
    }
    
    private func animateParticles() {
        withAnimation(.linear(duration: 3)) {
            for i in particles.indices {
                particles[i].y = 600
                particles[i].x += CGFloat.random(in: -100...100)
                particles[i].opacity = 0
            }
        }
    }
}

struct ConfettiParticle {
    let id: UUID
    var x: CGFloat
    var y: CGFloat
    let color: Color
    let size: CGFloat
    var opacity: Double
}

// MARK: - View Extensions

extension View {
    /// Fade in animasyonu ekler
    func fadeIn(delay: Double = 0, duration: Double = 0.5) -> some View {
        self.modifier(FadeInModifier(delay: delay, duration: duration))
    }
    
    /// Slide in animasyonu ekler
    func slideIn(from direction: SlideInModifier.SlideDirection = .bottom, delay: Double = 0, duration: Double = 0.5) -> some View {
        self.modifier(SlideInModifier(from: direction, delay: delay, duration: duration))
    }
    
    /// Scale in animasyonu ekler
    func scaleIn(delay: Double = 0, duration: Double = 0.5) -> some View {
        self.modifier(ScaleInModifier(delay: delay, duration: duration))
    }
    
    /// Rotation animasyonu ekler
    func rotating(duration: Double = 2, repeats: Bool = true) -> some View {
        self.modifier(RotationModifier(duration: duration, repeats: repeats))
    }
    
    /// Pulse animasyonu ekler
    func pulsing(minScale: CGFloat = 0.95, maxScale: CGFloat = 1.05, duration: Double = 1) -> some View {
        self.modifier(PulseModifier(minScale: minScale, maxScale: maxScale, duration: duration))
    }
    
    /// Shake animasyonu ekler
    func shaking(intensity: CGFloat = 10, duration: Double = 0.5) -> some View {
        self.modifier(ShakeModifier(intensity: intensity, duration: duration))
    }
    
    /// Konfeti efekti ekler
    func confetti(colors: [Color] = [.red, .blue, .green, .yellow, .purple], particleCount: Int = 50) -> some View {
        self.modifier(ConfettiModifier(colors: colors, particleCount: particleCount))
    }
    
    /// Animasyonlu geçiş efekti
    func animatedTransition<T: Equatable>(_ value: T, animation: Animation = AnimationPresets.smoothSpring) -> some View {
        self.animation(animation, value: value)
    }
}

// MARK: - Custom Transition Effects

extension AnyTransition {
    /// Özel slide geçişi
    static func customSlide(from edge: Edge, distance: CGFloat = 100) -> AnyTransition {
        let insertion = AnyTransition.move(edge: edge).combined(with: .opacity)
        let removal = AnyTransition.move(edge: edge.opposite).combined(with: .opacity)
        return .asymmetric(insertion: insertion, removal: removal)
    }
    
    /// Özel scale geçişi
    static var customScale: AnyTransition {
        .scale(scale: 0.8).combined(with: .opacity)
    }
    
    /// Özel flip geçişi
    static var flip: AnyTransition {
        .modifier(
            active: FlipModifier(flipped: true),
            identity: FlipModifier(flipped: false)
        )
    }
}

private extension Edge {
    var opposite: Edge {
        switch self {
        case .top: return .bottom
        case .bottom: return .top
        case .leading: return .trailing
        case .trailing: return .leading
        }
    }
}

struct FlipModifier: ViewModifier {
    let flipped: Bool
    
    func body(content: Content) -> some View {
        content
            .rotation3DEffect(
                .degrees(flipped ? 180 : 0),
                axis: (x: 0, y: 1, z: 0)
            )
            .opacity(flipped ? 0 : 1)
    }
}

// MARK: - Advanced Animation Components

/// Loading dots animasyonu
struct LoadingDots: View {
    @State private var animating = false
    let dotCount: Int
    let color: Color
    
    init(dotCount: Int = 3, color: Color = .blue) {
        self.dotCount = dotCount
        self.color = color
    }
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<dotCount, id: \.self) { index in
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                    .scaleEffect(animating ? 1.5 : 1.0)
                    .opacity(animating ? 0.5 : 1.0)
                    .animation(
                        .easeInOut(duration: 0.6)
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.2),
                        value: animating
                    )
            }
        }
        .onAppear {
            animating = true
        }
    }
}

/// Wave loading animasyonu
struct WaveLoading: View {
    @State private var animating = false
    let barCount: Int
    let color: Color
    
    init(barCount: Int = 5, color: Color = .blue) {
        self.barCount = barCount
        self.color = color
    }
    
    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<barCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(color)
                    .frame(width: 4, height: animating ? 20 : 10)
                    .animation(
                        .easeInOut(duration: 0.8)
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.1),
                        value: animating
                    )
            }
        }
        .onAppear {
            animating = true
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 30) {
        Text("Animasyon Örnekleri")
            .font(.title)
            .fadeIn(delay: 0.2)
        
        HStack(spacing: 20) {
            RoundedRectangle(cornerRadius: 12)
                .fill(.blue)
                .frame(width: 60, height: 60)
                .slideIn(from: .left, delay: 0.4)
            
            RoundedRectangle(cornerRadius: 12)
                .fill(.green)
                .frame(width: 60, height: 60)
                .scaleIn(delay: 0.6)
            
            RoundedRectangle(cornerRadius: 12)
                .fill(.orange)
                .frame(width: 60, height: 60)
                .slideIn(from: .right, delay: 0.8)
        }
        
        LoadingDots()
        WaveLoading()
    }
    .padding()
    .frame(width: 400, height: 300)
}
