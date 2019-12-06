import Flutter
import UIKit
import PDFKit
import WeScan

public class SwiftPdfscannerPlugin: NSObject, FlutterPlugin, ImageScannerControllerDelegate {
    
    var pendingResult : FlutterResult?
    
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
            
            let rootViewController: FlutterViewController! = UIApplication.shared.keyWindow?.rootViewController as? FlutterViewController
            if (scanSource == 4) {
                let scannerViewController = ImageScannerController()
                scannerViewController.imageScannerDelegate = self
                rootViewController.present(scannerViewController, animated: true)
            } else {
                let imageForProcess = argumentsMap["imageForProcess"] as? String
                print("Scanning with image from gallery! image received: \(String(describing: imageForProcess))")
                if (imageForProcess != nil) {
                    let image = UIImage(contentsOfFile: imageForProcess!)
                    let scannerViewController = ImageScannerController(image: image!.rotate(radians: 0), delegate: self)
                    scannerViewController.imageScannerDelegate = self
                    let rootViewController: FlutterViewController! = UIApplication.shared.keyWindow?.rootViewController as? FlutterViewController
                    rootViewController.present(scannerViewController, animated: true)
                }
            }
            
            break
        case "generatePdf":
            let argumentsMap = call.arguments! as! [String:Any?]
            var imagesPaths : [String]? = nil
            if (argumentsMap["imagesPaths"] != nil) {
                imagesPaths = argumentsMap["imagesPaths"] as? [String]
            }
            let pdfName = argumentsMap["pdfName"] as! String
            //let generatedPDFsPath = argumentsMap["generatedPDFsPath"] as! String
            let marginLeft = argumentsMap["marginLeft"] as! Int
            let marginRight = argumentsMap["marginRight"] as! Int
            let marginTop = argumentsMap["marginTop"] as! Int
            let marginBottom = argumentsMap["marginBottom"] as! Int
            //let cleanScannedImagesWhenPdfGenerate = argumentsMap["cleanScannedImagesWhenPdfGenerate"] as! Bool
            let pageWidth = argumentsMap["pageWidth"] as! Int
            let pageHeight = argumentsMap["pageHeight"] as! Int
            
            result(
                generatePdf(
                    imagesPaths: imagesPaths!,
                    pageWidth: pageWidth,
                    pageHeight: pageHeight,
                    pdfName: pdfName,
                    marginLeft: marginLeft,
                    marginRight: marginRight,
                    marginTop: marginTop,
                    marginBottom: marginBottom)
            )
            break
        default:
            result(FlutterError(code: "error", message: "Not Implemented!", details: nil))
            break
        }
    }
    
    public func imageScannerController(_ scanner: ImageScannerController, didFinishScanningWithResults results: ImageScannerResults) {
        print("Saving scanned image...")
        var path : String?
        if results.doesUserPreferEnhancedImage {
            path = (results.enhancedImage ?? results.scannedImage).savePicture(imageName: "scanned_\(Date().millisecondsSince1970).jpg")
        } else {
            path = results.scannedImage.savePicture(imageName: "scanned_\(Date().millisecondsSince1970).jpg")
        }
        
        if pendingResult != nil {
            pendingResult!(path)
        }
        scanner.dismiss(animated: true, completion: nil)
    }
    
    public func imageScannerControllerDidCancel(_ scanner: ImageScannerController) {
        scanner.dismiss(animated: true, completion: nil)
    }
    
    public func imageScannerController(_ scanner: ImageScannerController, didFailWithError error: Error) {
        scanner.dismiss(animated: false, completion: nil)
    }
}


/**
 Generates PDF documents with image paths
 returns path of genetared pdf or nil on error.
 */
func generatePdf(
    imagesPaths: [String],
    pageWidth: Int,
    pageHeight: Int,
    pdfName: String,
    marginLeft: Int,
    marginRight: Int,
    marginTop: Int,
    marginBottom: Int
) -> String? {
    let pdfMetaData = [
        kCGPDFContextCreator: "AREASeys S.L",
        kCGPDFContextAuthor: "areaseys.com"
    ]
    let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
    let format = UIGraphicsPDFRendererFormat()
    format.documentInfo = pdfMetaData as [String: Any]
    let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
    let data = renderer.pdfData { (context) in
        for imagePath in imagesPaths {
            context.beginPage(withBounds: pageRect, pageInfo: [:])
            let image = UIImage(contentsOfFile: imagePath)
            
            //rescaling... <-- (Copy-paste from Android Kotlin source mantain updated this code in both platforms)
            var rescaledByWidth = false
            let originalHeight = Int(image?.size.height ?? 0)
            let originalWidth = Int(image?.size.width ?? 0)
            var finalHeight = originalHeight
            var finalWidth = originalWidth
            let availableHeight = pageHeight - (marginTop + marginBottom)
            let availableWidth = pageWidth - (marginLeft + marginRight)
            if (originalWidth > availableWidth) { //width overflows, scaling by width
                finalWidth = availableWidth
                finalHeight = (availableWidth * originalHeight) / originalWidth
                if (finalHeight > availableHeight) { //height overflows in height after rescaled, scale by height...
                    finalWidth = (availableHeight * finalWidth) / finalHeight
                    finalHeight = availableHeight
                }
                rescaledByWidth = true
            }
            if (!rescaledByWidth && originalHeight > availableHeight) { //height overflows, scaling by height...
                finalHeight = availableHeight
                finalWidth = (availableHeight * originalWidth) / originalHeight
            }
            
            //Center image if it is necessary
            var plusForHorizontalCenter = 0
            if (finalWidth < availableWidth) {
                let difference = availableWidth - finalWidth
                plusForHorizontalCenter = difference / 2
            }
            
            let leftOffset = marginLeft + plusForHorizontalCenter
            let topOffset = marginTop
            
            image!.resize(targetSize: CGSize(width: finalWidth, height: finalHeight)).draw(in: CGRect(
                x: leftOffset,
                y: topOffset,
                width: finalWidth,
                height: finalHeight)
            )
        }
    }
    let document = PDFDocument(data: data)
    let pdfPath = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString).appendingPathComponent(pdfName)
    document?.write(toFile: pdfPath)
    return pdfPath
}

extension UIImage {
    
    func rotate(radians: Float) -> UIImage? {
        var newSize = CGRect(origin: CGPoint.zero, size: self.size).applying(CGAffineTransform(rotationAngle: CGFloat(radians))).size
        newSize.width = floor(newSize.width)
        newSize.height = floor(newSize.height)
        UIGraphicsBeginImageContextWithOptions(newSize, false, self.scale)
        let context = UIGraphicsGetCurrentContext()!
        context.translateBy(x: newSize.width/2, y: newSize.height/2)
        context.rotate(by: CGFloat(radians))
        self.draw(in: CGRect(x: -self.size.width/2, y: -self.size.height/2, width: self.size.width, height: self.size.height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
    
    func resize(targetSize: CGSize) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: targetSize.width, height: targetSize.height)
        UIGraphicsBeginImageContextWithOptions(targetSize, false, 1.0)
        self.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
    
    func savePicture(imageName: String) -> String {
        let imagePath = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString).appendingPathComponent(imageName)
        let data = UIImagePNGRepresentation(self)
        FileManager.default.createFile(atPath: imagePath, contents: data, attributes: nil)
        return imagePath
    }
}

/**
 Date extension for allow get milliseconds since 1970 of any Date object.
 */
extension Date {
    var millisecondsSince1970:Int64 {
        return Int64((self.timeIntervalSince1970 * 1000.0).rounded())
    }

    init(milliseconds:Int64) {
        self = Date(timeIntervalSince1970: TimeInterval(milliseconds) / 1000)
    }
}
