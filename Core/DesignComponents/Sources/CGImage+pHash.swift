//
//  UIImage+Phash.swift
//  DesignComponents
//
//  Created by Jun on 5/4/26.
//

import Accelerate
import CoreGraphics

public extension CGImage {
  var pHash: UInt64? {
    let pHashDCTSetup = vDSP_DCT_CreateSetup(nil, 32, .II)!
    let size = 32
    var pixelBytes = [UInt8](repeating: 0, count: size * size)
    
    guard let ctx = CGContext(data: &pixelBytes, width: size, height: size, bitsPerComponent: 8, bytesPerRow: size, space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue) else { return nil }
    ctx.interpolationQuality = .high
    ctx.draw(self, in: CGRect(x: 0, y: 0, width: size, height: size))
    
    var pixels = [Float](repeating: 0, count: size * size)
    vDSP_vfltu8(pixelBytes, 1, &pixels, 1, vDSP_Length(size * size))
    
    var rowDCT = [Float](repeating: 0, count: size * size)
    for row in 0..<size {
      pixels.withUnsafeBufferPointer { src in
        rowDCT.withUnsafeMutableBufferPointer { dst in
          vDSP_DCT_Execute(pHashDCTSetup, src.baseAddress! + row * size, dst.baseAddress! + row * size)
        }
      }
    }
    
    var transposed = [Float](repeating: 0, count: size * size)
    vDSP_mtrans(rowDCT, 1, &transposed, 1, vDSP_Length(size), vDSP_Length(size))
    
    var colDCT = [Float](repeating: 0, count: size * size)
    for row in 0..<size {
      transposed.withUnsafeBufferPointer { src in
        colDCT.withUnsafeMutableBufferPointer { dst in
          vDSP_DCT_Execute(pHashDCTSetup, src.baseAddress! + row * size, dst.baseAddress! + row * size)
        }
      }
    }
    
    var dct = [Float](repeating: 0, count: size * size)
    vDSP_mtrans(colDCT, 1, &dct, 1, vDSP_Length(size), vDSP_Length(size))
    
    var low = [Float]()
    low.reserveCapacity(63)
    for y in 0..<8 {
      for x in 0..<8 {
        guard !(x == 0 && y == 0) else { continue }
        low.append(dct[y * size + x])
      }
    }
    
    let median = low.sorted()[low.count / 2]
    var hash: UInt64 = 0
    for (i, v) in low.enumerated() where v > median {
      hash |= (1 << i)
    }
    return hash
  }
}
