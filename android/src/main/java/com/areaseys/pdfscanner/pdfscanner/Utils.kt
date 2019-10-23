package com.areaseys.pdfscanner.pdfscanner

import android.content.Context
import android.graphics.Bitmap
import android.net.Uri
import android.provider.MediaStore

import java.io.ByteArrayOutputStream
import java.io.IOException

/**
 * Created by jhansi on 05/04/15.
 * to kotlin by SantiiHoyos 23/10/2019
 */

fun getUri(context: Context, bitmap: Bitmap): Uri {
    val bytes = ByteArrayOutputStream()
    bitmap.compress(Bitmap.CompressFormat.PNG, 100, bytes)
    val path = MediaStore.Images.Media.insertImage(context.contentResolver, bitmap, "Title", "scanned by AREAseys.")
    return Uri.parse(path)
}

@Throws(IOException::class)
fun getBitmap(context: Context, uri: Uri): Bitmap = MediaStore.Images.Media.getBitmap(context.contentResolver, uri)