import SwiftUI

public struct SearchBar: View {
  @Binding var text: String
  @Binding var isExpanded: Bool
  let isLoading: Bool
  let placeholder: String
  
  @FocusState private var isFocused: Bool
  @ScaledMetric(relativeTo: .body) private var iconWidth: CGFloat = 18
  @ScaledMetric(relativeTo: .body) private var fieldMinHeight: CGFloat = 44
  @ScaledMetric(relativeTo: .body) private var circleButtonSize: CGFloat = 44
  
  public init(
    text: Binding<String>,
    isExpanded: Binding<Bool>,
    isLoading: Bool,
    placeholder: String
  ) {
    self._text = text
    self._isExpanded = isExpanded
    self.isLoading = isLoading
    self.placeholder = placeholder
  }
  
  public var body: some View {
    HStack(spacing: 8) {
      if isExpanded {
        HStack(spacing: 6) {
          Group {
            if isLoading {
              ProgressView()
            } else {
              Image(systemName: "magnifyingglass")
                .fontWeight(.medium)
            }
          }
          .frame(width: iconWidth, alignment: .center)
          
          TextField(placeholder, text: $text)
            .font(.body)
            .focused($isFocused)
            .textFieldStyle(.plain)
            .autocorrectionDisabled()
            .submitLabel(.search)
          
          if !text.isEmpty {
            Button {
              text = ""
            } label: {
              Image(systemName: "xmark.circle.fill")
                .foregroundStyle(.secondary)
                .imageScale(.medium)
            }
            .buttonStyle(.plain)
            .transition(.opacity.combined(with: .scale(scale: 0.7)))
          }
        }
        .padding(.horizontal, 13)
        .frame(minHeight: fieldMinHeight)
        .glassEffect(.regular.interactive())
        .transition(.blurReplace)
      }
      
      Button {
        withAnimation(.smooth) {
          isExpanded.toggle()
          isFocused = isExpanded
          if !isExpanded { text = "" }
        }
      } label: {
        Image(systemName: isExpanded ? "xmark" : "magnifyingglass")
          .fontWeight(.semibold)
      }
      .frame(width: circleButtonSize, height: circleButtonSize)
      .glassEffect(.regular.interactive())
    }
    .animation(.smooth, value: text.isEmpty)
  }
}

#Preview {
  @Previewable @State var text = ""
  @Previewable @State var isExpanded = false
  @Previewable @State var isLoading = false
  SearchBar(
    text: $text,
    isExpanded: $isExpanded,
    isLoading: isLoading,
    placeholder: "Search 350 cards…"
  )
  .padding()
}
