import DesignComponents
import Networking
import SwiftUI

struct RulingView<Client: MagicCardDetailRequestClient>: View {
  let card: Client.MagicCardModel
  let client: Client
  let rulings: [MagicCardRuling]
  let title: String
  
  var body: some View {
    ScrollView {
      LazyVStack(alignment: .leading, spacing: 13) {
        ForEach(rulings.indices, id: \.self) { index in
          let ruling = rulings[index]
          
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
        }
      }
    }
    .task {
      let _ = try? await client.getRulings(of: card)
    }
  }
  
  init(
    card: Client.MagicCardModel,
    rulings: [MagicCardRuling],
    title: String,
    client: Client
  ) {
    self.card = card
    self.rulings = rulings
    self.title = title
    self.client = client
  }
}
