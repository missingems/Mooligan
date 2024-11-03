import DesignComponents
import SwiftUI

struct HeaderView: View {
  let onTransformTapped: (() -> Void)?
  private let imageURL: URL
  private let isFlippable: Bool
  private let layoutConfiguration: LayoutConfiguration
  
  init?(
    imageURL: URL?,
    isFlippable: Bool,
    orientation: LayoutConfiguration.Orientation,
    rotation: CGFloat,
    onTransformTapped: (() -> Void)? = nil
  ) {
    guard let imageURL else {
      return nil
    }
    
    self.imageURL = imageURL
    self.isFlippable = isFlippable
    self.onTransformTapped = onTransformTapped
    
    layoutConfiguration = LayoutConfiguration(
      rotation: rotation,
      orientation: orientation
    )
  }
  
  var body: some View {
    ZStack(alignment: .trailing) {
      AmbientWebImage(
        url: imageURL,
        cornerRadius: 13,
        rotation: layoutConfiguration.rotation
      )
      .aspectRatio(
        layoutConfiguration.ratio,
        contentMode: .fit
      )
      .shadow(color: Color.black.opacity(0.31), radius: 13, x: 0, y: 13)
      
      if isFlippable {
        Button {
          onTransformTapped?()
        } label: {
          Image(systemName: "rectangle.portrait.rotate")
            .fontWeight(.semibold)
        }
        .tint(DesignComponentsAsset.accentColor.swiftUIColor)
        .frame(
          width: 44.0,
          height: 44.0
        )
        .background(.thinMaterial)
        .clipShape(
          Circle()
        )
        .overlay(
          Circle()
            .stroke(
              .separator,
              lineWidth: 1
            )
            .opacity(0.618)
        )
        .offset(x: 16.0, y: -16.0)
      }
    }
    .padding(layoutConfiguration.insets)
  }
}

extension HeaderView {
  struct LayoutConfiguration {
    enum Orientation {
      case landscape
      case portrait
    }
    
    let rotation: CGFloat
    let insets: EdgeInsets
    let ratio: CGFloat
    
    init(
      rotation: CGFloat,
      orientation: Orientation
    ) {
      insets = switch orientation {
      case .landscape:
        EdgeInsets(top: 21, leading: 34, bottom: 29, trailing: 34)
        
      case .portrait:
        EdgeInsets(top: 21, leading: 89, bottom: 29, trailing: 89)
      }
      
      self.rotation = rotation
      self.ratio = switch orientation {
      case .landscape:
        MagicCardImageRatio.heightToWidth.rawValue
        
      case .portrait:
        MagicCardImageRatio.widthToHeight.rawValue
      }
    }
  }
}
