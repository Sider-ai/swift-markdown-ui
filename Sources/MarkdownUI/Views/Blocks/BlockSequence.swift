import SwiftUI

struct ElementView<Element: Equatable, Content: View>: View, Equatable {
    
    static func == (lhs: ElementView<Element, Content>, rhs: ElementView<Element, Content>) -> Bool {
        return rhs.element == lhs.element && lhs.index == rhs.index
    }
    let index: Int
    let element: Element
    @ViewBuilder
    let content: () -> Content
    var body: some View {
        content()
    }
}

struct BlockSequence<Data, Content>: View
where
Data: Sequence,
Data.Element: Hashable,
Content: View
{
    @Environment(\.multilineTextAlignment) private var textAlignment
    @Environment(\.tightSpacingEnabled) private var tightSpacingEnabled
    
    @State private var blockMargins: [Int: BlockMargin] = [:]
    
    private let data: [Indexed<Data.Element>]
    private let content: (Int, Data.Element) -> Content
    
    init(
        _ data: Data,
        @ViewBuilder content: @escaping (_ index: Int, _ element: Data.Element) -> Content
    ) {
        self.data = data.indexed()
        self.content = content
    }
    
    var body: some View {
        ForEach(self.data, id: \.self) { element in
            self.content(element.index, element.value)
//                .onPreferenceChange(BlockMarginsPreference.self) { value in
//                    self.blockMargins[element.hashValue] = value
//                }
//                .padding(.top, self.topPaddingLength(for: element) ?? 2)
        }
    }
    
    private func topPaddingLength(for element: Indexed<Data.Element>) -> CGFloat? {
        guard element.index > 0 else {
            return 0
        }
        
        let topSpacing = self.blockMargins[element.hashValue]?.top
        let predecessor = self.data[element.index - 1]
        let predecessorBottomSpacing =
        self.tightSpacingEnabled ? 0 : self.blockMargins[predecessor.hashValue]?.bottom
        
        return [topSpacing, predecessorBottomSpacing]
            .compactMap { $0 }
            .max()
    }
}

 extension BlockSequence where Data == [BlockNode], Content == BlockNode {
     init(_ blocks: [BlockNode]) {
         self.init(blocks) { $1 }
     }
 }

extension TextAlignment {
    var alignment: Alignment {
        switch self {
        case .leading:
            return .leading
        case .center:
            return .center
        case .trailing:
            return .trailing
        }
    }
}
