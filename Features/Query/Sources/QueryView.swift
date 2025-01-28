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
          Section {
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
                  callToActionHorizontalOffset: 5,
                  priceVisibility: .display(usdFoil: cardInfo.card.getPrice(for: .usdFoil), usd: cardInfo.card.getPrice(for: .usd))
                )
                .matchedTransitionSource(id: cardInfo.card.id, in: namespace)
              }
              .buttonStyle(.sinkableButtonStyle)
              .shadow(color: DesignComponentsAsset.shadow.swiftUIColor, radius: 8, x: 0, y: 5)
              .task {
                if store.state.shouldLoadMore(at: index) {
                  store.send(.loadMoreCardsIfNeeded(displayingIndex: index))
                }
              }
            }
          } header: {
            ScrollView(.horizontal, showsIndicators: false) {
              HStack(spacing: 5.0) {
                VStack(alignment: .center, spacing: 3.0) {
                  HStack(spacing: 5.0) {
                    Text("Test")
                  }
                  .frame(minWidth: 66, minHeight: 34)
                  .padding(EdgeInsets(top: 5, leading: 11, bottom: 5, trailing: 11))
                  .background(Color(.systemFill))
                  .clipShape(RoundedRectangle(cornerRadius: 13.0))
                }
              }
            }
            .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
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
    .navigationTitle(store.title)
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      if case let .querySet(value, _) = store.queryType, let iconURL = URL(string: value.iconSvgUri) {
        ToolbarItem(placement: .principal) {
          Button {
            store.send(.didSelectShowInfo)
          } label: {
            VStack(spacing: 0) {
              Text(value.name).font(.headline)
              Text("\(value.cardCount) Cards").font(.caption).foregroundStyle(.secondary)
            }
          }
          .buttonStyle(HierarchicalToolbarButton())
          .popover(
            isPresented: $store.isShowingInfo,
            content: {
              VStack(spacing: 0) {
                HStack {
                  Text("Set Symbol")
                  Spacer(minLength: 55)
                  IconLazyImage(iconURL, tintColor: .secondary).frame(width: 21, height: 21, alignment: .center)
                }
                .padding(.vertical, 11.0)
                .safeAreaPadding(.horizontal, nil)
                
                Divider().safeAreaPadding(.leading, nil)
                
                HStack {
                  Text("Set Code")
                  Spacer(minLength: 55)
                  Text(value.code.uppercased()).foregroundStyle(.secondary).fontDesign(.monospaced)
                }
                .padding(.vertical, 11.0)
                .safeAreaPadding(.horizontal, nil)
                
                if let date = store.setReleasedDate {
                  Divider().safeAreaPadding(.leading, nil)
                  
                  HStack {
                    Text("Released Date")
                    Spacer(minLength: 55)
                    Text(date).foregroundStyle(.secondary)
                  }
                  .padding(.vertical, 11.0)
                  .safeAreaPadding(.horizontal, nil)
                }
                
                Divider().safeAreaPadding(.leading, nil)
                
                HStack {
                  Text("Number of Cards")
                  Spacer(minLength: 55)
                  Text("\(value.cardCount)").foregroundStyle(.secondary)
                }
                .padding(.vertical, 11.0)
                .safeAreaPadding(.horizontal, nil)
              }
              .presentationCompactAdaptation(.popover)
              .presentationBackground(Color.clear)
            }
          )
        }
      }
      
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
