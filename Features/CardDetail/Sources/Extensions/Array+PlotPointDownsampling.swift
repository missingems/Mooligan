import Foundation

extension Array where Element == ChartDerivedData.PlotPoint {
  /// At most `limit` points, picked with largest-triangle-three-buckets: the first and last points
  /// stay, and each bucket between keeps the point that forms the largest triangle with the point
  /// kept before it and the average of the next bucket, so peaks and dips survive the thinning.
  func downsampled(to limit: Int) -> [ChartDerivedData.PlotPoint] {
    guard limit >= 3, count > limit else { return self }

    let bucketSize = Double(count - 2) / Double(limit - 2)
    var sampled: [ChartDerivedData.PlotPoint] = [self[0]]
    sampled.reserveCapacity(limit)
    var kept = 0

    for bucket in 0..<(limit - 2) {
      let nextStart = Int(Double(bucket + 1) * bucketSize) + 1
      let nextEnd = Swift.max(Swift.min(Int(Double(bucket + 2) * bucketSize) + 1, count), nextStart + 1)
      var averageX = 0.0
      var averageY = 0.0
      for index in nextStart..<nextEnd {
        averageX += self[index].date.timeIntervalSinceReferenceDate
        averageY += self[index].value
      }
      let nextCount = Double(nextEnd - nextStart)
      averageX /= nextCount
      averageY /= nextCount

      let start = Int(Double(bucket) * bucketSize) + 1
      let end = Int(Double(bucket + 1) * bucketSize) + 1
      let keptX = self[kept].date.timeIntervalSinceReferenceDate
      let keptY = self[kept].value

      var best = start
      var bestArea = -1.0
      for index in start..<end {
        let x: Double = self[index].date.timeIntervalSinceReferenceDate
        let y: Double = self[index].value
        let across: Double = (keptX - averageX) * (y - keptY)
        let down: Double = (keptX - x) * (averageY - keptY)
        let area = Swift.abs(across - down)
        if area > bestArea {
          bestArea = area
          best = index
        }
      }

      sampled.append(self[best])
      kept = best
    }

    sampled.append(self[count - 1])
    return sampled
  }
}
