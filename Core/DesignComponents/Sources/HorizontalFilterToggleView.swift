import SwiftUI

struct ScalingMenuView: View {
  @State private var isExpanded = false
  
  var body: some View {
    Button("Menu") {
      withAnimation(.spring(response: 0.5)) {
        isExpanded.toggle()
      }
    }
    .padding()
    .background(Color.blue)
    .foregroundColor(.white)
    .cornerRadius(10)
    .overlay {
      if isExpanded {
        ExpandedMenuContent(isExpanded: $isExpanded)
          .transition(.scale.combined(with: .opacity))
      }
    }
  }
}

struct ExpandedMenuContent: View {
  @Binding var isExpanded: Bool
  
  var body: some View {
    VStack {
      // Your expanded content
      Text("Expanded Menu")
      Button("Close") {
        withAnimation { isExpanded = false }
      }
    }
    .frame(width: 300, height: 400)
    .background(Color.blue)
    .cornerRadius(20)
  }
}

// Your original code was correct!
// Its position in the parent view was the problem.
struct MorphingMenuView: View {
  @State private var isExpanded = false
  @Namespace private var animation
  
  var body: some View {
    ZStack(alignment: .center) {
      if !isExpanded {
        // Collapsed button state
        Button(action: { withAnimation(.spring(response: 0.6)) { isExpanded = true } }) {
          Text("Menu")
            .padding()
            .foregroundColor(.white)
        }
        .matchedGeometryEffect(id: "menu", in: animation)
      } else {
        // Expanded content view
        VStack(spacing: 20) {
          HStack {
            Text("Menu Content")
              .font(.headline)
            Spacer()
            Button("Close") {
              withAnimation(.spring(response: 0.6)) { isExpanded = false }
            }
          }
          
          Text("Item 1")
          Text("Item 2")
          Text("Item 3")
        }
        .matchedGeometryEffect(id: "menu", in: animation)
      }
    }
    .background(Color.blue)
    .cornerRadius(10)
  }
}

#Preview {
  MorphingMenuView()
}
