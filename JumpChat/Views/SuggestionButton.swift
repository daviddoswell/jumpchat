import SwiftUI

struct SuggestionButton: View {
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .fontWeight(.medium)
                    .font(.system(size: 15))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(subtitle)
                    .foregroundColor(.gray.opacity(0.8))
                    .font(.system(size: 13))
                    .lineLimit(1)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color(white: 0.17))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(white: 0.3), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }
}

struct SuggestionButton_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            HStack {
                SuggestionButton(
                    title: "Short",
                    subtitle: "test",
                    action: {}
                )
                SuggestionButton(
                    title: "Create a painting",
                    subtitle: "in Renaissance-style",
                    action: {}
                )
                SuggestionButton(
                    title: "A much longer suggestion title",
                    subtitle: "with longer subtitle text here",
                    action: {}
                )
            }
            .padding()
        }
    }
}
