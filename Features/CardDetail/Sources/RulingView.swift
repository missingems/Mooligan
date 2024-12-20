import ComposableArchitecture
import DesignComponents
import Networking
import ScryfallKit
import SwiftUI

struct RulingView<Client: MagicCardDetailRequestClient>: View {
  let store: StoreOf<RulingFeature<Client>>
  
  var body: some View {
    Group {
      switch store.mode {
      case let .loaded(rulings):
        if rulings.isEmpty {
          ContentUnavailableView(
            store.emptyStateTitle,
            systemImage: "magnifyingglass",
            description: store.emptyStateDescription.map { Text(.init($0)) }
          )
          .frame(maxHeight: .infinity)
          .offset(y: -34.0)
        } else {
//          ScrollView {
//            VStack(alignment: .leading, spacing: 13) {
//              ForEach(rulings) { ruling in
//                VStack(alignment: .leading, spacing: 3) {
//                  Text(ruling.displayDate)
//                    .font(.caption)
//                    .foregroundStyle(.secondary)
//                  
//                  TokenizedText(
//                    text: ruling.description,
//                    font: .preferredFont(forTextStyle: .body),
//                    paragraphSpacing: 8.0,
//                    keywords: []
//                  )
//                }
//                .safeAreaPadding(.horizontal, nil)
//                
//                Divider().safeAreaPadding(.leading, nil)
//              }
//            }
//          }
        }
        
      case .loading:
        ProgressView()
          .offset(y: -34.0)
      }
    }
    .task {
      store.send(.fetchRulings)
    }
    .navigationTitle(store.title)
    .toolbar {
      ToolbarItem(placement: .confirmationAction) {
        Button("Done") {
          store.send(.dismissTapped)
        }
      }
    }
  }
  
  init(
    store: StoreOf<RulingFeature<Client>>
  ) {
    self.store = store
  }
}
