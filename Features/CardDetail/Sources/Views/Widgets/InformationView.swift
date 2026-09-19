import DesignComponents
import Networking
import ScryfallKit
import SwiftUI

struct InformationView: View, Equatable {
  private let title: String
  private let widgets: [InformationWidget]
  /// The tapped tile, and the whole row for the pager to page through.
  private let onSelect: (InformationWidget, [InformationWidget]) -> Void

  /// The tiles are built in `init` from values that do not change once the card
  /// is on screen — bar the set icon and the pull odds, which are fetched and
  /// arrive later, and are carried inside `widgets`. Comparing them is what stops
  /// every other store change from rebuilding the row. `onSelect` is left out: a
  /// closure is never equal to another, and it only hands the tapped tile on.
  nonisolated static func == (lhs: InformationView, rhs: InformationView) -> Bool {
    lhs.title == rhs.title && lhs.widgets == rhs.widgets
  }

  @Environment(\.displayScale) private var displayScale
  private var strokeScale: CGFloat { max(displayScale, 1) }
  
  var body: some View {
    VibrantDivider().padding(.leading, systemHorizontalMargin)
    
    VStack(alignment: .leading, spacing: 8.0) {
      Text(title).font(.headline)
      
      ScrollView(.horizontal, showsIndicators: false) {
        // One container for the row's glass. On their own, each tile got a container of its own,
        // and SwiftUI resolved every one of them again on each frame of a scroll or a pager swipe.
        // Zero spacing keeps the tiles from merging into one shape.
        GlassEffectContainer(spacing: 0.0) {
          HStack(spacing: 5.0) {
            ForEach(widgets, id: \.self) { widget in
              Widget(kind: widget)
                .contentShape(.rect)
                .onTapGesture { onSelect(widget, widgets) }
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isButton)
                .accessibilityAction { onSelect(widget, widgets) }
                .accessibilityIdentifier("cardDetail.widget.\(widget.name)")
            }
          }
          // The odds land after the row is drawn, and slot in beside the set rather than popping
          // the tiles after them sideways.
          .animation(.smooth(duration: 0.25), value: widgets.count)
        }
      }
      .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
    }
    .safeAreaPadding(.horizontal, systemHorizontalMargin)
    .padding(.vertical, 13.0)
  }
  
  init(
    title: String,
    power: String?,
    toughness: String?,
    loyaltyCounters: String?,
    manaValue: Double?,
    rarity: Card.Rarity,
    collectorNumber: String?,
    colorIdentity: [String]?,
    setCode: String?,
    setIconURL: URL?,
    pullOdds: CardPullOdds?,
    stickerTilt: Double,
    onSelect: @escaping (InformationWidget, [InformationWidget]) -> Void
  ) {
    self.title = title
    self.onSelect = onSelect
    
    var widgets: [InformationWidget] = []
    
    if let setCode {
      widgets.append(.set(code: setCode, rarity: rarity, iconURL: setIconURL))
    }
    
    if let pullOdds {
      widgets.append(.pullOdds(pullOdds, rarity: rarity, tilt: stickerTilt))
    }
    
    if let collectorNumber {
      widgets.append(.collectorNumber(collectorNumber))
    }
    
    if let colorIdentity {
      widgets.append(.colorIdentity(colorIdentity))
    }
    
    if let manaValue {
      widgets.append(.manaValue("\(manaValue)"))
    }
    
    if let loyaltyCounters {
      widgets.append(.loyalty(counters: loyaltyCounters))
    }
    
    if let power, let toughness {
      widgets.append(.powerToughness(power: power, toughness: toughness))
    }
    
    self.widgets = widgets
  }
}
