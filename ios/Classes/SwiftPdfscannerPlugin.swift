import Flutter
import UIKit
import WeScan

public class SwiftPdfscannerPlugin: NSObject, FlutterPlugin, ImageScannerControllerDelegate {
    
    var pendingResult : FlutterResult?
    
    public func imageScannerController(_ scanner: ImageScannerController, didFinishScanningWithResults results: ImageScannerResults) {
        print("Saving scanned image...")
        var path : String?
        if results.doesUserPreferEnhancedImage {
            path = savePicture(picture: results.enhancedImage ?? results.scannedImage, imageName: "scanned_\(Date().millisecondsSince1970).jpg")
        } else {
            path = savePicture(picture: results.scannedImage, imageName: "scanned_\(Date().millisecondsSince1970).jpg")
        }
        
        if pendingResult != nil {
            pendingResult!(path)
        }
        scanner.dismiss(animated: true, completion: nil)
    }
    
    public func imageScannerControllerDidCancel(_ scanner: ImageScannerController) {
        print("entra aqui")
    }
    
    public func imageScannerController(_ scanner: ImageScannerController, didFailWithError error: Error) {
        scanner.dismiss(animated: false, completion: nil)
    }
    
    static var registrated: FlutterPluginRegistrar? = nil
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "com.areaseys.imagepdfscanner.plugin", binaryMessenger: registrar.messenger())
        let instance = SwiftPdfscannerPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        registrated = registrar
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        
        switch call.method {
        case "scan":
            let argumentsMap = call.arguments! as! [String:Any?]
            //let scanSource = argumentsMap["scanSource"] as! Int
            //let scannedImagesPath = argumentsMap["scannedImagesPath"] as! String
            //let scannedImageName = argumentsMap["scannedImageName"] as! String
            pendingResult = result
            let rootViewController: FlutterViewController! = UIApplication.shared.keyWindow?.rootViewController as! FlutterViewController
            let scannerViewController = ImageScannerController()
            scannerViewController.imageScannerDelegate = self
            rootViewController.present(scannerViewController, animated: true)
            
            break
        case "generatePdf":
            let argumentsMap = call.arguments! as! [String:Any?]
            var imagesPaths : [String]? = nil
            if (argumentsMap["scanSource"] != nil) {
                imagesPaths = argumentsMap["scanSource"] as! [String]
            }
            let pdfName = argumentsMap["pdfName"] as! String
            let generatedPDFsPath = argumentsMap["generatedPDFsPath"] as! String
            let marginLeft = argumentsMap["marginLeft"] as! Int
            let marginRight = argumentsMap["marginRight"] as! Int
            let marginTop = argumentsMap["marginTop"] as! Int
            let marginBottom = argumentsMap["marginBottom"] as! Int
            let cleanScannedImagesWhenPdfGenerate = argumentsMap["cleanScannedImagesWhenPdfGenerate"] as! Bool
            let pageWidth = argumentsMap["pageWidth"] as! Int
            let pageHeight = argumentsMap["pageHeight"] as! Int
            
            
            
            break
        default:
            result(FlutterError(code: "error", message: "Not Implemented!", details: nil))
            break
        }
        
    }
    
}

extension Date {
    var millisecondsSince1970:Int64 {
        return Int64((self.timeIntervalSince1970 * 1000.0).rounded())
    }

    init(milliseconds:Int64) {
        self = Date(timeIntervalSince1970: TimeInterval(milliseconds) / 1000)
    }
}

func savePicture(picture: UIImage, imageName: String) -> String {
    let imagePath = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString).appendingPathComponent(imageName)
    let data = UIImageJPEGRepresentation(picture, 0.9)
    FileManager.default.createFile(atPath: imagePath, contents: data, attributes: nil)
    return imagePath
}

