import DesignComponents
import SwiftUI

struct SetRow: View {
  private let viewModel: ViewModel
  private var onSelect: () -> ()
  
  var topCornerRadii: CGFloat { viewModel.isFirst ? 21 : 0 }
  var bottomCornerRadii: CGFloat { viewModel.isLast ? 21 : 0 }
  
  var body: some View {
    Button(
      action: {
        onSelect()
      },
      label: {
        HStack(spacing: 13) {
          IconLazyImage(viewModel.iconUrl).frame(width: 34, height: 34, alignment: .center)
          
          VStack(alignment: .leading, spacing: 3.0) {
            Text(viewModel.attributedTitle).multilineTextAlignment(.leading)
            
            HStack(spacing: 5.0) {
              PillText(viewModel.id).font(.caption)
              Text(viewModel.numberOfCardsLabel).font(.caption).foregroundColor(.secondary)
            }
          }
          
          Spacer()
          
          Image(systemName: viewModel.disclosureIndicatorImageName)
            .fontWeight(.medium)
            .imageScale(.small)
            .foregroundStyle(.tertiary)
        }
        .padding(
          EdgeInsets(
            top: 11,
            leading: 13,
            bottom: 11,
            trailing: 13
          )
        )
        .background { Color(.tertiarySystemFill) }
        .clipShape(
          UnevenRoundedRectangle(
            cornerRadii: RectangleCornerRadii(
              topLeading: topCornerRadii,
              bottomLeading: bottomCornerRadii,
              bottomTrailing: bottomCornerRadii,
              topTrailing: topCornerRadii
            )
          )
        )
      }
    )
    .buttonStyle(.sinkableButtonStyle)
  }
  
  init(viewModel: ViewModel, _ onSelect: @escaping () -> Void) {
    self.viewModel = viewModel
    self.onSelect = onSelect
  }
}
