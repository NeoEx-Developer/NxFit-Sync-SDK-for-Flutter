import Foundation
import NXFitModels

internal struct LocalIntegration : Encodable {
    let identifier: String
    let isConnected: Bool
    let availability: IntegrationAvailability
}

internal struct LocalIntegrationList : Encodable {
    let integrations: [LocalIntegration]
}

internal enum IntegrationAvailability : String, Encodable {
    case available = "available"
}
