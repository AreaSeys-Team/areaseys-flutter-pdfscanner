#import "ImagePdfScannerPlugin.h"
#import <pdfscanner/pdfscanner-Swift.h>

@implementation ImagePdfScannerPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftPdfscannerPlugin registerWithRegistrar:registrar];
}
@end
