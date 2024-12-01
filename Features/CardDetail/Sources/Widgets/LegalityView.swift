import DesignComponents
import Networking
import SwiftUI

struct LegalityView: View {
  let title: String
  let displayReleaseDate: String
  let legalities: [MagicCardLegalitiesValue]
  let numberOfColumns = 2
  
  var body: some View {
    Divider().safeAreaPadding(.leading, nil)
    
    VStack(alignment: .leading, spacing: 5.0) {
      Text(title).font(.headline)
      Text(displayReleaseDate).font(.caption).foregroundStyle(.secondary)
      
      Grid(horizontalSpacing: 5.0, verticalSpacing: 3.0) {
        GridRow {
          legalityRow(
            index: 0,
            numberOfColumns: numberOfColumns,
            legality: legalities[0]
          )
          .background(Color(.systemFill))
          .clipShape(RoundedRectangle(cornerRadius: 5))
          
          legalityRow(
            index: 1,
            numberOfColumns: numberOfColumns,
            legality: legalities[1]
          )
          .background(Color(.systemFill))
          .clipShape(RoundedRectangle(cornerRadius: 5))
        }
        
        GridRow {
          legalityRow(
            index: 2,
            numberOfColumns: numberOfColumns,
            legality: legalities[2]
          )
          
          legalityRow(
            index: 3,
            numberOfColumns: numberOfColumns,
            legality: legalities[3]
          )
        }
        
        GridRow {
          legalityRow(
            index: 4,
            numberOfColumns: numberOfColumns,
            legality: legalities[4]
          )
          .background(Color(.systemFill))
          .clipShape(RoundedRectangle(cornerRadius: 5))
          
          legalityRow(
            index: 5,
            numberOfColumns: numberOfColumns,
            legality: legalities[5]
          )
          .background(Color(.systemFill))
          .clipShape(RoundedRectangle(cornerRadius: 5))
        }
        
        GridRow {
          legalityRow(
            index: 6,
            numberOfColumns: numberOfColumns,
            legality: legalities[6]
          )
          
          legalityRow(
            index: 7,
            numberOfColumns: numberOfColumns,
            legality: legalities[7]
          )
        }
        
        GridRow {
          legalityRow(
            index: 8,
            numberOfColumns: numberOfColumns,
            legality: legalities[8]
          )
          .background(Color(.systemFill))
          .clipShape(RoundedRectangle(cornerRadius: 5))
          
          legalityRow(
            index: 9,
            numberOfColumns: numberOfColumns,
            legality: legalities[9]
          )
          .background(Color(.systemFill))
          .clipShape(RoundedRectangle(cornerRadius: 5))
        }
      }
      .padding(.top, 3.0)
    }
    .safeAreaPadding(.horizontal, nil)
    .padding(EdgeInsets(top: 13.0, leading: 0, bottom: 18, trailing: 0))
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
        .clipShape(RoundedRectangle(cornerRadius: 5.0))
      
      Text(legality.title)
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
        .font(.caption)
        .multilineTextAlignment(.leading)
    }
  }
}
