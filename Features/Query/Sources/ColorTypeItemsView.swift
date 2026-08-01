import DesignComponents
import ComposableArchitecture
import SwiftUI
import Networking

struct ColorTypeItemsView: View {
  @Bindable var store: StoreOf<QueryFeature>
  
  var body: some View {
    Button {
      store.isShowingColorTypeOptions.toggle()
    } label: {
      HStack(spacing: -5) {
        ForEach(
          store.query.colorIdentities.isEmpty ? store.availableColorTypeOptions : Array(store.query.colorIdentities).sorted(),
          id: \.rawValue
        ) { value in
          value.image.resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 19, height: 28)
            .offset(x: 0, y: -0.5)
            .background { Circle().fill(.black).offset(x: -0.75, y: 1) }
        }
      }
      .frame(maxWidth: .infinity)
      .padding(EdgeInsets(top: 8, leading: 13, bottom: 8, trailing: 13))
    }
    .glassEffect(.regular.interactive())
    .popover(
      isPresented: $store.isShowingColorTypeOptions,
      attachmentAnchor: .rect(.bounds),
      arrowEdge: .top
    ) {
      VStack(alignment: .leading, spacing: 2.0) {
        ForEach(store.availableColorTypeOptions, id: \.rawValue) { value in
          Button {
            store.query.colorIdentities.toggleSelection(for: value)
          } label: {
            HStack {
              value.image.resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 19, height: 21)
                .offset(x: 0, y: -0.5)
                .background {
                  Circle().fill(.black).offset(x: -0.75, y: 1)
                }
              
              Text(value.name)
              Spacer(minLength: 34)
              Image(systemName: "checkmark.circle.fill")
                .opacity(store.query.colorIdentities.contains(value) ? 1 : 0)
            }
            .padding(EdgeInsets(top: 8.0, leading: 11, bottom: 8.0, trailing: 11))
            .background(
              store.query.colorIdentities.contains(value) ? Color(.systemFill) : .clear,
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
