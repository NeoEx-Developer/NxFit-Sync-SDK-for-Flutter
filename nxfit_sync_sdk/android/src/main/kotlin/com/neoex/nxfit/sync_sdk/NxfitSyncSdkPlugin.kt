package com.neoex.nxfit.sync_sdk

import android.os.Build
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.BasicMessageChannel
import io.flutter.plugin.common.StringCodec

/** NxfitSyncSdkPlugin */
class NxfitSyncSdkPlugin: FlutterPlugin, MethodCallHandler {
  companion object {
    const val TAG = "NxfitSyncSdkPlugin"
  }

  private lateinit var methodChannel : MethodChannel
  private lateinit var authChannel: BasicMessageChannel<String>

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    methodChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.neoex.sdk")
    methodChannel.setMethodCallHandler(this)

    authChannel = BasicMessageChannel(flutterPluginBinding.binaryMessenger, "com.neoex.sdk/authProvider", StringCodec.INSTANCE).apply {
      setMessageHandler { message, replyChannel ->
        message?.let { message ->
          Log.d(TAG, "Received message: $message")
        }

        replyChannel.reply(null)
      }
    }
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    Log.d(TAG, "Received method call: ${call.method}")

    when (call.method) {
      "configure" -> {
        Log.d(TAG, "Configuration set successfully")
        result.success(null)
      }

      "connect" -> {
        Log.d(TAG, "Connected successfully")
        result.success(null)
      }

      "disconnect" -> {
        Log.d(TAG, "Disconnected successfully")
        result.success(null)
      }

      //Expected true/false response
      "isConnected" -> {
        result.success(false)
      }

      "purgeCache" -> {
        Log.d(TAG, "Purged successfully")
        result.success(null)
      }

      "sync" -> {
        Log.d(TAG, "Synced successfully")
        result.success(null)
      }

      else -> {
        result.notImplemented()
      }
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    methodChannel.setMethodCallHandler(null)
  }
}
