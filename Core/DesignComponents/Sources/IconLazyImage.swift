import Nuke
import SVGView
import SwiftUI

public struct IconLazyImage: View {
  private let url: URL?
  @State private var imageData: Data?
  @State private var shouldAnimate: Bool = false
  @Environment(\.colorScheme) private var colorScheme
  
  public init(_ url: URL?) {
    self.url = url
  }
  
  public var body: some View {
    ZStack {
      if let imageData {
        let view = SVGView(data: imageData)
        
        if let svg = view.svg {
          view
            .task(id: colorScheme, priority: .background) {
              tint(svg, colorScheme: colorScheme)
          }
        }
      }
    }
    .opacity(imageData == nil ? 0 : 1)
    .blur(radius: imageData == nil ? 5 : 0)
    .animation(.default, value: shouldAnimate)
    .task(priority: .background) {
      guard let url else { return }
      
      ImagePipeline.shared.loadImage(with: url) { result in
        switch result {
        case let .success(response):
          if imageData == nil {
            imageData = try? result.get().container.data
          }
          
          if response.cacheType == .disk || response.cacheType == .memory {
            shouldAnimate = false
          } else {
            shouldAnimate = true
          }
          
        case .failure:
          break
        }
      }
    }
  }
  
  private func tint(_ node: SVGNode, colorScheme: ColorScheme) {
    let color: SVGColor
    
    switch colorScheme {
    case .light:
      color = SVGColor(hex: "0E1250")
    case .dark:
      color = SVGColor(hex: "F8F6D8")
    @unknown default:
      color = SVGColor(hex: "0E1250")
    }
    
    if let group = node as? SVGGroup {
      for content in group.contents {
        tint(content, colorScheme: colorScheme)
      }
    } else if let shape = node as? SVGShape {
      shape.fill = color
    }
  }
}
