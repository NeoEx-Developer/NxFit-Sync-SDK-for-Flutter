package com.neoex.nxfit.sync_sdk.exceptions

/**
 * The integration is not valid. This is because the only supported integration is Health Connect.
 */
class InvalidIntegrationException(val integrationIdentifier: String) : Exception("The integration is not valid. This is because the only supported integration is Health Connect.")
