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
      
      LazyVStack(alignment: .leading, spacing: 5) {
        ForEach(rulings.indices, id: \.self) { index in
          let ruling = rulings[index]
          
          VStack(alignment: .leading, spacing: 3) {
            Text(ruling.displayDate).font(.caption).foregroundStyle(.secondary)
            Text(LocalizedStringKey(ruling.description)).font(.caption).multilineTextAlignment(.leading)
              .frame(maxWidth: .infinity, alignment: .leading)
          }
          .padding(.vertical, 8.0)
          .safeAreaPadding(.horizontal, nil)
          .background {
            if index.isMultiple(of: 2) {
              Color.primary.opacity(0.02).background(.ultraThinMaterial).clipShape(RoundedRectangle(cornerRadius: 13.0))
            }
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
