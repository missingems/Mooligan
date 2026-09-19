import ComposableArchitecture
import Networking
import SwiftUI

struct SettingsView: View {
  let store: StoreOf<SettingsFeature>

  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      List {
        if let freshness = store.freshness {
          developer(freshness)
        } else {
          ProgressView()
            .frame(maxWidth: .infinity)
        }
      }
      .navigationTitle("Settings")
      .toolbarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button(role: .close) {
            dismiss()
          }
          .accessibilityIdentifier("settings.close")
        }
      }
      .refreshable {
        await store.send(.refresh).finish()
      }
      .task {
        await store.send(.task).finish()
      }
    }
  }

  @ViewBuilder private func developer(_ freshness: DataFreshness) -> some View {
    Section {
      row("Last checked", freshness.catalog?.lastCheckedDate)
      row("Last downloaded", freshness.catalog?.lastIngestedDate)
      LabeledContent("Scryfall export", value: freshness.catalog?.remoteUpdatedAt.flatMap(exportDate) ?? "—")
      LabeledContent("Cards", value: (freshness.catalog?.ingestedCardCount ?? 0).formatted())
      LabeledContent("Status", value: freshness.catalog?.status.capitalized ?? "Never")
    } header: {
      Text("Developer")
    } footer: {
      Text("Scryfall's card catalog. Checked daily, downloaded again weekly.")
    }

    Section {
      row("Sets", freshness.setsFetchedAt)
      dataset("Search pages", freshness.cardPages)
    } header: {
      Text("Scryfall")
    } footer: {
      Text("Straight from Scryfall. Search pages are asked for again after the daily export.")
    }

    Section {
      LabeledContent("Current build", value: freshness.mtgjsonBuild ?? "Unknown")
      row("Asked", freshness.mtgjsonBuildAskedAt)
      dataset("Booster odds", freshness.boosterOdds)
      dataset("Pull odds", freshness.pullOdds)
      dataset("Price histories", freshness.priceHistories)
    } header: {
      Text("MTGJSON")
    } footer: {
      Text("Odds and prices are kept until MTGJSON makes a new build.")
    }

    Section {
      LabeledContent(
        "Version",
        value: freshness.cardImageHashes.map { "\($0.masterVersion) + \($0.latestPatch) patches" } ?? "Not downloaded"
      )
      row("Updated", freshness.cardImageHashesUpdatedAt)
    } header: {
      Text("Card scanner")
    } footer: {
      Text("The image database the scanner matches cards against.")
    }
  }

  private func row(_ title: LocalizedStringKey, _ date: Date?) -> some View {
    LabeledContent(title) {
      if let date {
        Text("\(date.formatted(date: .abbreviated, time: .shortened)) (\(date.formatted(.relative(presentation: .named))))")
      } else {
        Text("Never")
      }
    }
  }

  @ViewBuilder private func dataset(_ title: LocalizedStringKey, _ dataset: StoredDataset) -> some View {
    LabeledContent(title, value: dataset.count.formatted())
    if dataset.count > 0 {
      row("Newest", dataset.newest)
      row("Oldest", dataset.oldest)
      if let build = dataset.builds.first {
        LabeledContent("Newest build", value: build)
      }
    }
  }

  /// Scryfall stamps its exports like "2026-09-18T21:04:25.395+00:00".
  private func exportDate(_ stamp: String) -> String? {
    let parser = ISO8601DateFormatter()
    parser.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return parser.date(from: stamp)?.formatted(date: .abbreviated, time: .shortened) ?? stamp
  }
}
