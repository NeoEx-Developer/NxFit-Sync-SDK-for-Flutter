package com.neoex.nxfit.sync_sdk

import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import androidx.activity.result.ActivityResultLauncher
import androidx.core.app.ActivityCompat
import androidx.health.connect.client.PermissionController
import androidx.health.connect.client.permission.HealthPermission
import androidx.health.connect.client.records.StepsRecord
import com.neoex.nxfit.ConfigurationProvider
import com.neoex.nxfit.NXFit
import com.neoex.nxfit.enums.HttpLoggerLevel
import com.neoex.nxfit.healthconnect.HealthConnectState
import com.neoex.nxfit.healthconnect.NXFitHealthConnect
import com.neoex.nxfit.healthconnect.runIfAnyPermissionGranted
import com.neoex.nxfit.logger.LogLevel
import com.neoex.nxfit.logger.Logger
import com.neoex.nxfit.logger.NxFitLogger
import com.neoex.nxfit.sync_sdk.exceptions.InvalidIntegrationException
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.BasicMessageChannel
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StringCodec
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.launch
import kotlinx.serialization.json.Json

/** NxfitSyncSdkPlugin */
class NxfitSyncSdkPlugin : FlutterPlugin, ActivityAware {
    companion object {
        private const val TAG = "NxfitSyncSdkPlugin"

        private const val INVALID_ARGUMENT = "INVALID_ARGUMENT"
        private const val UNSUPPORTED_INTEGRATION = "UNSUPPORTED_INTEGRATION"
        private const val ERROR = "ERROR"

        private const val HEALTH_CONNECT_IDENTIFIER = "health_connect"
    }

    private val accessTokenFlow = MutableStateFlow<String?>(null)
    private val coroutineScope = CoroutineScope(Dispatchers.IO)
    private val logger = NxFitLogger(TAG)

    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private lateinit var methodChannel: MethodChannel
    private lateinit var authChannel: BasicMessageChannel<String>
    private lateinit var readyStateChannel: EventChannel
    private var nxfit: NXFit? = null
    private var nxfitHealthConnect: NXFitHealthConnect? = null
    private var activity: Activity? = null
    private var readyStateSink: EventChannel.EventSink? = null

    private val fragmentActivity: FlutterFragmentActivity
        get() = activity as FlutterFragmentActivity

    private val applicationContext: Context
        get() = fragmentActivity.applicationContext

    private var permissionRequestLauncher: ActivityResultLauncher<Set<String>>? = null

    /**
     * This is a TEMPORARY configuration provider that provides the necessary configuration for NXFit.
     */
    private var configProvider: ConfigurationProvider? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel = MethodChannel(flutterPluginBinding.binaryMessenger, Channel.Method.id).apply {
            setMethodCallHandler { call, result ->
                logger.d("Received method call: ${call.method}")

                try {
                    when (call.method) {
                        Method.GetIntegrations.id -> {
                            coroutineScope.launch {
                                try {
                                    nxfitHealthConnect?.testHealthConnectAvailability(
                                        { result.success(getIntegrationListWithAvailability(HealthConnectState.Unsupported).toJson()) },
                                        { result.success(getIntegrationListWithAvailability(HealthConnectState.Unavailable).toJson()) },
                                        { result.success(getIntegrationListWithAvailability(HealthConnectState.Available).toJson()) }
                                    )
                                }
                                catch (e: Exception) {
                                    logger.e("Error getting integrations", e)
                                    result.error(ERROR, e.message, e)
                                }
                            }
                        }

                        Method.Configure.id -> {
                            configure(
                                call.argument("baseUrl") ?: "",
                                call.argument("httpLoggerLevel") ?: "none",
                                call.argument("minLogLevel") ?: "warn",
                            )

                            result.success("Configuration set successfully")
                        }

                        Method.Connect.id -> {
                            call.withArgument("integrationIdentifier") { integrationIdentifier ->
                                connect(integrationIdentifier)
                                result.success("Connected successfully")
                            }
                        }

                        Method.Disconnect.id -> {
                            call.withArgument("integrationIdentifier") { integrationIdentifier ->
                                disconnect(integrationIdentifier)
                                result.success("Disconnected successfully")
                            }
                        }

                        Method.PurgeCache.id -> {
                            coroutineScope.launch {
                                try {
                                    nxfitHealthConnect?.purgeLocalHealthConnectData()
                                    result.success("Local cache purged successfully")
                                }
                                catch (e: Exception) {
                                    logger.e("Error purging local cache", e)
                                    result.error(ERROR, e.message, e)
                                }
                            }
                        }

                        Method.SyncExerciseSessions.id -> {
                            coroutineScope.launch {
                                try {
                                    nxfitHealthConnect?.runIfAnyPermissionGranted {
                                        logger.d("*** SyncExerciseSessions")
                                        nxfitHealthConnect?.syncExerciseSessions()
                                    }

                                    result.success("Exercise sessions synced")
                                }
                                catch (e: Exception) {
                                    logger.e("Error syncing exercise sessions", e)
                                    result.error(ERROR, e.message, e)
                                }
                            }
                        }

                        Method.SyncDailyMetrics.id -> {
                            coroutineScope.launch {
                                try {
                                    nxfitHealthConnect?.runIfAnyPermissionGranted {
                                        logger.d("*** SyncDailyMetrics")
                                        nxfitHealthConnect?.syncDailyRecords()
                                    }

                                    result.success("Daily metrics synced")
                                }
                                catch (e: Exception) {
                                    logger.e("Error syncing daily metrics", e)
                                    result.error(ERROR, e.message, e)
                                }
                            }
                        }

                        else -> {
                            result.notImplemented()
                        }
                    }
                }
                catch (e: IllegalArgumentException) {
                    result.error(INVALID_ARGUMENT, e.message, null)
                }
                catch (e: InvalidIntegrationException) {
                    result.error(UNSUPPORTED_INTEGRATION, "${e.integrationIdentifier} is not supported. Only 'health_connect' integration is supported.", null)
                }
                catch (e: Exception) {
                    logger.e("Error handling method call", e)
                    result.error(ERROR, e.message, e)
                }
            }
        }

        authChannel = BasicMessageChannel(flutterPluginBinding.binaryMessenger, Channel.Auth.id,StringCodec.INSTANCE).apply {
            setMessageHandler { message, replyChannel ->
                message?.let { message ->
                    logger.v("Received message: $message")

                    val authMessage = Json.decodeFromString<AuthMessage>(message)

                    if (authMessage.userId == null) {
                        nxfit = null
                        logger.d("NXFit instance cleared due to null userId.")

                        CoroutineScope(Dispatchers.Main).launch {
                            accessTokenFlow.emit(null)
                            readyStateSink?.success(false);
                        }
                    } else {
                        logger.d("User ID: ${authMessage.userId}, Access Token: ${authMessage.accessToken?.take(10) ?: "" }...")

                        CoroutineScope(Dispatchers.Main).launch {
                            accessTokenFlow.emit(authMessage.accessToken)

                            configProvider?.let { configProvider ->
                                if (nxfit == null) {
                                    nxfit = NXFit.build(
                                        flutterPluginBinding.applicationContext,
                                        configProvider,
                                        userId = authMessage.userId,
                                        accessTokenFlow
                                    ).also {
                                        logger.d("NXFit built successfully.")

                                        nxfitHealthConnect = NXFitHealthConnect.build(it).apply {
                                            logger.d("NXFitHealthConnect built successfully.")

                                            testHealthConnectAvailability(
                                                { logger.i("Health Connect is unsupported on this device.") },
                                                { logger.i("Health Connect is unavailable. User action may be required to install or update it.") },
                                                { logger.i("Health Connect is available.") }
                                            )

                                            readyStateSink?.success(true);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                replyChannel.reply(null)
            }
        }

        readyStateChannel = EventChannel(flutterPluginBinding.binaryMessenger, Channel.Ready.id).apply {
            setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    logger.d("onListen called with arguments: $arguments")
                    readyStateSink = events
    }

                override fun onCancel(arguments: Any?) {
                    logger.d("onCancel called with arguments: $arguments")
                    readyStateSink = null
                }
            })
        }
    }

    private fun MethodCall.assertArgumentExists(name: String) {
        if (argument<String>(name) == null) {
            throw IllegalArgumentException("Argument '$name' is required")
        }
    }

    private fun MethodCall.withArgument(name: String, block: (String) -> Unit) {
        argument<String>(name)?.let { value ->
            if (value.isEmpty()) logger.e("Argument '$name' must not be empty.")

            block(value)
        } ?: throw IllegalArgumentException("Argument '$name' is required")
    }

    private fun connect(integrationIdentifier: String) {
        if (integrationIdentifier != HEALTH_CONNECT_IDENTIFIER) throw InvalidIntegrationException(integrationIdentifier)

        activity?.let { activity ->
            val perms = NXFitHealthConnect.allRequiredPermissions.toTypedArray()

            perms.forEach { perm ->
                logger.d("Permission $perm is ${if (PackageManager.PERMISSION_GRANTED == ActivityCompat.checkSelfPermission(activity, perm)) "granted" else "not granted"}")
            }

            permissionRequestLauncher?.launch(NXFitHealthConnect.allRequiredPermissions)

            coroutineScope.launch {
                nxfit?.integrationsManager?.connect(integrationIdentifier)
            }
        }
    }

    private fun disconnect(integrationIdentifier: String) {
        if (integrationIdentifier != HEALTH_CONNECT_IDENTIFIER) throw InvalidIntegrationException(integrationIdentifier)

        coroutineScope.launch {
            nxfit?.integrationsManager?.disconnect(integrationIdentifier)
        }
    }

    private fun getIntegrationListWithAvailability(availability: HealthConnectState) : LocalIntegrationList {
        return LocalIntegrationList(listOf(LocalIntegration(
            identifier = HEALTH_CONNECT_IDENTIFIER,
            isConnected = nxfitHealthConnect?.isConnected ?: false,
            availability = availability.id
        )));
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        coroutineScope.cancel("Detaching from Flutter engine, canceling coroutine jobs")
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity

        val contract = PermissionController.createRequestPermissionResultContract()

        permissionRequestLauncher = fragmentActivity.registerForActivityResult(contract) { grantedPermissions: Set<String> ->
            // TODO: Is this required?

            // logger.d(">>> Permission request result: $grantedPermissions")

            if (
                grantedPermissions.contains(HealthPermission.getReadPermission(StepsRecord::class))
            ) {
                // Read or process steps related health records.
            } else {
                // user denied permission
            }
        }
    }

    override fun onDetachedFromActivity() {
        activity = null
        permissionRequestLauncher = null
    }

    override fun onDetachedFromActivityForConfigChanges() {
        onDetachedFromActivity()
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    private fun configure(baseUrl: String, httpLoggerLevel: String, minLogLevel: String) {
        if (baseUrl.isEmpty()) throw IllegalArgumentException("baseUrl is required")

        Logger.minLogLevel = logLevelFromString(minLogLevel)

        logger.i("Configuring with baseUrl: $baseUrl, httpLoggerLevel: $httpLoggerLevel, minLogLevel: $minLogLevel")

        configProvider =  object : ConfigurationProvider {
            override val baseUrl: String = baseUrl
            override val httpLoggerLevel: HttpLoggerLevel = httpLoggerLevelFromString(httpLoggerLevel)
            override val minLogLevel: LogLevel = Logger.minLogLevel
            override val readTimeoutSeconds: Long = 20
        }
    }

    private fun logLevelFromString(level: String): LogLevel {
        return when (level.lowercase()) {
            "verbose" -> LogLevel.VERBOSE
            "debug" -> LogLevel.DEBUG
            "info" -> LogLevel.INFO
            "warn" -> LogLevel.WARN
            else -> LogLevel.WARN
        }
    }

    private fun httpLoggerLevelFromString(level: String): HttpLoggerLevel {
        return when (level.lowercase()) {
            "none" -> HttpLoggerLevel.NONE
            "basic" -> HttpLoggerLevel.BASIC
            "headers" -> HttpLoggerLevel.HEADERS
            "body" -> HttpLoggerLevel.BODY
            else -> HttpLoggerLevel.NONE
        }
    }

    private fun LocalIntegrationList.toJson(): String = Json.encodeToString(this);
}
