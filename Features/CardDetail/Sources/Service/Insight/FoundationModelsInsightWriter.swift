import Foundation
import FoundationModels

/// Writes with Apple's on-device language model, so nothing about the card leaves the phone.
struct FoundationModelsInsightWriter: CardInsightWriter {
  var isAvailable: Bool {
    SystemLanguageModel.default.isAvailable
  }

  func write(_ prompt: String) -> AsyncThrowingStream<String, any Error> {
    AsyncThrowingStream { continuation in
      let task = Task {
        do {
          let session = LanguageModelSession(instructions: """
            You explain Magic: The Gathering to players inside a card collection app. The reader \
            tapped one detail of a card and wants to understand it. Work only from the definition \
            and the facts about the card you are given: never invent card names, rules, prices, \
            formats or numbers that are not in them. Write two short paragraphs of plain text, with \
            no headings, lists or markdown, and no more than 110 words in all. Speak to the reader \
            directly.
            """)
          // A little randomness keeps it from reading like a form, but not so much that it wanders
          // from the facts it was given.
          let options = GenerationOptions(temperature: 0.4, maximumResponseTokens: 400)
          for try await snapshot in session.streamResponse(to: prompt, options: options) {
            continuation.yield(snapshot.content)
          }
          continuation.finish()
        } catch {
          continuation.finish(throwing: error)
        }
      }
      continuation.onTermination = { _ in task.cancel() }
    }
  }
}
