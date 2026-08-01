import DesignComponents
import ComposableArchitecture
import SwiftUI
import Networking

struct SortOptionsView: View {
  @Bindable var store: StoreOf<QueryFeature>
  
  var body: some View {
    Button {
      store.isShowingSortOptions.toggle()
    } label: {
      HStack(spacing: 5.0) {
        Group {
          switch store.query.sortDirection {
          case .asc:
            Image(systemName: "arrow.up").resizable().scaledToFit()
          case .desc:
            Image(systemName: "arrow.down").resizable().scaledToFit()
          default:
            Image(systemName: "wand.and.sparkles").resizable().scaledToFit()
          }
        }
        .frame(width: 15, height: 28, alignment: .center)
        
        Text(store.query.sortMode.description)
          .font(.subheadline)
          .fontWeight(.medium)
          .multilineTextAlignment(.leading)
      }
      .frame(maxWidth: .infinity)
      .padding(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
    }
    .glassEffect(.regular.interactive())
    .popover(
      isPresented: $store.isShowingSortOptions,
      attachmentAnchor: .rect(.bounds),
      arrowEdge: .top
    ) {
      VStack(alignment: .leading, spacing: 2.0) {
        ForEach(store.availableSortModes, id: \.rawValue) { value in
          Button {
            store.query.sortMode = value
          } label: {
            HStack {
              Text(value.description)
              Spacer(minLength: 34)
              Image(systemName: "checkmark.circle.fill")
                .opacity(store.query.sortMode == value ? 1 : 0)
            }
            .padding(EdgeInsets(top: 8.0, leading: 11, bottom: 8.0, trailing: 11))
            .background(
              store.query.sortMode == value ? Color(.systemFill) : .clear,
              in: .capsule
            )
          }
        }
        
        Divider()
          .padding(EdgeInsets(top: 8.0, leading: 11, bottom: 8.0, trailing: 11))
        
        ForEach(store.availableSortOrders, id: \.rawValue) { value in
          Button {
            store.query.sortDirection = value
          } label: {
            HStack {
              Text(value.description)
              Spacer(minLength: 34)
              Image(systemName: "checkmark.circle.fill")
                .opacity(store.query.sortDirection == value ? 1 : 0)
            }
            .padding(EdgeInsets(top: 8.0, leading: 11, bottom: 8.0, trailing: 11))
            .background(
              store.query.sortDirection == value ? Color(.systemFill) : .clear,
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
