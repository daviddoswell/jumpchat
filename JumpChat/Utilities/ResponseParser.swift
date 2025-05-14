import SwiftUI

struct ResponseParser {
    static func parse(_ text: String) -> AttributedString {
        do {
            let options = AttributedString.MarkdownParsingOptions(
                interpretedSyntax: .inlineOnlyPreservingWhitespace
            )
            
            var result = try AttributedString(markdown: text, options: options)
            
            // Apply base style
            var baseAttributes = AttributeContainer()
            baseAttributes.font = .system(size: 16)
            baseAttributes.foregroundColor = .white
            result.mergeAttributes(baseAttributes)
            
            // Apply styles to markdown elements
            let lines = text.components(separatedBy: .newlines)
            var processedText = ""
            var inList = false
            
            for line in lines {
                let trimmedLine = line.trimmingCharacters(in: .whitespaces)
                
                // Handle section titles (e.g., "Pros of Using Sunscreen:")
                if trimmedLine.hasSuffix(":") && !trimmedLine.hasPrefix("-") {
                    if inList { processedText += "\n" }
                    processedText += "\n\(line)\n"
                    inList = false
                    continue
                }
                
                // Handle list items
                if trimmedLine.hasPrefix("-") || trimmedLine.hasPrefix("•") {
                    if !inList && !processedText.isEmpty { processedText += "\n" }
                    processedText += "\(line)\n"
                    inList = true
                    continue
                }
                
                // Handle regular paragraphs
                if !trimmedLine.isEmpty {
                    if inList { processedText += "\n" }
                    processedText += "\(line)\n"
                    inList = false
                }
            }
            
            // Create final attributed string
            result = try AttributedString(markdown: processedText, options: options)
            result.mergeAttributes(baseAttributes)
            
            // Apply specific styles
            let sections = processedText.components(separatedBy: .newlines)
            for section in sections {
                guard let sectionRange = result.range(of: section) else { continue }
                
                // Style section headers
                if section.hasSuffix(":") && !section.hasPrefix("-") {
                    var headerAttributes = AttributeContainer()
                    headerAttributes.font = .system(size: 16, weight: .bold)
                    result[sectionRange].mergeAttributes(headerAttributes)
                }
                
                // Style list items
                if section.hasPrefix("-") || section.hasPrefix("•") {
                    var listAttributes = AttributeContainer()
                    listAttributes.font = .system(size: 16)
                    result[sectionRange].mergeAttributes(listAttributes)
                }
            }
            
            return result
            
        } catch {
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
