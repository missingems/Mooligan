import Networking
import SwiftUI

public extension SearchQuery.CardType {
  var image: Image {
    return switch self {
    case .all:
      Image(systemName: "square.grid.2x2.fill")
      
    case .land:
      DesignComponentsAsset.land.swiftUIImage
      
    case .artifact:
      DesignComponentsAsset.artifact.swiftUIImage
      
    case .enchantment:
      DesignComponentsAsset.enchantment.swiftUIImage
      
    case .instant:
      DesignComponentsAsset.instant.swiftUIImage
      
    case .sorcery:
      DesignComponentsAsset.sorcery.swiftUIImage
      
    case .planeswalker:
      DesignComponentsAsset.planeswalker.swiftUIImage
      
    case .creature:
      DesignComponentsAsset.creature.swiftUIImage
    }
  }
}
