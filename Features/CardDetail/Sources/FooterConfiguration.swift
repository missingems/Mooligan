import Foundation

struct FooterConfiguration: Identifiable {
  let id: UUID = UUID()
  let iconName: String?
  let systemIconName: String?
  let title: String
  let detail: String
  
  init(
    iconName: String? = nil,
    systemIconName: String? = nil,
    title: String,
    detail: String
  ) {
    self.iconName = iconName
    self.systemIconName = systemIconName
    self.title = title
    self.detail = detail
  }
}
