import ComposableArchitecture
import DesignComponents
import Networking
import SwiftUI

struct QueryFilterPanel: View {
  @Bindable var store: StoreOf<QueryFeature>
  
  var body: some View {
    ScrollView(.vertical, showsIndicators: false) {
      VStack(alignment: .leading, spacing: 2.0) {
        header(String(localized: "Colour"))
        colourRows
        
        divider
        header(String(localized: "Type"))
        typeRows
        
        divider
        header(String(localized: "Sort"))
        sortRows
        
        divider
        orderRows
      }
      .padding(13.0)
    }
    .frame(width: 260.0)
    .frame(maxHeight: 440.0)
    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 26.0, style: .continuous))
    .accessibilityIdentifier("setDetail.filterPanel")
  }
  
  private func header(_ title: String) -> some View {
    Text(title)
      .font(.caption)
      .fontWeight(.semibold)
      .foregroundStyle(.secondary)
      .padding(.horizontal, 11.0)
      .padding(.vertical, 5.0)
  }
  
  private var divider: some View {
    VibrantDivider().padding(EdgeInsets(top: 8.0, leading: 11, bottom: 8.0, trailing: 11))
  }
  
  private var colourRows: some View {
    let options = store.availableColorTypeOptions
    
    return ForEach(Array(options.enumerated()), id: \.element.rawValue) { index, value in
      let isSelected = store.query.colorIdentities.contains(value)
      let isPreviousSelected = isSelected
      && index > 0
      && store.query.colorIdentities.contains(options[index - 1])
      let isNextSelected = isSelected
      && index < options.count - 1
      && store.query.colorIdentities.contains(options[index + 1])
      
      FilterOptionRow(
        title: value.name,
        isSelected: isSelected,
        isPreviousSelected: isPreviousSelected,
        isNextSelected: isNextSelected,
        identifier: "setDetail.filterOption.\(value.name)",
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
  
  private var typeRows: some View {
    let options = store.availableCardType
    
    return ForEach(Array(options.enumerated()), id: \.element.id) { index, value in
      let isSelected = store.query.cardType.contains(value)
      let isPreviousSelected = isSelected
      && index > 0
      && store.query.cardType.contains(options[index - 1])
      let isNextSelected = isSelected
      && index < options.count - 1
      && store.query.cardType.contains(options[index + 1])
      
      FilterOptionRow(
        title: value.title,
        isSelected: isSelected,
        isPreviousSelected: isPreviousSelected,
        isNextSelected: isNextSelected,
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
  
  private var sortRows: some View {
    ForEach(store.availableSortModes, id: \.rawValue) { value in
      FilterOptionRow(
        title: value.description,
        isSelected: store.query.sortMode == value,
        action: { store.query.sortMode = value }
      )
    }
  }
  
  private var orderRows: some View {
    ForEach(store.availableSortOrders, id: \.rawValue) { value in
      FilterOptionRow(
        title: value.description,
        isSelected: store.query.sortDirection == value,
        action: { store.query.sortDirection = value }
      )
    }
  }
}
