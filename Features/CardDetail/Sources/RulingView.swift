import ComposableArchitecture
import DesignComponents
import Networking
import ScryfallKit
import SwiftUI

struct RulingView<Client: MagicCardDetailRequestClient>: View {
  let store: StoreOf<RulingFeature<Client>>
  
  var body: some View {
    ScrollView {
      if store.rulings.isEmpty {
        ProgressView()
      } else {
        VStack(alignment: .leading, spacing: 13) {
          ForEach(store.rulings) { ruling in
            VStack(alignment: .leading, spacing: 3) {
              Text(ruling.displayDate)
                .font(.caption)
                .foregroundStyle(.secondary)
              
              TokenizedText(
                text: ruling.description,
                font: .preferredFont(forTextStyle: .body),
                paragraphSpacing: 8.0,
                keywords: []
              )
            }
            .safeAreaPadding(.horizontal, nil)
            
            Divider().safeAreaPadding(.leading, nil)
          }
        }
      }
    }
    .task {
      store.send(.fetchRulings)
    }
    .navigationTitle(store.title)
  }
  
  init(
    store: StoreOf<RulingFeature<Client>>
  ) {
    self.store = store
  }
}
