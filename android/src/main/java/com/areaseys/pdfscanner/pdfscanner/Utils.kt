package com.areaseys.pdfscanner.pdfscanner

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Environment
import java.io.*
import java.util.*

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
fun getBitmap(uri: Uri, desiredHeight: Int, desiredWidth: Int): Bitmap {
    return decodeFile(File(uri.path))!!
}


@Throws(IOException::class)
fun getBitmapScaledByHeight(uri: Uri, desiredHeight: Int): Bitmap {
    val options = BitmapFactory.Options()
    options.inJustDecodeBounds = true
    val bitmap = BitmapFactory.decodeFile(uri.path, options)
    options.outWidth = (desiredHeight * bitmap.width) / bitmap.height
    options.outHeight = desiredHeight
    options.inJustDecodeBounds = false
    options.inBitmap = bitmap
    return BitmapFactory.decodeFile(uri.path, options)
}

@Throws(IOException::class)
fun getBitmapScaledByWidth(uri: Uri, desiredWidth: Int): Bitmap {
    val options = BitmapFactory.Options()
    options.inJustDecodeBounds = true
    val bitmap = BitmapFactory.decodeFile(uri.path, options)
    options.outWidth = desiredWidth
    options.outHeight = (desiredWidth * bitmap.height) / bitmap.width
    options.inJustDecodeBounds = false
    options.inBitmap = bitmap
    return BitmapFactory.decodeFile(uri.path, options)
}

val IMAGE_MAX_SIZE = 1500

private fun decodeFile(f: File): Bitmap? {
    var b: Bitmap? = null

    //Decode image size
    val o = BitmapFactory.Options()
    o.inJustDecodeBounds = true

    var fis = FileInputStream(f)
    BitmapFactory.decodeStream(fis, null, o)
    fis.close()

    var scale = 1
    if (o.outHeight > IMAGE_MAX_SIZE || o.outWidth > IMAGE_MAX_SIZE) {
        scale = Math.pow(2.0, Math.ceil(Math.log(IMAGE_MAX_SIZE / Math.max(o.outHeight, o.outWidth).toDouble()) / Math.log(0.5)).toInt().toDouble()).toInt()
    }

    //Decode with inSampleSize
    val o2 = BitmapFactory.Options()
    o2.inSampleSize = scale
    fis = FileInputStream(f)
    b = BitmapFactory.decodeStream(fis, null, o2)
    fis.close()

    return b
}