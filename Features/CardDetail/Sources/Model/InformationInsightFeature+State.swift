import ComposableArchitecture
import Foundation
import Networking
import ScryfallKit

extension InformationInsightFeature {
  @ObservableState struct State: Equatable, Identifiable, Sendable {
    let widget: InformationWidget
    let title: String
    let summary: String
    let factGroups: [InsightFactGroup]
    let prompt: String
    var elaboration: InsightElaboration = .pending

    var id: InformationWidget { widget }

    init(widget: InformationWidget, card: Card, faceDirection: MagicCardFaceDirection?) {
      self.widget = widget
      title = widget.insightTitle
      summary = widget.insightSummary
      factGroups = widget.insightFactGroups(card: card, faceDirection: faceDirection)
      prompt = widget.insightPrompt(card: card)
    }
  }
}
