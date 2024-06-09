import DesignComponents
import Networking
import SwiftUI

struct LegalityView: View {
  let title: String
  let displayReleaseDate: String
  let legalities: [MagicCardLegalitiesValue]
  let columns = [GridItem(spacing: 5.0), GridItem(spacing: 5.0)]
  
  var body: some View {
    VStack(alignment: .leading) {
      Text(title).font(.headline)
      Text(displayReleaseDate).font(.caption).foregroundStyle(.secondary)
      
      LazyVGrid(
        columns: columns,
        spacing: 3.0
      ) {
        ForEach(legalities.indices, id: \.self) { index in
          GridRow { legalityRow(index: index, numberOfColumns: columns.count, legality: legalities[index]) }
        }
      }
    }
  }
  
  init(
    title: String,
    displayReleaseDate: String,
    legalities: [MagicCardLegalitiesValue]
  ) {
    self.title = title
    self.displayReleaseDate = displayReleaseDate
    self.legalities = legalities
  }
  
  @ViewBuilder
  private func legalityRow(index: Int, numberOfColumns: Int, legality: MagicCardLegalitiesValue) -> some View {
    let color = Color(legality.backgroundColorName, bundle: DesignComponentsResources.bundle)
    
    HStack {
      Text(legality.value)
        .foregroundStyle(.white)
        .frame(minWidth: 0, maxWidth: .infinity).font(.system(size: 12))
        .padding(.vertical, 5.0)
        .font(.caption)
        .background { color }
        .clipShape(ButtonBorderShape.roundedRectangle)
        .shadow(color: color.opacity(0.38), radius: 5.0)
      
      Text(legality.title)
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
        .font(.caption)
        .multilineTextAlignment(.leading)
    }
    .background {
      if (index / columns.count).isMultiple(of: 2) {
        Color(.quaternarySystemFill).clipShape(ButtonBorderShape.roundedRectangle)
      } else {
        Color.clear
      }
    }
  }
}

#Preview {
  LegalityView(
    title: "Legalities",
    displayReleaseDate: "12 Dec 2024",
    legalities: MagicCardFixture.stub[0].getLegalities().value
  )
}
