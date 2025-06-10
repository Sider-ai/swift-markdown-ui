//
//  SiderMarkdown.swift
//  swift-markdown-ui
//
//  Created by Avery on 2025/2/21.
//

import Foundation

public enum SiderMarkdown {
    public static let siderLinkPrefix = "@_"
    
    public static let siderSerialPrefix = "&_"
    
    public static let referenceScheme = "reference"
    public static let relatedScheme = "related"
    
    public static var serialLinkPattern: String {
        #"(?:(?:【\^|【C_|\^【)(\d{1,2})】|(?:\[\^|\[C_|\^\[)(\d{1,2})\])(?=\(.+\:\/\/.+)"#
    }
    
    public static var serialNumberPattern: String {
        #"(?:【\^|【C_|\^【)(\d+)】|(?:\[\^|\[C_|\^\[)(\d+)\]|\[(\^\d+(?:,\^\d+)*)\]|\[ref:(\s?\d+(?:,\s?\d+)*)\]"#
    }
}

extension SiderMarkdown {
    static func preprocessMarkdown(_ text: String) -> String {
        var result = LatexParser.preprocess(in: text)
        // 首先，替换序号链接的情况 [^1](http://...) -> [sider_1](http://...)
        replaceSerialLink(&result)
        // 然后，替换自由序号的情况 [^1] -> [1](reference://)
        replaceSerialNumberToLink(&result)
        return result
    }
    
    private static let replaceSerialLinkRegular: NSRegularExpression? = {
        let options: NSRegularExpression.Options = [.caseInsensitive]
        let pattern = serialLinkPattern
        return try? NSRegularExpression(pattern: pattern, options: options)
    }()
    
    private static var replaceSerialNumberToLinkRegular: NSRegularExpression? = {
        let options: NSRegularExpression.Options = [.caseInsensitive]
        let pattern = serialNumberPattern
        return try? NSRegularExpression(pattern: pattern, options: options)
    }()

    
    private static func replaceSerialLink(_ markdown: inout String) {
        guard let regex = replaceSerialLinkRegular else {
            assertionFailure("正则表达式不正确")
            return
        }
        let range = NSRange(markdown.startIndex..<markdown.endIndex, in: markdown)
        markdown = regex.stringByReplacingMatches(in: markdown, range: range, withTemplate: "[\(siderLinkPrefix)$1$2]")
    }
    
    private static func replaceSerialNumberToLink(_ markdown: inout String) {
        guard let regex = replaceSerialNumberToLinkRegular else {
            assertionFailure("正则表达式不正确")
            return
        }
        let range = NSRange(markdown.startIndex..<markdown.endIndex, in: markdown)
        markdown = regex.stringByReplacingMatches(in: markdown, range: range, withTemplate: "[\(siderSerialPrefix)$1$2$3$4](\(referenceScheme)://serial)")
    }
}
