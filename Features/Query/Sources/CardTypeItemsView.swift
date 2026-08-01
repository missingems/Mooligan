import DesignComponents
import ComposableArchitecture
import SwiftUI
import Networking

struct CardTypeItemsView: View {
  @Bindable var store: StoreOf<QueryFeature>
  
  var body: some View {
    Button {
      store.isShowingCardTypeOptions.toggle()
    } label: {
      HStack(spacing: 2) {
        ForEach(
          Array(store.query.cardType).sorted(),
          id: \.rawValue
        ) { value in
          value.image
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: 18, height: 28, alignment: .center)
        }
        
        if store.query.cardType.count == 1, let value = store.query.cardType.first {
          Text(value.title)
            .font(.subheadline)
            .fontWeight(.medium)
            .multilineTextAlignment(.leading)
            .lineLimit(1)
            .padding(.leading, 3)
        }
      }
      .frame(maxWidth: .infinity)
      .padding(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
    }
    .glassEffect(.regular.interactive())
    .popover(
      isPresented: $store.isShowingCardTypeOptions,
      attachmentAnchor: .rect(.bounds),
      arrowEdge: .top
    ) {
      VStack(alignment: .leading, spacing: 2.0) {
        ForEach(store.availableCardType) { value in
          Button {
            store.query.cardType.toggleSelection(for: value)
          } label: {
            HStack {
              Group {
                value.image
                  .renderingMode(.template)
                  .resizable()
                  .scaledToFit()
                  .frame(width: value == .all ? 15.0 : 21.0, height: 21, alignment: .center)
              }
              .frame(width: 21.0, height: 21, alignment: .center)
              
              Text(value.title)
              Spacer(minLength: 34)
              Image(systemName: "checkmark.circle.fill")
                .opacity(store.query.cardType.contains(value) ? 1 : 0)
            }
            .padding(EdgeInsets(top: 8.0, leading: 11, bottom: 8.0, trailing: 11))
            .background(
              store.query.cardType.contains(value) ? Color(.systemFill) : .clear,
              in: .capsule
            )
          }
        }
      }
      .padding(EdgeInsets(top: 11.0, leading: 8.0, bottom: 11.0, trailing: 8.0))
      .presentationCompactAdaptation(.popover)
    }
  }
}