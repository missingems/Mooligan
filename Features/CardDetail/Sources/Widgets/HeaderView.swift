import DesignComponents
import SwiftUI

struct HeaderView: View {
  let onTransformTapped: (() -> Void)?
  private let imageURL: URL
  private let isFlippable: Bool
  private let isRotatable: Bool
  private let layoutConfiguration: LayoutConfiguration
  @State private var isFlipped = false
  @State private var isRotated = false
  
  init?(
    imageURL: URL?,
    isFlippable: Bool,
    isRotatable: Bool,
    orientation: LayoutConfiguration.Orientation,
    rotation: CGFloat,
    onTransformTapped: (() -> Void)? = nil
  ) {
    guard let imageURL else {
      return nil
    }
    
    self.imageURL = imageURL
    self.isFlippable = isFlippable
    self.isRotatable = isRotatable
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
        rotation: layoutConfiguration.rotation,
        isFlipped: isFlipped
      )
      .aspectRatio(
        layoutConfiguration.ratio,
        contentMode: .fit
      )
      .rotationEffect(.degrees(isRotated ? 180 : 0))
      .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
      .animation(.bouncy, value: isFlipped || isRotated)
      .shadow(color: .black.opacity(0.31), radius: 13, x: 0, y: 13)
      
      if isFlippable {
        Button {
          isFlipped.toggle()
          onTransformTapped?()
        } label: {
          Image(systemName: "arrow.left.arrow.right").fontWeight(.semibold)
        }
        .tint(DesignComponentsAsset.accentColor.swiftUIColor)
        .frame(width: 44.0, height: 44.0)
        .background(.thinMaterial)
        .clipShape(Circle())
        .overlay(Circle().stroke(.separator, lineWidth: 1).opacity(0.618))
        .offset(x: 16.0, y: -16.0)
      }
      
      if isRotatable {
        Button {
          isRotated.toggle()
          onTransformTapped?()
        } label: {
          if isRotated {
            Image(systemName: "arrow.trianglehead.counterclockwise.rotate.90")
              .fontWeight(.semibold)
          } else {
            Image(systemName: "arrow.trianglehead.clockwise.rotate.90")
              .fontWeight(.semibold)
          }
        }
        .tint(DesignComponentsAsset.accentColor.swiftUIColor)
        .frame(width: 44.0, height: 44.0)
        .background(.thinMaterial)
        .clipShape(Circle())
        .overlay(Circle().stroke(.separator, lineWidth: 1).opacity(0.618))
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
