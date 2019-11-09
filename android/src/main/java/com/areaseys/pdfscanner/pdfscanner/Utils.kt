package com.areaseys.pdfscanner.pdfscanner

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Environment
import java.io.*
import java.util.*
import kotlin.math.ceil
import kotlin.math.ln
import kotlin.math.max
import kotlin.math.pow

/**
 * Created by jhansi on 05/04/15.
 * to kotlin by SantiiHoyos 23/10/2019
 */


/**
 * Saves a bitmap and returns File
 */
fun saveImage(path: String, imageName: String, bitmap: Bitmap): String? {
    val root = Environment.getExternalStorageDirectory().toString()
    val file = File(root + path.replace(" ", "_"))
    if (!file.exists()) {
        file.mkdirs()
    }
    val finalPath = file.toString() + "/" + imageName.replace(" ", "_") + "${Date().time}.jpg"
    try {
        FileOutputStream(finalPath).use { fos ->
            bitmap.compress(Bitmap.CompressFormat.JPEG, 100, fos)
            fos.flush()
            return finalPath
        }
    } catch (ex: Exception) {
        return null
    }
}

/**
 * Get bitmap scaled by biggest desired side
 */
fun getBitmap(uri: Uri, desiredHeight: Int, desiredWidth: Int): Bitmap =
    decodeFile(File(uri.path), max(desiredHeight, desiredWidth))!!


/**
 * Optimized scaled image, for avoid OutMemoryErrors.
 */
private fun decodeFile(f: File, bigSize: Int): Bitmap? {
    val b: Bitmap?

    //Decode image size
    val o = BitmapFactory.Options()
    o.inJustDecodeBounds = true

    var fis = FileInputStream(f)
    BitmapFactory.decodeStream(fis, null, o)
    fis.close()

    var scale = 1
    if (o.outHeight > bigSize || o.outWidth > bigSize) {
        scale = 2.0.pow(ceil(ln(bigSize / max(o.outHeight, o.outWidth).toDouble()) / ln(0.5)).toInt().toDouble()).toInt()
    }

    //Decode with inSampleSize
    val o2 = BitmapFactory.Options()
    o2.inSampleSize = scale
    fis = FileInputStream(f)
    b = BitmapFactory.decodeStream(fis, null, o2)
    fis.close()

    return b
}