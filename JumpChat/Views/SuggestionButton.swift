import SwiftUI

struct SuggestionButton: View {
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .fontWeight(.medium)
                    .font(.system(size: 14))
                Text(subtitle)
                    .foregroundColor(.gray)
                    .font(.system(size: 12))
            }
            .frame(width: 200, alignment: .leading)
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}
