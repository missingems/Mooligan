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
    ZStack {
      AmbientWebImage(
        url: imageURL,
        cornerRadius: 13,
        rotation: layoutConfiguration.rotation
      )
      .aspectRatio(
        MagicCardImageRatio.heightToWidth.rawValue,
        contentMode: .fit
      )
      
      if isFlippable {
        Button {
          onTransformTapped?()
        } label: {
          Image(systemName: "rectangle.portrait.rotate")
            .fontWeight(.semibold)
        }
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
              lineWidth: 1 / UIScreen.main.nativeScale
            )
            .opacity(0.618)
        )
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
    }
  }
}
