import SwiftUI

public struct ManaView: View {
  let identity: [String]
  let size: CGSize
  let spacing: CGFloat
  
  public init(
    identity: [String],
    size: CGSize,
    spacing: CGFloat = 3
  ) {
    self.identity = identity
    self.size = size
    self.spacing = spacing
  }
  
  public var body: some View {
    WrappingHStack(
      alignment: .trailing,
      horizontalSpacing: spacing,
      verticalSpacing: 2.0,
      fitContentWidth: true
    ) {
      ForEach(identity.indices, id: \.self) { index in
        Image(identity[index], bundle: DesignComponentsResources.bundle)
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(width: size.width, height: size.height)
          .background { Circle().fill(.black).offset(x: -0.75, y: 1.5) }
      }
    }
  }
}
