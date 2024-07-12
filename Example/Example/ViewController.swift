//
//  ViewController.swift
//  Example
//
//  Created by GongXiang on 12/8/16.
//  Copyright © 2016 Kevin. All rights reserved.
//

import Printer
import UIKit
import WebKit
import CoreImage

class ViewController: UIViewController {
    private let bluetoothPrinterManager = BluetoothPrinterManager()
    private let dummyPrinter = DummyPrinter()
    
    @IBOutlet var webView: WKWebView!
    let voucherR = VoucherReader()
    
    let context = CIContext()
    let filter = CIFilter.qrCodeGenerator()
    
    @IBOutlet weak var pruebaImage: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        dummyPrinter.ticketRender = self
        
        let service = "[L]CANT. [C]P.UNIT. [R]IMPORTE\n[L]3 PACK 281123 LECHE VALE\n[L]1.00[C]400.00[R]400.00\n[L]ITEM 281123 LECHE VALE\n[L]1.00[C]150.00[R]150.00\n[C]--------------------------------\n[R] OP.GRAVADAS: S/[R]466.10\n[R] SUBTOTAL: S/[R]466.10\n[R] IGV 18%: S/[R]83.90\n[R] TOTAL: S/ [R]550.00\n                               \n"
        
       // let receipt = Receipt(.init(maxWidthDensity: 500, fontDensity: 12, encoding: .utf8))
       
        voucherR.recognize(val_: service)
    }
    
    @IBAction func touchPrint(sender: UIButton) {
        guard let image = UIImage(named: "pepsi"), let cgImage = image.cgImage else {
            return
        }
             
        let receipt = Receipt(.init(maxWidthDensity: 500, fontDensity: 12, encoding: .ascii))
        <<~ .style(.initialize)
        <<< QRCode(content: "https://www.apple.com")
        

        print("show data \(receipt.data)")
        
        let stringQR = "00000000000|01|FF01|986|83.90|550.00|12/06/2024|RUC|00000000"
       
        
        if bluetoothPrinterManager.canPrint {
            //bluetoothPrinterManager.write(Data(receipt.data))

            bluetoothPrinterManager.write(Data(voucherR.printData))
        }
   
        dummyPrinter.write(Data(receipt.data))
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? BluetoothPrinterSelectTableViewController {
            vc.sectionTitle = "Choose Bluetooth Printer"
            vc.printerManager = bluetoothPrinterManager
        }
    }
}

extension ViewController: TicketRender {
    func printerDidGenerate(_ printer: DummyPrinter, html htmlTicket: String) {
        DispatchQueue.main.async { [weak self] in
            self?.webView.loadHTMLString(htmlTicket, baseURL: nil)
        }
//        debugPrint(htmlTicket)
    }
}
