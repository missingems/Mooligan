import DesignComponents
import ComposableArchitecture
import SwiftUI
import Networking

struct SortOptionsView: View {
  @Bindable var store: StoreOf<QueryFeature>
  
  var body: some View {
    FilterMenuButton {
      HStack(spacing: 5.0) {
        Group {
          switch store.query.sortDirection {
          case .asc:
            Image(systemName: "arrow.up").resizable().scaledToFit()
          case .desc:
            Image(systemName: "arrow.down").resizable().scaledToFit()
          default:
            Image(systemName: "wand.and.sparkles").resizable().scaledToFit()
          }
        }
        .frame(width: 15, height: 28, alignment: .center)
        
        Text(store.query.sortMode.description)
          .font(.subheadline)
          .fontWeight(.medium)
          .multilineTextAlignment(.leading)
          .lineLimit(1)
          .fixedSize(horizontal: true, vertical: false)
      }
    } content: {
      ForEach(store.availableSortModes, id: \.rawValue) { value in
        FilterOptionRow(
          title: value.description,
          isSelected: store.query.sortMode == value,
          action: { store.query.sortMode = value }
        )
      }
      
      VibrantDivider()
        .padding(EdgeInsets(top: 8.0, leading: 11, bottom: 8.0, trailing: 11))
      
      ForEach(store.availableSortOrders, id: \.rawValue) { value in
        FilterOptionRow(
          title: value.description,
          isSelected: store.query.sortDirection == value,
          action: { store.query.sortDirection = value }
        )
      }
    }
  }
}
