package com.areaseys.pdfscanner.pdfscanner

import android.content.Context
import android.graphics.Bitmap
import android.net.Uri
import android.os.Environment
import android.provider.MediaStore
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
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


@Throws(IOException::class)
fun getBitmap(context: Context, uri: Uri?): Bitmap = MediaStore.Images.Media.getBitmap(context.contentResolver, uri)