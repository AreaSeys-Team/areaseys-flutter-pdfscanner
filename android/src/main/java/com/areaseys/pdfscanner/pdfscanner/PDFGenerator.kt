package com.areaseys.pdfscanner.pdfscanner

import android.graphics.BitmapFactory
import android.graphics.Rect
import android.graphics.pdf.PdfDocument
import android.os.Environment
import android.util.Log
import java.io.File
import java.io.FileOutputStream


fun createPdf(
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
): String {
    val pdfDoc = PdfDocument()
    for (imageForWrite in imagesPaths) {
        try {
            //dimens in points see: https://www.prepressure.com/library/paper-size
            val pageInfo = PdfDocument.PageInfo.Builder(pageWidth, pageHeight, imagesPaths.size)
            val page = pdfDoc.startPage(pageInfo.create())
            val pageCanvas = page.canvas
            val bitmap = BitmapFactory.decodeFile(imageForWrite)
            pageCanvas.drawBitmap(
                bitmap,
                Rect(0, 0, bitmap.width, bitmap.height),
                Rect(marginLeft, marginTop, pageWidth - marginRight, pageHeight - marginBottom),
                null
            )
            pdfDoc.finishPage(page)
        } catch (ex: Exception) {
            Log.e("PDFGenerator plugin: ", "error on generate page for $imageForWrite path.")
        }
    }
    val filePath = File(Environment.getExternalStorageDirectory().toString() + generatedPDFsPath)
    if (!filePath.exists()) {
        filePath.mkdirs()
    }
    val fileOutput = FileOutputStream("$filePath/$pdfName")
    pdfDoc.writeTo(fileOutput)
    fileOutput.flush()
    fileOutput.close()
    pdfDoc.close()

    if (cleanScannedImagesWhenPdfGenerate) {
        for (imageForDelete in imagesPaths) {
            File(imageForDelete).deleteOnExit()
        }
    }

    return "$filePath/$pdfName"
}