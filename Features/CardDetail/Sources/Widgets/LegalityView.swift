import DesignComponents
import Networking
import SwiftUI

struct LegalityView: View {
  let title: String
  let displayReleaseDate: String
  let legalities: [MagicCardLegalitiesValue]
  let columns = [GridItem(spacing: 5.0), GridItem(spacing: 5.0)]
  
  var body: some View {
    Divider().safeAreaPadding(.leading, nil)
    
    VStack(alignment: .leading, spacing: 5.0) {
      Text(title).font(.headline)
      Text(displayReleaseDate).font(.caption).foregroundStyle(.secondary)
      
      LazyVGrid(
        columns: columns,
        spacing: 3.0
      ) {
        ForEach(legalities.indices, id: \.self) { index in
          GridRow {
            legalityRow(
              index: index,
              numberOfColumns: columns.count,
              legality: legalities[index]
            )
          }
        }
      }
      .padding(.top, 3.0)
    }
    .safeAreaPadding(.horizontal, nil)
    .padding(.vertical, 13.0)
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
  
  @ViewBuilder private func legalityRow(
    index: Int,
    numberOfColumns: Int,
    legality: MagicCardLegalitiesValue
  ) -> some View {
    HStack(spacing: 8.0) {
      Text(legality.value)
        .foregroundStyle(.white)
        .frame(minWidth: 0, maxWidth: .infinity)
        .font(.caption)
        .padding(.vertical, 5.0)
        .background {
          Color(
            legality.backgroundColorName,
            bundle: DesignComponentsResources.bundle
          )
        }
        .clipShape(RoundedRectangle(cornerRadius: 8.0))
      
      Text(legality.title)
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
        .font(.caption)
        .multilineTextAlignment(.leading)
    }
    .background {
      if (index / columns.count).isMultiple(of: 2) {
        Color(.systemFill)
          .clipShape(RoundedRectangle(cornerRadius: 8.0))
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
    legalities: MagicCardFixtures.split.value.getLegalities().value
  )
}
