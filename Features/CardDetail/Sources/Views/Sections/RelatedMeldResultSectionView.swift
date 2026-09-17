import ComposableArchitecture
import DesignComponents
import Networking
import SwiftUI

struct RelatedMeldResultSectionView: View {
  let store: StoreOf<CardDetailFeature>
  var body: some View { RelatedCardsSectionView(section: store.relatedMeldResult) }
}
