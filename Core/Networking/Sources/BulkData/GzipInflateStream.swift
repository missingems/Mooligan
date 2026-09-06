import Compression
import Foundation

public final class GzipInflateStream {
  public enum Failure: Error, Equatable {
    case notGzip
    case truncated
    case corrupt
    case unavailable
  }

  private let stream: UnsafeMutablePointer<compression_stream>
  private let outputCapacity = 64 * 1024
  private let output: UnsafeMutablePointer<UInt8>

  private var headerBuffer: [UInt8] = []
  private var isHeaderParsed = false
  private var isStreamComplete = false

  public init() throws {
    stream = .allocate(capacity: 1)
    stream.initialize(
      to: compression_stream(
        dst_ptr: UnsafeMutablePointer<UInt8>(bitPattern: -1)!,
        dst_size: 0,
        src_ptr: UnsafePointer<UInt8>(bitPattern: -1)!,
        src_size: 0,
        state: nil
      )
    )

    guard
      compression_stream_init(stream, COMPRESSION_STREAM_DECODE, COMPRESSION_ZLIB)
        == COMPRESSION_STATUS_OK
    else {
      stream.deallocate()
      throw Failure.unavailable
    }

    output = .allocate(capacity: outputCapacity)
  }

  deinit {
    compression_stream_destroy(stream)
    stream.deallocate()
    output.deallocate()
  }

  public var isComplete: Bool {
    isStreamComplete
  }

  public func inflate(_ chunk: Data) throws -> Data {
    guard isStreamComplete == false, chunk.isEmpty == false else { return Data() }

    var deflateBytes: [UInt8]

    if isHeaderParsed {
      deflateBytes = [UInt8](chunk)
    } else {
      headerBuffer.append(contentsOf: chunk)

      guard let headerLength = try Self.gzipHeaderLength(headerBuffer) else {
        return Data()
      }

      isHeaderParsed = true
      deflateBytes = Array(headerBuffer[headerLength...])
      headerBuffer = []

      guard deflateBytes.isEmpty == false else { return Data() }
    }

    var produced = Data()

    try deflateBytes.withUnsafeBufferPointer { source in
      stream.pointee.src_ptr = source.baseAddress!
      stream.pointee.src_size = source.count

      while true {
        stream.pointee.dst_ptr = output
        stream.pointee.dst_size = outputCapacity

        let status = compression_stream_process(stream, 0)
        let count = outputCapacity - stream.pointee.dst_size

        if count > 0 {
          produced.append(output, count: count)
        }

        switch status {
        case COMPRESSION_STATUS_OK:
          if stream.pointee.src_size == 0, stream.pointee.dst_size > 0 {
            return
          }

        case COMPRESSION_STATUS_END:
          isStreamComplete = true
          return

        default:
          throw Failure.corrupt
        }
      }
    }

    return produced
  }

  public func finish() throws {
    guard isStreamComplete else { throw Failure.truncated }
  }

  static func gzipHeaderLength(_ bytes: [UInt8]) throws -> Int? {
    guard bytes.count >= 2 else { return nil }
    guard bytes[0] == 0x1F, bytes[1] == 0x8B else { throw Failure.notGzip }
    guard bytes.count >= 4 else { return nil }
    guard bytes[2] == 8 else { throw Failure.notGzip }

    let flags = bytes[3]
    guard bytes.count >= 10 else { return nil }
    var index = 10

    if flags & 0x04 != 0 {
      guard bytes.count >= index + 2 else { return nil }
      let extraLength = Int(bytes[index]) | Int(bytes[index + 1]) << 8
      index += 2 + extraLength
    }

    if flags & 0x08 != 0 {
      guard let end = Self.indexAfterNulTerminator(bytes, from: index) else { return nil }
      index = end
    }

    if flags & 0x10 != 0 {
      guard let end = Self.indexAfterNulTerminator(bytes, from: index) else { return nil }
      index = end
    }

    if flags & 0x02 != 0 {
      index += 2
    }

    return bytes.count >= index ? index : nil
  }

  private static func indexAfterNulTerminator(_ bytes: [UInt8], from start: Int) -> Int? {
    var index = start
    while index < bytes.count {
      if bytes[index] == 0 { return index + 1 }
      index += 1
    }
    return nil
  }
}
