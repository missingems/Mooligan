import SwiftUI
import Networking

public struct ContentView: View {
  @State
  var sets: [Networking.Set] = []
  
  let request = BrowseRequest()
  
  public init() {
    
  }
  
  public var body: some View {
    Text("\(sets.count)")
      .padding()
      .onAppear {
        Task {
          sets = try await request.client.getAllSets()
        }
      }
  }
}


#Preview {
  ContentView()
}
