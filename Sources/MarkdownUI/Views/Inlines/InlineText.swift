import SwiftUI

extension InlineText {
    enum NodeType: Hashable {
        case latexBlock(content: String)
        case other([InlineNode])
    }
    
    enum ImageNodeType: Hashable {
        case latexBlock(content: String)
        case image(InlineNode)
    }
}

struct InlineText: View {
    @Environment(\.inlineImageProvider) private var inlineImageProvider
    @Environment(\.baseURL) private var baseURL
    @Environment(\.imageBaseURL) private var imageBaseURL
    @Environment(\.softBreakMode) private var softBreakMode
    @Environment(\.paragraphLineSpacing) private var paragraphLineSpacing
    @Environment(\.theme) private var theme
    @Environment(\.textStyle) private var textStyle

    @State private var latexImages: [String: (Image, CGSize)]
    @State private var inlineImages: [String: Image] = [:]
    @State private var loadInlineImageTasks: [String: Task<Void, Never>] = [:]
    
    private let inlines: [InlineNode]
    
    init(_ inlines: [InlineNode], fontSize: CGFloat) {
        self.inlines = inlines
        _latexImages = State<[String : (Image, CGSize)]>(initialValue: InlineText.latexCacheImages(inlines: inlines, fontSize: fontSize))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            let items = separateLatexFormulaBlock
            ForEach(0..<items.count, id: \.self) { index in
                let nodeType = items[index]
                switch nodeType {
                case .latexBlock(let content):
                    LatexView(content: content)
                case .other(let inlines): 
                    TextStyleAttributesReader { attributes in
                        inlines.renderText(
                            baseURL: self.baseURL,
                            textStyles: .init(
                                code: self.theme.code,
                                emphasis: self.theme.emphasis,
                                strong: self.theme.strong,
                                strikethrough: self.theme.strikethrough,
                                link: self.theme.link
                            ),
                            images: self.inlineImages,
                            latexImages: self.latexImages,
                            softBreakMode: self.softBreakMode,
                            attributes: attributes,
                            linkTextBuilder: self.theme.siderLinkTextBuilder
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .lineSpacing(paragraphLineSpacing)
                }
            }
        }
        .task(id: self.inlines) {
            Task {
                await loadInlineLatexImages()
            }
            Task {
                await loadInlineImages()
            }
        }
    }
    
    private func loadInlineLatexImages() async {
        let cacheKeys = InlineText.latexCacheImages(inlines: inlines, fontSize: fontSize).keys
        let currentKeys = latexImages.keys
        Set(currentKeys).subtracting(cacheKeys).forEach { key in
            latexImages.removeValue(forKey: key)
        }
        let loadImages = InlineText.loadImages(inlines: inlines)
        loadImages.forEach { imageNodeType in
            if case .latexBlock(let content) = imageNodeType {
                if latexImages[content] == nil && SVGCache.shared.canKey(key: content) {
                    if let image = SVGCache.shared.read(key: content, fontSize: fontSize) {
                        latexImages[content] = (Image(uiImage: image), image.size)
                    } else {
                        if loadInlineImageTasks[content] == nil {
                            let task = Task {
                                do {
                                    let image = try await LatexRenderer.image(with: content, fontSize: fontSize)
                                    latexImages[content] = (Image(uiImage: image), image.size)
                                } catch let error {
                                    debugPrint(error)
                                }
                                loadInlineImageTasks.removeValue(forKey: content)
                            }
                            loadInlineImageTasks[content] = task
                        }
                    }
                }
            }
        }
    }
    
    private func loadInlineImages() async {
        InlineText.loadImages(inlines: inlines).forEach { imageNodeType in
            if case .image(let inlineNode) = imageNodeType, let imageInfo = inlineNode.imageData {
                if inlineImages[imageInfo.source] == nil {
                    if loadInlineImageTasks[imageInfo.source] == nil {
                        let task = Task {
                            guard let url = URL(string: imageInfo.source, relativeTo: self.imageBaseURL) else {
                                return
                            }
                            do {
                                let image = try await self.inlineImageProvider.image(with: url, label: imageInfo.alt)
                                inlineImages[imageInfo.source] = image
                            } catch let error {
                                debugPrint(error)
                            }
                            loadInlineImageTasks.removeValue(forKey: imageInfo.source)
                        }
                        loadInlineImageTasks[imageInfo.source] = task
                    }
                }
            }
        }
    }
}

extension InlineText {
    
    private var attributes: AttributeContainer {
      var attributes = AttributeContainer()
      self.textStyle._collectAttributes(in: &attributes)
      return attributes
    }
    
    var fontSize: CGFloat {
        attributes.fontProperties?.size ?? 16
    }
    
    var separateLatexFormulaBlock: [InlineText.NodeType] {
        var items: [InlineNode] = []
        var alls: [InlineText.NodeType] = []
        inlines.forEach { inlineNode in
            if case .latex(_, let array) = inlineNode {
                array.forEach { latexNode in
                    switch latexNode {
                    case .text(let text):
                        items.append(InlineNode.text(text))
                    case .latex(let content, let isBlock):
                        if isBlock {
                            if items.isEmpty == false {
                                alls.append(.other(items))
                                items.removeAll()
                            }
                            alls.append(.latexBlock(content: content))
                        } else {
                            items.append(InlineNode.latex(rawContent: content, [LatexNode.latex(content: content, isBlock: isBlock)]))
                        }
                    }
                }
            } else {
                if case .lineBreak = inlineNode {
                    if items.isEmpty == false {
                        alls.append(.other(items))
                        items.removeAll()
                    }
//                    alls.append(.other([inlineNode]))
                } else {
                    items.append(inlineNode)
                }
            }
        }
        if items.isEmpty == false {
            alls.append(.other(items))
        }
        return alls
    }
}

extension InlineText {
    
    static func loadImages(inlines: [InlineNode]) -> [ImageNodeType] {
        var loadImages: [ImageNodeType] = []
        inlines.forEach { inlineNode in
            switch inlineNode {
            case .image:
                loadImages.append(.image(inlineNode))
            case .latex(_, let array):
                array.forEach { latexNode in
                    if case .latex(let content, let isBlock) = latexNode {
                        if isBlock == false {
                            loadImages.append(.latexBlock(content: content))
                        }
                    }
                }
            case .strong(let children):
                let nodes = InlineText.loadImages(inlines: children)
                if nodes.isEmpty == false {
                    loadImages.append(contentsOf: nodes)
                }
            case .strikethrough(let children):
                let nodes = InlineText.loadImages(inlines: children)
                if nodes.isEmpty == false {
                    loadImages.append(contentsOf: nodes)
                }
            case .emphasis(let children):
                let nodes = InlineText.loadImages(inlines: children)
                if nodes.isEmpty == false {
                    loadImages.append(contentsOf: nodes)
                }
            default: break
            }
        }
        return loadImages
    }
    
    static func latexCacheImages(inlines: [InlineNode], fontSize: CGFloat) -> [String: (Image, CGSize)] {
        var latexImages: [String: (Image, CGSize)] = [:]
        loadImages(inlines: inlines).forEach { obj in
            if case .latexBlock(let content) = obj {
                if let image = SVGCache.shared.read(key: content, fontSize: fontSize) {
                    latexImages[content] = (Image(uiImage: image), image.size)
                }
            }
        }
        return latexImages
    }
}
