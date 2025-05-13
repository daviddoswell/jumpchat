import SwiftUI

struct StreamingText: View {
    let text: String
    let isStreaming: Bool
    
    @State private var displayedText: String = ""
    @State private var opacity: Double = 0
    
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    
    private var containsMarkdown: Bool {
        displayedText.contains("*") ||
        displayedText.contains("#") ||
        displayedText.contains("`") ||
        displayedText.contains("- ") ||
        displayedText.contains("1. ") ||
        displayedText.contains("|") ||
        displayedText.contains("\n")
    }
    
    private var attributedText: AttributedString {
        if containsMarkdown {
            do {
                return try AttributedString(markdown: displayedText)
            } catch {
                return AttributedString(displayedText)
            }
        }
        return AttributedString(displayedText)
    }
    
    var body: some View {
        Text(attributedText)
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
