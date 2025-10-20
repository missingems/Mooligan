import SwiftUI

public struct HorizontalFilterToggleView<DataType, Content>: View where DataType: Identifiable, Content: View {
  var dataSource: [DataType]
  var didSelectItem: (DataType) -> Void
  @ViewBuilder let itemContentView: (DataType) -> Content
  
  public init(
    dataSource: [DataType],
    itemContentView: @escaping (DataType) -> Content,
    didSelectItem: @escaping (DataType) -> Void
  ) {
    self.dataSource = dataSource
    self.itemContentView = itemContentView
    self.didSelectItem = didSelectItem
  }
  
  public var body: some View {
    ScrollView(.horizontal) {
      HStack {
        ForEach(dataSource) { value in
          Button {
            didSelectItem(value)
          } label: {
            itemContentView(value)
          }
          .glassEffect(.regular.interactive())
        }
      }
    }
  }
}

struct aaaa: Identifiable {
  let title: String = "1"
  
  var id: String {
    return "1"
  }
}

#Preview {
  HorizontalFilterToggleView(dataSource: [aaaa.init()]) { value in
    Text(value.title)
  } didSelectItem: { value in
    print(value)
  }
  
}

