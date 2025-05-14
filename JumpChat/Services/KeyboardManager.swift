import SwiftUI
import Combine

class KeyboardManager: ObservableObject {
    @Published private(set) var keyboardRect: CGRect = .zero
    @Published private(set) var isVisible = false
    @Published private(set) var inputOffset: CGFloat = -34  // Revert to -34 for better nestling
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Keyboard will show
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .compactMap { notification -> (CGRect, TimeInterval, UIView.AnimationCurve)? in
                guard let rect = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
                      let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
                      let curve = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt
                else { return nil }
                return (rect, duration, UIView.AnimationCurve(rawValue: Int(curve)) ?? .easeInOut)
            }
            .sink { [weak self] rect, duration, curve in
                guard let self = self else { return }
                withAnimation(.easeOut(duration: duration)) {
                    self.keyboardRect = rect
                    self.isVisible = true
                    self.inputOffset = 0  // Base position with keyboard
                }
            }
            .store(in: &cancellables)
        
        // Keyboard will hide
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .compactMap { notification -> TimeInterval? in
                notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval
            }
            .sink { [weak self] duration in
                guard let self = self else { return }
                withAnimation(.easeOut(duration: duration)) {
                    self.keyboardRect = .zero
                    self.isVisible = false
                    self.inputOffset = 48
                }
            }
            .store(in: &cancellables)
    }
    
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
