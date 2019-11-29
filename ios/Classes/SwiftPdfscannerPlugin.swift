import Flutter
import UIKit

public class SwiftPdfscannerPlugin: NSObject, FlutterPlugin {
    
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
            let scannedImagesPath = argumentsMap["scannedImagesPath"] as! String
            let scannedImageName = argumentsMap["scannedImageName"] as! String
            
            let controller = ViewController()
            
            let rootViewController:UIViewController! = UIApplication.shared.keyWindow?.rootViewController
            if (rootViewController is UINavigationController) {
                (rootViewController as! UINavigationController).pushViewController(controller,animated:true)
            } else {
                let navigationController:UINavigationController! = UINavigationController(rootViewController: controller)
              rootViewController.present(navigationController, animated:true, completion:nil)
            }
            
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
