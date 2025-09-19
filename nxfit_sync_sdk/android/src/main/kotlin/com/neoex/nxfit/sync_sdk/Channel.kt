package com.neoex.nxfit.sync_sdk

enum class Channel(val id: String) {
    Method("com.neoex.sdk"),
    Auth("com.neoex.sdk/authProvider"),
    Ready("com.neoex.sdk/readyState"),
}
