import SwiftUI

 extension BlockNode: View {
     var body: some View {
         Group {
             switch self {
             case .blockquote(let children):
                 BlockquoteView(children: children)
             case .bulletedList(let isTight, let items):
                 BulletedListView(isTight: isTight, items: items)
             case .numberedList(let isTight, let start, let items):
                 NumberedListView(isTight: isTight, start: start, items: items)
             case .taskList(let isTight, let items):
                 TaskListView(isTight: isTight, items: items)
             case .codeBlock(let fenceInfo, let content):
                 CodeBlockView(fenceInfo: fenceInfo, content: content)
             case .htmlBlock(let content):
                 ParagraphView(content: content)
             case .paragraph(let content):
                 ParagraphView(content: content)
             case .heading(let level, let content):
                 HeadingView(level: level, content: content)
             case .table(let columnAlignments, let rows):
                 if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
                     TableView(columnAlignments: columnAlignments, rows: rows)
                 }
             case .thematicBreak:
                 ThematicBreakView()
             }
         }
     }
 }

// MARK: - BlockListView
struct BlockListView: View {
    private let nodeList: [BlockNodeModel]
    
    init(nodes: [BlockNode]) {
      nodeList = nodes.enumerated().map {
          BlockNodeModel(index: $0, node: $1)
      }
    }
    
    @Environment(\.multilineTextAlignment) private var textAlignment
    @Environment(\.tightSpacingEnabled) private var tightSpacingEnabled
    
    @State private var blockMargins: [Int: BlockMargin] = [:]
    
    var body: some View {
        ForEach(nodeList) { nodeModel in
            BlockNodeView(model: nodeModel)
//                .onPreferenceChange(BlockMarginsPreference.self) { value in
//                    self.blockMargins[nodeModel.hashValue] = value
//                }
//                .padding(.vertical, 4)
        }
    }
    
    private func topPaddingLength(for nodeModel: BlockNodeModel) -> CGFloat? {
        guard nodeModel.index > 0 else {
            return 0
        }
        
        let topSpacing = self.blockMargins[nodeModel.hashValue]?.top
        let predecessor = self.nodeList[nodeModel.index - 1]
        let predecessorBottomSpacing =
        self.tightSpacingEnabled ? 0 : self.blockMargins[predecessor.hashValue]?.bottom
        
        return [topSpacing, predecessorBottomSpacing]
            .compactMap { $0 }
            .max()
    }
}

// MARK: - General Block
class BlockNodeModel: ObservableObject, Hashable, Identifiable {
    let index: Int
    let node: BlockNode
    
    init(index: Int, node: BlockNode) {
        self.index = index
        self.node = node
    }
    
    static func == (lhs: BlockNodeModel, rhs: BlockNodeModel) -> Bool {
        return lhs.node == rhs.node
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.node)
    }
    
    var id: Int {
        index
    }
}

struct BlockNodeView: View {
    let model: BlockNodeModel
    
    var body: some View {
        model.node
    }
}

extension BlockNodeView: Equatable {
    static func == (lhs: BlockNodeView, rhs: BlockNodeView) -> Bool {
        return lhs.model.node == rhs.model.node
    }
}
