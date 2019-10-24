package com.areaseys.pdfscanner.pdfscanner

import android.content.Intent
import android.util.Log
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import io.flutter.plugin.common.PluginRegistry.Registrar

class ImagePdfScannerPlugin : MethodCallHandler, PluginRegistry.ActivityResultListener {

    companion object {

        private const val REQUEST_CODE_SCAN = 1
        private lateinit var registrar: Registrar

        @JvmStatic
        fun registerWith(registrar: Registrar) {
            val channel = MethodChannel(registrar.messenger(), "com.areaseys.imagepdfscanner.plugin")
            channel.setMethodCallHandler(ImagePdfScannerPlugin())
            this.registrar = registrar
        }
    }

    private var registeredForOnActivityResult: Boolean = false
    private var resultWaitingScan: Result? = null

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "scan" -> scan(
                result = result,
                scanSource = call.argument<Int>("scanSource") as Int,
                scannedImagesPath = call.argument<String>("scannedImagesPath") as String,
                scannedImageName = call.argument<String>("scannedImageName") as String
            )
            "generatePdf" -> generatePDF(
                result = result,
                imagesPaths = call.argument<List<String>>("imagesPaths") as List<String>,
                pdfName = call.argument<String>("pdfName") as String,
                generatedPDFsPath = call.argument<String>("generatedPDFsPath") as String,
                marginLeft = call.argument<Int>("marginLeft") as Int,
                marginRight = call.argument<Int>("marginRight") as Int,
                marginTop = call.argument<Int>("marginTop") as Int,
                marginBottom = call.argument<Int>("marginBottom") as Int,
                cleanScannedImagesWhenPdfGenerate = call.argument<Boolean>("cleanScannedImagesWhenPdfGenerate") as Boolean,
                pageWidth = call.argument<Int>("pageWidth") as Int,
                pageHeight = call.argument<Int>("pageHeight") as Int
            )
            else -> result.notImplemented()
        }
    }

    private fun scan(
        result: Result,
        scanSource: Int,
        scannedImagesPath: String,
        scannedImageName: String
    ) {
        try {
            if (!registeredForOnActivityResult) {
                registrar.addActivityResultListener(this)
            }
            resultWaitingScan = result
            val intent = Intent(registrar.activity(), ScanActivity::class.java)
            intent.putExtra(ScanActivity.BUNDLE_EXTRA_KEY_SCAN_SOURCE, scanSource)
            intent.putExtra(ScanActivity.BUNDLE_EXTRA_KEY_SCANNED_IMAGES_PATH, scannedImagesPath)
            intent.putExtra(ScanActivity.BUNDLE_EXTRA_KEY_SCANNED_IMAGE_NAME, scannedImageName)
            registrar.activity().startActivityForResult(intent, REQUEST_CODE_SCAN)
        } catch (ex: Exception) {
            result.success(ex.message)
        }
    }

    /**
     * Generates a pdf with images paths and return in method channel result
     * the generated pdf path.
     */
    private fun generatePDF(
        result: Result,
        imagesPaths: List<String>,
        pdfName: String,
        generatedPDFsPath: String,
        marginLeft: Int,
        marginRight: Int,
        marginTop: Int,
        marginBottom: Int,
        cleanScannedImagesWhenPdfGenerate: Boolean,
        pageWidth: Int,
        pageHeight: Int
    ) {
        try {
            val pdfPath = createPdf(
                imagesPaths,
                pdfName,
                generatedPDFsPath,
                marginLeft,
                marginRight,
                marginTop,
                marginBottom,
                cleanScannedImagesWhenPdfGenerate,
                pageWidth,
                pageHeight
            )
            result.success(pdfPath)
        } catch (ex: Exception) {
            result.error("ERROR!", ex.message, ex)
        }
    }


    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode == REQUEST_CODE_SCAN) {
            if (resultCode == ScanActivity.RESULT_CODE_OK) {
                try {
                    resultWaitingScan?.success(data?.getStringExtra(ScanActivity.BUNDLE_RESULT_KEY_SCANNED_IMAGE_PATH))
                } catch (ex: Exception) {
                    //nothing to do...
                    Log.e("Error on write result", ex.message)
                }
            } else if (resultCode == ScanActivity.RESULT_CODE_ERROR) {
                resultWaitingScan?.error("ERROR", "error on scan", null)
            }
        }
        return true
    }
}
