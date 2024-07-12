//
//  QRImage.swift
//  Printer
//
//  Created by Jesus Ervin Chapi Suyo on 9/07/24.
//

import Foundation
import CoreImage

public struct QRImage: ReceiptItem {
    public let textQR: String

    
    public init(_ textQR: String) {
        self.textQR = textQR

    }

    //  https://reference.epson-biz.com/modules/ref_escpos/index.php?content_id=145
    public func assemblePrintableData(_ profile: PrinterProfile) -> [UInt8] {
        let qrImage = generateQRCode(from: textQR)
        
        let imageDuplicate = increaseImageSize(image: qrImage, size: 5) // incrementamos el tamanio por 5
        
        let dataTas = iteratePixels(image: imageDuplicate!)
        
        return dataTas
    }
    
    func generateQRCode(from string: String) -> UIImage {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        
        filter.message = Data(string.utf8)

        if let outputImage = filter.outputImage {
            if let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
                return UIImage(cgImage: cgImage)
            }
        }

        return UIImage(systemName: "xmark.circle") ?? UIImage()
    }
    
    func increaseImageSize(image: UIImage, size: Int) -> UIImage? {
        let originalWidth = image.size.width
        let originalHeight = image.size.height
        
        let newWidth = originalWidth * 5
        let newHeight = originalHeight * 5
        let newSize = CGSize(width: newWidth, height: newHeight)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, image.scale)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        // Draw the original image twice to fill the new size
        context.draw(image.cgImage!, in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        return newImage
    }
    
    func iteratePixels(image: UIImage) -> [UInt8] {
        guard let cgImage = image.cgImage else {
            fatalError("Could not load CGImage")
        }
        
        let width = cgImage.width
        let height = cgImage.height
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        
        var pixelData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
        guard let context = CGContext(data: &pixelData,
                                      width: width,
                                      height: height,
                                      bitsPerComponent: bitsPerComponent,
                                      bytesPerRow: bytesPerRow,
                                      space: colorSpace,
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            fatalError("Could not create context")
        }
        //matrix  bits
        var binaryMatrix = [[Int]](repeating: [Int](repeating: 0, count: width), count: height)
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
       
        for y in 0..<height {
            for x in 0..<width {
                let pixelIndex = (y * width + x) * bytesPerPixel
                let red = pixelData[pixelIndex]
                let green = pixelData[pixelIndex + 1]
                let blue = pixelData[pixelIndex + 2]
                let alpha = pixelData[pixelIndex + 3]
                
                if red > 128 ||
                    green > 128 ||
                    blue > 128 {
                    binaryMatrix[y][x] = 0
                }else{
                    binaryMatrix[y][x] = 1
                }
                // Process each pixel here
                print("Pixel at (\(x), \(y)): R=\(red), G=\(green), B=\(blue), A=\(alpha)")
            }
        }
       print("kkk")
       print("\(binaryMatrix)")
        let response = ImageItem(image.cgImage!).buildImageFormatToPrint(arrayBits: binaryMatrix)
        return response
    }
}
