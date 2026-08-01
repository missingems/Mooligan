import SwiftUI

public struct SearchBar: View {
  @Binding var text: String
  @Binding var isExpanded: Bool
  var placeholder: String
  @FocusState private var isSearchFocused: Bool
  private let buttonSize: CGFloat = 28
  
  public init(
    text: Binding<String>,
    isExpanded: Binding<Bool>,
    placeholder: String = String(localized: "Search...")
  ) {
    self._text = text
    self._isExpanded = isExpanded
    self.placeholder = placeholder
  }
  
  public var body: some View {
    HStack(spacing: 8.0) {
      if isExpanded {
        TextField(placeholder, text: $text)
          .focused($isSearchFocused)
          .textFieldStyle(.plain)
          .autocorrectionDisabled()
          .submitLabel(.search)
          .id("searchTextField")
          .frame(maxWidth: .infinity, minHeight: 28.0)
          .padding(EdgeInsets(top: 8, leading: 13, bottom: 8, trailing: 13))
          .glassEffect()
        
        Button {
          isExpanded = false
          isSearchFocused = false
        } label: {
          Image(systemName: "xmark")
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(.primary)
            .frame(minWidth: 28, minHeight: 28)
            .padding(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
        }
        .glassEffect(.regular.interactive())
      } else {
        Button {
          isExpanded = true
          isSearchFocused = true
        } label: {
          Image(systemName: "magnifyingglass")
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(.primary)
            .frame(minWidth: 28, minHeight: 28)
            .padding(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
        }
        .glassEffect()
      }
    }
  }
}
