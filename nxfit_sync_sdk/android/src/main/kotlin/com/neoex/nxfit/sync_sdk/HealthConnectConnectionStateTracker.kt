package com.neoex.nxfit.sync_sdk

import android.content.Context
import android.content.SharedPreferences
import androidx.core.content.edit

/**
 * Tracks the connection state of Health Connect using SharedPreferences to persist the state.
 * What this means is that it only keeps track of whether the app is connected to Health Connect or not.
 * Use the the IntegrationsClient to manage the actual connection to Health Connect.
 * This class provides methods to connect and disconnect, updating the connection state accordingly.
 */
class HealthConnectConnectionStateTracker(appContext: Context) {
    var isConnected: Boolean
        get() = _isConnected
        set(isConnected) {
            _isConnected = isConnected
            sharedPref.edit { putBoolean("isConnected", _isConnected) }
        }

    private val sharedPref: SharedPreferences = appContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
    private var _isConnected: Boolean = sharedPref.getBoolean("isConnected", false)

    companion object {
        private const val PREFS = "HealthConnectPrefs"
    }

    fun connect() {
        isConnected = true
    }

    fun disconnect() {
        isConnected = false
    }
}
