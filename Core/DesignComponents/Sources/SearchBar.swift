import SwiftUI

public struct SearchBar: View {
  @Binding var text: String
  @Binding var isExpanded: Bool
  let placeholder: String
  
  @Namespace private var searchMorph
  @FocusState private var isFocused: Bool
  
  public init(
    text: Binding<String>,
    isExpanded: Binding<Bool>,
    placeholder: String
  ) {
    self._text = text
    self._isExpanded = isExpanded
    self.placeholder = placeholder
  }
  
  public var body: some View {
    HStack(spacing: 8) {
      if isExpanded {
        HStack {
          Image(systemName: "magnifyingglass")
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(.primary)
          
          TextField(placeholder, text: $text)
            .focused($isFocused)
            .textFieldStyle(.plain)
            .autocorrectionDisabled()
            .submitLabel(.search)
            .autocorrectionDisabled()
            .frame(maxWidth: .infinity, minHeight: 28.0)
        }
        .padding(EdgeInsets(top: 8, leading: 13, bottom: 8, trailing: 13))
        .glassEffect(.regular.interactive())
      }
      
      Button {
        isExpanded.toggle()
        text = ""
      } label: {
        Image(systemName: isExpanded ? "xmark" : "magnifyingglass")
          .fontWeight(.semibold)
      }
      .frame(width: 44, height: 44)
      .glassEffect(.regular.interactive())
    }
  }
}

#Preview {
  @Previewable @State var text = ""
  @Previewable @State var isExpanded = false
  
  SearchBar(
    text: $text,
    isExpanded: $isExpanded,
    placeholder: "Search 350 cards…"
  )
  .padding()
}
