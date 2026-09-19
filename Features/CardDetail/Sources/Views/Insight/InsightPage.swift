import ComposableArchitecture
import DesignComponents
import SwiftUI

/// One page of the insight pager: what the tile means, the facts behind it, and a few lines about
/// this card written on device.
struct InsightPage: View {
  let store: StoreOf<InformationInsightFeature>

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 21.0) {
        VStack(alignment: .leading, spacing: 8.0) {
          Text(store.title)
            .font(.largeTitle)
            .fontWeight(.bold)
            .accessibilityAddTraits(.isHeader)
            .accessibilityIdentifier("cardDetail.insight.title.\(store.widget.name)")

          Text(store.summary)
            .font(.body)
        }

        ForEach(store.factGroups, id: \.self) { group in
          facts(group)
        }

        elaboration
      }
      .padding(.horizontal, systemHorizontalMargin)
      .padding(.top, 8.0)
      .padding(.bottom, 34.0)
    }
    .scrollBounceBehavior(.basedOnSize)
  }

  /// A group as a grouped list sets one out: its heading, its rows on one panel, and its note.
  private func facts(_ group: InsightFactGroup) -> some View {
    VStack(alignment: .leading, spacing: 6.0) {
      if let header = group.header {
        Text(header.uppercased())
          .font(.footnote)
          .foregroundStyle(.secondary)
          .padding(.horizontal, 16.0)
          .accessibilityAddTraits(.isHeader)
      }

      VStack(spacing: 0) {
        ForEach(Array(group.facts.enumerated()), id: \.offset) { index, fact in
          if index > 0 {
            VibrantDivider()
          }

          HStack(alignment: .firstTextBaseline, spacing: 13.0) {
            Text(fact.title)

            Spacer(minLength: 8.0)

            if fact.symbols.isEmpty == false {
              ManaView(identity: fact.symbols, size: CGSize(width: 17, height: 17))
            } else if let value = fact.value {
              Text(value)
                .fontWeight(.semibold)
                .multilineTextAlignment(.trailing)
            }
          }
          .font(.body)
          .padding(.vertical, 11.0)
          .accessibilityElement(children: .combine)
        }
      }
      .padding(.horizontal, 16.0)
      .glassEffect(.regular, in: .rect(cornerRadius: 21.0))

      if let footer = group.footer {
        Text(footer)
          .font(.footnote)
          .foregroundStyle(.secondary)
          .padding(.horizontal, 16.0)
      }
    }
  }

  @ViewBuilder private var elaboration: some View {
    switch store.elaboration {
    case .pending, .unavailable:
      EmptyView()

    case let .writing(text), let .written(text):
      VStack(alignment: .leading, spacing: 8.0) {
        Label(String(localized: "For This Card"), systemImage: "sparkles")
          .font(.headline)

        if text.isEmpty {
          // Stands in for the first words, which take a moment while the model loads.
          Text(verbatim: String(repeating: "Placeholder text for the explanation. ", count: 4))
            .redacted(reason: .placeholder)
        } else {
          Text(Self.formatted(text))
            .accessibilityIdentifier("cardDetail.insight.elaboration.\(store.widget.name)")
        }

        Text(String(localized: "Written on device by Apple Intelligence, which can make mistakes."))
          .font(.footnote)
          .foregroundStyle(.secondary)
      }
    }
  }

  /// The model is asked for plain text but sometimes emphasises a word anyway; that is shown as
  /// emphasis rather than as asterisks.
  private static func formatted(_ text: String) -> AttributedString {
    (try? AttributedString(
      markdown: text,
      options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
    )) ?? AttributedString(text)
  }
}
