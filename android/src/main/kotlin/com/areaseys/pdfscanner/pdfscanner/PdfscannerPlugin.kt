package com.areaseys.pdfscanner.pdfscanner

import android.content.Context
import android.content.Intent
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar

class PdfscannerPlugin : MethodCallHandler {

  companion object {

    private lateinit var context: Context

    @JvmStatic
    fun registerWith(registrar: Registrar) {
      val channel = MethodChannel(registrar.messenger(), "pdfscanner")
      channel.setMethodCallHandler(PdfscannerPlugin())
      context = registrar.context()
    }

    lateinit var result: Result
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "scan" -> scan(result, call.arguments as Int)
      else -> result.notImplemented()
    }
  }

  private fun scan(result: Result, source: Int) {
    PdfscannerPlugin.result = result
    try {
      val intent = Intent(context, ScanActivity::class.java)
      intent.putExtra("SOURCE", source)
      intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
      context.startActivity(intent)
    } catch (ex: Exception) {
      result.success(ex.message)
    }
  }


}
