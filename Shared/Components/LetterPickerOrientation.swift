//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

enum LetterPickerOrientation: String, CaseIterable, Defaults.Serializable, Displayable {

    case leading
    case trailing

    var displayTitle: String {
        switch self {
        case .leading:
            return L10n.left
        case .trailing:
            return L10n.right
        }
    }
}
