package com.neoex.nxfit.sync_sdk

enum class Method(val id: String) {
    Configure("configure"),
    Connect("connect"),
    Disconnect("disconnect"),
    GetIntegrations("getIntegrations"),
    PurgeCache("purgeCache"),
    ResetAndRetry("resetAndRetry"),
    SyncExerciseSessions("syncExerciseSessions"),
    SyncDailyMetrics("syncDailyMetrics"),
}
