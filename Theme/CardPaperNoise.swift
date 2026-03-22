import SwiftUI

/// Subtle 3.5% opacity grain on elevated cards (spec: feTurbulence-style; implemented as sparse dot field).
struct CardPaperNoise: View {
    var body: some View {
        Canvas { context, size in
            var rng = StableRNG(seed: 99)
            let dotCount = Int(size.width * size.height * 0.002)
            for _ in 0..<dotCount {
                let x = CGFloat.random(in: 0...size.width, using: &rng)
                let y = CGFloat.random(in: 0...size.height, using: &rng)
                context.fill(
                    Path(ellipseIn: CGRect(x: x, y: y, width: 1, height: 1)),
                    with: .color(.black.opacity(0.035))
                )
            }
        }
        .allowsHitTesting(false)
    }
}

extension View {
    func cardPaperNoise() -> some View {
        overlay { CardPaperNoise().clipShape(Rectangle()) }
    }
}
