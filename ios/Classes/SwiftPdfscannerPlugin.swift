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
            let rootViewController: FlutterViewController! = UIApplication.shared.keyWindow?.rootViewController as? FlutterViewController
            if (scanSource == 4) {
                let scannerViewController = ImageScannerController()
                scannerViewController.imageScannerDelegate = self
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

/**
 Saves one UIImage with specified name and returns the path of saved image.
 */
func savePicture(picture: UIImage, imageName: String) -> String {
    let imagePath = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString).appendingPathComponent(imageName)
    let data = UIImagePNGRepresentation(picture)
    FileManager.default.createFile(atPath: imagePath, contents: data, attributes: nil)
    return imagePath
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
            
            //rescaling... <-- (Copy-paste from Android Kotlin source)
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
            let rightOffset = leftOffset + finalWidth
            let topOffset = marginTop
            let bottomOffset = finalHeight
            
            resizeImage(image: image!, targetSize: CGSize(width: finalWidth, height: finalHeight)).draw(in: CGRect(
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

 func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
    let size = image.size

    let widthRatio  = targetSize.width  / size.width
    let heightRatio = targetSize.height / size.height

    // Figure out what our orientation is, and use that to form the rectangle
    var newSize: CGSize
    if(widthRatio > heightRatio) {
        newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
    } else {
        newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
    }

    // This is the rect that we've calculated out and this is what is actually used below
    let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)

    // Actually do the resizing to the rect using the ImageContext stuff
    UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
    image.draw(in: rect)
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()

    return newImage!
}
