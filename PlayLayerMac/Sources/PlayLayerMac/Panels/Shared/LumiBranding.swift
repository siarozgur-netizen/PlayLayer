import SwiftUI

struct LumiOrbView: View {
    let size: CGFloat
    var opacity: Double = 1

    var body: some View {
        Image("LumiOrb", bundle: .module)
            .resizable()
            .interpolation(.high)
            .antialiased(true)
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
            .opacity(opacity)
            .shadow(color: Color(red: 0.23, green: 0.47, blue: 0.78).opacity(0.16), radius: size * 0.12, x: 0, y: size * 0.05)
    }
}
