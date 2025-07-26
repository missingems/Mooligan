import DesignComponents
import SwiftUI

struct SelectionView: View {
  let items: [Item]
  
  var body: some View {
    Divider().safeAreaPadding(.leading, nil)
    
    VStack(alignment: .leading, spacing: 8.0) {
      Text("Related").font(.headline)
      
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
      .background(Color(.systemFill))
      .clipShape(RoundedRectangle(cornerRadius: 21))
    }
    .safeAreaPadding(.horizontal, nil)
    .padding(.vertical, 13.0)
  }
}

extension SelectionView {
  struct Item: Sendable {
    let icon: Image
    let title: String
    let detail: String?
    let action: @MainActor @Sendable () -> Void
    
    init(icon: Image, title: String, detail: String? = nil, action: @escaping @MainActor @Sendable () -> Void) {
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
    didSelect: @escaping @MainActor @Sendable () -> Void
  ) -> some View {
    VStack(alignment: .leading, spacing: 0) {
      Button {
        didSelect()
      } label: {
        HStack(alignment: .center, spacing: 8.0) {
          icon
            .renderingMode(.template)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 21.0, height: 21.0)
            .tint(DesignComponentsAsset.accentColor.swiftUIColor)
          
          Text(title)
            .font(.headline)
            .tint(DesignComponentsAsset.accentColor.swiftUIColor)
          
          Spacer()
          
          if let detail {
            Text(detail)
              .font(.body)
              .tint(DesignComponentsAsset.accentColor.swiftUIColor.secondary)
          }
          
          Image(systemName: "chevron.right")
            .fontWeight(.medium)
            .imageScale(.small)
            .tint(DesignComponentsAsset.accentColor.swiftUIColor.secondary)
        }
      }
      .safeAreaPadding(.horizontal, nil)
      .padding(.vertical, 13.0)
      
      if shouldShowSeparator {
        Divider().safeAreaPadding(.leading, nil)
      }
    }
  }
}
