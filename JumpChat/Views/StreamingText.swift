import SwiftUI

struct StreamingText: View {
    let text: String
    let isStreaming: Bool
    
    @State private var displayedText: String = ""
    @State private var opacity: Double = 0
    
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    
    var body: some View {
        Text(ResponseParser.parse(displayedText))
            .textSelection(.enabled)
            .opacity(opacity)
            .animation(.easeIn(duration: 0.15), value: opacity)
            .onChange(of: text) { _, newText in
                displayedText = newText
                opacity = 1
                
                if isStreaming && displayedText.isEmpty {
                    feedbackGenerator.impactOccurred()
                }
            }
            .onAppear {
                displayedText = text
                opacity = 1
            }
    }
}
