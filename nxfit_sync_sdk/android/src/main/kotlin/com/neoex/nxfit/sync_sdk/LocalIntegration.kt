package com.neoex.nxfit.sync_sdk

import kotlinx.serialization.Serializable

@Serializable
data class LocalIntegration(
    var identifier: String,
    var isConnected: Boolean,
    var availability: String
)

@Serializable
data class LocalIntegrationList(
    val integrations: List<LocalIntegration>
)
