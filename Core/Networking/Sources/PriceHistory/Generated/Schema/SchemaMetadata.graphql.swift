// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

protocol MTGGraphQLAPI_SelectionSet: ApolloAPI.SelectionSet & ApolloAPI.RootSelectionSet
where Schema == MTGGraphQLAPI.SchemaMetadata {}

protocol MTGGraphQLAPI_InlineFragment: ApolloAPI.SelectionSet & ApolloAPI.InlineFragment
where Schema == MTGGraphQLAPI.SchemaMetadata {}

protocol MTGGraphQLAPI_MutableSelectionSet: ApolloAPI.MutableRootSelectionSet
where Schema == MTGGraphQLAPI.SchemaMetadata {}

protocol MTGGraphQLAPI_MutableInlineFragment: ApolloAPI.MutableSelectionSet & ApolloAPI.InlineFragment
where Schema == MTGGraphQLAPI.SchemaMetadata {}

extension MTGGraphQLAPI {
  typealias SelectionSet = MTGGraphQLAPI_SelectionSet

  typealias InlineFragment = MTGGraphQLAPI_InlineFragment

  typealias MutableSelectionSet = MTGGraphQLAPI_MutableSelectionSet

  typealias MutableInlineFragment = MTGGraphQLAPI_MutableInlineFragment

  enum SchemaMetadata: ApolloAPI.SchemaMetadata {
    static let configuration: any ApolloAPI.SchemaConfiguration.Type = SchemaConfiguration.self

    private static let objectTypeMap: [String: ApolloAPI.Object] = [
      "Card": MTGGraphQLAPI.Objects.Card,
      "CardPrices": MTGGraphQLAPI.Objects.CardPrices,
      "Query": MTGGraphQLAPI.Objects.Query
    ]

    static func objectType(forTypename typename: String) -> ApolloAPI.Object? {
      objectTypeMap[typename]
    }
  }

  enum Objects {}
  enum Interfaces {}
  enum Unions {}

}