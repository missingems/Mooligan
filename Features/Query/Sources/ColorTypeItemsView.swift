import ComposableArchitecture
import DesignComponents
import Networking
import SwiftUI

struct ColorTypeItemsView: View {
  @Bindable var store: StoreOf<QueryFeature>
  
  var body: some View {
    FilterMenuButton {
      HStack(spacing: -5) {
        ForEach(
          store.query.colorIdentities.isEmpty
          ? store.availableColorTypeOptions
          : Array(store.query.colorIdentities).sorted(),
          id: \.rawValue
        ) { value in
          value.image
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 19, height: 28)
            .offset(x: 0, y: -0.5)
            .background { Circle().fill(.black).offset(x: -0.75, y: 1) }
        }
      }
    } content: {
      ForEach(store.availableColorTypeOptions, id: \.rawValue) { value in
        FilterOptionRow(
          title: value.name,
          isSelected: store.query.colorIdentities.contains(value),
          action: { store.query.colorIdentities.toggleSelection(for: value) }
        ) {
          value.image
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 19, height: 21)
            .offset(x: 0, y: -0.5)
            .background {
              Circle().fill(.black).offset(x: -0.75, y: 1)
            }
        }
      }
    }
  }
}
