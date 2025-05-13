import SwiftUI
import Combine

class KeyboardManager: ObservableObject {
    @Published private(set) var keyboardRect: CGRect = .zero
    @Published private(set) var isVisible = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Keyboard will show
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .compactMap { notification -> CGRect? in
                notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
            }
            .sink { [weak self] rect in
                guard let self = self else { return }
                withAnimation(.easeOut(duration: 0.25)) {
                    self.keyboardRect = rect
                    self.isVisible = true
                }
            }
            .store(in: &cancellables)
        
        // Keyboard will hide
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .sink { [weak self] _ in
                guard let self = self else { return }
                withAnimation(.easeOut(duration: 0.25)) {
                    self.keyboardRect = .zero
                    self.isVisible = false
                }
            }
            .store(in: &cancellables)
    }
    
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
