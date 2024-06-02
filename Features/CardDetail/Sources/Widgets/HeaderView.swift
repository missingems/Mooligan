import DesignComponents
import SwiftUI
#if DEBUG
import Networking
#endif

struct HeaderView: View {
  private struct LayoutConfiguration {
    let horizontalPadding: CGFloat
    let imageWidth: CGFloat
    let imageHeight: CGFloat
    let cornerRadius: CGFloat
    let rotation: CGFloat
    
    init(
      horizontalPadding: CGFloat,
      cornerRadius: CGFloat,
      parentWidth: CGFloat,
      rotation: CGFloat,
      isLandscape: Bool
    ) {
      self.horizontalPadding = horizontalPadding
      self.imageWidth = parentWidth - horizontalPadding
      self.imageHeight = isLandscape ? (imageWidth / 1.3928).rounded() : (imageWidth * 1.3928).rounded()
      self.rotation = rotation
      self.cornerRadius = cornerRadius
    }
  }
  
  let onTransformTapped: () -> ()
  private let imageURL: URL
  private let isFlippable: Bool
  private let layoutConfiguration: LayoutConfiguration
  
  init(
    imageURL: URL,
    isFlippable: Bool,
    isLandscape: Bool,
    parentWidth: CGFloat,
    rotation: CGFloat,
    onTransformTapped: @escaping () -> Void
  ) {
    self.isFlippable = isFlippable
    self.onTransformTapped = onTransformTapped
    
    layoutConfiguration = LayoutConfiguration(
      horizontalPadding: (isLandscape ? 34 : 72) * 2,
      cornerRadius: 44.0,
      parentWidth: parentWidth,
      rotation: rotation,
      isLandscape: isLandscape
    )
  }
  
  var body: some View {
    ZStack(alignment: .bottom) {
      ZStack {
        AmbientWebImage(
          url: imageURL,
          cornerRadius: 13,
          blurRadius: 44.0,
          offset: CGPoint(x: 0, y: 10),
          scale: CGSize(width: 1.1, height: 1.1),
          rotation: layoutConfiguration.rotation,
          width: layoutConfiguration.imageWidth
        )
        
        if isFlippable {
          Button {
            withAnimation(.bouncy) {
              onTransformTapped()
            }
          } label: {
            Image(systemName: "rectangle.portrait.rotate").fontWeight(.semibold)
          }
          .frame(
            width: 44.0,
            height: 44.0,
            alignment: .center
          )
          .background(.thinMaterial)
          .clipShape(Circle())
          .overlay(Circle().stroke(Color(.separator), lineWidth: 1 / UIScreen.main.nativeScale).opacity(0.618))
          .offset(x: layoutConfiguration.imageWidth / 2 - 27, y: -44)
        }
      }
      .frame(
        width: layoutConfiguration.imageWidth,
        height: layoutConfiguration.imageHeight,
        alignment: .center
      )
      .padding(EdgeInsets(top: 13, leading: 0, bottom: 21, trailing: 0))
      
      Divider()
    }
  }
}

#Preview {
  GeometryReader { proxy in
    if proxy.size.width > 0 {
      ScrollView {
        VStack(alignment: .leading, spacing: 0) {
          if let card = MagicCardFixture.stub.first {
            HeaderView(
              : HeaderView.Content(
                imageURL: card.getImageURL()!,
                isFlippable: true,
                isLandscape: false,
                parentWidth: proxy.size.width,
                rotation: 0
              )
            ) {
              print("Tapped")
            }
          } else {
            Text("Stub is nil")
          }
        }
        .padding(.bottom, 13.0)
      }
      .background { Color(.secondarySystemBackground).ignoresSafeArea() }
    }
  }
}
