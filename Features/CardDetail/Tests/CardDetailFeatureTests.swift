@testable import CardDetail
import ComposableArchitecture
import Foundation
@testable import Networking
import Testing

struct CardDetailFeatureTests {
  typealias Client = Networking.MockMagicCardDetailRequestClient<MockMagicCard<MockMagicCardColor>>
  let card = MagicCardFixtures.split.value
  
  @Test(
    "Expected action from different entry points",
    arguments: [
      EntryPoint<Client>.query,
      EntryPoint<Client>.set(MockGameSet())
    ]
  )
  func entryPoint(_ entryPoint: EntryPoint<Client>) async throws {
    let state = Feature<Client>.State(card: card, entryPoint: entryPoint)
    
    switch entryPoint {
    case .query:
      #expect(state.start == .fetchSet(card: card))
      
    case .set:
      #expect(state.start == .fetchVariants(card: card))
    }
  }
  
  @Test(
    "Expected flow when view appeared",
    arguments: [
      EntryPoint<Client>.query,
      EntryPoint<Client>.set(MockGameSet())
    ],
    [
      Client.TestConfiguration.successFlow,
      Client.TestConfiguration.failureFlow
    ]
  )
  func viewAppeared(
    _ entryPoint: EntryPoint<Client>,
    configuration: Client.TestConfiguration
  ) async {
    let store = await TestStore(
      initialState: Feature.State(card: card, entryPoint: entryPoint),
      reducer: {
        Feature(client: Client(testConfiguration: configuration))
      }
    )
    
    switch entryPoint {
    case .query:
      if configuration == .successFlow {
        await store.send(.viewAppeared(initialAction: store.state.start))
        await store.receive(.fetchSet(card: card))
        await store.receive(.updateSetIconURL(.success(URL(string: "https://mooligan.com")))) { state in
          state.content.setIconURL = .success(URL(string: "https://mooligan.com"))
        }
        await store.receive(.fetchVariants(card: card))
        await store.receive(.updateVariants(.success([card]))) { state in
          state.content.variants = .success([card])
        }
      } else {
        let expectedErrorMessage = """
        The operation couldn’t be completed. (Networking.MockMagicCardDetailRequestClient\
        <Networking.MockMagicCard<Networking.MockMagicCardColor>>.MockError error 1.)
        """
        await store.send(.viewAppeared(initialAction: store.state.start))
        await store.receive(.fetchSet(card: card))
        await store.receive(
          .updateSetIconURL(.failure(.failedToFetchSetIconURL(errorMessage: expectedErrorMessage))
          )
        ) { state in
          state.content.setIconURL = .failure(FeatureError.failedToFetchSetIconURL(errorMessage: expectedErrorMessage))
        }
      }
      
    case .set:
      if configuration == .successFlow {
        await store.send(.viewAppeared(initialAction: store.state.start))
        await store.receive(.fetchVariants(card: card))
        await store.receive(.updateVariants(.success([card]))) { state in
          state.content.variants = .success([card])
        }
      } else {
        let expectedErrorMessage = """
        The operation couldn’t be completed. (Networking.MockMagicCardDetailRequestClient\
        <Networking.MockMagicCard<Networking.MockMagicCardColor>>.MockError error 0.)
        """
        await store.send(.viewAppeared(initialAction: store.state.start))
        await store.receive(.fetchVariants(card: card))
        await store.receive(
          .updateVariants(.failure(.failedToFetchVariants(errorMessage: expectedErrorMessage)))
        ) { state in
          state.content.variants = .failure(.failedToFetchVariants(errorMessage: expectedErrorMessage))
        }
      }
    }
  }
}

