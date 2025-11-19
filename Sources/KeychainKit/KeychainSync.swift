//
// Project: KeychainKit
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import Foundation

public enum KeychainSync {
    case localOnly
    case iCloud

    var attributeValue: Any? {
        switch self {
            case .localOnly:  return nil
            case .iCloud:     return kCFBooleanTrue
        }
    }
}
