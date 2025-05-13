

import SwiftUI

struct StreamingText: View {
    let text: String
    let isStreaming: Bool
    
    @State private var displayedText: String = ""
    @State private var opacity: Double = 0
    
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    
    var body: some View {
        Text(displayedText)
            .opacity(opacity)
            .animation(.easeIn(duration: 0.15), value: opacity)
            .onChange(of: text) { _, newText in
                if isStreaming {
                    let isFirstToken = displayedText.isEmpty
                    displayedText = newText
                    opacity = 1
                    
                    if isFirstToken {
                        feedbackGenerator.impactOccurred()
                    }
                }
            }
            .onAppear {
                if !isStreaming {
                    displayedText = text
                    opacity = 1
                }
            }
    }
}
