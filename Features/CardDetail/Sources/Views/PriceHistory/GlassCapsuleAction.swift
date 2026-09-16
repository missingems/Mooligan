import Networking
import SwiftUI

struct GlassCapsuleAction: View {
  let title: String
  let accessibilityID: String
  let action: () -> Void

  var body: some View {
    Text(title)
      .font(.subheadline)
      .fontWeight(.semibold)
      .lineLimit(1)
      .padding(.horizontal, 13.0)
      .padding(.vertical, 5.0)
      .glassEffect(.regular.interactive(), in: .capsule)
      .onTapGesture(perform: action)
      .accessibilityElement(children: .ignore)
      .accessibilityLabel(Text(title))
      .accessibilityAddTraits(.isButton)
      .accessibilityAction { action() }
      .accessibilityIdentifier(accessibilityID)
  }
}
