import ComposableArchitecture
import Foundation
import Networking
import ScryfallKit

extension InsightPagerFeature {
  @ObservableState struct State: Equatable, Sendable {
    /// A page for every tile of the row, in the row's order.
    var pages: IdentifiedArrayOf<InformationInsightFeature.State>
    /// The page on show, which the pages scroll to and report back as they settle.
    var selection: InformationWidget?
    /// The tile that was tapped to open the pager, whose badge spins in.
    let opened: InformationWidget

    init(widgets: [InformationWidget], selected: InformationWidget, card: Card, faceDirection: MagicCardFaceDirection?) {
      pages = IdentifiedArray(
        widgets.map { InformationInsightFeature.State(widget: $0, card: card, faceDirection: faceDirection) },
        uniquingIDsWith: { first, _ in first }
      )
      selection = selected
      opened = selected
    }
  }
}
