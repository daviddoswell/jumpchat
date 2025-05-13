

import SwiftUI

struct SlideTransition: ViewModifier {
    let isPresented: Bool
    
    func body(content: Content) -> some View {
        content
            .frame(width: UIScreen.main.bounds.width * 0.85)
            .background(Color(.systemBackground))
            .offset(x: isPresented ? 0 : -UIScreen.main.bounds.width)
            .animation(.spring(response: 0.3, dampingFraction: 1), value: isPresented)
    }
}

extension View {
    func slideTransition(isPresented: Bool) -> some View {
        modifier(SlideTransition(isPresented: isPresented))
    }
}

