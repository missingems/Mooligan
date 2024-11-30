import Nuke
import SVGView
import SwiftUI
import UIKit

public struct IconLazyImage: View {
  @Environment(\.colorScheme) private var colorScheme
  private let url: URL?
  @State private var imageData: Data?
  @State private var shouldAnimate: Bool = false
  private let tintColor: Color
  
  public init(_ url: URL?, tintColor: Color = DesignComponentsAsset.accentColor.swiftUIColor) {
    self.url = url
    self.tintColor = tintColor
  }
  
  public var body: some View {
    ZStack {
      if let imageData {
        let view = SVGView(data: imageData)
        
        if let svg = view.svg {
          
          view.task(id: colorScheme, priority: .background) {
            print(UIColor.label.resolvedColor(with: .current))
            tint(svg, tintColor: tintColor)
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
  
  private func tint(_ node: SVGNode, tintColor: Color) {
    if let group = node as? SVGGroup {
      for content in group.contents {
        tint(content, tintColor: tintColor)
      }
    } else if
      let shape = node as? SVGShape,
      let colorHex = tintColor.toHex(colorScheme: colorScheme) {
      shape.fill = SVGColor(hex: colorHex)
    }
  }
}

private extension UIColor {
  func toHex(includeAlpha: Bool = false, colorScheme: ColorScheme) -> String? {
    let color = resolvedColor(with: UITraitCollection(userInterfaceStyle: colorScheme.toUIUserInterfaceStyle))
    var red: CGFloat = 0
    var green: CGFloat = 0
    var blue: CGFloat = 0
    var alpha: CGFloat = 0
    let rgb = color.cgColor.components
    print(rgb)
    guard color.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
      return nil
    }
    
    let r = Int(red * 255)
    let g = Int(green * 255)
    let b = Int(blue * 255)
    let a = Int(alpha * 255)
    
    if includeAlpha {
      return String(format: "%02X%02X%02X%02X", r, g, b, a)
    } else {
      return String(format: "%02X%02X%02X", r, g, b)
    }
  }
}

private extension ColorScheme {
  var toUIUserInterfaceStyle: UIUserInterfaceStyle {
    switch self {
    case .light: return .light
    case .dark: return .dark
    default: return .light
    }
  }
}

private extension Color {
  func toHex(includeAlpha: Bool = false, colorScheme: ColorScheme) -> String? {
    let uiColor = UIColor(self)
    return uiColor.toHex(includeAlpha: includeAlpha, colorScheme: colorScheme)
  }
}
