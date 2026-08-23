import SwiftUI

public struct FilterMenuButton<Label: View, Content: View>: View {
  @State private var isShowingOptions = false
  
  private let label: () -> Label
  private let content: () -> Content
  
  public init(
    @ViewBuilder label: @escaping () -> Label,
    @ViewBuilder content: @escaping () -> Content
  ) {
    self.label = label
    self.content = content
  }
  
  public var body: some View {
    Button {
      isShowingOptions.toggle()
    } label: {
      label()
        .frame(maxWidth: .infinity)
        .padding(EdgeInsets(top: 8, leading: 13, bottom: 8, trailing: 13))
    }
    .glassEffect(.regular.interactive())
    .popover(
      isPresented: $isShowingOptions,
      attachmentAnchor: .rect(.bounds),
      arrowEdge: .top
    ) {
      VStack(alignment: .leading, spacing: 2.0) {
        content()
      }
      .padding(EdgeInsets(top: 13, leading: 13, bottom: 13, trailing: 13))
      .presentationCompactAdaptation(.popover)
    }
  }
}
