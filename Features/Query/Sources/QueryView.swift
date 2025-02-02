import ComposableArchitecture
import DesignComponents
import Foundation
import Featurist
import Networking
import Shimmer
import SwiftUI
import NukeUI
import VariableBlur

struct QueryView: View {
  @Bindable private var store: StoreOf<Feature>
  private var namespace: Namespace.ID
  
  init(store: StoreOf<Feature>, namespace: Namespace.ID) {
    self.store = store
    self.namespace = namespace
  }
  
  var body: some View {
    ScrollView(.vertical) {
      if case let .querySet(value, _) = store.queryType, let iconURL = URL(string: value.iconSvgUri) {
        Button {
          
        } label: {
          HStack(spacing: 13) {
            IconLazyImage(iconURL).frame(width: 34, height: 34, alignment: .center)
            
            VStack(alignment: .leading, spacing: 3.0) {
              Text(store.title).multilineTextAlignment(.leading).font(.headline)
              
              HStack(spacing: 5.0) {
                PillText(value.code.uppercased()).font(.caption).monospaced()
                Text("\(value.cardCount) Cards").font(.caption).foregroundStyle(.secondary)
              }
            }
            
            Spacer()
            
            Image(systemName: "chevron.down")
              .fontWeight(.medium)
              .imageScale(.small)
              .foregroundStyle(.tertiary)
          }
          .padding(
            EdgeInsets(
              top: 8,
              leading: 13,
              bottom: 11,
              trailing: 13
            )
          )
          .background { Color(.tertiarySystemFill) }
          .clipShape(RoundedRectangle(cornerRadius: 13.0))
          .safeAreaPadding(.horizontal, nil)
          .padding(.bottom, 5)
        }
      }
      
      LazyVGrid(
        columns: [GridItem](
          repeating: GridItem(
            spacing: 8.0,
            alignment: .center
          ),
          count: Int(store.numberOfColumns)
        ),
        spacing: 13
      ) {
        if let contentWidth = store.itemWidth, contentWidth > 0, let dataSource = store.dataSource {
          ForEach(Array(zip(dataSource.cardDetails, dataSource.cardDetails.indices)), id: \.0.card.id) { value in
            let cardInfo = value.0
            let index = value.1
            
            let layout = CardView.LayoutConfiguration(
              rotation: .portrait,
              maxWidth: contentWidth
            )
            
            Button {
              store.send(.didSelectCard(cardInfo.card, store.queryType))
            } label: {
              CardView(
                displayableCard: cardInfo.displayableCardImage,
                layoutConfiguration: layout,
                callToActionHorizontalOffset: 0,
                priceVisibility: .display(usdFoil: cardInfo.card.getPrice(for: .usdFoil), usd: cardInfo.card.getPrice(for: .usd))
              ).background {
                Rectangle().matchedTransitionSource(id: cardInfo.card.id, in: namespace)
              }
            }
            .buttonStyle(.sinkableButtonStyle)
            .task {
              if store.state.shouldLoadMore(at: index) {
                store.send(.loadMoreCardsIfNeeded(displayingIndex: index))
              }
            }
          }
        }
      }
      .onGeometryChange(
        for: CGFloat.self,
        of: { proxy in
          proxy.size.width
        }, action: { newValue in
          guard store.viewWidth == nil, newValue > 0 else {
            return
          }
          
          store.viewWidth = newValue
        }
      )
      .safeAreaPadding(.horizontal, nil)
      .placeholder(store.mode.isPlaceholder)
    }
    .contentMargins(.vertical, 8, for: .scrollContent)
    .scrollDisabled(store.mode.isPlaceholder)
    .scrollPosition($store.scrollPosition)
    .scrollBounceBehavior(.basedOnSize)
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItemGroup(placement: .primaryAction) {
        if case .querySet = store.queryType {
          Menu {
            Picker("SORT BY", selection: $store.query.sortMode) {
              ForEach(store.availableSortModes) { value in
                Text(value.description)
              }
            }
            
            Picker("SORT ORDER", selection: $store.query.sortDirection) {
              ForEach(store.availableSortOrders) { value in
                Text(value.description)
              }
            }
          } label: {
            Image(systemName: "arrow.up.arrow.down.circle.fill")
              .font(.title3)
              .symbolRenderingMode(.palette)
              .foregroundStyle(
                DesignComponentsAsset.accentColor.swiftUIColor,
                DesignComponentsAsset.accentColor.swiftUIColor.quinary
              )
          }
          .pickerStyle(.inline)
          .labelsVisibility(.visible)
          
          Button("Filter", systemImage: "line.3.horizontal.decrease.circle.fill") {
            store.send(.didSelectShowFilters)
          }
          .buttonStyle(HierarchicalToolbarButton())
          .popover(
            isPresented: $store.isShowingSortFilters,
            content: {
              NavigationStack {
                List {
                  TextField("Enter card name", text: $store.query.name)
                  
                  Picker("SORT BY", selection: $store.query.sortMode) {
                    ForEach(store.availableSortModes) { value in
                      Text(value.description)
                    }
                  }
                  .pickerStyle(.inline)
                  .labelsVisibility(.visible)
                  
                  Picker("SORT ORDER", selection: $store.query.sortDirection) {
                    ForEach(store.availableSortOrders) { value in
                      Text(value.description)
                    }
                  }
                  .pickerStyle(.inline)
                  .labelsVisibility(.visible)
                }
                .navigationTitle("Filter")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                  ToolbarItem(placement: .primaryAction) {
                    Button {
                      print("done")
                    } label: {
                      Text("Done")
                    }
                  }
                }
              }
            }
          )
        }
      }
    }
    .task {
      store.send(.viewAppeared)
    }
  }
}


