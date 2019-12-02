import Flutter
import UIKit
import WeScan
import PDFKit

public class SwiftPdfscannerPlugin: NSObject, FlutterPlugin, ImageScannerControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
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
            let scanSource = argumentsMap["scanSource"] as! Int
            //let scannedImagesPath = argumentsMap["scannedImagesPath"] as! String
            //let scannedImageName = argumentsMap["scannedImageName"] as! String
            pendingResult = result
            let rootViewController: FlutterViewController! = UIApplication.shared.keyWindow?.rootViewController as! FlutterViewController
            if (scanSource == 4) {
                let scannerViewController = ImageScannerController()
                scannerViewController.imageScannerDelegate = self
                scannerViewController.provideImageData(<#T##data: UnsafeMutableRawPointer##UnsafeMutableRawPointer#>, bytesPerRow: <#T##Int#>, origin: <#T##Int#>, <#T##y: Int##Int#>, size: <#T##Int#>, <#T##height: Int##Int#>, userInfo: <#T##Any?#>)
                rootViewController.present(scannerViewController, animated: true)
            } else {
                let pickerController = UIImagePickerController()
                pickerController.delegate = self
                pickerController.allowsEditing = true
                pickerController.mediaTypes = ["public.image", "public.movie"]
                pickerController.sourceType = .photoLibrary
                rootViewController.present(pickerController, animated: true, completion: nil)
            }
            
            break
        case "generatePdf":
            let argumentsMap = call.arguments! as! [String:Any?]
            var imagesPaths : [String]? = nil
            if (argumentsMap["imagesPaths"] != nil) {
                imagesPaths = argumentsMap["imagesPaths"] as! [String]
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
            
            let pdfMetaData = [
              kCGPDFContextCreator: "AREASeys S.L",
              kCGPDFContextAuthor: "raywenderlich.com"
            ]
            let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
            let format = UIGraphicsPDFRendererFormat()
            format.documentInfo = pdfMetaData as [String: Any]
            let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
            let data = renderer.pdfData { (context) in
                do {
                    for imagePath in imagesPaths! {
                        print("generating pdf page for image: \(imagePath)")
                        context.beginPage()
                        let image = UIImage(contentsOfFile: imagePath)
                        image?.drawAsPattern(in: CGRect(
                            x: marginLeft,
                            y: marginTop,
                            width: Int(image?.size.width ?? 0),
                            height: Int(image?.size.height ?? 0))
                        )
                    }
                } catch {
                    print("error generating PDF page for imagePath... ")
                }
            }
            let document = PDFDocument(data: data)
            let pdfPath = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString).appendingPathComponent(pdfName)
            document?.write(toFile: pdfPath)
            result(pdfPath)
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

