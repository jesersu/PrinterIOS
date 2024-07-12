//
//  VoucherReader.swift
//  Printer
//
//  Created by Jesus Ervin Chapi Suyo on 20/06/24.
//

import Foundation
import CoreImage.CIFilterBuiltins

@available(iOS 13.0, *)
public class VoucherReader{
    var command = ""
    var cadena = ""
    var text = ""
    var nextLine = ""
    var aligmentCode : [UInt8] = []
    var multipleColums : [String] = []
    public var printData:[UInt8] = []
    
    //QR
    let context = CIContext()
    let filter = CIFilter.qrCodeGenerator()
    
    public init(){
        self.printData = printHeaderCenter()
    }
    public func recognize ( val_ voucher : String) {
     
        for ch in voucher {
          
            //reconocer comandos [C]
            if ch == "[" {
                command = command + String(ch)
            }
            
            else if ch == "]" {
                if command.count == 2 {
                    command = command + String(ch) // "[C], [R], [L]"
                    aligmentCode.append(commandRecongnize()) // [0, 1, 2]
                    saveText()
                    command = ""
                    text = ""
                }
            }
            
            else if ch == "C"
                || ch == "L"
                || ch == "R" {
                
                if command == "[" { // ES COMANDO
                    ///Se agrega al los comandos [C , por ejemplo
                    command = command + String(ch)
                    ///se imprime xD
                    ///ya se tiene el comando y el texto
                   
                   
                }else{// SE AGREGA AL TEXTO
                    text = text + String(ch)
                }
              
            }
            //enline
            else if ch.isNewline {
                
                goToPrint()
                command  = ""
            }
            
            //Normal text
            else { text = text + String(ch) }
            
        }
    
    }
    
    public func goToPrint(){

        if aligmentCode.count == 1 { // normal text
            if text.starts(with: "<"){
                printData += esQRCommand()
                self.text = ""
                self.aligmentCode = []
                multipleColums = []
            }else{
                validateLayout()
                printData = printData + printText()
                self.text = ""
                self.aligmentCode = []
                multipleColums = []
            }
        }
        else if aligmentCode.count == 2 { // Two Columns
            
            let columsData = KVItem(multipleColums.first ?? "", text).assemblePrintableData(.🖨️58(.ascii))
            printData = printData + columsData
        
            multipleColums = []
            self.text = ""
            self.aligmentCode = []
        }
        
        else if aligmentCode.count == 3 { // Three Columns
         
            let columsData = XYZItem(multipleColums.first ?? "", multipleColums.last ?? "", text ).assemblePrintableData(.🖨️58(.ascii))
            printData = printData + columsData
        
            multipleColums = []
            self.text = ""
            self.aligmentCode = []
        }
 
        
    }
    
    func printHeaderCenter() -> [UInt8]{
        return Command.FontControlling.initialize.value + Command.Layout.justification(.center).value
    }
    
    func printHeaderLeft() -> [UInt8]{
        return Command.FontControlling.initialize.value + Command.Layout.justification(.left).value
    }
    
    func printHeaderRigth() -> [UInt8]{
        return Command.FontControlling.initialize.value + Command.Layout.justification(.right).value
    }
    
    //Se modifica la data
    func validateLayout(){
        if aligmentCode.first == 0 {
            printData += printHeaderLeft()
        }else if aligmentCode.first == 1 {
            printData += printHeaderCenter()
        }else if aligmentCode.first == 2 {
            printData += printHeaderRigth()
        }
    }
    
    func printText() -> [UInt8] {
        guard let data = text.data(using: .utf8) else {
            return []
        }
        return [UInt8](data) + Command.CursorPosition.lineFeed.value
        
    }
    func esQRCommand() -> [UInt8] {
        var qrText : String = ""
        var esText = false
        for letter in text{
            if letter == "<"{
                esText = false
            }
            else if letter == ">"{
                esText = true
            }
            else if esText {
                qrText = qrText + String(letter)
            }
           
        }
      // Final qrText
        let codeQR = QRImage(qrText).assemblePrintableData(.🖨️58())
        
        return codeQR
    }

    
    
    
    public func printCommand(aligment : String) {
       // print("\(commandRecongnize(in_: aligment)) -- \(text)")
        self.text = ""
    }
    
    public func commandRecongnize() -> UInt8 {
        switch command {
        case "[L]":
            return 0
        case "[C]":
            return 1
        case "[R]":
            return 2
        default:
            return 0
        }
    }
    
    public func saveText(){
        if aligmentCode.count == 2 {
            print("para guardar papi 2 \(text)")
            multipleColums.append(text)
        }
        else if aligmentCode.count == 3 {
            print("para guardar papi 3 \(text)")
            multipleColums.append(text)
        }
    }
    
    //QR
    func generateQRCode(from string: String) -> UIImage {
        filter.message = Data(string.utf8)

        if let outputImage = filter.outputImage {
            if let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
                return UIImage(cgImage: cgImage)
            }
        }
        return UIImage(systemName: "xmark.circle") ?? UIImage()
    }
}
