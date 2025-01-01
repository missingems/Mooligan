import DesignComponents
import SwiftUI

struct SetRow: View {
  private let viewModel: ViewModel
  private var onSelect: () -> ()
  
  var body: some View {
    Button(
      action: {
        onSelect()
      },
      label: {
        HStack(spacing: 13) {
          if viewModel.shouldShowIndentIndicator {
            Image(systemName: viewModel.childIndicatorImageName)
              .fontWeight(.medium)
              .imageScale(.small)
              .foregroundStyle(.tertiary)
              .frame(width: 34, height: 34)
          }
          
          IconLazyImage(viewModel.iconUrl).frame(width: 34, height: 34, alignment: .center)
          
          VStack(alignment: .leading, spacing: 3.0) {
            Text(viewModel.title).multilineTextAlignment(.leading)
            
            HStack(spacing: 5.0) {
              PillText(viewModel.id).font(.caption).monospaced()
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
            top: viewModel.shouldSetBackground ? 8 : 11,
            leading: 13,
            bottom: viewModel.shouldSetBackground ? 11 : 13,
            trailing: 13
          )
        )
        .background { viewModel.shouldSetBackground ? Color(.tertiarySystemFill) : Color.clear }
        .clipShape(RoundedRectangle(cornerRadius: 13.0))
      }
    )
    .buttonStyle(.sinkableButtonStyle)
  }
  
  init(viewModel: ViewModel, _ onSelect: @escaping () -> Void) {
    self.viewModel = viewModel
    self.onSelect = onSelect
  }
  
}
