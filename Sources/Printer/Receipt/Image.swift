//
//  ImageItem.swift
//  Printer
//
//  Created by gix on 2023/2/2.
//

import CoreGraphics
import Foundation

public struct ImageItem: ReceiptItem {
    public enum Mode: UInt8 {
        case normal = 0
        case doubleWidth = 1
        case doubleHeight = 2
        case doubleWH = 3
    }

    let mode: Mode
    let cgImage: CGImage
    let width: Int
    let height: Int

    let grayThreshold: UInt8

    public init(_ cgImage: CGImage, grayThreshold: UInt8 = 128, mode: Mode = .normal) {
        self.cgImage = cgImage
        self.mode = mode
        self.width = cgImage.width
        self.height = cgImage.height
        self.grayThreshold = grayThreshold
    }

    public func assemblePrintableData(_ profile: PrinterProfile) -> [UInt8] {
//        var data = [29, 118, 48, mode.rawValue]
//
//        // 一个字节8位
//        let widthBytes = (width + 7) / 8
//        //
//        let heightPixels = height
//
//        //
//        let xl = widthBytes % 256
//        let xh = widthBytes / 256
//
//        let yl = height % 256
//        let yh = height / 256
//
//        data.append(contentsOf: [xl, xh, yl, yh].map { UInt8($0) })
//
//        guard let md = cgImage.dataProvider?.data,
//              let bytes = CFDataGetBytePtr(md)
//        else {
//            fatalError("Couldn't access image data")
//        }
//
//        let bytesPerPixel = cgImage.bytesPerRow / width
//
//        if cgImage.colorSpace?.model != .rgb && cgImage.colorSpace?.model != .monochrome {
//            fatalError("unsupported colourspace mode \(cgImage.colorSpace?.model.rawValue ?? -1)")
//        }
//
//        var pixels = [UInt8]()
//
//        for y in 0 ..< height {
//            for x in 0 ..< width {
//                let offset = (y * cgImage.bytesPerRow) + (x * bytesPerPixel)
//
//                let components = (r: bytes[offset], g: bytes[offset + 1], b: bytes[offset + 2], a: bytes[offset + 3])
//                let grayValue = UInt8((Int(components.r) * 38 + Int(components.g) & 75 + Int(components.b) * 15) >> 7)
//
//                pixels.append(grayValue > grayThreshold ? 1 : 0)
////                    0..65535
////                    let grayValue = Int(bytes[offset]) * 256 + Int(bytes[offset + 1])
////                    pixels.append(grayValue > 65535/2 ? 1 : 0)
//            }
//        }
//
//        var rasterImage = [UInt8]()
//
//        // 现在开始往里面填数据
//        for y in 0 ..< heightPixels {
//            for w in 0 ..< widthBytes {
//                var value = UInt8(0)
//                for i in 0 ..< 8 {
//                    let x = i + w * 8
//                    var ch = UInt8(0)
//
//                    if x < width {
//                        let index = y * width + x
//                        ch = pixels[index]
//                    }
//
//                    value = value << 1
//                    value = value | ch
//                }
//                rasterImage.append(value)
//            }
//        }
//
//        data.append(contentsOf: rasterImage)

        return getImageBits()!//data
    }
    
    func getImageBits() -> [UInt8]? {

        //create empty
       
        var i = 0
        var count = 1
        let n = 3.0
        var size : Int = 0
        var bits = 8.0
        let block = n * bits
        var numOfBlocks = 1
        
        let arrayHeigth = block * n
        
        // original
        let inputCGImage = self.cgImage
        guard let context = getImageContext(for: inputCGImage),
              let data = context.data else {return nil}

        let white = RGBA32(red: 255, green: 255, blue: 255, alpha: 255)
        let black = RGBA32(red: 0, green: 0, blue: 0, alpha: 255)

        let width = Int(inputCGImage.width)
        let height = Int(inputCGImage.height)
        let pixelBuffer = data.bindMemory(to: RGBA32.self, capacity: width * height)

        // get size
        if width > height {
            size = width
        }else {
            size = height
        }
        // calculate number of blocks
        var div = Double(size) / block
        if div.isInteger {
            numOfBlocks = Int(div)
        }else{
            numOfBlocks = Int(div.rounded(.up))
        }
        
        print("numOfBlocks -> \(numOfBlocks)")
      
        var row = Array(repeating:0, count: width)

        var arrayBits = Array(repeating: row, count: height)
        
        //switch to black and white image
        for x in 0 ..< height {
            for y in 0 ..< width {
                let offset = x * width + y
                if pixelBuffer[offset].red > 0 || pixelBuffer[offset].green > 0 || pixelBuffer[offset].blue > 0 {
                    pixelBuffer[offset] = black
                    arrayBits[x][y] = Int(1)
               
                } else {
                    pixelBuffer[offset] = white
                    arrayBits[x][y] = 0
                 
                }
            }
        }
        
        // arrayBits has only balck and white bits
        
        print("image black and white \(arrayBits)")
        print("width \(inputCGImage.width)")
        print("height \(inputCGImage.height)")
        
        var byteBlock: String = ""
        var byteBlockArray: [String] = []
        var parcialPrint : [UInt8] = [27, 97, 49, 28, 46, 27, 51, 16, 27, 42, 33, UInt8(width), 0]
        var temp = 0
        var numberRow = 0
        var currentLimit : Int = Int (block)
        //block = n(3) * bits(8)
        while temp < numOfBlocks{
            for c in 0 ..< width {
                for f in numberRow ..< Int(currentLimit){ // cada 24 de columna
                    if byteBlock.count == 8 { //validamos si completa el byte
                        let decimalNumber = Int(byteBlock, radix: 2)! // se convierte a decimal (255)
                        parcialPrint.append(UInt8(decimalNumber))
                        if f > height-1{
                            byteBlock = "0"
                        }else{
                            byteBlock = String(arrayBits[f][c])
                        }
                        
                    }else{
                        if f > height-1{
                            byteBlock += "0"
                            byteBlockArray.append("0")
                        }else{
                            byteBlock += String(arrayBits[f][c])
                        }
                    }
                  
                }
            }// termina un bloque de 24 bits
            
            //Siempre escapara un bit por lo que lo guardamos y seteamos a 0 otra vez
            let decimalNumber = Int(byteBlock, radix: 2)!
            parcialPrint.append(UInt8(decimalNumber))
            byteBlock = ""
            
           
            temp += 1
            numberRow += Int(block)
            currentLimit += Int(block)
            if temp < numOfBlocks {
                parcialPrint.append(10)
                parcialPrint.append(27)
                parcialPrint.append(42)
                parcialPrint.append(33)
                parcialPrint.append(UInt8(width))
                parcialPrint.append(0)
            }
           
        }
       
        parcialPrint.append(10)
        parcialPrint.append(27)
        parcialPrint.append(50)
        print ("pami \(parcialPrint) -- \(parcialPrint.count)")
        return parcialPrint

    }
    
    func getImageContext(for inputCGImage: CGImage) ->CGContext? {

        let colorSpace       = CGColorSpaceCreateDeviceRGB()
        let width            = inputCGImage.width
        let height           = inputCGImage.height
        let bytesPerPixel    = 4
        let bitsPerComponent = 8
        let bytesPerRow      = bytesPerPixel * width
        let bitmapInfo       = RGBA32.bitmapInfo

        guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo) else {
            print("unable to create context")
            return nil
        }

        context.setBlendMode(.copy)
        context.draw(inputCGImage, in: CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))

        return context
    }
    
    

//    private func invert(src: UIImage) -> UIImage{
//        var p = src.scale.bitPattern
//    }
    
    public func constructImage(arr: [[Int]]){
        
    }
    
    public func buildImageFormatToPrint(arrayBits: [[Int]]) -> [UInt8] {

         var i = 0
         var count = 1
         let n = 3.0
         var size : Int = 0
         var bits = 8.0
         let block = n * bits
         var numOfBlocks = 1
         
        let heightImage = arrayBits.count // Number of rows
        let widthImage = arrayBits.first?.count ?? 0 // Number of columns in the first row (assuming all rows have the same number of columns)
        
        var byteBlock: String = ""
        var byteBlockArray: [String] = []
        var parcialPrint : [UInt8] = [27, 97, 49, 28, 46, 27, 51, 16, 27, 42, 33, UInt8(widthImage), 0]
        var temp = 0
        var numberRow = 0
        var currentLimit : Int = Int (block)
       
        // get size
        if widthImage > heightImage {
            size = widthImage
        }else {
            size = heightImage
        }
        // calculate number of blocks
        var div = Double(size) / block
        if div.isInteger {
            numOfBlocks = Int(div)
        }else{
            numOfBlocks = Int(div.rounded(.up))
        }
        
        print("numOfBlocks -> \(numOfBlocks)")
        //block = n(3) * bits(8)
        while temp < numOfBlocks{
            for c in 0 ..< widthImage {
                for f in numberRow ..< Int(currentLimit){ // cada 24 de columna
                    if byteBlock.count == 8 { //validamos si completa el byte
                        let decimalNumber = Int(byteBlock, radix: 2)! // se convierte a decimal (255)
                        parcialPrint.append(UInt8(decimalNumber))
                        if f > heightImage-1{
                            byteBlock = "0"
                        }else{
                            byteBlock = String(arrayBits[f][c])
                        }
                        
                    }else{
                        if f > heightImage-1{
                            byteBlock += "0"
                            byteBlockArray.append("0")
                        }else{
                            byteBlock += String(arrayBits[f][c])
                        }
                    }
                  
                }
            }// termina un bloque de 24 bits
            
            //Siempre escapara un bit por lo que lo guardamos y seteamos a 0 otra vez
            let decimalNumber = Int(byteBlock, radix: 2)!
            parcialPrint.append(UInt8(decimalNumber))
            byteBlock = ""
            
           
            temp += 1
            numberRow += Int(block)
            currentLimit += Int(block)
            if temp < numOfBlocks {
                parcialPrint.append(10)
                parcialPrint.append(27)
                parcialPrint.append(42)
                parcialPrint.append(33)
                parcialPrint.append(UInt8(widthImage))
                parcialPrint.append(0)
            }
           
        }
       
        parcialPrint.append(10)
        parcialPrint.append(27)
        parcialPrint.append(50)
        parcialPrint.append(10)

        print ("pami \(parcialPrint) -- \(parcialPrint.count)")
        return parcialPrint

    }
}
struct RGBA32: Equatable {
    var color: UInt32

    var red: UInt8 {
        return UInt8((color >> 24) & 255)
    }

    var green: UInt8 {
        return UInt8((color >> 16) & 255)
    }

    var blue: UInt8 {
        return UInt8((color >> 8) & 255)
    }

    var alpha: UInt8 {
        return UInt8((color >> 0) & 255)
    }

    init(red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8) {
        color = (UInt32(red) << 24) | (UInt32(green) << 16) | (UInt32(blue) << 8) | (UInt32(alpha) << 0)
    }

    static let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
}

func ==(lhs: RGBA32, rhs: RGBA32) -> Bool {
    return lhs.color == rhs.color
}
extension FloatingPoint {
  var isInteger: Bool { rounded() == self }
}

