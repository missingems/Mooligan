import DesignComponents
import ComposableArchitecture
import SwiftUI
import Networking

struct CardTypeItemsView: View {
  @Bindable var store: StoreOf<QueryFeature>
  
  var body: some View {
    FilterMenuButton {
      HStack(spacing: 2) {
        ForEach(
          Array(store.query.cardType).sorted(),
          id: \.rawValue
        ) { value in
          value.image
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: 18, height: 28, alignment: .center)
        }
        
        if store.query.cardType.count == 1, let value = store.query.cardType.first {
          Text(value.title)
            .font(.subheadline)
            .fontWeight(.medium)
            .multilineTextAlignment(.leading)
            .lineLimit(1)
            .padding(.leading, 3)
        }
      }
    } content: {
      ForEach(store.availableCardType) { value in
        FilterOptionRow(
          title: value.title,
          isSelected: store.query.cardType.contains(value),
          action: { store.query.cardType.toggleSelection(for: value) }
        ) {
          value.image
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: value == .all ? 15.0 : 21.0, height: 21, alignment: .center)
            .frame(width: 21.0, height: 21, alignment: .center)
        }
      }
    }
  }
}
