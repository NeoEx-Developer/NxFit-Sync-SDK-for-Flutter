class UnavailableIntegrationException implements Exception {
    final String integration;
    final String message;

    UnavailableIntegrationException(this.integration, {this.message = "The integration is not available. The user may need to update or install the appropriate app."});

    @override
    String toString() {
        return "UnavailableIntegrationException - The integration is not available on this device: $message";
    }
}
