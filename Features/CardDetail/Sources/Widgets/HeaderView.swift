import DesignComponents
import SwiftUI
#if DEBUG
import Networking
#endif

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
    guard let imageURL else { return nil }
    
    self.imageURL = imageURL
    self.isFlippable = isFlippable
    self.onTransformTapped = onTransformTapped
    
    layoutConfiguration = LayoutConfiguration(
      rotation: rotation,
      orientation: orientation
    )
  }
  
  var body: some View {
    ZStack(alignment: .bottom) {
      ZStack {
        AmbientWebImage(
          url: imageURL,
          rotation: layoutConfiguration.rotation
        )
        
        if isFlippable {
          Button {
            onTransformTapped?()
          } label: {
            Image(systemName: layoutConfiguration.transformButtonSystemImageName).fontWeight(.semibold)
          }
          .frame(
            width: layoutConfiguration.transformButtonSize.width,
            height: layoutConfiguration.transformButtonSize.height
          )
          .background(.thinMaterial)
          .clipShape(Circle())
          .overlay(Circle().stroke(Color(.separator), lineWidth: 1 / UIScreen.main.nativeScale).opacity(0.618))
        }
      }
      .padding(layoutConfiguration.insets)
      
      Divider()
    }
  }
}

extension HeaderView {
  struct LayoutConfiguration {
    enum Orientation {
      case landscape
      case portrait
    }
    
    let rotation: CGFloat
    let transformButtonSystemImageName = "rectangle.portrait.rotate"
    let transformButtonSize = CGSize(width: 44.0, height: 44.0)
    let insets: EdgeInsets
    
    init(
      rotation: CGFloat,
      orientation: Orientation
    ) {
      insets = switch orientation {
      case .landscape:
        EdgeInsets(top: 13, leading: 34, bottom: 21, trailing: 34)
      case .portrait:
        EdgeInsets(top: 13, leading: 72, bottom: 21, trailing: 72)
      }
      
      self.rotation = rotation
    }
  }
}

#Preview {
  ScrollView {
    VStack(alignment: .leading, spacing: 0) {
      MagicCardFixture.stub.first.map { card in
        HeaderView(
          imageURL: card.getCardFace(for: .front).getImageURL()!,
          isFlippable: card.isFlippable,
          orientation: card.isSplit ? .landscape : .portrait,
          rotation: 0
        )
      }
    }
    .padding(.bottom, 13.0)
  }
  .background { Color(.secondarySystemBackground).ignoresSafeArea() }
}
