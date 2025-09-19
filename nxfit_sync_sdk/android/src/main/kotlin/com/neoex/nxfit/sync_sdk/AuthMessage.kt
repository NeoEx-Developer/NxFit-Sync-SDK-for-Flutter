package com.neoex.nxfit.sync_sdk

import kotlinx.serialization.Serializable

@Serializable
data class AuthMessage(
    val accessToken: String?,
    val userId: Int?
)
