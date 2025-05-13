
import SwiftUI
import UIKit

struct CustomTextInput: UIViewRepresentable {
    @Binding var text: String
    @Binding var isFocused: Bool
    let placeholder: String
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.font = .systemFont(ofSize: 17)
        textView.backgroundColor = .clear
        textView.textColor = .white
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 4, bottom: 8, right: 4)
        textView.isScrollEnabled = true
        // Max height calculation based on ~10 lines
        let maxHeight = textView.font?.lineHeight ?? 20 * 10 + textView.textContainerInset.top + textView.textContainerInset.bottom
        textView.constraints.forEach { constraint in
            if constraint.firstAttribute == .height {
                constraint.constant = maxHeight
            }
        }
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.text = text
        if text.isEmpty && !isFocused {
            uiView.text = placeholder
            uiView.textColor = UIColor.gray.withAlphaComponent(0.8)
        } else if uiView.text == placeholder && isFocused {
            uiView.text = ""
            uiView.textColor = .white
        }
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: CustomTextInput
        
        init(_ parent: CustomTextInput) {
            self.parent = parent
        }
        
        func textViewDidBeginEditing(_ textView: UITextView) {
            parent.isFocused = true
            if textView.text == parent.placeholder {
                textView.text = ""
                textView.textColor = .white
            }
        }
        
        func textViewDidEndEditing(_ textView: UITextView) {
            parent.isFocused = false
            if textView.text.isEmpty {
                textView.text = parent.placeholder
                textView.textColor = UIColor.gray.withAlphaComponent(0.8)
            }
        }
        
        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
        }
    }
}
