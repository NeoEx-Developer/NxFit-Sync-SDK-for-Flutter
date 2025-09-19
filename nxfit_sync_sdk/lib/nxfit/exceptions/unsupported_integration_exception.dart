class UnsupportedIntegrationException implements Exception {
    final String integration;
    final String message;

    UnsupportedIntegrationException(this.integration, {this.message = "The integration is not supported."});

    @override
    String toString() {
        return "UnsupportedIntegrationException - The integration is not supported on this device: $message";
    }
}
