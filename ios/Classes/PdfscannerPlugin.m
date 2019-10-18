#import "PdfscannerPlugin.h"
#import <pdfscanner/pdfscanner-Swift.h>

@implementation PdfscannerPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftPdfscannerPlugin registerWithRegistrar:registrar];
}
@end
