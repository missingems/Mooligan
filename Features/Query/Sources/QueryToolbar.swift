//
//  QueryToolbar.swift
//  Query
//
//  Created by Jun on 22/8/26.
//

import SwiftUI
import ComposableArchitecture

struct QueryToolbar: View {
  @Bindable var store: StoreOf<QueryFeature>
  
  var body: some View {
    ViewThatFits(in: .horizontal) {
      HStack(spacing: 8) {
        content
      }
      
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 8) {
          content
        }
      }
    }
  }
  
  @ContentBuilder private var content: some View {
    ColorTypeItemsView(store: store)
    CardTypeItemsView(store: store)
    SortOptionsView(store: store)
  }
}
