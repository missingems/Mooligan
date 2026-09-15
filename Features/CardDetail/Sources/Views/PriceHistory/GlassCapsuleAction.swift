import Networking
import SwiftUI

struct GlassCapsuleAction: View {
  let title: String
  var systemImage: String?
  let accessibilityID: String
  let action: () -> Void

  var body: some View {
    Group {
      if let systemImage {
        Image(systemName: systemImage)
          .fontWeight(.medium)
          .frame(width: 44, height: 44)
          .contentShape(.circle)
          .glassEffect(.regular.interactive())
      } else {
        // Without an icon there is nothing else to show, so the title is the button.
        Text(title)
          .font(.subheadline)
          .fontWeight(.semibold)
          .lineLimit(1)
          .padding(.horizontal, 13.0)
          .padding(.vertical, 5.0)
          .contentShape(.capsule)
          .glassEffect(.regular.interactive(), in: .capsule)
      }
    }
    .onTapGesture(perform: action)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(Text(title))
    .accessibilityAddTraits(.isButton)
    .accessibilityAction { action() }
    .accessibilityIdentifier(accessibilityID)
  }
}
