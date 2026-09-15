import Foundation
import Networking

extension ChartDerivedData.PlotSeries {
  func value(at date: Date) -> Double? {
    guard let first = points.first, let last = points.last else { return nil }
    guard date > first.date else { return first.value }
    guard date < last.date else { return last.value }

    var low = 0
    var high = points.count - 1
    while high - low > 1 {
      let mid = (low + high) / 2
      if points[mid].date <= date { low = mid } else { high = mid }
    }

    let x0 = points[low].date.timeIntervalSinceReferenceDate
    let x1 = points[high].date.timeIntervalSinceReferenceDate
    let width = x1 - x0
    guard width > 0.0 else { return points[low].value }

    let u = (date.timeIntervalSinceReferenceDate - x0) / width
    let u2 = u * u
    let u3 = u2 * u
    let y0 = points[low].value
    let y1 = points[high].value

    return (2.0 * u3 - 3.0 * u2 + 1.0) * y0
      + (u3 - 2.0 * u2 + u) * width * tangents[low]
      + (-2.0 * u3 + 3.0 * u2) * y1
      + (u3 - u2) * width * tangents[high]
  }

  static func monotoneTangents(_ points: [ChartDerivedData.PlotPoint]) -> [Double] {
    let count = points.count
    guard count > 1 else { return Array(repeating: 0.0, count: count) }

    let xs = points.map(\.date.timeIntervalSinceReferenceDate)
    let ys = points.map(\.value)

    func secant(_ index: Int) -> Double {
      let width = xs[index + 1] - xs[index]
      return width > 0.0 ? (ys[index + 1] - ys[index]) / width : 0.0
    }

    guard count > 2 else {
      let slope = secant(0)
      return [slope, slope]
    }

    var tangents = Array(repeating: 0.0, count: count)
    for index in 1..<(count - 1) {
      let h0 = xs[index] - xs[index - 1]
      let h1 = xs[index + 1] - xs[index]
      let s0 = secant(index - 1)
      let s1 = secant(index)
      let p = h0 + h1 > 0.0 ? (s0 * h1 + s1 * h0) / (h0 + h1) : 0.0
      let sign0: Double = s0 < 0.0 ? -1.0 : 1.0
      let sign1: Double = s1 < 0.0 ? -1.0 : 1.0
      let tangent = (sign0 + sign1) * min(abs(s0), abs(s1), 0.5 * abs(p))
      tangents[index] = tangent.isFinite ? tangent : 0.0
    }

    tangents[0] = (3.0 * secant(0) - tangents[1]) / 2.0
    tangents[count - 1] = (3.0 * secant(count - 2) - tangents[count - 2]) / 2.0
    return tangents
  }
}
