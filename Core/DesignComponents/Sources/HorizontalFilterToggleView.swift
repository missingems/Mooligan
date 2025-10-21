import SwiftUI

public struct HorizontalFilterToggleView<DataType, Content>: View where DataType: Identifiable & Equatable, Content: View {
  var dataSource: [DataType]
  @Binding var selectedItem: DataType
  @ViewBuilder let itemContentView: (DataType) -> Content
  
  public init(
    dataSource: [DataType],
    selectedItem: Binding<DataType>,
    itemContentView: @escaping (DataType) -> Content
  ) {
    self.dataSource = dataSource
    self.itemContentView = itemContentView
    self._selectedItem = selectedItem
  }
  
  public var body: some View {
    ScrollView(.horizontal) {
      HStack {
        ForEach(dataSource) { value in
          Button {
            selectedItem = value
          } label: {
            itemContentView(value)
          }
          .tint(value == selectedItem ? DesignComponentsAsset.invertedPrimary.swiftUIColor : .secondary)
          .glassEffect(
            value == selectedItem ? .regular.tint(Color.primary) : .regular
          )
        }
        .animation(.default, value: selectedItem)
      }
    }
  }
}
