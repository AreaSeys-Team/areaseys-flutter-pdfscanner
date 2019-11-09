package com.areaseys.pdfscanner.pdfscanner

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Rect
import android.graphics.pdf.PdfDocument
import android.net.Uri
import android.os.AsyncTask
import android.os.Environment
import android.util.Log
import androidx.core.content.ContextCompat
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
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
    pageHeight: Int,
    callBack: (generatedPdfPath: String) -> Unit
) {
    AsyncTask.execute {
        val pdfDoc = PdfDocument()
        val options = BitmapFactory.Options()
        //options.inSampleSize = 2
        var bitmap: Bitmap?
        for (imageForWrite in imagesPaths) {
            try {
                //dimens in points see: https://www.prepressure.com/library/paper-size
                val pageInfo = PdfDocument.PageInfo.Builder(pageWidth, pageHeight, imagesPaths.size)
                val page = pdfDoc.startPage(pageInfo.create())
                val pageCanvas = page.canvas
                bitmap = getBitmap(Uri.fromFile(File(imageForWrite)), pageHeight, pageWidth)

                //rescaling...
                var rescaledByWidth = false
                val originalHeight = bitmap.height
                val originalWidth = bitmap.width
                var finalHeight = originalHeight
                var finalWidth = originalWidth
                val availableHeight = pageHeight - (marginTop + marginBottom)
                val availableWidth = pageWidth - (marginLeft + marginRight)
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
                    val difference = availableWidth - finalWidth
                    plusForHorizontalCenter = difference / 2
                }

                val leftOffset = marginLeft + plusForHorizontalCenter
                val rightOffset = leftOffset + finalWidth
                val topOffset = marginTop
                val bottomOffset = finalHeight

                //Draw into page...
                pageCanvas.drawBitmap(bitmap!!, Rect(0, 0, bitmap.width, bitmap.height), Rect(leftOffset, topOffset, rightOffset, bottomOffset), null)
                pdfDoc.finishPage(page)
                bitmap.recycle()
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
                File(imageForDelete).delete() //scanned image
                val originalImage = imageForDelete.substring(0, imageForDelete.length - 4) + "_original.png"
                File(originalImage).delete() //original image
            }
        }
        callBack("$filePath/$pdfName")
    }
}