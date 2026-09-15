import ComposableArchitecture
import DesignComponents
import Networking
import SwiftUI

struct RelatedComboPiecesSectionView: View {
  let store: StoreOf<CardDetailFeature>
  var body: some View { RelatedCardsSectionView(section: store.relatedComboPieces) }
}
