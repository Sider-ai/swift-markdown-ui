import SwiftUI

struct ListItemView: View {
  @Environment(\.theme.listItem) private var listItem
  @Environment(\.listLevel) private var listLevel

  private let item: RawListItem
  private let number: Int
    private let total: Int
  private let markerStyle: BlockStyle<ListMarkerConfiguration>
  private let markerWidth: CGFloat?

  init(
    item: RawListItem,
    number: Int,
    total: Int,
    markerStyle: BlockStyle<ListMarkerConfiguration>,
    markerWidth: CGFloat?
  ) {
    self.item = item
    self.number = number
      self.total = total
    self.markerStyle = markerStyle
    self.markerWidth = markerWidth
  }

  var body: some View {
    self.listItem.makeBody(
      configuration: .init(
        label: .init(self.label),
        index: self.number,
        total: self.total,
        level: self.listLevel,
        content: .init(blocks: item.children)
      )
    )
  }

  private var label: some View {
//    Label {
//        VStack(alignment: .leading, spacing: 0) {
      ListItemContentSequence(self.item.children, number: self.number, total: self.total, listLevel: self.listLevel, markerStyle: self.markerStyle, markerWidth: self.markerWidth)
          
//        }
//    } icon: {
//      self.markerStyle
//        .makeBody(configuration: .init(listLevel: self.listLevel, itemNumber: self.number))
//        .textStyleFont()
//        .readWidth(column: 0)
//        .frame(width: self.markerWidth, alignment: .trailing)
//    }
    #if os(visionOS)
      .labelStyle(BulletItemStyle())
    #endif
  }
}

extension VerticalAlignment {
  private enum CenterOfFirstLine: AlignmentID {
    static func defaultValue(in context: ViewDimensions) -> CGFloat {
      let heightAfterFirstLine = context[.lastTextBaseline] - context[.firstTextBaseline]
      let heightOfFirstLine = context.height - heightAfterFirstLine
      return heightOfFirstLine / 2
    }
  }
  static let centerOfFirstLine = Self(CenterOfFirstLine.self)
}

struct BulletItemStyle: LabelStyle {
  func makeBody(configuration: Configuration) -> some View {
    HStack(alignment: .centerOfFirstLine, spacing: 4) {
      configuration.icon
      configuration.title
    }
  }
}

struct ListItemContentSequence<Data, Content>: View
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
    
    private let number: Int
      private let total: Int
    private let listLevel: Int
    private let markerStyle: BlockStyle<ListMarkerConfiguration>
    private let markerWidth: CGFloat?
    
    init(
        _ data: Data,
        number: Int,
        total: Int,
        listLevel: Int,
        markerStyle: BlockStyle<ListMarkerConfiguration>,
        markerWidth: CGFloat?,
        @ViewBuilder content: @escaping (_ index: Int, _ element: Data.Element) -> Content
    ) {
        self.data = data.indexed()
        self.number = number
        self.total = total
        self.listLevel = listLevel
        self.markerStyle = markerStyle
        self.markerWidth = markerWidth
        self.content = content
    }
    
    var body: some View {
        ForEach(self.data, id: \.self.index) { element in
            self.content(element.index, element.value)
                .safeAreaInset(edge: .leading, content: {
                    VStack(spacing: 0) {
                        ZStack {
                            Text(" ")
                                .textStyleFont()
                            self.markerStyle
                                .makeBody(configuration: .init(listLevel: self.listLevel, itemNumber: self.number))
                                .textStyleFont()
                                .readWidth(column: 0)
                                .frame(width: self.markerWidth, alignment: .trailing)
                                .opacity(element.index == 0 ? 1 : 0)
                        }
                        Spacer(minLength: 0)
                    }
                  })
        }
    }
}

 extension ListItemContentSequence where Data == [BlockNode], Content == BlockNode {
     init(_ blocks: [BlockNode],
          number: Int,
          total: Int,
          listLevel: Int,
          markerStyle: BlockStyle<ListMarkerConfiguration>,
          markerWidth: CGFloat?,) {
         self.init(blocks, number: number, total: total, listLevel: listLevel, markerStyle: markerStyle, markerWidth: markerWidth) { $1 }
     }
 }
