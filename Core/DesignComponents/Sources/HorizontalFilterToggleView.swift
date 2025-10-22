import SwiftUI

public struct Section<
  Label,
  Content,
  LabelView,
  ContentView
>: View, Identifiable where Content: Identifiable & Equatable & Hashable, LabelView: View, ContentView: View {
  private let label: Label
  private let items: [Content]
  @Binding private var selectedContent: Content
  
  private let labelBuilder: (Label) -> LabelView
  private let contentBuilder: (Content) -> ContentView
  
  public var body: some View {
    Menu {
      Picker("Title", selection: $selectedContent) {
        ForEach(items) { value in
          contentBuilder(value).tag(value)
        }
      }
    } label: {
      labelBuilder(label)
    }
  }
  
  public let id: UUID
  
  public init(
    label: Label,
    items: [Content],
    selectedContent: Binding<Content>,
    labelBuilder: @escaping (Label) -> LabelView,
    contentBuilder: @escaping (Content) -> ContentView
  ) {
    self.label = label
    self.items = items
    self._selectedContent = selectedContent
    self.labelBuilder = labelBuilder
    self.contentBuilder = contentBuilder
    id = UUID()
  }
}

public struct HorizontalFilterToggleView<
  Label,
  Content,
  LabelView,
  ContentView
>: View where Content: Identifiable & Equatable & Hashable, LabelView: View, ContentView: View {
  var dataSource: [
    Section<Label, Content, LabelView, ContentView>
  ]

  public init(dataSource: [Section<Label, Content, LabelView, ContentView>]) {
    self.dataSource = dataSource
  }
  
  public var body: some View {
    HStack {
      ForEach(dataSource) { section in
        section
      }
    }
  }
}
