import ComposableArchitecture
import DesignComponents
import Foundation
import Featurist
import Networking
import Shimmer
import SwiftUI
import NukeUI

struct QueryView: View {
  private var store: StoreOf<Feature>
  private var numberOfColumns: Double = 2
  @State private var contentWidth: CGFloat?
  @State private var search: String = ""
  @State private var isShowingPopover = false
  
  init(store: StoreOf<Feature>) {
    self.store = store
  }
  
  var body: some View {
    ScrollView(.vertical) {
      LazyVGrid(
        columns: [GridItem](
          repeating: GridItem(
            spacing: 8.0,
            alignment: .center
          ),
          count: Int(numberOfColumns)
        ),
        spacing: 13
      ) {
        if let contentWidth, contentWidth > 0, let dataSource = store.dataSource {
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
          guard contentWidth == nil, newValue > 0 else {
            return
          }
          
          contentWidth = (newValue - ((numberOfColumns - 1) * 8.0)) / numberOfColumns
        }
      )
      .safeAreaPadding(.horizontal, nil)
      .placeholder(store.mode.isPlaceholder)
      .scrollDisabled(store.mode.isPlaceholder)
    }
    .scrollBounceBehavior(.basedOnSize)
    .navigationTitle(store.title)
    .searchable(text: $search, placement: .navigationBarDrawer(displayMode: .always), prompt: store.searchPlaceholder)
    .toolbar {
      ToolbarItemGroup(placement: .primaryAction) {
        if case let .set(value, _) = store.queryType, let iconURL = URL(string: value.iconSvgUri) {
          Button("Info", systemImage: "info.circle") {
            isShowingPopover.toggle()
          }
          .disabled(isShowingPopover)
          .labelStyle(.iconOnly)
          .popover(
            isPresented: $isShowingPopover,
            attachmentAnchor: .rect(.bounds),
            content: {
              VStack(spacing: 8.0) {
                HStack {
                  Text("Set Symbol").safeAreaPadding([.leading, .top], nil)
                  Spacer(minLength: 55)
                  IconLazyImage(iconURL, tintColor: .secondary).frame(width: 21, height: 21, alignment: .center).safeAreaPadding([.trailing, .top], nil)
                }
                
                Divider()
                
                HStack {
                  Text("Set Code").safeAreaPadding(.leading, nil)
                  Spacer(minLength: 55)
                  Text(value.code.uppercased()).foregroundStyle(.secondary).fontDesign(.monospaced).safeAreaPadding(.trailing, nil).multilineTextAlignment(.trailing)
                }
                
                Divider()
                
                HStack {
                  Text("Released Date").safeAreaPadding(.leading, nil)
                  Spacer(minLength: 55)
                  
                  if let date = store.setReleasedDate {
                    Text(date.formatted(date: .numeric, time: .omitted)).foregroundStyle(.secondary).safeAreaPadding(.trailing, nil).multilineTextAlignment(.trailing)
                  }
                }
                
                Divider()
                
                HStack {
                  Text("Number of Cards").safeAreaPadding([.leading, .bottom], nil)
                  Spacer(minLength: 55)
                  Text("\(value.cardCount)").foregroundStyle(.secondary).safeAreaPadding([.trailing, .bottom], nil).multilineTextAlignment(.trailing)
                }
              }
              
              .presentationCompactAdaptation(.popover)
              .presentationBackground {
                Color.clear
              }
            }
          )
          
          Button("Info", systemImage: "line.3.horizontal.decrease.circle") {
          }
          .labelStyle(.iconOnly)
        }
      }
    }
    .task {
      store.send(.viewAppeared)
    }
  }
}
