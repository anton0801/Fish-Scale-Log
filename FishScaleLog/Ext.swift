import Foundation
import SwiftUI

extension Double {
    func format(digits: Int = 2) -> String {
        if digits == 0 {
            return String(Int(self))
        }
        return String(format: "%.\(digits)f", self)
    }
}
