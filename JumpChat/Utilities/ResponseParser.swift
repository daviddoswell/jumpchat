import SwiftUI

struct ResponseParser {
    static func parse(_ text: String) -> AttributedString {
        do {
            // Configure markdown parsing options
            let options = AttributedString.MarkdownParsingOptions(
                interpretedSyntax: .inlineOnlyPreservingWhitespace
            )
            
            // Create attributed string from markdown
            var result = try AttributedString(markdown: text, options: options)
            
            // Apply base style
            var baseAttributes = AttributeContainer()
            baseAttributes.font = .system(size: 16)
            baseAttributes.foregroundColor = .white
            result.mergeAttributes(baseAttributes)
            
            // Apply styles to markdown elements
            let lines = text.components(separatedBy: .newlines)
            for (index, line) in lines.enumerated() {
                guard let lineRange = result.range(of: line) else { continue }
                
                // Headers (##)
                if line.hasPrefix("##") {
                    var headerAttributes = AttributeContainer()
                    headerAttributes.font = .system(size: 18, weight: .bold)
                    headerAttributes.foregroundColor = .white
                    result[lineRange].mergeAttributes(headerAttributes)
                }
                
                // Lists
                if line.hasPrefix("- ") || line.hasPrefix("• ") {
                    // Add proper indentation
                    if !line.hasPrefix("  ") {
                        result.characters.insert(contentsOf: "  ", at: lineRange.lowerBound)
                    }
                }
                
                // Add paragraph spacing
                if index < lines.count - 1 {
                    let nextLine = lines[index + 1]
                    let shouldAddSpace = !line.isEmpty &&
                                      !nextLine.isEmpty &&
                                      (line.hasSuffix(".") ||
                                       line.hasSuffix(":") ||
                                       line.hasSuffix("?") ||
                                       nextLine.hasPrefix("##") ||
                                       nextLine.hasPrefix("-") ||
                                       nextLine.hasPrefix("•"))
                    
                    if shouldAddSpace {
                        if let endOfLine = result.range(of: line)?.upperBound {
                            result.characters.insert(contentsOf: "\n", at: endOfLine)
                        }
                    }
                }
            }
            
            return result
            
        } catch {
            // Fallback if markdown parsing fails
            var result = AttributedString(text)
            var attributes = AttributeContainer()
            attributes.font = .system(size: 16)
            attributes.foregroundColor = .white
            result.mergeAttributes(attributes)
            return result
        }
    }
}

private extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
