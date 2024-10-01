import DesignComponents
import SwiftUI

struct SelectionView: View {
  let items: [Item]
  
  var body: some View {
    VStack(spacing: 0) {
      ForEach(items.indices, id: \.self) { index in
        let item = items[index]
        
        makeRow(
          icon: item.icon,
          title: item.title,
          detail: item.detail,
          shouldShowSeparator: index != items.count - 1,
          didSelect: item.action
        )
      }
    }
    .background { Color(.systemFill) }
    .clipShape(.buttonBorder)
    .safeAreaPadding(.horizontal, nil)
  }
}

extension SelectionView {
  struct Item: Sendable, Identifiable {
    let id = UUID().uuidString
    let icon: Image
    let title: String
    let detail: String?
    let action: @Sendable () -> Void
    
    init(icon: Image, title: String, detail: String? = nil, action: @escaping @Sendable () -> Void) {
      self.icon = icon
      self.title = title
      self.detail = detail
      self.action = action
    }
  }
}

extension SelectionView {
  @ViewBuilder func makeRow(
    icon: Image,
    title: String,
    detail: String?,
    shouldShowSeparator: Bool,
    didSelect: @escaping @Sendable () -> Void
  ) -> some View {
    VStack(alignment: .leading, spacing: 0) {
      Button {
        didSelect()
      } label: {
        HStack(spacing: 13.0) {
          icon
            .renderingMode(.template)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 16.0, height: 16.0)
            .tint(.primary)
          
          Text(title)
            .font(.body)
            .fontWeight(.medium)
            .tint(.primary)
          
          Spacer()
          
          if let detail {
            Text(detail)
              .font(.body)
              .fontWeight(.medium)
              .tint(.secondary)
          }
          
          Image(systemName: "chevron.right")
            .fontWeight(.medium)
            .imageScale(.small)
            .tint(.secondary)
        }
      }
      .safeAreaPadding(.horizontal, nil)
      .padding(.vertical, 8.0)
      
      if shouldShowSeparator {
        Divider().safeAreaPadding(.leading, nil)
      }
    }
  }
}
