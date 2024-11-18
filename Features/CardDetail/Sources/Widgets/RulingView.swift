import DesignComponents
import Networking
import SwiftUI

struct RulingView: View {
  let rulings: [MagicCardRuling]
  let title: String
  
  var body: some View {
    Divider().safeAreaPadding(.leading, nil)
    
    VStack(alignment: .leading, spacing: 8.0) {
      Text("Rulings").font(.headline)
        .safeAreaPadding(.horizontal, nil)
      
      LazyVStack(alignment: .leading, spacing: 13) {
        ForEach(rulings.indices, id: \.self) { index in
          let ruling = rulings[index]
          
          VStack(alignment: .leading, spacing: 3) {
            Text(ruling.displayDate).font(.caption).foregroundStyle(.secondary)
            Text(LocalizedStringKey(ruling.description)).font(.caption).multilineTextAlignment(.leading)
              .frame(maxWidth: .infinity, alignment: .leading)
          }
          .safeAreaPadding(.horizontal, nil)
        }
      }
    }
    .padding(.vertical, 13)
  }
  
  init(rulings: [MagicCardRuling], title: String) {
    self.rulings = rulings
    self.title = title
  }
}
