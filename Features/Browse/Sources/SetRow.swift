import DesignComponents
import SwiftUI

struct SetRow: View, Equatable {
  /// Compared on what it draws. `onSelect` is a closure, which is never equal, and only sends a
  /// fixed action to a store that outlives the comparison.
  nonisolated static func == (lhs: SetRow, rhs: SetRow) -> Bool {
    lhs.viewModel == rhs.viewModel && lhs.highlightedText == rhs.highlightedText
  }

  @Environment(\.colorScheme) var colorScheme
  private let viewModel: ViewModel
  /// The search text, marked in the title.
  private let highlightedText: String?
  private var onSelect: () -> ()

  var topCornerRadii: CGFloat { viewModel.isFirst ? 21 : 0 }
  var bottomCornerRadii: CGFloat { viewModel.isLast ? 21 : 0 }

  /// Made only when the row draws, so the search text costs nothing on rows that do not.
  private var attributedTitle: AttributedString {
    var title = AttributedString(viewModel.title)
    if let highlightedText, highlightedText.isEmpty == false,
       let range = title.range(of: highlightedText, options: .caseInsensitive) {
      title[range].backgroundColor = .yellow.opacity(0.8)
      title[range].font = .body.bold()
      title[range].foregroundColor = .black
    }
    return title
  }

  var body: some View {
    Button(
      action: {
        onSelect()
      },
      label: {
        HStack(spacing: 13) {
          IconLazyImage(viewModel.iconUrl).frame(width: 34, height: 34, alignment: .center)
          
          VStack(alignment: .leading, spacing: 3.0) {
            Text(attributedTitle).multilineTextAlignment(.leading)
            
            HStack(spacing: 5.0) {
              PillText(viewModel.id).font(.caption).fontWidth(.condensed)
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
        .background {
          UnevenRoundedRectangle(
            cornerRadii: .init(
              topLeading: topCornerRadii,
              bottomLeading: bottomCornerRadii,
              bottomTrailing: bottomCornerRadii,
              topTrailing: topCornerRadii
            ),
            style: .continuous
          )
          .foregroundStyle(
            DesignComponentsAsset.setRowColor.swiftUIColor
          )
        }
      }
    )
    .buttonStyle(.sinkableButtonStyle)
    .accessibilityIdentifier("browse.setRow.\(viewModel.id)")
  }
  
  init(viewModel: ViewModel, highlightedText: String?, _ onSelect: @escaping () -> Void) {
    self.viewModel = viewModel
    self.highlightedText = highlightedText
    self.onSelect = onSelect
  }
}
 
