import DesignComponents
import Networking
import SwiftUI

struct GlassIdentity: ViewModifier {
  let glass: (id: String, namespace: Namespace.ID)?

  func body(content: Self.Content) -> some View {
    if let glass {
      content.glassEffectID(glass.id, in: glass.namespace)
    } else {
      content
    }
  }
}
