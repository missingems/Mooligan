import DesignComponents
import SwiftUI

struct HeaderView: View {
  struct Content: Equatable {
    let imageWidth: CGFloat
    let imageHeight: CGFloat
    let imageURL: URL
    let rotation: CGFloat
    let isFlippable: Bool
  }
  
  let content: Content
  let onTransformTapped: () -> ()
  
  init(content: Content, onTransformTapped: @escaping () -> Void) {
    self.content = content
    self.onTransformTapped = onTransformTapped
  }
  
  var body: some View {
    ZStack(alignment: .bottom) {
      ZStack {
        AmbientWebImage(
          url: [content.imageURL],
          cornerRadius: 13,
          blurRadius: 44.0,
          offset: CGPoint(x: 0, y: 10),
          scale: CGSize(width: 1.1, height: 1.1),
          rotation: content.rotation,
          width: content.imageWidth
        )
        
        if content.isFlippable {
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
          .offset(x: content.imageWidth / 2 - 27, y: -44)
        }
      }
      .frame(width: content.imageWidth, height: content.imageHeight, alignment: .center)
      .padding(EdgeInsets(top: 13, leading: 0, bottom: 21, trailing: 0))
      
      Divider()
    }
  }
}
