import Foundation

struct SimCtlDTO: Codable {
    let devices: [String: [SimCtlDevice]]
    
    struct SimCtlDevice: Codable {
        let name: String
        let udid: String
        let state: String
        let isAvailable: Bool
    }
}
