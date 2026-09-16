import UIKit

/// One in-flight fetch-and-render per `IconRequest`, shared by every `IconLazyImage` waiting on it.
///
/// Sibling rows in a set list often show the same icon (a set and its tokens, promos and art
/// series), and without this each of them fetched and rasterized it on its own before any could
/// reach the cache. The shared task is deliberately not a child of the caller: a row scrolling off
/// screen cancels its own wait, but the render finishes for the rows still waiting and for the cache.
@MainActor
enum IconRenderTasks {
  private static var tasks: [String: Task<UIImage?, Never>] = [:]

  static func image(
    for request: IconRequest,
    render: @escaping @MainActor @Sendable () async -> UIImage?
  ) async -> UIImage? {
    guard let key = IconBitmapCache.key(for: request) else { return nil }
    if let task = tasks[key] {
      return await task.value
    }

    let task = Task { await render() }
    tasks[key] = task
    let image = await task.value
    if tasks[key] == task { tasks[key] = nil }
    return image
  }
}
